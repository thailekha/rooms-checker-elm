#!/bin/bash
PACKER_LOG=1 packer build -var "aws_access_key=$AWS_ACCESS_KEY" -var "aws_secret_key=$AWS_SECRET_KEY" -var "build_path=$TRAVIS_BUILD_DIR" "$TRAVIS_BUILD_DIR/scripts/aws-ebs.json"