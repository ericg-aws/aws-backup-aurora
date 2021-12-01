module "lambda_function" {
  source          = "terraform-aws-modules/lambda/aws"
  version         = ">=2.27.1"

  function_name   = "${var.project}-gather-tags"
  description     = "Gather RDS/Aurora instances tags for backup consideration"
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"

  source_path     = "./lambda-gather-tags/lambda_function.py"

  cloudwatch_logs_retention_in_days = 7
  cloudwatch_logs_tags              = local.common_tags

  role_name = "${var.project}-lambda"
  role_tags = local.common_tags
  attach_policy_json = true
  policy_json = file("${path.module}/input-files/iam-lambda.json")

  tags            = local.common_tags
}
