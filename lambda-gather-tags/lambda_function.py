import boto3
import os

def get_instances_with_tag(region, instance_backup_key):
    instance_list = []
    try:
            rds = boto3.client('rds', region_name=region)
            paginator = rds.get_paginator('describe_db_instances').paginate()
            for page in paginator:
                for dbinstance in page['DBInstances']:
                    instance_dict = {}
                    cluster_id = dbinstance["DBClusterIdentifier"]
                    cluster_status = dbinstance["DBInstanceStatus"]
                    instance_id = dbinstance["DBInstanceIdentifier"]
                    instance_endpoint = get_nested(dbinstance, "Endpoint", "Address")
                    instance_username = dbinstance["MasterUsername"]
                    instance_backup_tag = check_tag_in_list(dbinstance["TagList"], instance_backup_key)
                    instance_secret_name = get_tag_in_list(dbinstance["TagList"], "backup:db-secret-name")
                    instance_dict = dict({ \
                        'cluster_id': cluster_id, \
                        'cluster_status': cluster_status, \
                        'instance_id': instance_id, \
                        'instance_endpoint': instance_endpoint, \
                        'instance_username': instance_username, \
                        'instance_secret_name': instance_secret_name, \
                        'instance_backup_tag': instance_backup_tag})
                    if instance_backup_tag == 'True':
                        instance_list.append(instance_dict)
    except Exception as e:
        print(e)
    return instance_list

def get_nested(data, *args):
    if args and data:
        element  = args[0]
        if element:
            value = data.get(element)
            return value if len(args) == 1 else get_nested(value, *args[1:])

def check_tag_in_list(list, key):
    for item in list:
        if item["Key"] == key and item["Value"] == "True":
            return item["Value"]
    return "False"

def get_tag_in_list(list, key):
    for item in list:
        if item["Key"] == key:
            return item["Value"]
    return "False"

def lambda_handler(event, context):

    '''
    incoming payload must conform to:
        { 
        "instance_backup_key": "backup:db-automated"
        }
    '''
    region = os.environ['AWS_REGION']

    try:
        instance_backup_key = get_nested(event, "instance_backup_key")
        # get instances that are active and have the backup key set
        return_payload = get_instances_with_tag(region, instance_backup_key)
    except Exception as e:
        print(e)
    finally:
        print(return_payload)
        return {
        "statusCode": 200,
        "body": return_payload
        }