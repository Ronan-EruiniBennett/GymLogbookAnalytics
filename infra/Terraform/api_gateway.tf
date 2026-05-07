// Using API GatewayV2 to create a http API
resource "aws_apigatewayv2_api" "httpAPI" {
  name          = "gym-log-API"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "authorization"]
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
  identity_sources = [ "$request.header.Authorization" ]

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
}

// API gateway Deployment not needed with auto_deploy
