// Creates Cognito User Pool. Users can use username, email, or phone number to sign in.
resource "aws_cognito_user_pool" "Gymlogbook_user_pool" {
    name = var.cognito_user_pool
    username_attributes = ["email"]
    auto_verified_attributes = ["email"]
    
    admin_create_user_config {
      allow_admin_create_user_only = true
    }
}

resource "aws_cognito_user_pool_client" "Gymlogbook_user_pool_client" {
    name = var.cognito_user_pool_client
    user_pool_id = aws_cognito_user_pool.Gymlogbook_user_pool.id
    
    allowed_oauth_flows_user_pool_client = true
    callback_urls = [var.subdomain]
    logout_urls = [var.subdomain]
    supported_identity_providers = ["COGNITO"]
    allowed_oauth_flows = ["implicit"]
    allowed_oauth_scopes = ["openid"]

    access_token_validity = 1
    id_token_validity = 1
    auth_session_validity = 3
}
