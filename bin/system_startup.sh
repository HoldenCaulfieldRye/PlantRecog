#!/bin/bash
#
#	This script starts up all components of the system in a particular env
#	Author: ghaughian (Feb 2014)
#	Command Line Args: $1 = 'start' or 'stop'...the action you wish to happen
#			   $2 = 'dev', 'qa', or 'prod'...the environment you wish to run
#

USAGE=$"Usage: $0 -a {start|stop} -e {dev|qa|prod} [-s {httpserver|graphicserver|classifier}]"

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

#Do we need to set up a distributd system or a local one? (dev is always local)
if [ "$ENV" == "qa" -o "$ENV" == "prod" ]
  then DISTRIBUTED=true
  else DISTRIBUTED=false
fi
echo $DISTRIBUTED

echo "Are you sure you have cloned the latest version of the repo:"
echo "    https://gitlab.doc.ic.ac.uk/bjm113/group-project-master.git "
if $DISTRIBUTED ; then 
	echo "In user:$USER's home directory on BOTH the VM and graphic machines? [yes|no]:" 
else 
	echo "In user:$USER's home directory on the VM machine? [yes|no]:" 
fi
read cloned

if [ "$cloned" == "no" ] ; then 
	echo "Please clone the latest revision of the repo to your home directory on: "
	if $DISTRIBUTED ; then echo "   both the VM and graphic machines" ; else echo "   on the VM machine" ; fi
fi


DATE=`date +"%Y.%m.%d"`
HTTP_SERVER_LOG="httpserver_"${ENV}_${DATE}
GRAPHIC_SERVER_LOG="graphicserver_"${ENV}_${DATE}

VM_MONGODB_CMD="sudo nohup /usr/bin/mongod --config $HOME/group-project-master/env/mongodb_$ENV.conf &"
GRAPHIC_MONGODB_CMD="sudo nohup /usr/bin/mongod --config $HOME/group-project-master/env/mongodb_graphic_$ENV.conf &"
echo $STUBS | grep httpserver
if [ $? -eq 0 ]; then
	HTTP_SERVER_CMD="nohup $HOME/group-project-master/bin/stubs/httpserver_stub.js > /tmp/$HTTP_SERVER_LOG 2>&1 &"
else 
	HTTP_SERVER_CMD="nohup $HOME/group-project-master/Nodejs/httpserver.js > /tmp/$HTTP_SERVER_LOG 2>&1 &"
fi
echo $STUBS | grep graphicserver
if [ $? -eq 0 ]; then
	GRAPHIC_SERVER_CMD="nohup $HOME/group-project-master/bin/stubs/graphicserver_stub.js > /tmp/$GRAPHIC_SERVER_LOG 2>&1 &"
else
	GRAPHIC_SERVER_CMD="nohup $HOME/group-project-master/Nodejs/graphicserver.js > /tmp/$GRAPHIC_SERVER_LOG 2>&1 &"
fi

EXEC_GRAPHIC_SERVER_START_SCRIPT="./$HOME/group-project-master/bin/start_graphic.sh -a $ACTION -e $ENV -s $STUBS"
EXEC_GRAPHIC_SERVER_STOP_SCRIPT="./$HOME/group-project-master/bin/stop_graphic.sh -a $ACTION -e $ENV -s $STUBS"

#Check user is on a doc host before continuing.
MACHINE=`hostname -A | awk 'BEGIN {FS="."}{print $2}'`
if [ ! "$MACHINE" == "doc" ] ; then
	echo "WARN:script must be run from a doc server"
	exit 2
fi

if [ "`hostname -i`" == "146.169.44.217" ] ; then SSH=false ; else SSH=true ; fi
SSH_VM="ssh -p 55022 $USER@146.169.44.217"
SSH_GRAPHIC="ssh $USER@graphic02.doc.ic.ac.uk"

if [ "$ENV" == "prod" ] ; then BRANCH=master ; else BRANCH=$ENV ; fi
#Handle the requested action i.e start and stop
case "$ACTION" in
  start)
	if [ -d $HOME/group-project-master ] ; then
		echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
		exit 2
	fi
        echo "Starting environment: $ENV "
	
	#start mongod server on VM
	ps -ef | grep mongodb_vm_$ENV.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_vm_$ENV.pid
        if [ -s /tmp/mongod_vm_$ENV.pid ] ; then
                echo "MongoDB is already running...PID=`cat /tmp/mongodb_vm_$ENV.pid`"
        else
		${VM_MONGODB_CMD}
		ps -ef | grep mongodb_vm_$ENV.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_vm_$ENV.pid
        fi

	#start http server on VM
	ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_vm_$ENV.pid
        if [ -s /tmp/node_vm_$ENV.pid ] ;
        then
                echo "http server is already running...PID=`cat /tmp/node_vm_$ENV.pid`"
        else
		${HTTP_SERVER_CMD}
		ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_vm_$ENV.pid
        fi

	if $DISTRIBUTED ; then 
		REPO=`${SSH_GRAPHIC} [ -d $HOME/group-project-master ] ` 
		if $REPO ; then `${SSH_GRAPHIC} ${EXEC_GRAPHIC_SERVER_START_SCRIPT}`
		else	
			echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
			exit 2
		fi
	else 	#start node graphic server locally
		ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_graphic02_$ENV.pid
        	if [ -s /tmp/node_graphic02_$ENV.pid ] ; then echo "graphic server is already running...PID=`cat /tmp/node_graphic02_$ENV.pid`" ; else
			$GRAPHIC_SERVER_CMD
			ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_graphic02_$ENV.pid
        	fi
	 	#start graphic02 instance of MongoDB locally
		ps -ef | grep mongodb_graphic_$ENV.conf | grep -v grep |  awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
        	if [ -s /tmp/mongodb_graphic_$ENV.pid ] ; then echo "graphic02 instance of MongoDB is already running...PID=`cat /tmp/mongodb_graphic_$ENV.pid`" ; else
			$GRAPHIC_MONGODB_CMD
			ps -ef | grep mongodb_graphic_$ENV.conf | grep -v grep | awk '{print $2}' > /tmp/mongodb_graphic_$ENV.pid
        	fi
	fi
        ;;
  stop)
	echo "Stopping environment: $ENV"	
	
	if [ ! -s /tmp/mongod_vm_$ENV.pid ] ; then
                echo "MongoDB is not running...therefore it can't be stopped"
        else
                echo "Stopping MongoDB.."
                sudo kill `cat /tmp/mongodb_vm_$ENV.pid`
        fi
        
	if [ ! -s /tmp/node_vm_$ENV.pid ] ; then
                echo "http server is not running...therefore it can't be stopped"
        else
                echo "Stopping http server.." 
                kill -9 `cat /tmp/node_vm_$ENV.pid`
        fi

	if $DISTRIBUTED ; then 
		`$SSH_GRAPHIC $EXEC_GRAPHIC_SERVER_STOP_SCRIPT`
	else
		if [ ! -s /tmp/node_graphic02_$ENV.pid ] ; then
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


	fi
	;;
  *)
        echo $USAGE
        exit 2
esac

