#!/usr/bin/env bash

set -ex # print command before executing

echo "--- SHELL PROVISIONING ---"

pwd
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g n
sudo n 6.11.2
mv /tmp/rooms-checker-elm.tgz .
tar -xvzf rooms-checker-elm.tgz
cd ./package && npm i --production && tar -xvzf dist.tgz