// IAM Policy for role
data "aws_iam_policy_document" "lambda_gym_log_execution_policy" {
    statement {
      sid = ""
      effect = "Allow"

      principals {
        type = "Service"
        identifiers = [ "lambda.amazonaws.com" ]
      }

      actions = [ "s3:PutObject" ]
      resources = [ "${aws_s3_bucket.data_bucket.arn}/*" ]

      condition {
        test = "StringEquals"
        variable = "aws:PrincipalArn"
        values = [ "${aws_lambda_function.gym-log-csv-function.arn}" ]
      }
    }
}


// Packaging the Lambda function file
data "archive_file" "CSV_transformation_logic" {
    type = "zip"
    source_file = var.lambda_source_path
    output_path = var.lambda_zip_output_path
}

// Creating execution role for lambda
resource "aws_iam_role" "lambda_gym_log_execution_role" {
    name = "Gymlog_function_role"
    assume_role_policy = data.aws_iam_policy_document.lambda_gym_log_execution_policy.json 
}


// Create the Lambda function resource, uses sha256 to discover changes in source file, creates environment variable BUCKET_NAME for the lambda function to use.
resource "aws_lambda_function" "gym_log_csv_function" {
  filename = data.archive_file.CSV_transformation_logic.output_path
  function_name = "GymLog Submit JSON to CSV function"
  role = aws_iam_role.lambda_gym_log_execution_role.arn
  handler = var.lambda_file_name.lambda_handler
  code_sha256 = data.archive_file.CSV_transformation_logic.output_base64sha512

  runtime = "python3.14"

  environment {
    variables = {
        BUCKET_NAME = aws_s3_bucket.data_bucket.id
    }
  }
}

