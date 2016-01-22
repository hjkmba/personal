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
#
# ##############################################################################

infoMsg() {
	TIME_STAMP=`date +%Y-%m-%d" "%H:%M:%S`
	echo "[INFO]  [$TIME_STAMP] $1"
}

log_date=`date --date="1 days ago" +%y%m%d`

# server enviroment coverage
SERVER_ENV=("Hydra" "PPE" "Prod")
#Hydra_SERVERS=("hgcdb" "hmunidb" "hdatadb1")
#PPE_SERVERS=("hsgcdb1" "hsmunidb" "hsdatadb")
#Prod_SERVERS=("hpmunidb" "hpgcdb1" "hpdatadb")
Hydra_SERVERS=("hdatadb1" "hdatadep" "hextdb" "hgcdb" "hmunidb" "hpridb1" "hrack11" "hvalqa1" "reu0bjg1")
PPE_SERVERS=("hsbldb1" "hsdatadb" "hsgcdb1" "hsmunidb" "hsrddb1" "hscmodb1" "hsdsedb2" "hsothdb" "hsricdb" "hscpdb" "hsextdb" "hsmortdb" "hspridb1" "hssddb1")
Prod_SERVERS=("hpbldb1" "hpcmodb1" "hpcpdb" "hpdatadb" "hpdsedb2" "hpextdb" "hpgcdb1" "hpmortdb" "hpmunidb" "hpothdb" "hppridb1" "hprddb1" "hpricdb" "hpsddb1")

SOURCE_PATH="/home/users/nitang/programming/Performance/TM/log/hardware"
DEST_PATH="/data/ejvqa/logFile/todo/database"

lc(){
    echo $a | perl -ne 'print lc'
}

for env in ${SERVER_ENV[@]}
do
	if [ "$env" == "Hydra" ]; then
		for hydra_s in ${Hydra_SERVERS[@]}
		do
			source_file="$SOURCE_PATH/$env/$hydra_s/done/hw_$log_date.bcp.gz"
			if [ -f "$source_file" ]; then
				des_env=`echo $env | perl -ne 'print lc'`
				dest_file="$DEST_PATH/$des_env/$hydra_s.$log_date.gz"
				infoMsg "Copy database logs from $source_file to $dest_file"
				cp -f  "$source_file" "$dest_file"
				infoMsg "gunzip  file : $dest_file"
				gunzip -f "$dest_file"
			else
				infoMsg "$source_file not found!"
			fi
		done
	elif [ "$env" == "PPE" ]; then
	 	for ppe_s in ${PPE_SERVERS[@]}
		do
			source_file="$SOURCE_PATH/$env/$ppe_s/done/hw_$log_date.bcp.gz"
			if [ -f "$source_file" ]; then
				des_env=`echo $env | perl -ne 'print lc'`
				dest_file="$DEST_PATH/$des_env/$ppe_s.$log_date.gz"
				infoMsg "Copy database logs from $source_file to $dest_file"
				cp -f  "$source_file" "$dest_file"
				infoMsg "gunzip  file : $dest_file"
				gunzip -f "$dest_file"
			else
				infoMsg "$source_file not found!"
			fi
		done
	else
		for prod_s in ${Prod_SERVERS[@]}
		do
			source_file="$SOURCE_PATH/$env/$prod_s/done/hw_$log_date.bcp.gz"
			if [ -f "$source_file" ]; then
				des_env=`echo $env | perl -ne 'print lc'`
				dest_file="$DEST_PATH/$des_env/$prod_s.$log_date.gz"
				infoMsg "Copy database logs from $source_file to $dest_file"
				cp -f  "$source_file" "$dest_file"
				infoMsg "gunzip  file : $dest_file"
				gunzip -f "$dest_file"
			else
				infoMsg "$source_file not found!"
			fi
		done
	fi
done

exit 0


