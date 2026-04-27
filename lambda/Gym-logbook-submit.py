import json
import csv
import io
import uuid
import boto3
import os       


# Test event simulating data from api gateway to the lambda function.
### test_event = {
    ### "body": "{\"workout_date\":\"2026-04-10\",\"notes\":\"Good session\",\"exercises\":[{\"name\":\"Bench Press\",\"sets\":[{\"reps\":10,\"weight_kg\":60},{\"reps\":8,\"weight_kg\":70}]},{\"name\":\"Squat\",\"sets\":[{\"reps\":5,\"weight_kg\":100},{\"reps\":5,\"weight_kg\":105}]}]}"
###}

# Function that defines how the event object is parsed into a Python dictionary. Event.body is expected to be a String.
def event_parse(event):
    body = json.loads(event["body"])
    return body

# workout_dict = event_parse(test_event)

# The row_maker function takes the parsed workout data and iterates through each exercise and its corresponding sets. For each set, it creates a row containing the workout date, notes, exercise name, number of reps, and weight in kilograms. These rows are collected in a list called "rows", which is printed at the end.
def row_maker(workout):
    rows = []
    for exercise in workout["exercises"]:
        for set_number in exercise["sets"]:
            row = [workout["workout_date"], workout["notes"], exercise["name"], set_number["reps"], set_number["weight_kg"]]
            rows.append(row)
    return rows
           

# rows = row_maker(workout_dict)

# This code creates a fake CSV file in memory using the io.StringIO class. It then uses the csv.writer to write the header row and the data rows to the fake CSV file. 
def csv_maker(rows):
    fake_csv = io.StringIO()
    writer = csv.writer(fake_csv)
    writer.writerow(["workout_date", "notes", "exercise_name", "reps", "weight_kg"])
    writer.writerows(rows)
    return fake_csv.getvalue()

# csv_content = csv_maker(rows)

# The key_maker function generates a unique key for storing the workout data in a storage system (like S3). It constructs the key using the workout date and a UUID.
def key_maker(workout):
    workout_key = (f"workouts/{workout['workout_date']}/{uuid.uuid4()}.csv")
    return workout_key

# workout_key = key_maker(workout_dict)

# Creates a boto3 client for S3. Boto3 is AWS SDK for Python, allows easy interation with AWS services. Retrieves bucket name from environment variables and pushes the CSV content to the specified S3 bucket using the put_object method. The content type is set to "text/csv" to indicate that the uploaded file is a CSV file.
def upload_to_s3(csv_content, key):
    s3 = boto3.client("s3")
    bucket_name = os.environ["BUCKET_NAME"]
    object_key = key
    body = csv_content
    s3.put_object(
        Bucket= bucket_name,
        Key= object_key,
        Body= body,
        ContentType="text/csv"
    )

# upload_to_s3(csv_file, workout_key)

# Orchestration of the process of handling the workout data.
def process_workout(event):
    workout_dict = event_parse(event)
    validate_workout(workout_dict)
    rows = row_maker(workout_dict)
    csv_content = csv_maker(rows)
    workout_key = key_maker(workout_dict)
    upload_to_s3(csv_content, workout_key)
    return rows, workout_key

# Handles responses
def response(status_code, body):
    return {
        "statusCode": status_code,
        "body": json.dumps(body)
    }

# Validates data
def validate_workout(workout):
        for exercise in workout["exercises"]:
            for set_number in exercise["sets"]:
                if set_number.get("reps") in ("", None) or set_number.get("weight_kg") in ("", None):
                    raise ValueError("Reps and weight_kg cannot be empty or null")

def lambda_handler(event, context):
    try:
        rows, workout_key = process_workout(event)
        return response(200, {"message": "Workout processed successfully", 
                              "row_count": len(rows), 
                              "s3_key": workout_key})

    except ValueError as ve:
        return response(400, {"message": "Invalid workout data",
                              "error": str(ve)})  
        
    except Exception as e:
        return response(500, {"message": "Error processing workout",
                              "error": str(e)})

