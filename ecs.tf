module "ecs" {
  source                              = "terraform-aws-modules/ecs/aws"  
  version                             = ">= 3.4.1"
  name                                = "${var.project}-clu01"
  container_insights                  = true
  capacity_providers                  = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE_SPOT"
    }
  ]
  tags                                = local.common_tags
}

resource "aws_ecs_task_definition" "task1" {
  family                    = "${var.project}"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  task_role_arn             = aws_iam_role.ecs_task_role.arn
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn
  cpu                       = var.container_cpu
  memory                    = var.container_mem
  container_definitions = templatefile("${path.module}/input-files/ecs-task-def.json", {
    name = "${var.project}-task01",
    region = var.region,
    log_group = module.log_group.cloudwatch_log_group_name,
    container_image = var.container_image
    container_comm01 = var.container_comm01
    container_comm02 = var.container_comm02
    container_mem = var.container_mem
    container_cpu = var.container_cpu
    task_role = aws_iam_role.ecs_task_role.arn
  })
  tags                    = local.common_tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-execution"
  tags = local.common_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-task"
  tags = local.common_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs-secrets" {
  name        = "${var.project}-01-ecs-secrets"
  path        = "/"
  description = "allow ECS task to read secrets starting with aurora"
  policy = file("${path.module}/input-files/iam-ecs-secrets.json")
}

resource "aws_iam_policy" "ecs-s3" {
  name        = "${var.project}-01-ecs-s3"
  path        = "/"
  description = "allow ECS task to read backup s3 buckets"
  policy = templatefile("${path.module}/input-files/iam-ecs-s3.json", {
    s3_bucket = aws_s3_bucket.backup_bucket.arn
  })
}

# attach to existing policy to allow Amazon ECS to add permissions for 
# future features and enhancements as they are introduced
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role        = aws_iam_role.ecs_task_execution_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# task role for container permissions 
resource "aws_iam_role_policy_attachment" "ecs-s3" {
  role        = aws_iam_role.ecs_task_role.name
  policy_arn  = aws_iam_policy.ecs-s3.arn
}

# task role for container permissions 
resource "aws_iam_role_policy_attachment" "ecs-secrets" {
  role        = aws_iam_role.ecs_task_role.name
  policy_arn  = aws_iam_policy.ecs-secrets.arn
}

module "log_group" {
  source            = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version           = ">= 2.1, < 3.0"
  name              = "/aws/ecs/${var.project}"
  retention_in_days = 3
}