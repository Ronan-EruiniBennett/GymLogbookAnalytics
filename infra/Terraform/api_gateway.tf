// Using API GatewayV2 to create a http API
resource "aws_apigatewayv2_api" "httpAPI" {
  name          = "gym-log-API"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["Content-Type", "Authorization"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_origins     = ["https://${var.subdomain}"]
    max_age           = 3600
  }

  description = "A Post HTTP API, to send json data from frontend to lambda for transformation"
}

// Setting up our cognito User pool and Client to act as the Authorizer for the HTTP API
resource "aws_apigatewayv2_authorizer" "APIAuthorizer" {
  api_id                           = aws_apigatewayv2_api.httpAPI.id
  authorizer_type                  = "JWT"
  name                             = "Cognito_Token_Authorizer"
  authorizer_result_ttl_in_seconds = 0
  identity_sources                 = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.Gymlogbook_user_pool_client.id]
    issuer   = "https://${aws_cognito_user_pool.Gymlogbook_user_pool.endpoint}"
  }
}

// API gateway integration with Lambda
resource "aws_apigatewayv2_integration" "apigateway_lambda_integration" {
  api_id = aws_apigatewayv2_api.httpAPI.id

  integration_type   = "AWS_PROXY"
  connection_type    = "INTERNET"
  integration_uri    = aws_lambda_function.gym_log_csv_function.invoke_arn
  integration_method = "POST"
}

// API gateway route creation
resource "aws_apigatewayv2_route" "post_route" {
  api_id             = aws_apigatewayv2_api.httpAPI.id
  route_key          = "POST /workout"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.APIAuthorizer.id

  target = "integrations/${aws_apigatewayv2_integration.apigateway_lambda_integration.id}"
}

// API gateway Stage
resource "aws_apigatewayv2_stage" "httpAPI_stage" {
  api_id = aws_apigatewayv2_api.httpAPI.id
  name   = "$default"

  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.workout_api_logs.arn
    format = jsonencode({
      apiId = "$context.apiId"
      userId = "$context.authorizer.claims.sub"
      cognito_clientId = "$context.authorizer.claims.aud"
      cognito_error_message = "$context.authorizer.error"
      domain_of_request = "$context.domainName"
      apigateway_error_message = "$context.error.message"
      http_method = "$context.httpMethod"
      cognito_authentication_info = "$context.identity.cognitoAuthenticationProvider"
      cognito_user_authentication_status = "$context.identity.cognitoAuthenticationType"
      request_time = "$context.requestTime"
      response_latency = "$context.responseLatency"
      api_route_key = "$context.routeKey"
      api_stage = "$context.stage"
    })
  }
}

// API gateway Deployment not needed with auto_deploy

// Trust policy for api gateway
data "aws_iam_policy_document" "api_trust_policy" {
  statement {
    sid = "api_gateway_assume_role"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [ "apigateway.amazonaws.com" ]
    }

    actions = [ "sts:AssumeRole" ]

    condition {
    test     = "StringEquals"
    variable = "aws:SourceAccount"
    values   = [data.aws_caller_identity.account.account_id]

    }
  }
}

// Role for api gateway at account level
resource "aws_iam_role" "api_gateway_logging_role" {
  name = "api_gateway_account_role"
  assume_role_policy = data.aws_iam_policy_document.api_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "Logging" {
  role = aws_iam_role.api_gateway_logging_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

// API gateway logging for the account
resource "aws_api_gateway_account" "logging_role" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_logging_role.arn
}

// Creating a log group for the stage
resource aws_cloudwatch_log_group "workout_api_logs" {
  name = "workout_api_log_group"
  log_group_class = "STANDARD"
  retention_in_days = 30
}