// Glue Database catalog
resource "aws_glue_catalog_database" "workout_analytics" {
    name = "workout_analytics"
}

// Glue Table
resource "aws_glue_catalog_table" "workout_table" {
  name = "workout_table"
  database_name = aws_glue_catalog_database.workout_analytics.id
}

// Creating account number data to be used for other resources
data "aws_caller_identity" "account" {}


// IAM trust policy for crawler, trusts glue service to assume role only from the terraformer's account and from specific crawler
data "aws_iam_policy_document" "workout_crawler_role" {
    statement {
      sid = "WorkoutCrawlerTrustPolicy"
      effect = "Allow"

      principals {
        type = "Service"
        identifiers = ["glue.amazonaws.com"]
      }

      actions = [ "sts:AssumeRole" ]

      condition {
        test = "StringEquals"
        variable = "aws:SourceAccount"
        values = [data.aws_caller_identity.account.account_id]
      }

      condition {
        test = "ArnLike"
        variable = "aws:SourceArn"
        values = [ "arn:aws:glue:ap-southeast-2:${data.aws_caller_identity.account.account_id}:crawler/*" ]
      }
    }  
}

// IAM permission policy for crawler to use workout data
data "aws_iam_policy_document" "workout_crawler_permissions" {
    statement {
      sid = "WorkoutCrawlerPermissionPolicy"
      effect = "Allow"

      actions = [ "s3:GetObject", "s3:PutObject" ]

      resources = ["${aws_s3_bucket.data_bucket.arn}/*"]
    }
  
}


// Creating IAM role for crawler with trust policy
resource "aws_iam_role" "workout_crawler_role" {
    name = "workout_crawler_role"
    assume_role_policy = data.aws_iam_policy_document.workout_crawler_role.json
}

// Attaching managed glue service policy to role
resource "aws_iam_role_policy_attachment" "ManagerdGluePolicy" {
    role = aws_iam_role.workout_crawler_role.id
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

// Attatching bucket specific permission policy inline to crawler
resource "aws_iam_role_policy" "s3_workout_crawler_permissions" {
  name = "s3_workout_crawler_permissions"
  role = aws_iam_role.workout_crawler_role.id
  policy = data.aws_iam_policy_document.workout_crawler_permissions.json
}

// Glue crawler
resource "aws_glue_crawler" "workout_crawler" {
    database_name = aws_glue_catalog_database.workout_analytics.id
    name = "Workout_crawler"
    role = aws_iam_role.workout_crawler_role.arn

    s3_target {
      path = "s3://${aws_s3_bucket.data_bucket.bucket}/"
    }

    recrawl_policy {
      recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
    }
  
}