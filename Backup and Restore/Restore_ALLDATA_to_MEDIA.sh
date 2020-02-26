#!/bin/bash 
##### RESTORE to RAID0  #######

BACKUPDEST="/media/RAID0/MEDIA"

DIRS="M_J Audio Books Installs Karaoke Pictures Torah Videos" 

echo "Run the command on a separate terminal : watch lsof -ad3-999 -c rsync"
trap STOPSCRIPT SIGINT

#################################################################
#################################################################

function STOPSCRIPT () {
echo "CTRL+C Trapped, stopping Backup";
exit
}

#################################################################
#################################################################



for X in $DIRS; do 

case $X in
Videos ) BACKUPSRC="/media/ALLDATA1";;
Audio|Books|Karaoke|M_J|Pictures|Torah ) BACKUPSRC="/media/ALLDATA2";;
Installs ) BACKUPSRC="/media/ALLDATA3";;
* ) echo "No pattern matched, skipping this folder"; continue;;
esac

echo "------------------------------------------------------------------------"
tput setaf 1; echo -e "\nRestoring: ${BACKUPSRC}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 10; rsync -az --info=progress2 "${BACKUPSRC}/${X}/" "${BACKUPDEST}/${X}";
tput setaf 21; echo -e "\nBackup Completed: ${BACKUPSRC}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 7;
done




