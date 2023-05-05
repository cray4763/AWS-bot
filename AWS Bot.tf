# Define provider
provider "aws" {
  region = "us-east-1"
}

# Define IAM role for the machine learning bot
resource "aws_iam_role" "ml_bot_role" {
  name = "ml_bot_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Define IAM policy for the machine learning bot
resource "aws_iam_policy" "ml_bot_policy" {
  name = "ml_bot_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::example-email-bucket/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::example-email-bucket"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = [
          "${aws_sqs_queue.serial_numbers_queue.arn}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::example-serial-number-bucket/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = [
          "${aws_dynamodb_table.serial_numbers_table.arn}"
        ]
      }
    ]
  })
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "ml_bot_role_policy_attachment" {
  policy_arn = "${aws_iam_policy.ml_bot_policy.arn}"
  role       = "${aws_iam_role.ml_bot_role.name}"
}

# Define an SQS queue for the machine learning bot to send serial numbers to
resource "aws_sqs_queue" "serial_numbers_queue" {
  name = "serial_numbers_queue"
}

# Define an S3 bucket for the machine learning bot to read emails from
resource "aws_s3_bucket" "email_bucket" {
  bucket = "example-email-bucket"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Define an S3 bucket for the machine learning bot to write serial numbers to
resource "aws_s3_bucket" "serial_number_bucket" {
  bucket = "example-serial-number-bucket"
  acl    = "private"

  lifecycle {
    prevent_destroy = true
  }
}

# Define a DynamoDB table to store the serial numbers
resource "aws_dynamodb_table" "serial_numbers_table" {
  name = "serial_numbers_table"

  attribute {
    name = "serial_number"
    type = "S"
  }

  key {
    name = "serial_number"
    type = "HASH"
  }

  billing_mode = "PAY_PER_REQUEST"
}

# Define an EC2 instance to run the machine learning bot
resource "aws_instance" "ml_bot_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2
}

# Add tags to the EC2 instance
tags = {
Name = "ml_bot_instance"
}

# Associate the IAM role with the EC2 instance
iam_instance_profile = "${aws_iam_instance_profile.ml_bot_instance_profile.id}"

# Define user data for the EC2 instance to run the machine learning bot
user_data = <<-EOF
#!/bin/bash

          # Install necessary packages
          yum -y update
          yum install -y python3-pip git
          
          # Clone the machine learning bot repository
          git clone https://github.com/example/ml-bot.git
          
          # Install dependencies
          cd ml-bot
          pip3 install -r requirements.txt
          
          # Run the machine learning bot
          python3 bot.py
          EOF
# Define an IAM instance profile for the EC2 instance to assume the IAM role
resource "aws_iam_instance_profile" "ml_bot_instance_profile" {
name = "ml_bot_instance_profile"

role = "${aws_iam_role.ml_bot_role.name}"

# Define a security group for the EC2 instance
resource "aws_security_group" "ml_bot_security_group" {
name_prefix = "ml_bot_sg"

ingress {
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

# Associate the security group with the EC2 instance
resource "aws_security_group_rule" "ml_bot_sg_rule" {
type = "ingress"
from_port = 0
to_port = 65535
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
security_group_id = "${aws_security_group.ml_bot_security_group.id}"
}

# Output the public IP address of the EC2 instance
output "ml_bot_instance_public_ip" {
value = "${aws_instance.ml_bot_instance.public_ip}"
}
}