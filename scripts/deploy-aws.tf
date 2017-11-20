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

data "aws_availability_zones" "available" {}

resource "aws_default_vpc" "default" {
    tags {
        Name = "Default VPC"
    }
}

resource "aws_security_group" "elb" {
  name        = "rooms_checker_elb_sg"
  description = "Used for ELB"
  vpc_id      = "${aws_default_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "frontend" {
  name        = "rooms_checker_frontend_sg"
  description = "Used for frontend instance"
  vpc_id      = "${aws_default_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "frontend" {
  ami           = "${var.ami_id}"
  instance_type = "t2.micro"

  vpc_security_group_ids = ["${aws_security_group.frontend.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web" {
  name = "rooms-checker-elb"

  instances       = ["${aws_instance.frontend.id}"]
  availability_zones = ["${aws_instance.frontend.availability_zone}"]
  security_groups = ["${aws_security_group.elb.id}"]  

  listener {
    instance_port     = 5000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 10
  }
}