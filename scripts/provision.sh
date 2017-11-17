#!/usr/bin/env bash

echo "--- SHELL PROVISIONING ---"

set -ex # print command before executing

pwd
curl --silent --location https://rpm.nodesource.com/setup_6.x | sudo bash -
sudo yum -y install nodejs
sudo npm install -g n
sudo n 6.11.2
mv /tmp/rooms-checker-elm.tgz .
tar -xvzf rooms-checker-elm.tgz
cd ./package && npm i --production && tar -xvzf dist.tgz