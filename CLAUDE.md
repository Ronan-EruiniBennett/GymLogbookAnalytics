# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GymLogbookAnalytics is a serverless AWS data pipeline that ingests gym workout data from a web form, transforms it, stores it as CSV in S3, and enables analytics via Athena and QuickSight. The live app is at `https://rebgymlog.info`; the Terraform-deployed version at `https://tf.rebgymlog.info`.

## Infrastructure Commands

All Terraform commands run from `infra/Terraform/`:

```bash
cd infra/Terraform

terraform init       # initialise providers and backend
terraform plan       # preview changes
terraform apply      # deploy changes
terraform destroy    # tear down all resources
```

The `terraform.tfvars` file contains local absolute paths (`lambda_source_path`, `index_path`) that must be updated if the repo is cloned to a different machine.

**QuickSight is intentionally excluded from Terraform** to avoid ongoing costs.

## Lambda

The Lambda function lives in `lambda/Gym_logbook_submit.py`. Terraform packages it into a zip automatically via `archive_file`; there is no separate build step.

To test locally, uncomment the `test_event` block at the top of the file and run:

```bash
python3 lambda/Gym_logbook_submit.py
```

The function reads `BUCKET_NAME` from an environment variable set by Terraform. The runtime is Python 3.14.

## Data Normalisation Script

`scripts/exercise-name-normalise-script.py` is a one-off migration script that reads CSVs from the `raw/` and `workouts/` S3 prefixes, title-cases the exercise name field (column index 2), and writes corrected files to `cleaned/workouts/`. It requires AWS credentials with `s3:GetObject`, `s3:ListBucket`, and `s3:PutObject` on the data bucket.

Run it directly with configured AWS credentials:

```bash
python3 scripts/exercise-name-normalise-script.py
```

## Architecture

```
Browser → Route 53 → CloudFront → S3 (static frontend)
                                        ↓
                              Cognito (implicit OAuth, JWT)
                                        ↓
                           API Gateway v2 (HTTP, JWT authoriser)
                                        ↓
                                 Lambda (Python)
                                        ↓
                              S3 data bucket (CSV files)
                                        ↓
                          Glue crawler → Athena → QuickSight
```

**Frontend** (`index.html.tftpl`): A Terraform template file — Terraform interpolates `API_URL`, `COGNITO_DOMAIN`, `CLIENT_ID`, `REDIRECT_URI`, `AWS_REGION`, and `API_WORKOUT_ROUTE` at deploy time and uploads the rendered HTML directly to the static S3 bucket. Template variables use `${VAR}` syntax; JavaScript `${}` template literals are escaped as `$${VAR}`.

**Auth flow**: Cognito implicit grant → JWT stored in `localStorage` → sent as `Authorization: Bearer <token>` header → API Gateway JWT authoriser validates before invoking Lambda.

**Data flow**: Form JSON payload → Lambda validates (`reps` and `weight_kg` not empty/null) → flattens nested exercises/sets into rows → writes in-memory CSV (`io.StringIO`) → uploads to S3 at `workouts/<date>/<uuid>.csv`.

**S3 buckets** (defined in `terraform.tfvars`):
- `gym-log-static-bucket` — static frontend (OAC-protected, CloudFront only)
- `gym-log-bucket` — workout CSVs (`workouts/<date>/<uuid>.csv`)
- `gym-log-bucket-query` — Athena query results
- `cloudfront-log-bucket-19991611` — CloudFront access logs

**Logging**: API Gateway logs to CloudWatch (`/aws/apigateway/workout_api`, 30-day retention). Lambda logs to CloudWatch (`/aws/lambda/workout_function`, JSON format, 30-day retention). CloudFront logs to the S3 log bucket for potential Athena querying.

## AWS Region

Primary region: `ap-southeast-2` (Sydney). A second `us-east-1` provider alias is used for CloudFront-required resources (ACM certificates, etc.).

## Key Constraints

- Cognito is admin-create-only (`allow_admin_create_user_only = true`) — users cannot self-register.
- Access and ID tokens have a 1-hour validity.
- CORS on API Gateway is locked to `https://tf.rebgymlog.info` only.
- CSV multiline notes can break Athena schema-on-read parsing — a known limitation.
- The `index_path` and `lambda_source_path` in `terraform.tfvars` are absolute paths tied to the original machine.
