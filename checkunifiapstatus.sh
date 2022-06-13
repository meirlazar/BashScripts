#!/bin/bash

SCRIPTNAME=$(basename "$0") # The name of the script
SCRIPTDIR=$(dirname "$0") # Directory of the script
LOGFILE="${SCRIPTDIR}/${SCRIPTNAME}.log.$(date +'%F')"
MAINLOG="${SCRIPTDIR}/${SCRIPTNAME}.MAIN.log"
UNIFIIP="X.X.X.X Y.Y.Y.Y" # change to the ip addresses of the UNIFI APs
UNIFIUSER=myusername # change to unifi login userid
UNIFIPASS=XXXXXXXXXXXXX # Change to password
SSHTOAP="sshpass -p ${UNIFIPASS} ssh -oStrictHostKeyChecking=no ${UNIFIUSER}@${X}"
CONTROLLERIP=Z.Z.Z.Z # change to UNIFi Controller IP address
CONTROLLERPORT=8080
NOTIFY=email@mail.com # change to your email address for noitifcations 

###########################################################################

function LOG () {
printf "%b\n" "$(date +"%b/%d/%Y:%H:%M:%S") $*" | tee -a ${LOGFILE}
}

###########################################################################

function MAILERR () {
cat "${LOGFILE}" | mail -s "${SCRIPTDIR}\${SCRIPTNAME} - ERRORS with UNIFI AP" ${NOTIFY}
}

###########################################################################

function CLEANUP () {
cat "${LOGFILE}" >> "${MAINLOG}"
rm -f "${LOGFILE}"
exit
}

###########################################################################

function UNIFIAPCONN () {
LOG "INFO" "${FUNCNAME[0]} Subroutine Initiated."
LOG "INFO" "CHECKING CONNECTIVITY OF UNFI AP - ${X}"
timeout 2 ping -c 1 -W 1 -q ${X} > /dev/null 2>&1

if [[ $? = 0 ]]; then LOG "INFO" "UNIFI AP - ${X} HAS BASIC CONNECTIVITY TO THE NETWORK"
else
LOG "ERROR" "UNIFI AP - ${X} IS UNREACHABLE"
LOG "ERROR" "${FUNCNAME[0]} Subroutine Completed with errors."
MAILERR
CLEANUP
fi
LOG "INFO" "${FUNCNAME[0]} Subroutine Completed."
}
###########################################################################

function GETAPSTATE () {
LOG "INFO" "${FUNCNAME[0]} Subroutine Initiated."
APINFO=$(sshpass -p ${UNIFIPASS} ssh -oStrictHostKeyChecking=no ${UNIFIUSER}@${X} 'mca-cli-op info')
APSTATE=$(echo "${APINFO}" | grep Status | awk '{print $2}')
UNIFIIP=$(echo "${APINFO}" | grep "IP Address" | awk -F: '{print $2}' | xargs)
APINFO=$(echo "${APINFO}" | tr -s ' ' | grep -v '^$')
LOG "INFO" "UNIFI AP INFO ${X};\n${APINFO}"
LOG "INFO" "${FUNCNAME[0]} Subroutine Completed."
}

###########################################################################

function SETINFORM () {
LOG "INFO" "${FUNCNAME[0]} Subroutine Initiated."
LOG "INFORMING THE UNIFI AP ${X} OF THE UNIFI CONTROLLER - mca-cli-op set-inform http://${CONTROLLERIP}:${CONTROLLERPORT}/inform"
sshpass -p ${UNIFIPASS} ssh -oStrictHostKeyChecking=no ${UNIFIUSER}@${X} "mca-cli-op set-inform http://${CONTROLLERIP}:${CONTROLLERPORT}/inform"
LOG "INFO" "${FUNCNAME[0]} Subroutine Completed."
}

###########################################################################

function BOUNCEAP () {
LOG "INFO" "${FUNCNAME[0]} Subroutine Initiated."
LOG "INFO" "REBOOTING THE UNIFI AP - ${X}"
sshpass -p ${UNIFIPASS} ssh -oStrictHostKeyChecking=no ${UNIFIUSER}@${X} "reboot"
LOG "INFO" "${FUNCNAME[0]} Subroutine Completed."
}

###########################################################################
function CHECKAPSTATE () {
LOG "INFO" "${FUNCNAME[0]} Subroutine Initiated."
if [[ "${APSTATE}" != "Connected" ]]; then
	LOG "ERROR - AP - ${X} is in ${APSTATE} state"
	SETINFORM; sleep 300; CHECKAPSTATE

	if [[ "${APSTATE}" != "Connected" ]]; then
		BOUNCEAP; sleep 300; UNIFIAPCONN
		if [[ "${APSTATE}" != "Connected" ]]; then
			LOG "ERROR" "UNIFI AP - ${X} WAS INFORMED OF UNFI CONTROLLER http://${CONTROLLERIP}:${CONTROLLERPORT} - BUT IS STILL NOT FUNCTIONING PROPERLY. PLEASE RESOLVE"
			LOG "ERROR" "${FUNCNAME[0]} Subroutine Completed with errors."
			MAILERR
			CLEANUP
		fi
	fi
else LOG "INFO" "UNIFI AP - ${X} IS FUNCTIONING PROPERLY."
fi

}

###########################################################################

for X in ${UNIFIIP}; do
UNIFIAPCONN
GETAPSTATE
CHECKAPSTATE
done
