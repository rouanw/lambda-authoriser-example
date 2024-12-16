provider "aws" {
  region = "eu-west-2"
}

data "archive_file" "example_lambda_archive" {
  type        = "zip"
  source_dir  = "../src/example_lambda"
  output_path = "example_lambda.zip"
}

data "aws_iam_policy_document" "lambda_execution_policy" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution_iam_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_execution_policy.json
  name               = "lambda_execution_iam_role"
}

resource "aws_lambda_function" "example_lambda" {
  filename      = "example_lambda.zip"
  function_name = "example_lambda"
  role          = aws_iam_role.lambda_execution_iam_role.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.example_lambda_archive.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      none = "sense"
    }
  }
}
