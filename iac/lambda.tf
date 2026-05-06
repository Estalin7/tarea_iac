data "archive_file" "upload" {
  type        = "zip"
  source_dir  = ".../src/lambda/upload"
  output_path = ".../src/lambda/upload.zip"
}

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = ".../src/lambda/crop"
  output_path = ".../src/lambda/crop.zip"
}


resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${local.name_prefix}-upload"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/${local.name_prefix}-crop"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "upload" {
  function_name    = "${local.name_prefix}-upload"
  description      = "Recibe imágenes y las guarda en S3 uploads/"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = aws_iam_role.upload.arn
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256
  
  memory_size      = 256
  timeout          = 30

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.buckets.bucket
      UPLOAD_PREFIX = "uploads/"
    }
  }

  vpc_config {
    subnet_ids         = [
        aws_subnet.private[0].id,
        aws_subnet.private[1].id
    ]
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.upload_basic_execution,
    aws_iam_role_policy_attachment.upload_vpc,
    aws_cloudwatch_log_group.upload
    ]
}


resource "aws_lambda_function" "crop" {
  function_name    = "${local.name_prefix}-crop"
  description      = "Lee SQS, recorta imagen a 40x40 circular PNG"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  role             = aws_iam_role.crop.arn
  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256
  
  
  memory_size      = 512
  timeout          = 60
  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.buckets.bucket
      upload_prefix    = "uploads/"
      PROCESSED_PREFIX = "processed/"
    }
  }

  vpc_config {
    subnet_ids         = [
        aws_subnet.private[0].id,
        aws_subnet.private[1].id
        ]
    
    security_group_ids = [
        aws_security_group.crop_lambda.id
        ]
  }

  depends_on = [
    aws_cloudwatch_log_group.crop,
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.sqs,
    aws_vpc_endpoint.logs,
    ]

}


resource "aws_lambda_event_source_mapping" "sqs_to_crop" {
  event_source_arn                   = aws_sqs_queue.main.arn
  function_name                      = aws_lambda_function.crop.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 0
  function_response_types            = ["ReportBatchItemFailures"]

  enabled = true
}
