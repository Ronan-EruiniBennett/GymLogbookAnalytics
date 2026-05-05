variable "data_bucket_name" {
  description = "The name of the S3 bucket to store data"
  type        = string
}

variable "static_bucket_name" {
  description = "The name of the S3 bucket to store static files"
  type        = string
}

variable "lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "api_gateway_name" {
  description = "The name of the API Gateway"
  type        = string
}

variable "query_bucket_name" {
  description = "The name of the S3 bucket to store query results"
  type        = string
}

variable "index_path" {
  description = "The path to the index.html file"
  type        = string
}

variable "my_domain_name" {
  description = "Route 53 domain name"
  type        = string
}

variable "cognito_user_pool" {
  description = "Cognito user pool"
  type = string
}

variable "cognito_user_pool_client" {
  description = "Cognito user client"
  type = string
}