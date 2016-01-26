#!/bin/bash
# #############################################################################
#
# Key Features
# 1. copy sybase logs
#
# Parameters : N/A
#
# Version : 1.0
# Dev : lhua < liang.hua@thomsonreuters.com >
# Last update : 2015.7.3
# ##############################################################################
# Modified By: He Dong
# Modified At: 2016.1.25
#
# Usage: ./collect_db_log.sh   (execute on us2d-ejvcap0[12], to access /data)
#
# change to adjust new requirements:
#	1. keep the original output folder structure
#	2. temporary copy files to .../test folder, -> also need to adjust job_exec.sh to adopt .../test folder
#	3. copy all files in source folder, and backup successful files to .../source/backup
#
# ##############################################################################
debugMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[DEBUG]  [$TIME_STAMP] $1"
}

infoMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[INFO]  [$TIME_STAMP] $1"
}

errorMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[ERROR]  [$TIME_STAMP] $1"
}


# server enviroment coverage
SERVER_ENV=("Hydra" "PPE" "Prod")
Hydra_SERVERS=("hdatadb1" "hdatadep" "hextdb" "hgcdb" "hmunidb" "hpridb1" "hrack11" "hvalqa1" "reu0bjg1")
PPE_SERVERS=("hsbldb1" "hsdatadb" "hsgcdb1" "hsmunidb" "hsrddb1" "hscmodb1" "hsdsedb2" "hsothdb" "hsricdb" "hscpdb" "hsextdb" "hsmortdb" "hspridb1" "hssddb1")
Prod_SERVERS=("hpbldb1" "hpcmodb1" "hpcpdb" "hpdatadb" "hpdsedb2" "hpextdb" "hpgcdb1" "hpmortdb" "hpmunidb" "hpothdb" "hppridb1" "hprddb1" "hpricdb" "hpsddb1")

SOURCE_PATH="/home/users/hdong/sybase_log"
# DEST_PATH="/data/ejvqa/logFile/todo/database"
DEST_PATH="/data/ejvqa/logFile/test/database"

# 1. get file list
for file in $(ls $SOURCE_PATH/*bcp.gz)
do
	file_name=${file##/*/}
	infoMsg "processing: $file_name"
	# 2. extract env, server name
	# Notice: using =~ has a compatible issue, on us2d, the pattern should have no "". 
	# But on dev15, it has to include the "";
	# using a variable instead of string in condition directly could solve this issue
	pattern="([a-zA-Z]+[0-9]?)\.[a-zA-Z]+\.([0-9]+)\.bcp\.gz"
	if [[ "$file_name" =~ $pattern ]]
	then
		server_name=${BASH_REMATCH[1]}
		log_date=${BASH_REMATCH[2]}
		debugMsg "server name = $server_name"
		debugMsg "log date = $log_date"

		if [[ $server_name == "" || $log_date == "" ]]; then
			errorMsg "parsing server_name/log_date failed"
			continue
		fi

		if [[ "${Hydra_SERVERS[@]}" =~ $server_name ]]; then
			env=hydra
		elif [[ "${PPE_SERVERS[@]}" =~ $server_name ]]; then
			env=ppe
		elif [[ "${Prod_SERVERS[@]}" =~ $server_name ]]; then
			env=prod
		else
			errorMsg "$server_name: unrecognized server name, can not find the target enviroment!"
			continue
		fi
		debugMsg "env = $env"
	else
		infoMsg "$file_name: file name didn't match!"
		continue
	fi
	# 3. copy to target folder
	dest_file="$DEST_PATH/$env/$server_name.$log_date.gz"
	cp -f $file $dest_file || (errorMsg "$file_name: copy failed"; continue)
	gunzip -f $dest_file || (errorMsg "$dest_file: unzip failed"; continue)
	# 4. backup remote files
	mv -f $file "$SOURCE_PATH/backup/$file_name" 2>/dev/null || (errorMsg "$file_name: backup failed"; continue)
done
