import json
import os
import io
import csv
import uuid
from datetime import datetime, timezone

import boto3

s3 = boto3.client("s3")
BUCKET = os.environ["BUCKET_NAME"]

FIELDNAMES = [
    "session_id",
    "workout_date",
    "exercise",
    "set_number",
    "reps",
    "weight_kg",
    "notes",
    "submitted_at"
]

def lambda_handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")

        workout_date = str(body.get("workout_date", "")).strip()
        notes = str(body.get("notes", "")).strip()
        exercises = body.get("exercises", [])

        if not workout_date:
            return response(400, {"message": "Missing required field: workout_date"})

        if not isinstance(exercises, list) or len(exercises) == 0:
            return response(400, {"message": "You must provide at least one exercise"})

        session_id = str(uuid.uuid4())
        submitted_at = datetime.now(timezone.utc).isoformat()

        rows = []

        for exercise_index, exercise_obj in enumerate(exercises, start=1):
            exercise_name = str(exercise_obj.get("name", "")).strip()
            sets = exercise_obj.get("sets", [])

            if not exercise_name:
                return response(400, {"message": f"Exercise {exercise_index} is missing a name"})

            if not isinstance(sets, list) or len(sets) == 0:
                return response(400, {"message": f'Exercise "{exercise_name}" must contain at least one set'})

            for set_index, set_obj in enumerate(sets, start=1):
                reps = set_obj.get("reps")
                weight_kg = set_obj.get("weight_kg")

                if reps in ("", None):
                    return response(400, {"message": f'Missing reps for set {set_index} of exercise "{exercise_name}"'})

                if weight_kg in ("", None):
                    return response(400, {"message": f'Missing weight_kg for set {set_index} of exercise "{exercise_name}"'})

                try:
                    reps_value = int(reps)
                except (TypeError, ValueError):
                    return response(400, {"message": f'Invalid reps for set {set_index} of exercise "{exercise_name}"'})

                try:
                    weight_value = float(weight_kg)
                except (TypeError, ValueError):
                    return response(400, {"message": f'Invalid weight_kg for set {set_index} of exercise "{exercise_name}"'})

                rows.append({
                    "session_id": session_id,
                    "workout_date": workout_date,
                    "exercise": exercise_name,
                    "set_number": set_index,
                    "reps": reps_value,
                    "weight_kg": weight_value,
                    "notes": notes,
                    "submitted_at": submitted_at
                })

        csv_buffer = io.StringIO()
        writer = csv.DictWriter(csv_buffer, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)

        date_partition = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        key = f"raw/date={date_partition}/session-{session_id}.csv"

        s3.put_object(
            Bucket=BUCKET,
            Key=key,
            Body=csv_buffer.getvalue().encode("utf-8"),
            ContentType="text/csv"
        )

        return response(200, {
            "message": "Workout session saved",
            "row_count": len(rows),
            "session_id": session_id,
            "s3_key": key
        })

    except Exception as e:
        return response(500, {
            "message": "Internal server error",
            "error": str(e)
        })

def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        "body": json.dumps(body)
    }
