import csv
import io
import uuid
import boto3

# download whole directory from s3 bucket to local machine
s3 = boto3.client('s3')
bucket_name = 'my-gym-logbook-12345'

list = s3.list_objects_v2(Bucket=bucket_name)

# Gathering all file names into a list.
files = [name['Key'] for name in list['Contents']]

def upload_to_s3(csv_content, key):
    object_key = key
    body = csv_content
    s3.put_object(
        Bucket= bucket_name,
        Key= object_key,
        Body= body,
        ContentType="text/csv"
    )

# Extracting the content of each file and storing it in a variable called "csv". 
for key in files:
    response = s3.get_object(Bucket=bucket_name, Key=key)
    csv_file = response['Body'].read().decode('utf-8')
    old_file = io.StringIO(csv_file)
    reader_object = csv.reader(old_file)
    new_file = io.StringIO()
    writer = csv.writer(new_file)
    workout_key = (f"cleaned/workouts/{uuid.uuid4()}.csv")
    for row in reader_object:
        normalised_data = [word.capitalize() for word in row[2].split()]
        new_row =' '.join(normalised_data)
        row[2] = new_row
        writer.writerow(row)
    upload_to_s3(new_file.getvalue(), workout_key)
    
