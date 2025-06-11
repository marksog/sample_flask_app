terraform {
  backend "s3" {
    bucket = "just-sample-poc-buc"
    key    = "terraform/state/dev/backend.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "just-sample-dynamo"
  }
}