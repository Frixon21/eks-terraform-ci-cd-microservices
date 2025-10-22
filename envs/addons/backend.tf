terraform {
  backend "s3" {
    bucket         = "alex-capstone-tfstate"
    key            = "envs/addons/addons.tfstate"
    region         = "us-east-1"
    dynamodb_table = "alex-capstone-tf-locks"
    encrypt        = true
  }
}
