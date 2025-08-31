terraform {
  required_version = ">= 1.6"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

provider "aws" { region = var.region }

locals { tags = { Project = "pcsoft", Env = "bootstrap" } }

resource "aws_s3_bucket" "tf" { bucket = var.state_bucket  tags = local.tags }
resource "aws_s3_bucket_versioning" "tf" {
  bucket = aws_s3_bucket.tf.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "tf" {
  bucket = aws_s3_bucket.tf.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}
resource "aws_s3_bucket_public_access_block" "tf" {
  bucket = aws_s3_bucket.tf.id
  block_public_acls = true; block_public_policy = true
  ignore_public_acls = true; restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute { name = "LockID"; type = "S" }
  tags = local.tags
}

variable "region"       { type = string  default = "us-east-2" }
variable "state_bucket" { type = string  default = "pcsoft-tfstate-CHANGE-ME" }
variable "lock_table"   { type = string  default = "pcsoft-tflock" }
