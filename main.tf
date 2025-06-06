variable "region" {
  default = "eu-north-1"
}

variable "project_name" {
    default = "arqiva"
}

provider "aws" {
  region = var.region
}

#craete a random suffix to make the bucket name unique
resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "website" {
    bucket = "${var.project_name}-website-${random_id.suffix.hex}"
    force_destroy = true
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"
}

#enable public access to bucket
resource "aws_s3_bucket_public_access_block" "website_public_access" {
    bucket = aws_s3_bucket.website.id
    block_public_policy     = false
    restrict_public_buckets = false
}

#allow public read access to index.html
resource "aws_s3_bucket_policy" "public_index_html" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.website.bucket}/${aws_s3_object.index_html.key}"
    }]
  })
}

data "archive_file" "lambda_func_zip" {
    type = "zip"
    source_file = "lambda_func.py"
    output_path = "lambda_func.zip"
}

#neccessary for creating the lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "webtite-updater-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

#attach basic execution role to give CloudWatch access to the lambda function
resource "aws_iam_role_policy_attachment" "lambda_exec_role_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#create policy to allow lambda function to change the index.html file in the bucket
resource "aws_iam_role_policy" "lambda_s3_put_acess_policy" {
  name = "lambda-s3-put-access-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.website.bucket}/${aws_s3_object.index_html.key}"
      }
    ]
  })
}

resource "aws_lambda_function" "website_updater" {
    function_name = "${var.project_name}_website_updater"
    filename = data.archive_file.lambda_func_zip.output_path
    source_code_hash = data.archive_file.lambda_func_zip.output_base64sha256
    role = aws_iam_role.lambda_exec_role.arn
    handler = "lambda_func.lambda_handler"
    runtime = "python3.11"
    timeout = 10

    environment {
        variables = {
            "BUCKET_NAME" = aws_s3_bucket.website.bucket
        }
    }
}

#create a public url for the lambda function
resource "aws_lambda_function_url" "public_url" {
  function_name      = aws_lambda_function.website_updater.function_name
  authorization_type = "NONE"
}

#allow public invoke to the lambda function
resource "aws_lambda_permission" "allow_public_invoke" {
  statement_id            = "AllowPublicFunctionURLInvoke"
  action                  = "lambda:InvokeFunctionUrl"
  function_name           = aws_lambda_function.website_updater.function_name
  principal               = "*"
  function_url_auth_type  = "NONE"
}

output "website_url" {
  value = "https://${aws_s3_bucket.website.bucket}.s3.amazonaws.com/${aws_s3_object.index_html.key}"
}

output "updater_url" {
  value = aws_lambda_function_url.public_url.function_url
}

