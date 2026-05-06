
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project}-${var.environment}-images-dlq"
  message_retention_seconds = 1209600 

  tags = {
     Name = "${local.name_prefix}-images-dlq"
     project = "procesador-imagenes"
     Env = var.environment
     }
}

resource "aws_sqs_queue" "main" {
  name                       = "${local.name_prefix}-cola-imagenes"
  visibility_timeout_seconds = 360
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20 

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })

  tags = { 
    Name = "${local.name_prefix}-images-queue" 
    project = "procesador-imagenes"
    Env = var.environment
    }
}

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
      Sid    = "AllowS3SendMessage"
      Effect = "Allow"
      Principal = {
         Service = "s3.amazonaws.com"
          }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.main.arn
      Condition = {
        ArnLike = { 
            "aws:SourceArn" = aws_s3_bucket.buckets.arn 
        }
      }
    }]
  })
}

resource "aws_cloudwatch_metric_alarm" "dlq_alarm" {
  alarm_name          = "${local.name_prefix}-dlq-messages"
  alarm_description   = "Hay mensajes en la DLQ — revisar logs del crop Lambda"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
     QueueName = aws_sqs_queue.dlq.name 
     }

  tags = {
     Name = "${local.name_prefix}-dlq-alarm" 
      project = "procesador-imagenes"
      Env = var.environment
     }
}
