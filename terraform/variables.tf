variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for Flask app ZIP"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch EC2 instance"
  type        = string
}
