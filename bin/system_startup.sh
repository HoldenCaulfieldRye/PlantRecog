#!/bin/bash
#
#	This script starts up all components of the system in a particular env
#	Author: ghaughian (Feb 2014)
#	Command Line Args: $1 = 'start' or 'stop'...the action you wish to happen
#			   $2 = 'dev', 'qa', or 'prod'...the environment you wish to run
#

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

# Enfore that this script is run from the VM machine
if [ ! "`hostname -i`" == "146.169.44.217" ] ; then 
	echo "This script must be run from the VM machine"
	exit 2
fi

#Do we need to set up a distributd system or a local one? (dev is always local)
if [ "$ENV" == "qa" -o "$ENV" == "prod" ]
  then DISTRIBUTED=true
  else DISTRIBUTED=false
fi

echo -n "Have you cloned the latest version of the repo to your home directory [yes|no]: "
read cloned

if [ "$cloned" == "no" ] ; then 
	echo "ERROR: Please clone the latest revision of the repo to your home directory on"
	if $DISTRIBUTED ; then echo "       both the VM and graphic02 machines" ; else echo "       the VM machine" ; fi
	exit 2
fi

DATE=`date +"%Y.%m.%d"`
HTTP_SERVER_LOG="/tmp/AppServer_${ENV}_${DATE}.log"
GRAPHIC_SERVER_LOG="/tmp/graphicserver_${ENV}_${DATE}.log"

cd $HOME/group-project-master

VM_MONGODB_CMD="sudo su -c \"mongod --config ./env/vm_${ENV}_env.conf &\" -s /bin/sh mongodb"
GRAPHIC_MONGODB_CMD="sudo su -c \"mongod --config ./env/graphic_${ENV}_env.conf &\" -s /bin/sh mongodb"

echo $STUBS | grep httpserver
if [ $? -eq 0 ]; then
	HTTP_SERVER_CMD="nohup node ./bin/stubs/httpserver_stub.js ./env/vm_${ENV}_env.conf > $HTTP_SERVER_LOG 2>&1 &"
else 
	HTTP_SERVER_CMD="nohup node ./Nodejs/AppServer/app.js ./env/vm_${ENV}_env.conf > $HTTP_SERVER_LOG 2>&1 &"
fi
echo $STUBS | grep graphicserver
if [ $? -eq 0 ]; then
	GRAPHIC_SERVER_CMD="nohup node ./bin/stubs/graphicserver_stub.js ./env/graphic_${ENV}_env.conf  > $GRAPHIC_SERVER_LOG 2>&1 &"
else
	GRAPHIC_SERVER_CMD="nohup node ./Nodejs/AppServer/app.js ./env/graphic_${ENV}_env.conf  > $GRAPHIC_SERVER_LOG 2>&1 &"
fi

GRAPHIC_SERVER_STARTSTOP_SCRIPT_CMD="$HOME/group-project-master/bin/startstop_graphic.sh -a $ACTION -e $ENV -s $STUBS"

SSH_GRAPHIC="ssh $USER@graphic02.doc.ic.ac.uk"

if [ "$ENV" == "prod" ] ; then BRANCH=master ; else BRANCH=$ENV ; fi
#Handle the requested action i.e start and stop
case "$ACTION" in
  start)
	if [ ! -d $HOME/group-project-master ] ; then
		echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
		exit 2
	fi
        
	echo "Starting environment: ${ENV}"
	#git checkout $BRANCH

	#start mongod server on VM
	ps -fC mongod | grep vm_${ENV}_env.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_vm_${ENV}.pid
        if [ -s /tmp/mongodb_vm_${ENV}.pid ] ; then
                echo "MongoDB is already running...PID=`cat /tmp/mongodb_vm_${ENV}.pid`"
        else
		eval $VM_MONGODB_CMD
		ps -fC mongod | grep vm_${ENV}_env.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_vm_${ENV}.pid
        fi

	#start http server on VM
	ps -fC node | grep vm_${ENV}_env.conf | grep -v grep |  awk '{print $2}' > /tmp/node_vm_${ENV}.pid
        if [ -s /tmp/node_vm_${ENV}.pid ] ;
        then
                echo "app server is already running...PID=`cat /tmp/node_vm_${ENV}.pid`"
        else
		eval $HTTP_SERVER_CMD
		ps -fC node | grep vm_${ENV}_env.conf | grep -v grep | awk '{print $2}' > /tmp/node_vm_${ENV}.pid
        fi

	if $DISTRIBUTED ; then 
		eval `${SSH_GRAPHIC} ${GRAPHIC_SERVER_STARTSTOP_SCRIPT_CMD}`
	else 	#start node graphic server locally
		ps -fC node | grep graphic_${ENV}_env.conf | grep -v grep |  awk '{print $2}' > /tmp/node_graphic_${ENV}.pid
        	if [ -s /tmp/node_graphic_${ENV}.pid ] ; then echo "graphic server is already running...PID=`cat /tmp/node_graphic_${ENV}.pid`" ; else
			eval $GRAPHIC_SERVER_CMD
			ps -fC node | grep graphic_${ENV}_env.conf | grep -v grep | awk '{print $2}' > /tmp/node_graphic_${ENV}.pid
        	fi
	 	#start graphic02 instance of MongoDB locally
		ps -fC mongod | grep graphic_${ENV}_env.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
        	if [ -s /tmp/mongodb_graphic_$PENV}.pid ] ; then echo "graphic02 instance of MongoDB is already running...PID=`cat /tmp/mongodb_graphic_${ENV}.pid`" ; else
			eval $GRAPHIC_MONGODB_CMD
			ps -fC mongod | grep graphic_${ENV}_env.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_graphic_${ENV}.pid
        	fi
	fi
        ;;
  stop)
	echo "Stopping environment: $ENV"	
	
	if [ ! -s /tmp/mongodb_vm_${ENV}.pid ] ; then
                echo "MongoDB is not running...therefore it can't be stopped"
        else
                echo "Stopping MongoDB.."
                sudo kill `cat /tmp/mongodb_vm_${ENV}.pid`
        fi
        
	if [ ! -s /tmp/node_vm_${ENV}.pid ] ; then
                echo "http server is not running...therefore it can't be stopped"
        else
                echo "Stopping http server.." 
                kill -9 `cat /tmp/node_vm_${ENV}.pid`
        fi

	if $DISTRIBUTED ; then 
		`$SSH_GRAPHIC $GRAPHIC_SERVER_STARTSTOP_SCRIPT_CMD`
	else
		if [ ! -s /tmp/node_graphic_${ENV}.pid ] ; then
                	echo "graphic server is not running...therefore it can't be stopped"
        	else
                	echo "Stopping node server.." 
                	kill -9 `cat /tmp/node_graphic_${ENV}.pid`
        	fi
		if [ ! -s /tmp/mongodb_graphic_${ENV}.pid ] ; then
                	echo "graphic02 instance of MongoDB is not running...therefore it can't be stopped"
        	else
                	echo "Stopping 'graphic02' MongoDB.." 
                	sudo kill `cat /tmp/mongodb_graphic_${ENV}.pid`
        	fi
	fi
	;;
  *)
        echo $USAGE
        exit 2
esac

