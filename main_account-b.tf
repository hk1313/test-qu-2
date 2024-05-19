resource "aws_sqs_queue" "message_queue" {
  provider = aws.account_b
  name     = "message-queue"
}

resource "aws_iam_role" "ec2_role_b" {
  provider = aws.account_b
  name     = "ec2_role_b"

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

resource "aws_iam_role_policy" "ec2_role_b" {
  provider = aws.account_b
  name     = "ec2_role_b"
  role     = aws_iam_role.ec2_role_b.id
  policy   = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = [
          aws_sqs_queue.message_queue.arn,
          "${aws_s3_bucket.message_bucket.arn}/*"
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

resource "aws_instance" "server_b" {
  provider = aws.account_b
  ami           = var.ami
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile_b.name
  subnet_id     = "subnet-01cb09a818042fd21"
  associate_public_ip_address = true
  key_name = "jumphost-test"
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install python3 python3-pip cronie -y
              pip3 install boto3
              systemctl start crond
              systemctl enable crond
              aws s3 cp s3://script-bucket-guardian-b/server_b_script.py /home/ec2-user/server_b_script.py
              chmod +x /home/ec2-user/server_b_script.py
              echo "* * * * * python3 /home/ec2-user/server_b_script.py" >> /etc/cron.d/every_minute
              EOF

  tags = {
    Name = "server-b"
  }
}

resource "aws_iam_instance_profile" "ec2_instance_profile_b" {
  provider = aws.account_b
  name     = "ec2_instance_profile_b"
  role     = aws_iam_role.ec2_role_b.name
}
