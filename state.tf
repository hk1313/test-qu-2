terraform {
  backend "s3" {
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}