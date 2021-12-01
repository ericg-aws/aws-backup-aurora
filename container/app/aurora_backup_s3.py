import boto3
import base64
from botocore.exceptions import ClientError
import datetime
import json
import os
import psycopg2
import subprocess

def get_nested(data, *args):
    if args and data:
        element  = args[0]
        if element:
            value = data.get(element)
            return value if len(args) == 1 else get_nested(value, *args[1:])

def get_date():
    current_date = datetime.datetime.utcnow().strftime("%Y%m%d")
    return current_date

def get_time():
    current_time = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    return current_time

def get_secret(secret_name, region):
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
            return json.loads(secret) 
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
            return decoded_binary_secret

def perform_db_backup(base_path, instance_username, instance_password, instance_host, instance_port, instance_db, s3_bucket, env_path, region):
    print(f'Backing up {instance_db} database from cluster {instance_host}')
    current_time = get_time()
    current_date = get_date()
    s3_file = f'{base_path}/{current_date}/data-{instance_host}-{instance_db}-{current_time}.dmp'
    command1 =  f'PATH={env_path} ' \
                f'pg_dump --host={instance_host} ' \
                f'--username={instance_username} ' \
                f'--no-password ' \
                f'--port={instance_port} ' \
                f'-Z 9 ' \
                f'{instance_db}'

    command2 =  f'PATH={env_path} ' \
                f'aws s3 cp - --region={region} ' \
                f's3://{s3_bucket}/{s3_file}' 

    try:
        bufsize = 1024 * 1024 * 1 # 1MB

        proc1 = subprocess.Popen(command1, shell=True, stdin=subprocess.PIPE, \
            stdout=subprocess.PIPE, bufsize=bufsize, env={
            'PGPASSWORD': instance_password
            })

        proc2 = subprocess.Popen(command2, shell=True, stdin=proc1.stdout, stdout=subprocess.PIPE)
        proc2.wait()

    except Exception as e:
            print(f'Exception during dump of {instance_db} database from cluster {instance_host}')
            print(e)

def perform_roles_backup(base_path, instance_username, instance_password, instance_host, instance_port, s3_bucket, env_path, region):
    print(f'Backing up roles from cluster {instance_host}')
    current_time = get_time()
    current_date = get_date()
    s3_file = f'{base_path}/{current_date}/roles-{instance_host}-{current_time}.dmp'

    command1 =  f'PATH={env_path} ' \
                f'pg_dumpall --host={instance_host} ' \
                f'--username={instance_username} ' \
                f'--no-password ' \
                f'--port={instance_port} ' \
                f'--no-role-passwords --roles-only ' 
    
    command2 =  f'PATH={env_path} ' \
                f'aws s3 cp - --region={region} ' \
                f's3://{s3_bucket}/{s3_file}' 

    try:
        bufsize = 1024 * 1024 * 1 # 1MB

        proc1 = subprocess.Popen(command1, shell=True, stdin=subprocess.PIPE, \
            stdout=subprocess.PIPE, bufsize=bufsize, env={
            'PGPASSWORD': instance_password
            })

        proc2 = subprocess.Popen(command2, shell=True, stdin=proc1.stdout, stdout=subprocess.PIPE)
        proc2.wait()
    except Exception as e:
        print(f'Exception during dump of roles data from cluster {instance_host}')
        print(e)

def get_db_list(instance_username, instance_password, instance_host, instance_port, instance_db):
    print(f'Getting database list from cluster {instance_host}')
    conn_string = f'host={instance_host} dbname={instance_db} user={instance_username} password={instance_password} port={instance_port}'
    db_list_clean = []
    try:
        conn = psycopg2.connect(conn_string)
        cur = conn.cursor()
        cur.execute('SELECT datname FROM pg_database')
        db_list = cur.fetchall()
        cur.close()

        # clean unwanted databases
        for db in db_list:
            db_string = str(db)
            db_string = db_string.translate({ord(i):None for i in '(),\''})
            if db_string not in ['template0', 'template1', 'postgres', 'rdsadmin']:
                db_list_clean.append(db_string)
        return db_list_clean
    except Exception as e:
        cur.close()
        print(f'Exception getting database list from cluster {instance_host}')
        print(e)

def main():
    # required env variables in container 
    region = os.environ['AWS_REGION']
    secret_name = os.environ['instance_secret_name']
    s3_bucket = os.environ['s3_bucket']
    # having database env variable set is optional
    specific_db = os.getenv('specific_db', False)
    env_path = os.getenv('PATH', '/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin')

    # gather secret and associated details
    secret_dict = get_secret(secret_name, region)
    instance_username = get_nested(secret_dict, 'username')
    instance_password = get_nested(secret_dict, 'password')
    instance_host =  get_nested(secret_dict, 'host')
    instance_port =  get_nested(secret_dict, 'port')
    instance_db =  get_nested(secret_dict, 'dbname')

    # if no ad hoc backup specified - no specific DB value set, backup all databases
    if specific_db:
        print(f'Backing up single database of: {specific_db}, on host: {instance_host}')
        base_path = 'adhoc'
        perform_db_backup(base_path, instance_username, instance_password, instance_host, instance_port, specific_db, s3_bucket, env_path, region)
        perform_roles_backup(base_path, instance_username, instance_password, instance_host, instance_port, s3_bucket, env_path, region)
    else:
        print(f'Backing up all databases on host: {instance_host}')
        base_path = 'scheduled'
        # get a list of non default databases 
        db_list_clean = get_db_list(instance_username, instance_password, instance_host, instance_port, instance_db)
        # perform a dump of each database on the cluster
        for instance_db in db_list_clean:
            perform_db_backup(base_path, instance_username, instance_password, instance_host, instance_port, instance_db, s3_bucket, env_path, region)
        # perform roles only backup for all DBs
        perform_roles_backup(base_path, instance_username, instance_password, instance_host, instance_port, s3_bucket, env_path, region)

if __name__ == "__main__":
    main()
