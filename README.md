# Web server

1. Here I added Github action to apply terraform on specific account.
2. If require to run, must have to store AWS credential in Github secrets as per `dev.yaml` like **DEV_AWS_ACCESS_KEY_ID** and **DEV_AWS_SECRET_ACCESS_KEY**
3. In Github action step init, require to pass Terraform S3 bucket and KMS key for terraform remote state.
4. For additional env, add additional secrets in Github repos secrets, add new tfvars file in envs.
5. For more improvement, we can customize workflow to run from different branch for different env and also we can pass manualy approval between Action steps plan and apply