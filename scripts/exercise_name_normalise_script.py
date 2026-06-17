"""One-off migration script to title-case exercise names in S3 CSVs and write to cleaned/."""
# pylint: disable=duplicate-code
import csv
import io
import uuid
import boto3

s3 = boto3.client('s3')
BUCKET_NAME = 'my-gym-logbook-12345'

old_paths = [
    'raw/',
    'workouts/'
]

# Gather CSV file names only from the old paths.
files = []

for old_path in old_paths:
    object_list = s3.list_objects_v2(
        Bucket=BUCKET_NAME,
        Prefix=old_path
    )

    files.extend([
        name['Key']
        for name in object_list.get('Contents', [])
        if name['Key'].endswith('.csv')
    ])


def upload_to_s3(csv_content, s3_key):
    """Upload csv_content to BUCKET_NAME at s3_key."""
    object_key = s3_key
    body = csv_content

    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=object_key,
        Body=body,
        ContentType='text/csv'
    )


# Extract and transform the content of each file.
for key in files:
    response = s3.get_object(
        Bucket=BUCKET_NAME,
        Key=key
    )

    csv_file = response['Body'].read().decode('utf-8')
    old_file = io.StringIO(csv_file)
    reader_object = csv.reader(old_file)

    new_file = io.StringIO()
    writer = csv.writer(new_file)

    workout_key = f"cleaned/workouts/{uuid.uuid4()}.csv"

    for row in reader_object:
        normalised_data = [
            word.capitalize()
            for word in row[2].split()
        ]

        new_row = ' '.join(normalised_data)
        row[2] = new_row

        writer.writerow(row)

    upload_to_s3(new_file.getvalue(), workout_key)
