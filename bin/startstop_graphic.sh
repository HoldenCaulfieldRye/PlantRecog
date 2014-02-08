#!/bin/bash

USAGE="Usage: $0 -a {start|stop} -e {dev|qa|prod} [-s {'httpserver graphicserver classifier'}]"

while getopts "a:e:s:" OPTION
do
    case $OPTION in
        a)	ACTION="$OPTARG";;
	e)	ENV="$OPTARG";;
	s)	STUBS="$OPTARG";;
	*)	echo $USAGE; exit 2;;
    esac
done

DATE=`date +"%Y.%m.%d"`
HTTP_SERVER_LOG="/tmp/httpserver_${ENV}_${DATE}.log"
GRAPHIC_SERVER_LOG="/tmp/graphicserver_${ENV}_${DATE}.log"

cd $HOME/group-project-master

GRAPHIC_MONGODB_CMD="nohup mongod --config ./env/graphic_$ENV_env.conf &"
echo $STUBS | grep graphicserver
if [ $? -eq 0 ]; then
	GRAPHIC_SERVER_CMD="nohup node ./bin/stubs/graphicserver_stub.js ./env/graphic_$ENV_env.conf  > $GRAPHIC_SERVER_LOG 2>&1 &"
else
	GRAPHIC_SERVER_CMD="nohup node ./Nodejs/AppServer/app.js ./env/graphic_$ENV_env.conf  > $GRAPHIC_SERVER_LOG 2>&1 &"
fi

if [ "$ENV" == "prod" ] ; then BRANCH=master ; else BRANCH=$ENV ; fi

case "$ACTION" in
  start)
	if [ ! -d $HOME/group-project-master ] ; then
		echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
		exit 2
	fi

	echo "Starting environment: $ENV "
	#git checkout $BRANCH

	ps -fC node | grep graphic_$ENV_env.conf | grep -v grep |  awk '{print $2}' > /tmp/node_graphic_$ENV.pid
        if [ -s /tmp/node_graphic_$ENV.pid ] ; then 
		echo "graphic server is already running...PID=`cat /tmp/node_graphic_$ENV.pid`"
	else
		$GRAPHIC_SERVER_CMD
		ps -fC node | grep graphic_$ENV_env.conf | grep -v grep | awk '{print $2}' > /tmp/node_graphic_$ENV.pid
        fi
	 #start graphic02 instance of MongoDB locally
	ps -fC mongod | grep graphic_$ENV_env.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
        if [ -s /tmp/mongodb_graphic_$ENV.pid ] ; then 
		echo "graphic02 instance of MongoDB is already running...PID=`cat /tmp/mongodb_graphic_$ENV.pid`"
	else	
		$GRAPHIC_MONGODB_CMD
		ps -fC mongod | grep graphic_$ENV_env.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
       	fi
	;;
  stop)
	echo "Stoping environment: $ENV "

	if [ ! -s /tmp/node_graphic_$ENV.pid ] ; then
               	echo "graphic server is not running...therefore it can't be stopped"
       	else
               	echo "Stopping node server.." 
               	kill -9 `cat /tmp/node_graphic02_$ENV.pid`
       	fi
	if [ ! -s /tmp/mongodb_graphic_$ENV.pid ] ; then
               	echo "graphic02 instance of MongoDB is not running...therefore it can't be stopped"
       	else
               	echo "Stopping 'graphic02' MongoDB.." 
               	kill `cat /tmp/mongodb_graphic_$ENV.pid`
       	fi
	;;
  *)
        echo $USAGE
        exit 2
esac

