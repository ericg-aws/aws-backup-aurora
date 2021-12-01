module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"
  version = ">= 1.13.1"
  attach_sfn_policy = false
  sfn_target_arns = [module.step_function.state_machine_arn]
  # will use default bus
  create_bus = false

  rules = {
    aurora-backup = {
      description         = "Trigger Aurora backup Step Function every 5 minutes"
      schedule_expression = var.event_cron
    }
  }

  targets = {
    aurora-backup = [
      {
        name  = "${var.project}-trigger"
        arn   = module.step_function.state_machine_arn
        input = jsonencode({ "instance_backup_key": "${var.tag_backup}" })
        attach_role_arn = true
      }
    ]
  }

  role_name = "${var.project}-eventbridge"
  role_tags = local.common_tags
  attach_policy_json = true
  policy_json = templatefile("${path.module}/input-files/iam-eventbridge.json", {
    step_function_arn = module.step_function.state_machine_arn
  })

  tags = local.common_tags
}