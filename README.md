# GymLogbookAnalytics

## Overview
This system implements a serverless, end-to-end data pipeline on AWS for collecting, processing, and visualising gym workout data.

# How it works
## Architecture
<img width="3449" height="1100" alt="Cloud Architecture" src="https://github.com/user-attachments/assets/9592bfe0-400a-4a9d-a1cf-006a505079ef" />

### 1. Frontend & Delivery
- User accesses the application via a custom domain
- DNS is resolved using Route 53
- Static frontend is served through CloudFront from an S3 bucket (OAC enabled)

### 2. Authentication
- User clicks "Login" and is redirected to Amazon Cognito
- After successful authentication, Cognito redirects back with a JWT token

### 3. Data Ingestion
- User submits workout data via the web form
- API Gateway validates the request using Cognito User Pool authorisation
- Data is sent to an AWS Lambda function

### 4. Data Processing & Storage
- Lambda validates and transforms raw JSON into structured CSV format
- Processed data is stored in an S3 data bucket

### 5. Data Analytics
- AWS Glue crawlers catalog the data
- Amazon Athena queries the dataset
- Amazon QuickSight visualises trends and performance insights

#Challenges and Learnings
- Ingestion issues caused by multiline fields in CSV breaking schema-on-read parsing in Athena
