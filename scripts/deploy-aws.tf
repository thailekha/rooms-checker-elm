variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "ami_id" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-assessment"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

data "terraform_remote_state" "state" {
  backend = "s3"
  # cannot use variables in terraform{backend{}} block so extend s3 here. notice to include everything
  config {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    bucket = "terraform-state-assessment"
    key    = "network/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

resource "aws_instance" "frontend" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"
}