#Provider Block

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      hashicorp-learn = "prometheus_metrics"
    }
  }

}

#Create Security Group resource

resource "aws_security_group" "prometheus_allow_all" {
  name        = "prometheus_allow_all"
  description = "Learn tutorial Security Group for prometheus instance"

  ingress {
    description = "Allow port 9090 inbound"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow port 3000 inbound"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow port 80 inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow port 443 inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow port 9090 outbound"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow port 3000 outbound"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow port 80 outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow port 443 outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#data source which will retrieve AMI of existing Terraform Enterprise instance

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

#data source which will retrieve subnet_id of existing Terraform Enterprise instance

data "aws_instance" "get_existing_tfe_subnet_id" {
  filter {
    name   = "tag:Name"
    values = [var.tfe_tag_name]
  }
  filter {
    name   = "image-id"
    values = [data.aws_ami.amazon_linux.id]
  }
}

#Create aws_iam_role resource

resource "aws_iam_role" "prometheus_aws_iam_role" {
  name = "prometheus_aws_iam_role"

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

#Create aws_iam_instance_profile resource

resource "aws_iam_instance_profile" "prometheus_iam_instance_profile" {
  name = "prometheus_iam_instance_profile"
  role = aws_iam_role.prometheus_aws_iam_role.name
}

#Create aws_iam_role_policy resource

resource "aws_iam_role_policy" "prometheus_iam_role_policy" {
  name = "prometheus_iam_role_policy"
  role = aws_iam_role.prometheus_aws_iam_role.id

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

resource "aws_instance" "prometheus_instance" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.prometheus_allow_all.id]
  subnet_id              = data.aws_instance.get_existing_tfe_subnet_id.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.prometheus_iam_instance_profile.name
  user_data              = templatefile("prometheus-install.sh.tftpl", { tfe_tag_name = var.tfe_tag_name, aws_region = var.aws_region })
  tags = {
    "Name" = "prometheus_instance"
  }
}