#!/bin/bash

# #############################################################################
#
# Key Features
# 1. start logstash for log parse and nomalized data to elasticsearch
# 2. check sincedb to tracking file parsing progress.
# 3. stop logstash/restart logstash
#
# Parameters : start | stop | restart | reload <job name>
# 	E.g.: jobexec start autosys
#
# Version : 1.0
# Dev : lhua < liang.hua@thomsonreuters.com >
# Last update : 2015.7.1
#
# ##############################################################################

#SCRIPT="$0"
APP_HOME="/home/users/qa/performance"

#  ====== ATTENTION ==========
# APP_NAME should be same as
#  -- configuration file
#  -- logstash conf file name
# =============================
APP_NAME="$2"
JOB_CONFIG="$APP_HOME/confs/jobs/$APP_NAME.cfg"
LOGSTASH_CONFIG="$APP_HOME/confs/logstash/$APP_NAME.conf"


debugMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[DEBUG] [$TIME_STAMP] $1"
}

infoMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[INFO]  [$TIME_STAMP] $1"
}

errorMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[ERROR] [$TIME_STAMP] $1"
}

infoMsg $APP_HOME

##################################################
#
# Logstash configuration files
#
LOGSTASH_DESC="Logstash $APP_NAME Agent"
# Logstash app location and daemon
LOGSTASH_DEAMON="$APP_HOME/elastic/logstash/bin/logstash"
LOGSTASH_LOCATION="$APP_HOME/elastic/logstash/bin"
# Path where sincedb files are.
LOGSTASH_SINCEDB="$APP_HOME/elastic/sincedb/$APP_NAME"
# Path for logstash log
LOGSTASH_LOGFILE="$APP_HOME/elastic/logs/logstash_$APP_NAME.log"
# Path for logstash pid file
LOGSTASH_PIDFILE="$APP_HOME/elastic/pid/logstash_$APP_NAME.pid"
# ARGS
# LOGSTASH_ARGS="-Xmx$JAVAMEM -Xms$JAVAMEM -jar ${JARNAME} agent --config ${CONFIG_DIR} --log ${LOGFILE} --grok-patterns-path ${PATTERNSPATH}"
LOGSTASH_ARGS="-f ${LOGSTASH_CONFIG} --log ${LOGSTASH_LOGFILE}"
#
# END CONFIGURATION

. /etc/init.d/functions

# set pid file

setPidfile()
{
  	pgrep -f "$LOGSTASH_CONFIG" > $LOGSTASH_PIDFILE
}

# clean up sincedb file

clearSincedb()
{
	infoMsg "clean up sincedb file : $LOGSTASH_SINCEDB. "

	if [ -e $LOGSTASH_SINCEDB ]; then
		rm -rf $LOGSTASH_SINCEDB
	fi

	infoMsg "$LOGSTASH_SINCEDB deleted. "
}

checkpid() {
    local i
    for i in $* ; do
            [ -d "/proc/$i" ] && return 0
    done
    return 1
}

startLogstash()
{
  cd $LOGSTASH_LOCATION && \
  ($LOGSTASH_DEAMON $LOGSTASH_ARGS &) \
  && success || failure
  setPidfile
}

stopLogstash()
{
  	pid=`cat $LOGSTASH_PIDFILE`
  	if checkpid $pid 2>&1; then
       	# TERM first, then KILL if not dead
       	kill -TERM $pid >/dev/null 2>&1
       	usleep 100000
       	if checkpid $pid && sleep 1 &&
                 checkpid $pid && sleep 1 &&
                 checkpid $pid ; then
            kill -KILL $pid >/dev/null 2>&1
            usleep 100000
       	fi
   	fi
   	checkpid $pid
   	RC=$?
   	[ "$RC" -eq 0 ] && failure $"$NAME shutdown" || success $"$NAME shutdown"
   	rm $LOGSTASH_PIDFILE
}

restartLogstash()
{
	stopLogstash
	sleep ${SLEEP_INTERVAL}
	startLogstash
}

checkSincedb()
{
	# debugMsg "find $LOG_FILE_PATH -type f| awk $LOG_FILE_PATTERN"
	# redirect errors if find command has no permission to enter a sub-directory
	for file in `find $LOG_FILE_PATH -type f| awk $LOG_FILE_PATTERN 2> /dev/null`; do
	    txt=""
	    inode=`ls -i $file | awk '{print $1}'`
	    txt="$txt file:$file inode:$inode";
	    actual_size=`ls -l $file | awk '{print $5}'`

	    grep $inode $LOGSTASH_SINCEDB > /dev/null 2>&1
	    if [ $? -eq 0 ]; then
	        txt="$txt found in sincedb file"
	        txt="$txt actual_size:$actual_size"
	        scanned_sizes=`grep $inode $LOGSTASH_SINCEDB | awk '{print $4}'`

	        for scanned_size in $scanned_sizes; do
	            txtv="scanned_size:$scanned_size"
	            if [ $actual_size -eq $scanned_size ]; then
	                date_last_modification=`perl -MPOSIX=strftime -le 'print strftime("%Y%m%d%H%M", localtime((stat shift)[9]))' $file`
	                txtv="$txtv [fully scanned since $date_last_modification]"
	                back_up_file=$( echo ${file} | sed "s/todo\//done\//g" )

	                infoMsg "back up $file to $back_up_file"
	                mkdir -p `dirname $back_up_file`
	                mv $file $back_up_file

	                infoMsg "$txt $txtv"

	            elif [ $actual_size -gt $scanned_size ]; then
	                infoMsg "$txt $txtv"
	            fi;
	        done;
	    else
	        txt="$txt not found in sincedb file"
	        infoMsg $txt
	    fi;
	done;
}

isFinished()
{
	file_count=0
	for file in `find $LOG_FILE_PATH -type f| awk $LOG_FILE_PATTERN 2> /dev/null`; do
		let file_count+=1
	done

	infoMsg "found $file_count log files ..."

	if [ $file_count -eq 0 ]; then
		retval=1
	else
		retval=0
	fi
	return $retval
}

jobMonitoring()
{
	checked_count=0
	is_finished_flag=0
	infoMsg "sleep ${SLEEP_INTERVAL}"
	sleep ${SLEEP_INTERVAL}

	infoMsg "check if all jobs are finished"
	while [ $is_finished_flag -lt 1 ]
	do
		infoMsg "check sincedb and delete finished logs"
		checkSincedb

		infoMsg "check whether logstash is finished"
		isFinished
		is_finished_flag=$?

		let "checked_count+=1"

		infoMsg "loop $checked_count times"
		if [ $checked_count -eq ${WHILE_LOOP_MAX_TIME} ]; then
			infoMsg "loop ${WHILE_LOOP_MAX_TIME} times and restart logstash"
			sleep ${SLEEP_INTERVAL}
			restartLogstash
			checked_count=0
		fi
		infoMsg "sleep ${SLEEP_INTERVAL}"
		sleep ${SLEEP_INTERVAL}
	done
	infoMsg "All logs are done! stop logstash"
}

showUsage() {

	echo "Usage: jobexec { start | stop | status | restart } <job name>" >&2
}

checkCommand() {
	if [ $# -ne 2 ]
  	then
    	showUsage
    	exit
	fi

	# prepare job execution configurations
	if [ -f "$JOB_CONFIG" ] ; then
		source "$JOB_CONFIG"
	else
		errorMsg "job configuration file not found : $JOB_CONFIG"
		exit
	fi
	infoMsg "configuration file loaded successful!"

	infoMsg "sleep interval for check sincedb is : $SLEEP_INTERVAL"
	infoMsg "check loop number is : $WHILE_LOOP_MAX_TIME"
	infoMsg "log file path is: $LOG_FILE_PATH"
	infoMsg "log file parttern is : $LOG_FILE_PATTERN"

	# check logstash configuration file
	if [ -f "$LOGSTASH_CONFIG" ] ; then
		infoMsg "found logstash configuration file!"
	else
		errorMsg "logstash configuration file not found : $LOGSTASH_CONFIG"
		exit
	fi

	# Exit if the package is not installed
	if [ ! -x "$LOGSTASH_DEAMON" ]; then
	{
	  	errorMsg "Couldn't find $LOGSTASH_DEAMON"
	  	exit
	}
	fi
}

docommand() {

	case "$1" in
	  start)
	    infoMsg "Starting $LOGSTASH_DESC "
	    clearSincedb
	    startLogstash
	    jobMonitoring
	    stopLogstash
	    ;;
	  stop)
	    infoMsg "Stopping $LOGSTASH_DESC "
	    stopLogstash
	    ;;
	  restart|reload)
	    infoMsg "Restarting $LOGSTASH_DESC "
	    restartLogstash
	    ;;
	  status)
		pid=`cat $LOGSTASH_PIDFILE`
		if checkpid $pid 2>&1; then
			if ps -p $pid >&- ; then
				infoMsg "logstash is running"
			else
				infoMsg "logstash is not running"
			fi
		else
			infoMsg "logstash PID file not found."
		fi
	    ;;
	  *)
	    showUsage
	    exit
	    ;;
	esac

}

checkCommand "$@"
docommand "$@"

exit 0
