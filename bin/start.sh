#!/bin/bash

CMD=$1
ENV=$2

#start mongod server on VM
ssh -p 55022 gerardh@146.169.44.217
sudo nohup /usr/bin/mongod --config /home/gerardh/group-project-master/ENV/mongodb_$ENV.conf &


