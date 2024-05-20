import boto3
from datetime import datetime
import os

def receive_message():
    sqs = boto3.client('sqs', region_name='eu-west-1')
    queue_url = 'https://sqs.eu-west-1.amazonaws.com/184850965464/message-queue'
    s3 = boto3.client('s3', region_name='eu-west-1')
    bucket_name = 'message-bucket-abc'

    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=10
    )

    if 'Messages' in response:
        for message in response['Messages']:
            body = message['Body']
            timestamp = body.split(" at ")[-1]
            dt = datetime.fromisoformat(timestamp)
            file_name = dt.strftime('%Y-%m-%d-%H:%M:%S-message.log')
            with open(file_name, 'w') as f:
                f.write(body)
            s3.upload_file(file_name, bucket_name, file_name)
            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=message['ReceiptHandle']
            )
            os.remove(file_name)
            print("Message processed and file uploaded to S3:", file_name)


receive_message()
