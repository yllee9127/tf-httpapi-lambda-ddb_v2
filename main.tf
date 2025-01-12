data "aws_caller_identity" "current" {}

locals {
  name_prefix = split("/", "${data.aws_caller_identity.current.arn}")[1]
}

#resource "aws_cloudwatch_log_group" "lambda_logs" {
  #name = "/moviedb-api/yl"
#  name = "/aws/lambda/${aws_lambda_function.http_api_lambda.function_name}"

#}

resource "aws_cloudwatch_log_metric_filter" "info_count" {
  name = "info-count"
  log_group_name = aws_cloudwatch_log_group.function_log_group.name  # Replace <alias> with your actual alias or variable
  
  
  pattern = "[INFO]"
  metric_transformation {
    name          = "info-count"
    namespace     = "/moviedb-api/yl"  # Replace <alias> with your actual alias or variable
    value         = "1"
    default_value = 0
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarm" {
  alarm_name          = "yl-info-count-breach"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "info-count"
  namespace           = "/moviedb-api/yl"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = " "
  actions_enabled     = "true"
  alarm_actions       = [aws_sns_topic.topic.arn]
}

resource "aws_sns_topic" "topic" {
  name = "yl_CloudWatch_Alarms_Topic"
}

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "yllee9127@gmail.com"
}
