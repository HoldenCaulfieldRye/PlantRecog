#!/bin/bash
#
#	This script starts up all components of the system in a particular env
#	Author: ghaughian (Feb 2014)
#	Command Line Args: $1 = 'start' or 'stop'...the action you wish to happen
#			   $2 = 'dev', 'qa', or 'prod'...the environment you wish to run
#

ENV=$2

USER=whoami
DATE=`date +"%Y.%m.%d"`
HTTP_SERVER_LOG="httpserver_"${ENV}_${DATE}
GRAPHIC_SERVER_LOG="graphicserver_"${ENV}_${DATE}

USAGE=$"Usage: $0 {start|stop} {dev|qa|prod}"

#logic to deal with checking and ensuring user is on a doc host.
HOSTNAME=`echo hostname -A | awk 'BEGIN {FS="/"}{print $2}'`
if [ ! "$HOSTNAME" == "doc" ]
then
	echo "WARN:script must be run from a doc server"
	exit
fi


case "$1" in
  start)
        echo "Starting environment: $ENV "
        
	ssh -p 55022 $USER@146.169.44.217

	#start mongod server on VM
	ps -ef | grep mongodb_$ENV.conf | grep -v grep |  awk '{print $2}' > /tmp/mongo_$ENV.pid
        if [ -s /tmp/mongo_$ENV.pid ]
        then
                echo "MongoDB is already running...PID=`cat /tmp/mongo_$ENV.pid`"
        else
		sudo nohup /usr/bin/mongod --config /home/gerardh/group-project-master/ENV/mongodb_$ENV.conf &
		ps -ef | grep mongodb_$ENV.conf | grep -v grep | awk '{print $2}' > /tmp/mongo_$ENV.pid
        fi

	#start http server on VM
	ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_$ENV.pid
        if [ -s /tmp/node_$ENV.pid ]
        then
                echo "http server is already running...PID=`cat /tmp/node_$ENV.pid`"
        else
		sudo nohup /home/gerardh/group-project-master/Nodejs/httpserver.js > $HTTP_SERVER_LOG 2>&1 &
		ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_$ENV.pid
        fi

	#start node graphic server on graphic02
	ssh $USER@graphic02.doc.ic.ac.uk
	
	ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_$ENV.pid
        if [ -s /tmp/node_$ENV.pid ]
        then
                echo "graphic server is already running...PID=`cat /tmp/node_$ENV.pid`"
        else
		nohup /home/gerardh/group-project-master/Nodejs/graphicserver.js > $GRAPHIC_SERVER_LOG 2>&1 &
		ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_$ENV.pid
        fi

	

        ;;
  stop)
	ssh -p 55022 $USER@146.169.44.217
        
	if [ ! -s /tmp/mongo_$ENV.pid ]
        then
                echo "MongoDB is not running...therefore it can't be stopped"
        else
                echo "Stopping MongoDB.."
                kill -9 `cat /tmp/mongo_$ENV.pid`
        fi
        
	if [ ! -s /tmp/node_$ENV.pid ]
        then
                echo "http server is not running...therefore it can't be stopped"
        else
                echo "Stopping http server.." 
                kill -9 `cat /tmp/node_$ENV.pid`
        fi

	ssh $USER@graphic02.doc.ic.ac.uk
	
	if [ ! -s /tmp/node_$ENV.pid ]
        then
                echo "graphic server is not running...therefore it can't be stopped"
        else
                echo "Stopping node server.." 
                kill -9 `cat /tmp/node_$ENV.pid`
        fi
	
	;;
  *)
        echo $USAGE
        exit 2
esac



