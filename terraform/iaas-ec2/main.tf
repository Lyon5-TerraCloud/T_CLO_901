terraform {
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}
provider "aws" { region = var.region }

locals { tags = { Project="pcsoft", Env=var.env, Stack="iaas" } }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { name = "name"; values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

resource "aws_security_group" "web" {
  name        = "pcsoft-iaas-sg"
  description = "HTTP/SSH"
  vpc_id      = data.aws_vpc.default.id
  ingress { from_port=80  to_port=80  protocol="tcp" cidr_blocks=["0.0.0.0/0"] }
  ingress { from_port=22  to_port=22  protocol="tcp" cidr_blocks=[var.allowed_ssh_cidr] }
  egress  { from_port=0   to_port=0   protocol="-1"  cidr_blocks=["0.0.0.0/0"] }
  tags = local.tags
}

data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" { filter { name="vpc-id" values=[data.aws_vpc.default.id] } }

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name      = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    usermod -aG docker ubuntu
    systemctl enable --now docker
    docker pull ${var.app_image}
    docker run -d --restart unless-stopped -p 80:80 --name app ${var.app_image}
  EOF

  tags = merge(local.tags, { Name="pcsoft-iaas-web" })
}

output "ec2_public_ip"   { value = aws_instance.web.public_ip }
output "ec2_public_dns"  { value = aws_instance.web.public_dns }
output "ec2_name_tag"    { value = "pcsoft-iaas-web" }

variable "region"           { type=string default="us-east-2" }
variable "env"              { type=string default="dev" }
variable "instance_type"    { type=string default="t3.micro" }
variable "key_name"         { type=string } # Use an existing EC2 key pair name
variable "allowed_ssh_cidr" { type=string default="0.0.0.0/0" } # tighten later
variable "app_image"        { type=string default="nginx:alpine" } # replace with your ECR image
