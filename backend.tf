terraform {
  backend "s3" {
    bucket = "nc-demo-terraform-state-bucket"
    key    = "tfstate"
    region = "eu-east-1"
  }
}
