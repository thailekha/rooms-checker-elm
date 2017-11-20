variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "ami_id" {}
variable "keypair_name" {}
variable "key_file" {}
variable "build_path" {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

# location of the remote state
terraform {
  backend "s3" {
    bucket  = "terraform-state-assessment"
    key     = "network/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# location of the remote state
data "terraform_remote_state" "state" {
  backend = "s3"
  # cannot use variables in terraform{backend{}} block so extend s3 here. notice to include everything
  config {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    bucket     = "terraform-state-assessment"
    key        = "network/terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}

# availability_zones, used to configure the load balancer later
data "aws_availability_zones" "available" {}

# a reference to the default vpc
resource "aws_default_vpc" "default" {
    tags {
        Name = "Default VPC"
    }
}

# Security group for the load balancer
resource "aws_security_group" "elb" {
  name        = "rooms_checker_elb_sg"
  description = "Used for ELB"
  vpc_id      = "${aws_default_vpc.default.id}"

  # Inbound rule - HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the EC2 instance that will run the app
resource "aws_security_group" "frontend" {
  name        = "rooms_checker_frontend_sg"
  description = "Used for frontend instance"
  vpc_id      = "${aws_default_vpc.default.id}"

  # Inbound rule accepting any TCP traffic from the load balancer
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.elb.id}"]
  }

  # Inbound rule accepting any SSH traffic
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  # outbound rule to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The EC2 instance that will run the app, named "frontend"
resource "aws_instance" "frontend" {
  count                   = 1
  ami                     = "${var.ami_id}"
  instance_type           = "t2.micro"
  key_name                = "${var.keypair_name}"
  vpc_security_group_ids  = ["${aws_security_group.frontend.id}"]

  lifecycle {
  # if this isntance needs updating, 
  # terraform creates a new identical instance, 
  # apply the updates to the new instance, 
  # and finally destroy this instance
    create_before_destroy = true
  }

  # make terrform wait until instance is fully initialized
  provisioner "file" {
    source      = "${var.build_path}/scripts/waitFullInit.sh"
    destination = "/tmp/waitFullInit.sh"

    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${var.key_file}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/waitFullInit.sh",
      "/tmp/waitFullInit.sh",
    ]

    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file("${var.key_file}")}"
    }
  }
}

# Load balancer pointing to the "frontend" ec2 instance
resource "aws_elb" "web" {
  name                = "rooms-checker-elb"
  instances           = ["${aws_instance.frontend.id}"]
  availability_zones  = ["${aws_instance.frontend.availability_zone}"]
  security_groups     = ["${aws_security_group.elb.id}"]

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