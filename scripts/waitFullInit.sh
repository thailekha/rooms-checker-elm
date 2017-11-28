#!/usr/bin/env bash

echo "--- Checking boot-finished ---"

while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  echo "Waiting for cloud-init...";
  sleep 1;
done

echo "--- Curling port 5000 ---"

# curl has to be called indirectly via the run function. 
#Otherwise, if curl fails, the script exits immediately with an error exit code
run()
{
	$1 && return $?
}

while ! run "curl 0.0.0.0:5000" ; do
  echo -e "Waiting for app on port 5000";
  sleep 1;
done