# AWS RDS/Aurora Postgres Logical Backup

![Alt text](diagram.jpg?raw=true "Title")

# Summary
Solution for automating Logical backups up RDS or Aurora PostgreSQL databases via pg_dump utility. The pg_dump utility uses the COPY command to create a schema and data dump of a PostgreSQL database. This is quite useful because, it allows even a single row to be restored or an individual database to a lower environment. Also the workflow allows for scheduled or ad hoc based backups.

A cron-based Amazon EventBridge rule initiates an AWS Step Function. The Step Function, triggers a Lambda that searches for specific backup tags applied to Aurora instances. If the PostgreSQL DB instances have the "backup:db-automated = True" tag, the Step Function the passes the list of dinctionaries to a Map state. Map state will execute the same ESC task steps for multiple entries of an list. The ECS tasks perform the scheduled backup for all non-default databases in the cluster. Ad hoc databases are also allowed when specifying specific databases. Backups are stored in S3 with lifecycle rules based on path.

## Prerequisites
- RDS master user password storaged in Secrets Manager 
- RDS instances properly tagged
- Existing VPC and Subnets setup prior
- RDS security group access gives 
- Container image pushed to a public repo  

## Inputs

Following Terraform inputs are needed to be updated in the vars file.
```bash
# common
project         = "backup-aurora"
environment     = "prod"
region          = "us-east-1"

vpc_id              = "vpc-1064165af4a32147"
vpc_subnet_ids      = ["subnet-072bc74918e01aa2", "subnet-08d25f37ef83b9014", "subnet-0e81e346b2426b067"]

# eventbridge
tag_backup = "backup:db-automated"
event_cron = "cron(*/4 * * * ? *)"

# ecs
container_image   = "public.ecr.aws/o6n4m6y4/backup-aurora-postgres:latest"
container_comm01  = "python"
container_comm02  = "aurora_backup_s3.py"
container_mem     = 2048
container_cpu     = 1024

# s3
s3_bucket               = "backup-aurora-20211130"
s3_days_until_glacier   = 15
s3_days_until_expiry    = 60
```

## Deployment 

```bash
terraform apply -var-file=us-east-1-examples.tfvars
```

## Ad hoc usage 

To backup a specific database (e.g. db04), perform:
```bash
aws ecs run-task --cluster backup-aurora-clu01 --overrides file:///ecs-task-overrides.json --task-definition backup-aurora:24
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
