# GymLogbookAnalytics

## Overview
This system implements a serverless, end-to-end data pipeline on AWS for collecting, processing, and visualising gym workout data.

It was built to explore how serverless architectures can be used to capture and analyse real-world data, while gaining hands-on experience with AWS data and analytics services.

## Project Structure
```
.
├── Athena_Queries/        # Screenshots of Athena queries and results
├── README.md              # Project documentation
├── architecture.png       # Cloud architecture diagram
├── lambda                 # Lambda function code for transformation and validation
├── sample-data            # example lambda event and output csv
├── Quicksight             # Dashboard Screenshots and results
```
## Architecture
<img width="3449" height="1100" alt="Cloud Architecture" src="https://github.com/user-attachments/assets/9592bfe0-400a-4a9d-a1cf-006a505079ef" />

## Tech Stack

**Frontend**

* HTML, JavaScript

**Cloud & Infrastructure**

* S3, CloudFront, Route 53, API Gateway, Lambda, Cognito, ACM

**Data & Analytics**

* AWS Glue, Athena

**Visualisation**

* QuickSight

## Data Pipeline

### 1. Frontend & Delivery

* User accesses the application via a custom domain
* DNS is resolved using Route 53
* Static frontend is served through CloudFront from an S3 bucket (OAC enabled)

### 2. Authentication

* User clicks "Login" and is redirected to Amazon Cognito
* After successful authentication, Cognito redirects back with a JWT token

### 3. Data Ingestion

* User submits workout data via the web form
* API Gateway validates the request using Cognito User Pool authorisation
* Data is posted to an AWS Lambda function

### 4. Data Processing & Storage

* Lambda validates and transforms raw JSON into structured CSV format
* Processed data is stored in an S3 data bucket

### 5. Data Analytics

* AWS Glue crawlers catalog the data
* Amazon Athena queries the dataset
* Amazon QuickSight visualises trends and performance insights

## Live Demo
- Web App: https://rebgymlog.info

## Athena Queries Examples
- These queries were used to analyse workout patterns and extract insights from the dataset.

### Total Workout Sessions
![Total workout sessions](Athena_Queries/total_session_query.png)

### Total Sets
![Total Sets](Athena_Queries/total_sets_query.png)

### Exercises per date
![Exercises per date](Athena_Queries/exercises_per_date_query.png)

### Average Exercises per session
![Average Exercises per session](Athena_Queries/avg_exercise_per_session_query.png)

### Total sets per Exercise
![Total sets per Exercise Query](Athena_Queries/total_sets_per_exercise_query.png "Query")
![Total sets per Exercise Results](Athena_Queries/total_sets_per_exercise_query_results.png "Results")

## Quicksight Visualisation Examples
Interactive QuickSight visualisations exploring gym performance metrics and training patterns.

### Donut Chart Sum of Reps per Exercise
![donut](QuickSight_Visualisations/donut_graph.png)

### Stacked Bar chart Sum of Reps by Exercise and Set Number
![stackedbar](QuickSight_Visualisations/stacked_bar_chart.png)

### Sankey Diagram Sum of Reps by Session and Exercise
![sankey](QuickSight_Visualisations/sankey_diagram.png)

## Future Improvements

### Application Features
- Prefill or duplicate values from the previous set
- Display last week’s weights alongside each exercise
- Save and suggest exercises from previous sessions
- Allow users to select and reuse saved workouts
- Add support for assisted bodyweight exercises, including band-assisted options
- Add body weight metric

### Data Quality & Processing
- Sanitize multiline notes before writing to CSV
- Improve input validation to reduce malformed or incomplete records
- Extend the schema to capture heart rate or RPE data per set
- Expand dataset size for more meaningful analysis

### Analytics & Platform
- Add richer QuickSight dashboards for progress tracking and exercise trends
- Convert processed CSV data into Parquet for more efficient querying
- Automate deployment and updates with CI/CD using GitHub actions

## Challenges and Learnings

- Debugged ingestion issues caused by multiline CSV fields breaking schema-on-read parsing in Athena  
- Identified problems caused by incorrect file formats (.numbers vs CSV) in S3  
- Integrated Cognito authentication with API Gateway and frontend JavaScript  
- Designed and implemented an end-to-end serverless data pipeline  
- Structured SQL queries to extract meaningful insights from workout data  
- Developed an understanding of how data formatting impacts downstream analytics systems  
