// IAM permissions Policy for role
data "aws_iam_policy_document" "lambda_gym_log_execution_policy" {
  statement {
    sid    = "AllowLambdas3Push"
    effect = "Allow"

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.data_bucket.arn}/*"]
  }
}

// IAM trusy policy for lambda
data "aws_iam_policy_document" "trust_policy_gym_function" {
  statement {
    sid    = "AllowLambdaToAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.account.account_id]
    }
  }

}

// Packaging the Lambda function file
data "archive_file" "CSV_transformation_logic" {
  type        = "zip"
  source_file = var.lambda_source_path
  output_path = var.lambda_zip_output_path
}

// Creating execution role for lambda
resource "aws_iam_role" "lambda_gym_log_execution_role" {
  name               = "Gymlog_function_role"
  assume_role_policy = data.aws_iam_policy_document.trust_policy_gym_function.json
}

// Allowing Lambda to push objects to s3 data bucket
resource "aws_iam_role_policy" "add_permissions" {
  name   = "LambdaAllows3Push"
  policy = data.aws_iam_policy_document.lambda_gym_log_execution_policy.json
  role   = aws_iam_role.lambda_gym_log_execution_role.id
}

// Allowing lambda to publish logs to cloudwatch logs for troubleshooting
resource "aws_iam_role_policy_attachment" "add_logging" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_gym_log_execution_role.id
}

// Adding lambda resource policy to allow invokes from api gateway http api
resource "aws_lambda_permission" "lambda_resource_policy" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gym_log_csv_function.id
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.httpAPI.execution_arn}/*"
}

// Create the Lambda function resource, uses sha256 to discover changes in source file, creates environment variable BUCKET_NAME for the lambda function to use.
resource "aws_lambda_function" "gym_log_csv_function" {
  filename      = data.archive_file.CSV_transformation_logic.output_path
  function_name = "GymLogSubmitJSONtoCSV"
  role          = aws_iam_role.lambda_gym_log_execution_role.arn
  handler       = "${var.lambda_file_name}.lambda_handler"
  code_sha256   = data.archive_file.CSV_transformation_logic.output_base64sha512

  runtime = "python3.14"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.id
    }
  }
}

