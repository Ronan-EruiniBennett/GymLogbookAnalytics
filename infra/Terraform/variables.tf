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
  type        = string
}

variable "cognito_user_pool_client" {
  description = "Cognito user client"
  type        = string
}

variable "hosted_zone_domain" {
  description = "pre-made hosted zone domain"
  type        = string
}

variable "subdomain" {
  description = "new subdomain of hosted zone"
  type        = string
}

variable "lambda_source_path" {
  description = "lambda source path"
  type        = string
}

variable "lambda_zip_output_path" {
  description = "Output path for the lambda zip package"
  type        = string
}

variable "lambda_file_name" {
  description = "File name for the lambda function, no suffix"
  type        = string
}

variable "AWS_REGION" {
  description = "AWS selected region"
  type        = string
}