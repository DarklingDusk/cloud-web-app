provider "aws" {
  region = var.aws_region
}

##########################
# Use existing IAM User: web-app-user
##########################

data "aws_iam_user" "jenkins_user" {
  user_name = "web-app-user"
}

resource "aws_iam_policy" "s3_read_write_policy" {
  name = "s3_read_write_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.bucket_name}",
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_s3_policy" {
  user       = data.aws_iam_user.jenkins_user.user_name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

##########################
# Security Group for EC2
##########################

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and HTTPS inbound traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##########################
# S3 Bucket
##########################

resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

##########################
# EC2 Instance to run Flask (manual run)
##########################

resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # No IAM instance profile since you manage IAM roles manually

  tags = {
    Name        = "flask-web-server"
    Environment = "production"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 unzip awscli
              # Flask app deployment and start will be done manually by you
              EOF
}
