
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.project}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name    = "/aws/apigateway/${var.project}-${var.environment}"
    Project = var.project
    Env     = var.environment
  }
}



resource "aws_cloudwatch_log_group" "upload_lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}-upload"
  retention_in_days = 14

  tags = {
    Name    = "/aws/lambda/${var.project}-${var.environment}-upload"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_cloudwatch_log_group" "crop_lambda" {
  name              = "/aws/lambda/${var.project}-${var.environment}-crop"
  retention_in_days = 14

  tags = {
    Name    = "/aws/lambda/${var.project}-${var.environment}-crop"
    Project = var.project
    Env     = var.environment
  }
}

resource "aws_sns_topic" "dlq_alarm" {
  name = "${var.project}-${var.environment}-dlq-alarm-topic"

  tags = {
    Name    = "${var.project}-${var.environment}-dlq-alarm-topic"
    Project = var.project
    Env     = var.environment
  }
}


resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project}-${var.environment}-dlq-messages-alarm"
  alarm_description   = "Alerta cuando el DLQ tiene mensajes visibles — indica fallos en crop-lambda"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm.arn]

  tags = {
    Name    = "${var.project}-${var.environment}-dlq-messages-alarm"
    Project = var.project
    Env     = var.environment
  }
}