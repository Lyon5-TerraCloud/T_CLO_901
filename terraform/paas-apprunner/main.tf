terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }

locals { tags = { Project="pcsoft", Env=var.env, Stack="paas" } }

resource "aws_ecr_repository" "app" {
  name = var.ecr_repo_name
  image_scanning_configuration { scan_on_push = true }
  tags = local.tags
}

data "aws_iam_policy_document" "apprunner_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service" identifiers = ["build.apprunner.amazonaws.com", "tasks.apprunner.amazonaws.com", "apprunner.amazonaws.com"] }
  }
}

resource "aws_iam_role" "apprunner_ecr" {
  name               = "pcsoft-apprunner-ecr"
  assume_role_policy = data.aws_iam_policy_document.apprunner_trust.json
  tags = local.tags
}

resource "aws_iam_role_policy" "apprunner_ecr_policy" {
  role = aws_iam_role.apprunner_ecr.id
  policy = jsonencode({
    Version="2012-10-17",
    Statement=[{
      Effect="Allow",
      Action=[
        "ecr:GetAuthorizationToken","ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage","ecr:GetDownloadUrlForLayer","logs:CreateLogStream",
        "logs:PutLogEvents","logs:CreateLogGroup"
      ],
      Resource="*"
    }]
  })
}

resource "aws_apprunner_service" "app" {
  service_name = "pcsoft-apprunner"
  source_configuration {
    authentication_configuration { access_role_arn = aws_iam_role.apprunner_ecr.arn }
    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_configuration { port = var.container_port }
    }
    auto_deployments_enabled = true
  }
  tags = local.tags
}

output "ecr_repo_url"     { value = aws_ecr_repository.app.repository_url }
output "apprunner_url"    { value = aws_apprunner_service.app.service_url }
variable "region"         { type=string  default="us-east-2" }
variable "env"            { type=string  default="dev" }
variable "ecr_repo_name"  { type=string  default="pcsoft-app" }
variable "container_port" { type=string  default="80" }
