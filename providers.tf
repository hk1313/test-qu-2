terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }
}

provider "aws" {
  alias  = "account_a"
  region = var.aws_region
  profile = "account_a"
}

provider "aws" {
  alias  = "account_b"
  region = var.aws_region
  profile = "account_b"
}

