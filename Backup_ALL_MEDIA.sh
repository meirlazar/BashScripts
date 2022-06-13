
#!/bin/bash

# Written by Meir Lazar
# Version 3.6 11/27/2019

# Purpose: This is a terminal menu-driven user-defined backup program for Linux (tested on Ubuntu) USING A SIMILAR SETUP AS RSNAPSHOT BUT ALL-IN-ONE

########################################################
########################################################

TRAPERROR () {
echo "Script had an error at line $1 with exit code $2"
if [ $1 -lt 15 ]; then echo "Script had an error at line $1 with exit code $2" 
elif [ $1 -ge 15 ]; then echo "Script had a FATAL error at line $1 with exit code $2"
exit $2
fi
}

########################################################
########################################################

trap 'TRAPERROR ${LINENO} $?' ERR  

# USER DEFINED VARIABLES
BACKUPDIRS="Audio Books Apps Pictures Videos" # SPECIFY WHICH SUB-DIRS TO BACKUP - CHANGE THIS
BACKUPSOURCE="/media/mymedia" # SPEFICY THE BACKUP SOURCE DIRECTORY 
DIRTOTALUSED="/tmp/DIRTOTALUSED.log"
NO=5 # NUMBER OF INCREMENTAL BACKUPS TO KEEP


########################################################
########################################################

function TYP () {
	case $1 in 
		WHITE ) tput setaf 7;;
		BLUE ) tput setaf 21;;
		YELLOW ) tput setaf 11;;
		GREEN ) tput setaf 10;;
		RED ) tput setaf 1;;
		DRED ) tput setaf 9;;
		PINK ) tput setaf 13;;
		PURPLE ) tput setaf 5;;
		CLEAR ) tput clear; tput sgr0; tput rc;;
		RESET ) tput sgr0;;
		BOLD ) tput bold;;
		REVERSE ) tput rev;;
		esac
}

##########################################################
##########################################################

function MOVE () {
	tput cup $1 $2
}

##########################################################
##########################################################

function CLEANUP () {
TYP CLEAR
clear
QUIT=1
exit 0
}

########################################################
########################################################

function TOPMENU () {
TYP CLEAR
MOVE 0 10; TYP BLUE; TYP BOLD; echo "L I N U X - B A C K U P  &  R E S T O R E   v 3 . 6"
MOVE 2 10; TYP WHITE; TYP REVERSE; echo "${MENUNAME}"; TYP RESET
MOVE 4 10; TYP YELLOW; echo "SOURCE:"; MOVE 4 30; TYP RED; echo "${BACKUPSOURCE}"
MOVE 5 10; TYP YELLOW; echo "SOURCE SUB-DIRS:"; MOVE 5 30; TYP RED; echo "${BACKUPDIRS}"
MOVE 6 10; TYP GREEN; echo "DESTINATION:"; MOVE 6 30; TYP RED; echo "${BACKUPDEST}"
MOVE 7 10; TYP PURPLE; echo "ROTATE AFTER:"; MOVE 7 30; TYP RED; echo "${NO}"; TYP RESET;
}

########################################################
########################################################


function SHOWMOUNTED () {
unset COUNT
TYP BOLD; TYP BLUE; echo "+++++++++++++++++  MOUNTED DIRS +++++++++++++++++"; TYP RESET
df -h | egrep -v 'squashfs|tmpfs|fuse|loop|udev'
TYP BOLD; TYP BLUE; echo "+++++++++++++++++++++++++++++++++++++++++++++++++";  TYP RESET
MOUNTS=$(df -h | egrep -v 'squashfs|tmpfs|fuse|loop|udev|Filesystem|/boot/efi' | awk '{print $6}')
for X in ${MOUNTS}; do
COUNT=$(( COUNT + 1 ))
echo "${COUNT}. ${X}"
done
}


########################################################
########################################################

function DIRTOTALS () {
TYP BLUE; echo -e "\n\n++++++++++++++++++++++++++++++++++ DIRECTORY LISTING INFORMATION ++++++++++++++++++++++++++++++++++\n"
TYP WHITE
for X in ${BACKUPDIRS}; do
DIRINFO=$(du -sh "${BACKUPSOURCE}/${X}")
if ! [[ -f "${BACKUPDEST}/BACKUP.LOG" ]]; then touch "${BACKUPDEST}/BACKUP.LOG"; fi
LASTBACKUP=$(grep "${X}" "${BACKUPDEST}/BACKUP.LOG" | tail -1)
if [[ -z ${LASTBACKUP} ]]; then LASTBACKUP="NEVER BACKED UP ON THIS DEVICE"; fi
echo "${DIRINFO} - ${LASTBACKUP}"
done

DESTFREE=$(df -h ${BACKUPDEST} | grep -v "Filesystem" | awk '{print $4}')
TYP RED; echo -e "\nFREE SPACE ON DESTINATION - ${DESTFREE}\n"
TYP BLUE; echo -e "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
TYP RESET
}


########################################################
########################################################

function BESTFIT () {

rm -f ${DIRTOTALUSED} 
touch ${DIRTOTALUSED}

MENUNAME="B E S T  F I T - M E N U"
TOPMENU

echo "DIR TOTALS VERSUS WHAT WILL FIT ON DESTINATION"

echo "GETTING TOTAL SPACE USED ON DIRECTORIES"
for X in ${BACKUPDIRS}; do
du -bs "${BACKUPSOURCE}/${X}" >> ${DIRTOTALUSED}
done

TOTALUSED=$(echo "${DIRTOTALUSED}" | awk '{print $1}') 

echo "GETTING FREE SPACE ON DESTINATION"
BACKUPDESTFREE=$(df -k ${BACKUPDEST} | | grep -v "Filesystem" | awk '{print $4}') 

echo "SHOWING YOUR OPTIONS FOR BEST FIT ON DESTINATION"

until [[ ${FREESPACE} -le 50000000000 ]] || [[ ${FREESPACE} -le 0 ]]; do
SHUFFLE=$(for X in $(echo ${TEMPLOG} | awk '{print $1}' | shuf); do echo $X; done | shuf)
for X in ${SHUFFLE}; do echo ""; done ############# fix later
done



read -p "Press Enter to return to the MAIN MENU..."
tput clear; tput sgr0; tput rc
}

########################################################
########################################################


function SETSOURCEMENU () {
	
MENUNAME="S E T  S O U R C E - M E N U"
TOPMENU
MOVE 10 10; TYP BOLD; TYP BLUE; echo -e "SPECIFY THE DIRECTORY FOR THE BACKUP SOURCE\n";


SHOWMOUNTED
echo ""

TYP RED; read -p "BACKUP SOURCE PATH W/O LEADING SLASH (i.e, /media/mymedia)": BACKUPSOURCE

TYP WHITE; ls ${BACKUPSOURCE}
TYP BLUE; read -p "BACKUP SOURCE DIRS LIST (i.e, Audio Books Apps Pictures Videos)": BACKUPDIRS

TYP WHITE; read -p "Press Enter to return to the MAIN MENU..."
TYP CLEAR
}

########################################################
########################################################

function SETDESTMENU () {
	
MENUNAME="S E T  D E S T I N A T I O N - M E N U"
TOPMENU
MOVE 10 10; TYP BOLD; tput setaf 4; echo -e "SPECIFY THE DIRECTORY FOR THE BACKUP DESTINATION\n"

tput setaf 6; 
SHOWMOUNTED
echo ""

TYP BLUE; read -p "BACKUP DESTINATION PATH W/O LEADING SLASH (i.e, /media/usb1/allmedia)": BACKUPDEST

TYP WHITE; echo "BACKUP DESTINATION SET AS: ${BACKUPDEST}"

echo -e "\n"; read -p "Press Enter to Continue..."

}

########################################################
########################################################

function CHECKDEST () {

if [[ -z ${BACKUPDEST} ]]; then SETDESTMENU; fi

MENUNAME="C H E C K  D E S T I N A T I O N - M E N U"
TOPMENU
	
DESTMOUNTED=$(grep -c $BACKUPDEST /proc/mounts)
if  [[ "$DESTMOUNTED" = "0" ]]; then mount ${BACKUPDEST} || DESTMOUNTED=FAIL; fi
	
DESTFULL=$(df -PkHl $DEST2 | grep -vE ^Filesystem | awk '{print $6}' | cut -d "%" -f1 -)

if [[ $DESTMOUNTED -eq "FAIL" ]]; then echo "DESTINATION DIRECTORY FAILED TO MOUNT. CANNOT CONTINUE WITH BACKUP"
	read -p "Press Enter to return to the MAIN MENU..."
	tput clear; tput sgr0; tput rc
fi

}

########################################################
########################################################

function CHECKDATEMENU () {
if [[ -z ${BACKUPDEST} ]]; then SETDESTMENU; fi
MENUNAME="C H E C K   B A C K U P S - M E N U"
TOPMENU
DIRTOTALS
read -p "Press Enter to return to the MAIN MENU..."
tput clear; tput sgr0; tput rc
}

########################################################
########################################################

function MOUNTDRIVE () {

MENUNAME="M O U N T   A  D R I V E - M E N U"
TOPMENU

lsblk -f | grep -v loop
echo -e "\n\n"
read -p "CHOOSE A PARTITION TO MOUNT(i.e. /dev/sdf1)": PARTITION
read -p "CHOOSE A MOUNT POINT (i.e. /media/BACKUP)": MPOINT

if ! [[ -d  ${MPOINT} ]]; then 
sudo mkdir -p ${MPOINT}
	if [[ $? = 0 ]]; then 
	sudo chmod 777 ${MPOINT}
	echo "CREATED MOUNT POINT: ${MPOINT}"
	else
	echo "UNABLE TO CREATE MOUNT POINT: ${MPOINT}"
	read -p "Press Enter to return to the MAIN MENU..."
	continue
	fi
fi

sudo mount ${PARTITION} ${MPOINT}
	if [[ $? = 0 ]]; then 
	sudo chmod 777 ${MPOINT}
	echo "MOUNTED: ${PARTITION} ON ${MPOINT}"
	read -p "Press Enter to return to the MAIN MENU..."
	else
	echo "UNABLE TO MOUNT: ${PARTITION} ON ${MPOINT}"
	read -p "Press Enter to return to the MAIN MENU..."
	fi
}

########################################################
########################################################


function SETINCREMNUMBER () {
	
MENUNAME="S E T   N U M B E R   O F   I N C R E M E N T A L   B A C K U P S - M E N U"
TOPMENU

read -p "How many incremental backups do you want on this device?": NO
if [[ -z ${NO} ]]; then NO=5; fi

echo "The number of backups are now set to: ${NO}"
read -p "Press Enter to return to the MAIN MENU..."
tput clear; tput sgr0; tput rc
}


########################################################
########################################################

function RUNBACKUPORIG () { # THIS IS DEFUNCT NOW THAT WE USE CP -AL FOR INCREMENTALS

if [[ -z ${BACKUPDEST} ]]; then SETDESTMENU; fi
MENUNAME="R U N   B A C K U P S - M E N U"
TOPMENU
DIRTOTALS

echo -e "\n"
for X in ${BACKUPDIRS}; do
read -p "BACKUP THE DIRECTORY: $X (Y/N)?": STARTBACKUP
if [[ ${STARTBACKUP} = [Yy] ]]; then 
rsync -az --info=progress2 "${BACKUPSOURCE}/${X}" "${BACKUPDEST}/" 
	if [[ $? = 0 ]]; then 
	NOW=$(date +"%m/%d/%Y %H:%M:%S")
	echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW"
	echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW" >> "${BACKUPDEST}/BACKUP.LOG"
	fi
fi

done
	read -p "Press Enter to return to the MAIN MENU..."
	tput clear; tput sgr0; tput rc
}

########################################################
########################################################

function RUNBACKUP () {

if [[ -z ${BACKUPDEST} ]]; then SETDESTMENU; fi

MENUNAME="R U N   I N C R E M E N T A L   B A C K U P S - M E N U"
TOPMENU
# DIRTOTALS
TODAY=$(date +%F)

echo -e "\n"

for X in ${BACKUPDIRS}; do
	read -p "BACKUP THE DIRECTORY: $X (Y/N)?": STARTBACKUP
		if [[ ${STARTBACKUP} = [Yy] ]]; then 
		echo "Starting Backup: ${BACKUPSOURCE}/${X}  ------->  ${BACKUPDEST}/${X}"
		find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.${NO}.*"  -exec rm -rf {} \; 

		HIGHERNUMBER=${NO}
		unset LOWERNUMBER
		
			until [[ ${LOWERNUMBER} -eq 1 ]]; do 
			LOWERNUMBER=$(( HIGHERNUMBER - 1 ))  
			# step 2: shift the middle snapshots(s) up 1 number, but leave backup.0 alone
			find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.${LOWERNUMBER}.*" | while read DIR; do mv "${DIR}" "${DIR//backup.${LOWERNUMBER}./backup.${HIGHERNUMBER}.}"; done
			HIGHERNUMBER=$(( HIGHERNUMBER - 1 ))
			done

		# step 3: make a hard-link-only (except for dirs) copy of the latest snapshot
			find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.0.*" | while read DIR; do cp -al "${DIR}" "${DIR//backup.0./backup.1.}"; done

		# step 4: rsync from the system into the latest snapshot (notice that
		# rsync behaves like cp --remove-destination by default, so the destination
		# is unlinked first.  If it were not so, this would copy over the other
		# snapshot(s) too!

		rsync -az --info=progress2 --delete "${BACKUPSOURCE}/${X}/" "${BACKUPDEST}/${X}/backup.0.${TODAY}/"


			if [[ $? = 0 ]]; then 
			NOW=$(date +"%m/%d/%Y %H:%M:%S")
			echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW"
			echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW" >> "${BACKUPDEST}/BACKUP.LOG"
			fi
		fi

done

	read -p "Press Enter to return to the MAIN MENU..."
	TYP CLEAR
}

########################################################
########################################################


function RUNPREVBACKUP () {

if [[ -z ${BACKUPDEST} ]]; then SETDESTMENU; fi

MENUNAME="R E R U N   P R E V I O U S L Y  B A C K E D U P   -  M E N U"
TOPMENU
#DIRTOTALS
TODAY=$(date +%F)

echo -e "\n"
read -p "Press Enter to start the backup..."

		for X in ${BACKUPDIRS}; do

		LASTBACKUP=$(grep "${X}" "${BACKUPDEST}/BACKUP.LOG" | tail -1)
				if ! [[ -z ${LASTBACKUP} ]]; then 
				TYP BLUE; echo -e "\nStarting Backup: ${BACKUPSOURCE}/${X}  ------->  ${BACKUPDEST}/${X}"; TYP WHITE;

						find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.${NO}.*"  -exec rm -rf {} \; 
						
						HIGHERNUMBER=${NO}
						unset LOWERNUMBER

								until [[ ${LOWERNUMBER} -eq 1 ]]; do 
									LOWERNUMBER=$(( HIGHERNUMBER - 1 ))   
									# step 2: shift the middle snapshots(s) up 1 number, but leave backup.0 alone
									find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.${LOWERNUMBER}.*" | while read DIR; do mv "${DIR}" "${DIR//backup.${LOWERNUMBER}./backup.${HIGHERNUMBER}.}"; done
									HIGHERNUMBER=$(( HIGHERNUMBER - 1 ))
								done

						# step 3: make a hard-link-only (except for dirs) copy of the latest snapshot
						find "${BACKUPDEST}/${X}" -maxdepth 1 -type d -name "backup.0.*" | while read DIR; do cp -al "${DIR}" "${DIR//backup.0./backup.1.}"; done

						# step 4: rsync from the system into the latest snapshot (notice that
						# rsync behaves like cp --remove-destination by default, so the destination
						# is unlinked first.  If it were not so, this would copy over the other
						# snapshot(s) too!

						rsync -az --info=progress2 --delete "${BACKUPSOURCE}/${X}/" "${BACKUPDEST}/${X}/backup.0.${TODAY}/"


							if [[ $? = 0 ]]; then 
							NOW=$(date +"%m/%d/%Y %H:%M:%S")
							TYP GREEN; echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW"; TYP RESET
							echo "${BACKUPSOURCE}/${X} BACKED UP ON $NOW" >> "${BACKUPDEST}/BACKUP.LOG"
							fi
				fi

		done

	TYP RED; echo -e "\nBACKUPS HAVE COMPLETED\n"
	TYP BLUE; read -p "Press Enter to return to the MAIN MENU..."
	TYP CLEAR
}




########################################################
########################################################


# MAIN MENU

until [[ $QUIT = 1 ]]; do

unset CHOICE1
clear

MENUNAME="M A I N - M E N U"
TOPMENU

tput cup 10 10; TYP BLUE; echo "1. BACKUP A DIRECTORY"
tput cup 11 10; echo "2. RESTORE A BACKUP"
tput cup 12 10; echo "3. CHECK DATE OF LAST BACKUP OF ALL DIRECTORIES"
tput cup 13 10; echo "4. SET/CHANGE AMOUNT OF INCREMENTAL BACKUPS (DEFAULT: 5)"
tput cup 14 10; echo "5. SET/CHANGE BACKUP SOURCE AND DIRS"
tput cup 15 10; echo "6. SET/CHANGE BACKUP DESTINATION"
tput cup 16 10; echo "7. GET DIRECTORY TOTAL USED SPACE"
tput cup 17 10; echo "8. MOUNT A NEW DRIVE"
tput cup 18 10; echo "9. BACKUP PREVIOUSLY BACKED UP DIRS ON THIS DEVICE"
tput cup 19 10; echo "Q - Quit"
tput cup 22 10; TYP BOLD; TYP RED;  read -p "Enter your choice:" CHOICE1
TYP CLEAR

case $CHOICE1 in
1 ) CHECKDEST; RUNBACKUP;;
2 ) RESTOREMENU;;
3 ) CHECKDATEMENU;;
4 ) SETINCREMNUMBER;;
5 ) SETSOURCEMENU;;
6 ) SETDESTMENU;;
7 ) DIRTOTALS;;
8 ) MOUNTDRIVE;;
9 ) CHECKDEST; RUNPREVBACKUP;;
[qQ] ) CLEANUP;;
* ) echo "Invalid selection, please try again."; sleep 3;;
esac

done
##########################################################
##########################################################
