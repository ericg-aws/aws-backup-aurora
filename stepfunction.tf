module "step_function" {
  source  = "terraform-aws-modules/step-functions/aws"
  version = ">= 2.5.0"

  create  = true
  name    = "${var.project}-01"

  type              = "standard"
  trusted_entities  = ["events.amazonaws.com"]
  definition        = templatefile("${path.module}/input-files/stepfunction-definition.json", {
    step_function_arn = module.lambda_function.lambda_function_arn,
    ecs_cluster_arn   = module.ecs.ecs_cluster_arn,
    ecs_task_arn      = aws_ecs_task_definition.task1.arn,
    vpc_subnet_ids    = var.vpc_subnet_ids
    security_group_id = module.sgr_ecs.security_group_id
    s3_bucket         = var.s3_bucket
  })

  use_existing_cloudwatch_log_group = true
  cloudwatch_log_group_name         = aws_cloudwatch_log_group.step_function_log_group.name

  # can change down to ERROR level at later time 
  logging_configuration = {
    include_execution_data = true
    level                  = "ALL"
  }
  depends_on = [aws_cloudwatch_log_group.step_function_log_group]

  attach_policy = true
  policy        = aws_iam_policy.ecs.arn

  tags          = local.common_tags
}

resource "aws_cloudwatch_log_group" "step_function_log_group" {
  name = "/${var.project}-01/step-function"
}

resource "aws_iam_policy" "ecs" {
  name        = "${var.project}-01-ecs"
  path        = "/"
  description = "Run Task and pass role to ECS"
  policy = templatefile("${path.module}/input-files/iam-stepfunction-ecs.json", { 
      project       = var.project
      ecs_task1_arn = aws_ecs_task_definition.task1.arn
      lambda_arn    = module.lambda_function.lambda_function_arn
    }
  )
}