data "archive_file" "authorizer_lambda_archive" {
  type        = "zip"
  source_dir  = "../src/authorizer_lambda"
  output_path = "authorizer_lambda.zip"
}

data "aws_iam_policy_document" "gateway_invocation_policy_document" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_lambda_function" "auth0_authorizer_lambda" {
  filename      = "authorizer_lambda.zip"
  function_name = "auth0_authorizer_lambda"
  role          = aws_iam_role.lambda_execution_iam_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
}

resource "aws_iam_role" "gateway_invocation_role" {
  name               = "api_gateway_auth_invocation"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.gateway_invocation_policy_document.json
}

resource "aws_iam_role_policy" "gateway_invocation_policy" {
  name = "default"
  role = aws_iam_role.gateway_invocation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.auth0_authorizer_lambda.arn
      }
    ]
  })
}

resource "aws_api_gateway_authorizer" "auth0_authorizer" {
  name                   = "auth0_authorizer"
  rest_api_id            = aws_api_gateway_rest_api.example_rest_api.id
  type                   = "REQUEST"
  authorizer_uri         = aws_lambda_function.auth0_authorizer_lambda.invoke_arn
  authorizer_credentials = aws_iam_role.gateway_invocation_role.arn
}
