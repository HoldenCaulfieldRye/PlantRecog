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
        echo "Starting environment: $ENV "
	if $DISTRIBUTED ; then  
		if [ $SSH ] ; then 
			REPO=`$SSH_VM [ -d $HOME/group-project-master ] ` 
			if [ ! $REPO ] ; then 
				echo "Please ensure the group-project-master repo has been cloned to your home directory: $HOME/group-project-master"
				exit 2
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
: '		`SSH_GRAPHIC [ ! -d $HOME/group-project-master ] ` 
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
	`$SSH_GRAPHIC ps -ef | grep node | grep -v grep |  awk '{print $2}' > /tmp/node_graphic02_$ENV.pid`
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



