#!/usr/bin/env bash

echo "--- SHELL PROVISIONING ---"

set -ex # print command before executing
APP_PATH=/usr/share/rooms-checker
pwd

curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs
npm install -g n
n 6.11.2
mkdir $APP_PATH
mv /tmp/rooms-checker-elm.tgz $APP_PATH/.
cd $APP_PATH && tar -xvzf rooms-checker-elm.tgz
cd $APP_PATH/package && npm i --production && tar -xvzf dist.tgz

echo "cd $APP_PATH/package && npm run serve" >> /etc/rc.local