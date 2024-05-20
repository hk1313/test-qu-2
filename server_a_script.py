import boto3
from datetime import datetime

def publish_message():
    sns = boto3.client('sns', region_name='eu-west-1')
    message = f"Hello from server A at {datetime.utcnow().isoformat()}"
    response = sns.publish(
        TopicArn='arn:aws:sns:eu-west-1:434606482519:message-topic',
        Message=message
    )
    print("Message published:", response)


publish_message()