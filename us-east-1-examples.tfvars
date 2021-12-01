# common
project         = "backup-aurora"
environment     = "prod"
region          = "us-east-1"

vpc_id              = "vpc-1064165af4a39147"
vpc_subnet_ids      = ["subnet-072bc74918e01aa2", "subnet-08d25f37ef83b9014", "subnet-0e81e346b2426b067"]

# security groups
sgr_ingress_cidr_blocks     = ["192.168.0.0/16"]
sgr_cidr_blocks             = "192.168.1.20/32"

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
s3_days_until_glacier   = 14
s3_days_until_expiry    = 90