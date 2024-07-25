terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 3.27"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terras3" { //public access default
  bucket = "terras3"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "privaccess" {
    bucket = aws_s3_bucket.terras3.id //making the S3 private

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
  
}

resource "aws_iam_policy" "bucket_policy" { // creating bucket policy 
  name        = "buckpol"
  path        = "/"
  description = "Allow "
  policy = jsonencode({
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "VisualEditor0",
      "Effect" : "Allow",
      "Action" : [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource" : [
        "arn:aws:s3:::*/*",
        "arn:aws:s3:::terras3"
      ]
    }
  ]
})
}
//create an IAM role to attach this policy to
resource "aws_iam_role" "EC2-S3" {
  name = "EC2-S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "some_bucket_policy" {//attach iam role to policy
  role       = aws_iam_role.EC2-S3.name
  policy_arn = aws_iam_policy.bucket_policy.arn
}

resource "aws_iam_instance_profile" "some_profile" {//creating iam instance profile for attaching to EC2
  name = "ec2-iam-profile"
  role = aws_iam_role.EC2-S3.name
}
resource "aws_instance" "web_instances" {//create an ec2 instance with this iam profile attached to it
  ami           = var.amiid
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.some_profile.id
}
