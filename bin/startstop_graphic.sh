#!/bin/bash

USAGE="Usage: $0 -a {start|stop} -e {dev|qa|prod} [-s {httpserver|graphicserver|classifier}]"

while getopts "a:e:s:" OPTION
do
    case $OPTION in
        a)	ACTION="$OPTARG";;
	e)	ENV="$OPTARG";;
	s)	STUBS="$OPTARG";;
	?)	echo $USAGE; exit 2;;
    esac
done

echo "action = $ACTION"
echo "environemnt = $ENV"
echo "required stubs: $STUBS"


DATE=`date +"%Y.%m.%d"`
HTTP_SERVER_LOG="httpserver_"${ENV}_${DATE}
GRAPHIC_SERVER_LOG="graphicserver_"${ENV}_${DATE}

GRAPHIC_MONGODB_CMD="nohup /usr/bin/mongod --config $HOME/group-project-master/env/mongodb_graphic_$ENV.conf &"
echo $STUBS | grep graphicserver
if [ $? -eq 0 ]; then
	GRAPHIC_SERVER_CMD="nohup $HOME/group-project-master/bin/stubs/graphicserver_stub.js > /tmp/$GRAPHIC_SERVER_LOG 2>&1 &"
else
	GRAPHIC_SERVER_CMD="nohup $HOME/group-project-master/Nodejs/graphicserver.js > /tmp/$GRAPHIC_SERVER_LOG 2>&1 &"
fi

if [ "$ENV" == "prod" ] ; then BRANCH=master ; else BRANCH=$ENV ; fi

case "$ACTION" in
  start)
	if [ ! -d $HOME/group-project-master ] ; then
		echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
		exit 2
	fi

	echo "Starting environment: $ENV "
	cd $HOME/group-project-master
	#git checkout $BRANCH

	ps -ef | grep graphicserver.js | grep -v grep |  awk '{print $2}' > /tmp/node_graphic_$ENV.pid
        if [ -s /tmp/node_graphic_$ENV.pid ] ; then 
		echo "graphic server is already running...PID=`cat /tmp/node_graphic_$ENV.pid`"
	else
		$GRAPHIC_SERVER_CMD
		ps -ef | grep graphicserver.js | grep -v grep | awk '{print $2}' > /tmp/node_graphic_$ENV.pid
        fi
	 #start graphic02 instance of MongoDB locally
	ps -ef | grep mongodb_graphic_$ENV.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
        if [ -s /tmp/mongodb_graphic_$ENV.pid ] ; then 
		echo "graphic02 instance of MongoDB is already running...PID=`cat /tmp/mongodb_graphic_$ENV.pid`"
	else	
		$GRAPHIC_MONGODB_CMD
		ps -ef | grep mongodb_graphic_$ENV.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
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

