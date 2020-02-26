#!/bin/bash 
##### Sync MEDIA to ALLDATA  #######

BACKUPSOURCE="/media/RAID0/MEDIA"
DIRS="Audio Books Installs Karaoke M_J Pictures Torah Videos" 

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
Videos ) BACKUPDEST="/media/ALLDATA1";;
Audio|Books|Karaoke|M_J|Pictures|Torah ) BACKUPDEST="/media/ALLDATA2";;
Installs ) BACKUPDEST="/media/ALLDATA3";;
* ) echo "No pattern matched, skipping this folder"; continue;;
esac

echo "------------------------------------------------------------------------"
tput setaf 1; echo -e "\nBacking Up: ${BACKUPSOURCE}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 10; rsync -az --info=progress2 "${BACKUPSOURCE}/${X}/" "${BACKUPDEST}/${X}";
tput setaf 21; echo -e "\nBackup Completed: ${BACKUPSOURCE}/${X}  ------->  ${BACKUPDEST}/${X}";
tput setaf 7;
done




