#!/usr/bin/env bash

echo "--- SHELL PROVISIONING ---"

set -ex # print command before executing
APP_PATH=/usr/share/rooms-checker
pwd

# Install Node.js
curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs

# Set Node.js version to 6.11.2
npm install -g n
n 6.11.2

# Extract the app artifact to appropriate location
mkdir $APP_PATH
mv /tmp/rooms-checker-elm.tgz $APP_PATH/.
cd $APP_PATH && tar -xvzf rooms-checker-elm.tgz
cd $APP_PATH/package && npm i --production && tar -xvzf dist.tgz

# Configure the OS to run the app at startup
echo "cd $APP_PATH/package && npm run serve" >> /etc/rc.local