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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_iam_role.name
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

resource "aws_api_gateway_rest_api" "example_rest_api" {
  name        = "example_rest_api"
  description = "Example API Gateway with Lambda and Custom Authorizer"
}

resource "aws_api_gateway_resource" "example_api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_rest_api.id
  parent_id   = aws_api_gateway_rest_api.example_rest_api.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_method" "example_api_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_rest_api.id
  resource_id   = aws_api_gateway_resource.example_api_gateway_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.auth0_authorizer.id
}

resource "aws_api_gateway_integration" "example_api_gateway_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_rest_api.id
  resource_id             = aws_api_gateway_resource.example_api_gateway_resource.id
  http_method             = aws_api_gateway_method.example_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_lambda_backend_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example_rest_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "example_api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.example_api_gateway_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.example_rest_api.id
}

resource "aws_api_gateway_stage" "example_api_gateway_stage" {
  deployment_id = aws_api_gateway_deployment.example_api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.example_rest_api.id
  stage_name    = "sandbox"
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.example_api_gateway_deployment.invoke_url}${aws_api_gateway_stage.example_api_gateway_stage.stage_name}${aws_api_gateway_resource.example_api_gateway_resource.path}"
}
