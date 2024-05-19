resource "aws_sqs_queue_policy" "sqs_policy" {
  provider = aws.account_b
  queue_url = aws_sqs_queue.message_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Principal: "*",
        Action: "SQS:SendMessage",
        Resource: aws_sqs_queue.message_queue.arn,
        Condition: {
          ArnEquals: {
            "aws:SourceArn": aws_sns_topic.message_topic.arn
          }
        }
      }
    ]
  })
}