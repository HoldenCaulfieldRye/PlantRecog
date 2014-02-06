#!/bin/bash
#
#	This script starts up all components of the system in a particular env
#	Author: ghaughian (Feb 2014)
#	Command Line Args: $1 = 'start' or 'stop'...the action you wish to happen
#			   $2 = 'dev', 'qa', or 'prod'...the environment you wish to run
#

ENV=$2
if [ "$ENV" == "prod" ] ; then BRANCH=master ; else BRANCH=$ENV ; fi
USER=`whoami`
DATE=`date +"%Y.%m.%d"`

HTTP_SERVER_LOG="httpserver_"${ENV}_${DATE}
GRAPHIC_SERVER_LOG="graphicserver_"${ENV}_${DATE}

USAGE=$"Usage: $0 {start|stop} {dev|qa|prod}"

#Check user is on a doc host before continuing.
HOSTNAME=`hostname -A | awk 'BEGIN {FS="."}{print $2}'`
if [ ! "$HOSTNAME" == "doc" ] ; then
	echo "WARN:script must be run from a doc server"
	exit
fi

#Do we need to set up a distributd system or a local one? (dev is always local)
if [ "$ENV" == "qa" -o "$ENV" == "prod" ]
  then DISTRIBUTED=true
  else DISTRIBUTED=false
fi
echo $DISTRIBUTED


while getopts "s:" OPTION
do
    case $OPTION in
        s)
            STUBS=$OPTARG 
        ;;
    esac
done

echo "required stubs: $STUBS"


#Handle the 2 options for running the script i.e start and stop
case "$1" in
  start)
        echo "Starting environment: $ENV "
	
	if $DISTRIBUTED ; then  
		if [ ! "`hostname -i`" == "146.169.44.217" ] ; then 
			ssh -p 55022 $USER@146.169.44.217
			if [ ! -d $HOME/group-project-master ] ; then 
				echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
				exit
			else 
				cd $HOME/group-project-master/bin
			fi
		fi
	fi
	git checkout $BRANCH
	
	#start mongod server on VM
	ps -ef | grep mongodb_$ENV.conf | grep -v grep |  awk '{print $2}' > /tmp/mongod_vm_$ENV.pid
        if [ -s /tmp/mongod_vm_$ENV.pid ] ;
        then
                echo "MongoDB is already running...PID=`cat /tmp/mongod_vm_$ENV.pid`"
        else
		sudo nohup /usr/bin/mongod --config ../env/mongodb_$ENV.conf &
		ps -ef | grep mongodb_$ENV.conf | grep -v grep | awk '{print $2}' > /tmp/mongod_vm_$ENV.pid
        fi

	#start http server on VM
	ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_vm_$ENV.pid
        if [ -s /tmp/node_vm_$ENV.pid ] ;
        then
                echo "http server is already running...PID=`cat /tmp/node_vm_$ENV.pid`"
        else
		nohup ../Nodejs/httpserver.js > /tmp/$HTTP_SERVER_LOG 2>&1 &
		ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_vm_$ENV.pid
        fi

	if $DISTRIBUTED ; then 
		CMD="ssh $USER@graphic02.doc.ic.ac.uk"
: '		if [ ! -d $HOME/group-project-master ] ; then 
			echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
			exit
		else 
			cd $HOME/group-project-master/bin
		fi
'	fi
	#git checkout $BRANCH

	#start mongod server on VM
	#TO-DO: ADD

	#start node graphic server on graphic02
	$CMD ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_graphic02_$ENV.pid
        $CMD if [ -s /tmp/node_graphic02_$ENV.pid ] ; then echo "graphic server is already running...PID=`cat /tmp/node_graphic02_$ENV.pid`" ; else
		nohup ../Nodejs/graphicserver.js > /tmp/$GRAPHIC_SERVER_LOG 2>&1 &
		ps -ef | grep node | grep -v grep | awk '{print $2}' > /tmp/node_graphic02_$ENV.pid
        fi

        ;;

  stop)
	echo "Stopping environment: $ENV"	
	
	if $DISTRIBUTED ; then  
		if [ ! "`hostname -i`" == "146.169.44.217" ] ; then 
			ssh -p 55022 $USER@146.169.44.217
		fi
	fi

	if [ ! -s /tmp/mongod_vm_$ENV.pid ]
        then
                echo "MongoDB is not running...therefore it can't be stopped"
        else
                echo "Stopping MongoDB.."
                sudo kill -9 `cat /tmp/mongod_vm_$ENV.pid`
        fi
        
	if [ ! -s /tmp/node_vm_$ENV.pid ]
        then
                echo "http server is not running...therefore it can't be stopped"
        else
                echo "Stopping http server.." 
                kill -9 `cat /tmp/node_vm_$ENV.pid`
        fi

	if $DISTRIBUTED ; then ssh $USER@graphic02.doc.ic.ac.uk ; fi

	if [ ! -s /tmp/node_graphic02_$ENV.pid ]
        then
                echo "graphic server is not running...therefore it can't be stopped"
        else
                echo "Stopping node server.." 
                kill -9 `cat /tmp/node_graphic02_$ENV.pid`
        fi
	
	;;
  *)
        echo $USAGE
        exit 2
esac



