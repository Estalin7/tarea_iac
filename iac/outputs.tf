output "api_url" {
  description = "URL del endpoint para subir imágenes"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.buckets.id
}

output "sqs_queue_url" {
  description = "URL de la cola SQS principal"
  value       = aws_sqs_queue.main.id
}

output "sqs_dlq_url" {
  description = "URL de la Dead-Letter Queue"
  value       = aws_sqs_queue.dlq.id
}

output "upload_lambda" {
  description = "Nombre de la función upload"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda" {
  description = "Nombre de la función crop"
  value       = aws_lambda_function.crop.function_name
}

output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}
