terraform {
  backend "s3" {
    bucket         = "pcsoft-tfstate-CHANGE-ME"
    key            = "iaas/dev/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "pcsoft-tflock"
    encrypt        = true
  }
}
