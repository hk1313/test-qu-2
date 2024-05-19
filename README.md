# Cross Account SNS-SQS

1. Here I added Github action to apply terraform with provider alias a and b account
2. We are passing four secrets to Gitub action for account a, b. I'm using account A for storing terraform state but if it's different then have to add GH secrets for same.
3. This whole terraform code assume that you have default vpc in place as it use default vpc.
4. For additional env, add additional secrets in Github repos secrets, add new tfvars file in envs.
5. Have to retrive Subscription URl from SQS using SQS console and confirm sub. on SNS.