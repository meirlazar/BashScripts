#!/bin/bash 
##### RESTORE to RAID0  #######

BACKUPDEST="/media/RAID1"

DIRS="Audio Books Installs Karaoke M_J Pictures Torah Videos PRON" 

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
Videos|Audio|Books|Karaoke|M_J|Pictures|Torah|Installs ) BACKUPSRC="/media/RAID0/MEDIA";;
PRON ) BACKUPSRC="/media/RAID0";;
* ) echo "No pattern matched, skipping this folder"; continue;;
esac

echo "------------------------------------------------------------------------"
tput setaf 1; echo -e "\nRestoring: ${BACKUPSRC}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 10; rsync -az --info=progress2 "${BACKUPSRC}/${X}/" "${BACKUPDEST}/${X}";
tput setaf 21; echo -e "\nBackup Completed: ${BACKUPSRC}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 7;
done




