resource "aws_sns_topic" "message_topic" {
  provider = aws.account_a
  name     = "message-topic"
}

resource "aws_sns_topic_subscription" "example_subscription" {
  provider = aws.account_a
  topic_arn = aws_sns_topic.message_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.message_queue.arn
}

# Creating bucket account A with versioning and upload python file
resource "aws_s3_bucket" "script_bucket_a" {
  provider = aws.account_a
  bucket   = "script-bucket-guardian-a"
}

resource "aws_s3_bucket_versioning" "script_bucket_a" {
  provider = aws.account_a
  bucket = aws_s3_bucket.script_bucket_a.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object" "objects_a" {
  provider = aws.account_a
  depends_on = [
    aws_s3_bucket.script_bucket_a
  ]
  bucket = aws_s3_bucket.script_bucket_a.id
  key    = "server_a_script.py"
  source = "server_a_script.py"
  etag = filemd5("server_a_script.py")
}

# Creating bucket account B with versioning and upload python file
resource "aws_s3_bucket" "script_bucket_b" {
  provider = aws.account_b
  bucket   = "script-bucket-guardian-b"
}

resource "aws_s3_bucket_versioning" "script_bucket_b" {
  provider = aws.account_b
  bucket = aws_s3_bucket.script_bucket_b.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object" "objects_b" {
  provider = aws.account_b
  depends_on = [
    aws_s3_bucket.script_bucket_b
  ]
  bucket = aws_s3_bucket.script_bucket_b.id
  key    = "server_b_script.py"
  source = "server_b_script.py"
  etag = filemd5("server_b_script.py")
}

# message bucket in account A which will get file from Account B instance script.
resource "aws_s3_bucket" "message_bucket" {
  provider = aws.account_a
  bucket   = "message-bucket-abc"
}

resource "aws_s3_bucket_policy" "message_bucket" {
  provider = aws.account_a
  depends_on = [
    aws_s3_bucket.message_bucket
  ]
  bucket = aws_s3_bucket.message_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:PutObject",
        Resource  = [
          aws_s3_bucket.message_bucket.arn,
          "${aws_s3_bucket.message_bucket.arn}/*",
        ],
        Condition = {
          ArnLike  = {
            "aws:PrincipalArn" = [aws_iam_role.ec2_role_b.arn]
          }
        }
      },
    ],
  })
}

resource "aws_iam_role" "ec2_role_a" {
  provider = aws.account_a
  name     = "ec2_role_a"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_role_a" {
  provider = aws.account_a
  name     = "ec2_role_a"
  role     = aws_iam_role.ec2_role_a.id
  policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sns:Publish"
        ],
        Effect   = "Allow",
        Resource = [
          aws_sns_topic.message_topic.arn,
        ]
      },
      {
        Action = [
          "s3:*"
        ],
        Effect   = "Allow",
        Resource = [
          "*",
        ]
      }      
    ]
  })
}

resource "aws_instance" "server_a" {
  provider = aws.account_a
  ami           = var.ami
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile_a.name
  key_name = "jumphostadmin"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install python3 cronie -y
              pip3 install boto3
              aws s3 cp s3://script-bucket-guardian-a/server_a_script.py /home/ec2-user/server_a_script.py
              chmod +x /home/ec2-user/server_a_script.py
              systemctl enable crond
              systemctl start crond
              echo "* * * * * python3 /home/ec2-user/server_a_script.py" >> /etc/cron.d/every_minute
              EOF

  tags = {
    Name = "server-a"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile_a" {
  provider = aws.account_a
  name     = "ec2_instance_profile_a"
  role     = aws_iam_role.ec2_role_a.name
}