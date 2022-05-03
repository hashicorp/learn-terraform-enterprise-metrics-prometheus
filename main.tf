terraform {
  required_version = ">= 0.14.9" 
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Provider Block
provider "aws" {
  region  = var.aws_region
  profile = "default"
}

# Create Security Group resource
resource "aws_security_group" "education-example-sg" {
  name        = "education-example-sg"
  description = "Learn tutorial Security Group"
  
ingress {
    description = "Allow all IP and Ports Inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all IP and Ports Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  
  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2",
    ]
  }

}

 resource "aws_iam_role" "education_example_role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": "ec2.amazonaws.com"
       },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
 }
 EOF
 }

 resource "aws_iam_instance_profile" "education_example_profile" {
  name = "education_example_profile"
  role = "${aws_iam_role.education_example_role.name}"
}

 resource "aws_iam_role_policy" "education_example_policy" {
  name        = "education-example-policy"
  role        = "${aws_iam_role.education_example_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:Describe*",
            "Resource": "*"
        }
    ]
}
 EOF
 }

# Create EC2 Instance
resource "aws_instance" "example_learn_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.education-example-sg.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = "${aws_iam_instance_profile.education_example_profile.name}"
  user_data = templatefile("prometheus-install.sh.tftpl", { tfe_tag_name = var.tfe_tag_name, aws_region = var.aws_region })
  tags = {
    "Name" = "example_learn_instance"
  }    
}

# The IP address of your test EC2 instance will be display in this output after the Terraform apply command completes.
 output "b_prometheus_dashboard_ip" {
   description = "Prometheus instance dashboard"
   value       = "http://${aws_instance.example_learn_instance.public_ip}:9090/graph"
 }

 output "c_grafana_dashboard_ip" {
   description = "Grafana instance dashboard"
   value       = "http://${aws_instance.example_learn_instance.public_ip}:3000"
 }





