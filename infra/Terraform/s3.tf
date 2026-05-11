// 3 S3 Buckets for GymLog Application. One for static files, one for data storage, and one for query results.
resource "aws_s3_bucket" "static_web_bucket" {
  bucket = var.static_bucket_name
}

// Index.html file upload with MD5 hash to detect changes and trigger updates in the static website hosting.
resource "aws_s3_object" "staticpage" {
  bucket       = aws_s3_bucket.static_web_bucket.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile(var.index_path, {
    API_URL = aws_apigatewayv2_stage.httpAPI_stage.invoke_url, 
    COGNITO_DOMAIN = aws_cognito_user_pool_domain.Gymlogbook_user_pool_domain.domain,
    CLIENT_ID = aws_cognito_user_pool_client.Gymlogbook_user_pool_client.id,
    REDIRECT_URI = aws_cognito_user_pool_client.Gymlogbook_user_pool_client.default_redirect_uri,
    AWS_REGION = var.AWS_REGION,
    API_WORKOUT_ROUTE = split(" ", aws_apigatewayv2_route.post_route.route_key)[1]
  })

  etag = filemd5(var.index_path)
}

// Data bucket for storing user data and workout logs
resource "aws_s3_bucket" "data_bucket" {
  bucket = var.data_bucket_name
}

// Query bucket for storing results of Athena queries
resource "aws_s3_bucket" "query_bucket" {
  bucket = var.query_bucket_name
}