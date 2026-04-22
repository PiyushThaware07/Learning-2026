terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Variables =========================================
variable "bucket_name" {
  type    = string
  default = "imagify"
}

variable "lambda_zip_path" {
  type    = string
  default = "function.zip"
}

# Resources =========================================

# Create S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-bucket"
  force_destroy = true
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to access S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda-s3-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

# Create Lambda Function from local ZIP
resource "aws_lambda_function" "lambda" {
  function_name = "imagify-lambda"

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  memory_size   = 1024
  timeout       = 30
  architectures = ["arm64"]

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.bucket.bucket
    }
  }
}

# Allow S3 to trigger Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

# S3 Event Notification -> Lambda trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
