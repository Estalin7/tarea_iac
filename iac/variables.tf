variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno: dev | qa | prod"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "El entorno debe ser dev, qa o prod."
  }
}

variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "image-processor"
}

variable "suffix" {
  description = "Sufijo único para nombres globales (ej: últimos 6 dígitos de tu Account ID)"
  type        = string
}

# VPC
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "true = 1 NAT GW (barato). false = 2 NAT GW (HA para prod)"
  type        = bool
  default     = true
}

# Lambda
variable "upload_memory" {
  type    = number
  default = 256
}

variable "crop_memory" {
  type    = number
  default = 512
}

variable "upload_timeout" {
  type    = number
  default = 30
}

variable "crop_timeout" {
  type    = number
  default = 60
}

# SQS
variable "sqs_visibility_timeout" {
  type    = number
  default = 360
}

variable "sqs_retention" {
  type    = number
  default = 86400
}

variable "sqs_max_receive_count" {
  type    = number
  default = 3
}

# S3 lifecycle
variable "uploads_expiration_days" {
  type    = number
  default = 30
}

variable "processed_expiration_days" {
  type    = number
  default = 90
}

# CloudWatch
variable "log_retention_days" {
  type    = number
  default = 14
}
