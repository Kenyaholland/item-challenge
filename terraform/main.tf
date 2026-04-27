
# defines with cloud provider to use and the region
provider "aws" { 
  region = var.aws_region
}

##################################################################
## AWS Lambda functions:

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
resource "aws_lambda_function" "api_lambda" {
  filename = "placeholder.zip" //deployment is not required
  function_name = var.lambda_name
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"

  runtime = "nodejs20.x"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.exam_items.name
    }
  }
}

##################################################################
## API Gateway and endpoint Lambda Functions:

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.lambda_name}-api"
}

# This defines the URL path /items
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id = aws_api_gateway_rest_api.api.root_resource_id
  path_part = "items"
}

# HTTP METHOD: GET /items
resource "aws_api_gateway_method" "get_items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = "GET"
  authorization = "NONE" # no auth for simplicity but this is where it would be implemented
}

# HTTP METHOD: POST /items
resource "aws_api_gateway_method" "post_items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id
  http_method = "POST"
  authorization = "NONE" # no auth for simplicity but this is where it would be implemented
}

# Connects API Gateway to Lambda function using proxy integration for GET requests
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration
resource "aws_api_gateway_integration" "lambda_get" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id

  http_method = aws_api_gateway_method.get_items.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"

  uri = aws_lambda_function.api_lambda.invoke_arn
}

# Connects API Gateway to Lambda function using proxy integration for POST requests
resource "aws_api_gateway_integration" "lambda_post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.items.id

  http_method = aws_api_gateway_method.post_items.http_method

  integration_http_method = "POST"
  type = "AWS_PROXY"

  uri = aws_lambda_function.api_lambda.invoke_arn
}

# TODO add other endpoints

# Permission for API Gateway to invoke Lambda
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_lambda.function_name
  principal = "apigateway.amazonaws.com"

  # Allows any stage/method on this API to invoke Lambda
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

##################################################################
## DynamoDB table

# Store ExamItems
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table
resource "aws_dynamodb_table" "exam_items" {
  name = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  # Primary key used for GetItem queries
  hash_key = "id"

  # Defines attribute type for partition key
  attribute {
    name = "id"
    type = "S" # String type
  }
}

##################################################################
## IAM roles and policies

# This defines a role that AWS Lambda assumes when it runs
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}-role"

  # Trust policy: allows Lambda service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
    }]
  })
}

# Grants Lambda permission to interact with DynamoDB table: Get, create, update, and query
resource "aws_iam_role_policy" "dynamodb_access" {
  role = aws_iam_role.lambda_role.id
  name = "${var.lambda_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      Resource = aws_dynamodb_table.exam_items.arn
    }]
  })
}

##################################################################
## CloudWatch Logs:
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission#cloudwatch-log-group-integration

resource "aws_lambda_permission" "logging" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.logging.function_name
  principal     = "logs.us.east-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.default.arn}:*"
}

resource "aws_cloudwatch_log_group" "default" {
  name = "/default"
}

resource "aws_cloudwatch_log_subscription_filter" "logging" {
  depends_on      = [aws_lambda_permission.logging]
  destination_arn = aws_lambda_function.logging.arn
  filter_pattern  = ""
  log_group_name  = aws_cloudwatch_log_group.default.name
  name            = "logging_default"
}

resource "aws_lambda_function" "logging" {
  filename      = "lamba_logging.zip"
  function_name = "lambda_called_from_cloudwatch_logs"
  handler       = "exports.handler"
  role          = aws_iam_role.default.arn
  runtime       = "python3.12"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "default" {
  name               = "iam_for_lambda_called_from_cloudwatch_logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}