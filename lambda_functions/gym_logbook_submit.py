"""Lambda function that receives workout data from API Gateway and stores it as CSV in S3."""
# pylint: disable=duplicate-code
import json
import csv
import io
import uuid
import os
import boto3


# Test event simulating data from api gateway to the lambda function.
### test_event = {
###     "body": json.dumps({
###         "workout_date": "2026-04-10",
###         "notes": "Good session",
###         "exercises": [
###             {
###                 "name": "bench press",
###                 "sets": [{"reps": 10, "weight_kg": 60}, {"reps": 8, "weight_kg": 70}]
###             },
###             {
###                 "name": "SQUAT",
###                 "sets": [{"reps": 5, "weight_kg": 100}, {"reps": 5, "weight_kg": 105}]
###             }
###         ]
###     })
### }

# Function that defines how the event object is parsed into a Python dictionary.
# Event.body is expected to be a String.
def event_parse(event):
    """Parse the API Gateway event body from a JSON string into a Python dictionary."""
    body = json.loads(event["body"])
    return body

# workout_dict = event_parse(test_event)

# The row_maker function iterates through each exercise and its corresponding sets.
# For each set, it creates a row containing the workout date, notes, exercise name,
# number of reps, and weight in kilograms. These rows are collected in a list called "rows".
def row_maker(workout):
    """Flatten nested workout exercises and sets into a list of CSV-ready rows."""
    rows = []
    if workout["exercises"] == []:
        raise ValueError("Exercises musn't be empty")
    
    for exercise in workout["exercises"]:
        for set_number in exercise["sets"]:
            row = [
                workout["workout_date"],
                workout["notes"],
                exercise["name"].title(),
                set_number["reps"],
                set_number["weight_kg"]
            ]
            rows.append(row)
    return rows

# rows = row_maker(workout_dict)

# Creates a CSV file in memory using io.StringIO and writes the header
# row and data rows using csv.writer.
def csv_maker(rows):
    """Write rows to an in-memory CSV string with a standard header and return its content."""
    fake_csv = io.StringIO()
    writer = csv.writer(fake_csv)
    writer.writerow(["workout_date", "notes", "exercise_name", "reps", "weight_kg"])
    writer.writerows(rows)
    return fake_csv.getvalue()

# csv_content = csv_maker(rows)
# print(csv_content)

# Generates a unique S3 key for storing the workout data,
# constructed from the workout date and a UUID.
def key_maker(workout):
    """Generate a unique S3 object key using the workout date and a UUID."""
    workout_key = f"workouts/{workout['workout_date']}/{uuid.uuid4()}.csv"
    return workout_key

# workout_key = key_maker(workout_dict)

# Creates a boto3 S3 client, retrieves the bucket name from an environment variable,
# and uploads the CSV content to the specified S3 bucket using put_object.
def upload_to_s3(csv_content, key):
    """Upload CSV content to the S3 data bucket at the given object key."""
    s3 = boto3.client("s3")
    bucket_name = os.environ["BUCKET_NAME"]
    object_key = key
    body = csv_content
    s3.put_object(
        Bucket=bucket_name,
        Key=object_key,
        Body=body,
        ContentType="text/csv"
    )

# upload_to_s3(csv_file, workout_key)

# Orchestration of the process of handling the workout data.
def process_workout(event):
    """Parse, validate, transform, and upload a workout event end-to-end."""
    workout_dict = event_parse(event)
    validate_workout(workout_dict)
    rows = row_maker(workout_dict)
    csv_content = csv_maker(rows)
    workout_key = key_maker(workout_dict)
    upload_to_s3(csv_content, workout_key)
    return rows, workout_key

# Handles responses
def response(status_code, body):
    """Build a Lambda proxy response dict with a status code and JSON-encoded body."""
    return {
        "statusCode": status_code,
        "body": json.dumps(body)
    }

# Validates data
def validate_workout(workout):
    """Raise ValueError if any set is missing reps or weight_kg."""
    for exercise in workout["exercises"]:
        for set_number in exercise["sets"]:
            if set_number.get("reps") in ("", None) or set_number.get("weight_kg") in ("", None):
                raise ValueError("Reps and weight_kg cannot be empty or null")

def lambda_handler(event, _context):
    """Entry point for the Lambda function; routes success and errors to structured responses."""
    try:
        rows, workout_key = process_workout(event)
        return response(200, {"message": "Workout processed successfully",
                              "row_count": len(rows),
                              "s3_key": workout_key})

    except ValueError as ve:
        return response(400, {"message": "Invalid workout data",
                              "error": str(ve)})

    except Exception as e:  # pylint: disable=broad-exception-caught
        return response(500, {"message": "Error processing workout",
                              "error": str(e)})
