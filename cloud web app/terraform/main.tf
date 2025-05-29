provider "aws" {
  region = var.aws_region   # <-- Change your AWS region here
}

##########################
# IAM Role & Policy for EC2 to access S3 bucket
##########################

resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_read_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
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
          "arn:aws:s3:::${var.bucket_name}",        # bucket itself (for list)
          "arn:aws:s3:::${var.bucket_name}/*"       # all objects in bucket
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_s3_policy" {
  user       = aws_iam_user.jenkins_user.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}


resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

##########################
# Security Group for EC2 instance
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
# S3 Bucket to store Flask app ZIP
##########################

resource "aws_s3_bucket" "static_files" {
  bucket = var.bucket_name  # <-- Change your bucket name here
}

resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

##########################
# EC2 Instance running Flask app
##########################

resource "aws_instance" "web_server" {
  ami                    = var.ami_id       # <-- Change to your AMI ID (e.g. Amazon Linux 2)
  instance_type          = "t2.micro"
  key_name               = var.key_name     # <-- Change to your EC2 Key Pair Name
  subnet_id              = var.subnet_id    # <-- Change to your subnet ID
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name        = "flask-web-server"
    Environment = "production"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 unzip awscli
              cd /home/ec2-user
              aws s3 cp s3://${var.bucket_name}/flask-app.zip flask-app.zip
              unzip -o flask-app.zip -d flask-app
              cd flask-app
              pip3 install -r requirements.txt
              nohup python3 app.py > app.log 2>&1 &
              EOF
}
