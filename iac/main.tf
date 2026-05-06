locals {
  name_prefix = "${var.project}-${var.environment}"
  bucket_name = "${var.project}-${var.environment}-images-${var.suffix}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}
