// Athena catalog resource not needed, will just use AWSDataCatolog (default catalog)

// Athena workgroup
resource "aws_athena_workgroup" "workout_workgroup" {
  name          = "athena_workout_workgroup"
  force_destroy = true

  configuration {
    publish_cloudwatch_metrics_enabled = true
    enforce_workgroup_configuration    = true

    result_configuration {
      expected_bucket_owner = data.aws_caller_identity.account.account_id
      output_location       = "s3://${aws_s3_bucket.query_bucket.bucket}/"
    }
  }
}
