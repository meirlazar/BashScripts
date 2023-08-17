#!/bin/bash
#  source this file in your .bashrc so you can call any of these standalone functions from your BASH SHell session
# or use this for your scripts


# VARIABLES NEEDED FOR FUNCTIONS TO WORK
: <<'END_COMMENT'
# THIS IS A MULTILINE COMMENT USING HERETO TO DEFINE WHAT VARS ARE NEEDED BY SCRIPTS SOURCING THIS FILE
# THESE VARS SHOULD BE PLACED IN EACH INDIVIDUAL SCRIPT SINCE THEY WILL BE UNIQ - DO NOT UNCOMMENT THESE VARS HERE

Purpose='Standalone functions for a variety of uses'
Author='Meir Lazar'
VersionDate='07.26.2023'

# BASE AND SCRIPT VARS
SCRIPTDIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)  # /usr/local/scripts
BASEDIR="${SCRIPTDIR%/*}"                              # /usr/local
SCRIPTNAME=$(basename "$0")                            # scriptfile.sh
FULLSCRIPTPATH="${SCRIPTDIR}/${SCRIPTNAME}"            # /usr/local/scripts/scriptfile.sh
SCRIPTNAME_NO_EXT="${SCRIPTNAME%.*}"                   # scriptfile

# UNIVERSAL LOG VARS
LOGDIR="${BASEDIR}/logs" ;        					   # logfiles and snippets reside here
SNIPPET="${LOGDIR}/${SCRIPTNAME_NO_EXT}.snippet" ;     # log for this one execution
LOGFILE="${LOGDIR}/${SCRIPTNAME_NO_EXT}.log" ;         # longterm logfile appended to at te end of execution

# UNIVERSAL PID INFO
PIDDIR="${BASEDIR}/pids" ;      					   # dir for the pidfile to reside
MYPID=$$                                               # Current PID of script
PIDFILE="${PIDDIR}/${SCRIPTNAME_NO_EXT}.pid" ;         # pidfile used to check if script is running

# UNIVERSAL BACKUP VARS
BKUPDIR="${BASEDIR}/backups" ;  					   #  BACKUPS DIR FOR ALL SCRIPTS

# internal field separater space,tab,new line
IFS=$' \t\n' ;
shopt -s extglob

. /usr/local/scripts/allfunctions.sh
GetTimeDateInfo

END_COMMENT

#######################################################################################################################
# internal field separater space,tab,new line
IFS=$' \t\n' ;
shopt -s extglob

############### UNIVERSAL VARIABLES FOR ALL SCRIPTS #################

# COMMON DIRS
WEBDATA='/var/www/html';
SYSDIRS='/etc/systemd/system';
WEBCONF='/etc/httpd';
# USER INFO
PGUSER='postgres'                                       # postgres user
# THRESHOLD VALUES
SIZETHRESH='10000'                                      # 10MB # minimum size of gz backup file

#############################################################
#####     LOGGING, TRAPPING, SHORTCUT FUNCTIONS          ####
#############################################################

function LOG () {
if [[ -z "${SNIPPET}" ]]; then printf "%b\n" "$(date +"%F %T") $*" ; else
printf "%b\n" "$(date +"%F %T") $*" | tee -a "${SNIPPET}" ; fi
}

function LOGINIT () {
if [[ -z "${SNIPPET}" ]]; then printf "%b\n" "$(date +"%F %T") INFO ${1} Subroutine Initiated." ; else
printf "%b\n" "$(date +"%F %T") INFO ${1} Subroutine Initiated." | tee -a "${SNIPPET}" ; fi
}

function LOGSTOP () {
if [[ -z "${SNIPPET}" ]]; then printf "%b\n" "$(date +"%F %T") INFO ${1} Subroutine Completed."; else
printf "%b\n" "$(date +"%F %T") INFO ${1} Subroutine Completed." | tee -a "${SNIPPET}" ; fi
}

function FatalTrap () { LOG "FATAL" "${FULLSCRIPTPATH} - Had an error. Function = $1  Line # = $2 Exit Code = $3"; exit $3 ; }
function BreakTrap () { LOG "HALTED" "${FULLSCRIPTPATH} - User stopped this process. It halted at Function = $1  Line # = $2 Exit Code = $3"; exit $3 ; }
function GetTimeDateInfo () { MY=$(date +'%m_%Y') ; TODAY=$(date +'%F') ; HM=$(date +'%H%M') ; NOW=${TODAY}_${HM} ; }
#############################################################

#############################################################
#####     CHECK OR VERIFY  SOMETHING FUNCTIONS           ####
#############################################################

# prevent more than 1 instance of this script
function Highlander () {
LOGINIT "${FUNCNAME[0]}"
if [[ -z ${PIDDIR} ]] || [[ -z ${PIDFILE} ]]; then LOG "WARN" "PIDDIR or PIDFILE var not set."; return 10;
elif ! [[ -d "${PIDDIR}" ]]; then mkdir -p "${PIDDIR}"; fi

if ! [[ -s "${PIDFILE}" ]]; then echo "${MYPID}" > "${PIDFILE}"; LOG "INFO" "${PIDFILE} created.PID = ${MYPID}";
LOGSTOP "${FUNCNAME[0]}" ; return 0 ; fi

grep -q "${MYPID}" <"${PIDFILE}" && return 0 ;

if pgrep -cF "${PIDFILE}"; then LOG "ERROR" "Another istance of this script is already running" ;
LOG "ERROR" "Current script PID = ${MYPID} Other PID = $(cat "${PIDFILE}") which is still active" ; return 100 ;
fi

echo "${MYPID}" > "${PIDFILE}" ;  LOG "INFO" "Created PIDFILE = ${PIDFILE} with PID = ${MYPID}" ;
LOGSTOP "${FUNCNAME[0]}"
return 0 ;
}

function RunAsRoot () {
LOGINIT "${FUNCNAME[0]}" ;
if [[ "${USER}" != "root" ]]; then LOG "ERROR" "You must be root to run this script" ; return 200 ; fi
LOGSTOP "${FUNCNAME[0]}" ; return 0
}

function GetIPAddress () {
unset IPADDR NEWIPADDR
LOGINIT "${FUNCNAME[0]}"
IPADDR=$(ip a | grep -iEow 'inet [0-9]+.[0-9]+.[0-9]+.[0-9]+' | grep -Ev '127.0.|lo|docker|veth' | awk '{print $2}')
LOG "INFO" "Current IP Found: ${IPADDR}"
read -p "Correct? Press Enter to continue or change it now here:" NEWIPADDR
if [[ -n ${NEWIPADDR} ]]; then IPADDR=${NEWIPADDR}; fi
export IPADDR ; LOGSTOP "${FUNCNAME[0]}" ; return 0
}

function CheckPostgresVersion () {
LOGINIT "${FUNCNAME[0]}"
if rpm --quiet -q postgresql12-server; then
	SERVICES='httpd postgresql-12'
	DB='postgresql-12' ; postgresv1='12' ; export SERVICES DB postgresv1;
elif rpm --quiet -q postgresql15-server; then SERVICES='httpd postgresql-15';
	DB='postgresql-15'; postgresv2='15'; export SERVICES DB postgresv2;
fi
LOG "INFO" "Postgres v${postgresv1}${postgresv2} detected"
LOGSTOP "${FUNCNAME[0]}"; return 0 ;
}

function CheckSpecificFiles () {
LOGINIT "${FUNCNAME[0]}"; WEBDATA='/var/www/html'; GetIPAddress
readarray -t allfiles< <(find "${WEBDATA}" -type f -regextype awk -iregex ".*/((file1|file2)settings|runtime|web|()).(js|json|config|htaccess)" -printf '%h/%f\n')
LOG "INFO" "Counted - ${#allfiles[@]} files in ${WEBDATA}"
LOG "INFO" "-------------------- Start File List ------------------------"
printf '%s\n' ${allfiles[@]}
LOG "INFO" "-------------------- End File List ------------------------"

for x in ${allfiles[@]}; do
	if grep -iEwo 'https://[0-9]+.*:[0-9]+' ${x}; then
	LOG "INFO" "${x} = $(grep -iEwo 'https://[0-9]+.*:[0-9]+' ${x})";
	fi
done
LOGSTOP "${FUNCNAME[0]}" ; return 0
}


function GetDBInfo() {
LOGINIT "${FUNCNAME[0]}" ; PGUSER="postgres"
su - "${PGUSER}" -c "psql -U "${PGUSER}" -c '\l+' | tail -n +4"
#sudo su - "${PGUSER}" << EOF
#psql -U "${PGUSER}" -c '\l+'
#EOF
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function CheckPerms () {
LOGINIT "${FUNCNAME[0]}"
if [[ -z ${LOGDIR} || -z ${BKUPDIR} || -z ${PIDDIR} ]]; then
LOG "WARN" "Essential var not set for this function"; return 100; fi

mkdir -p {"$LOGDIR","$BKUPDIR","$PIDDIR"}
setfacl -Rdm g:admin:rw,g:postgres:rw {"$LOGDIR","$BKUPDIR","$PIDDIR"}
setfacl -Rm g:admin:rw,g:postgres:rw {"$LOGDIR","$BKUPDIR","$PIDDIR"}
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function CheckPorts () {
LOGINIT "${FUNCNAME[0]}"
for x in 80 443 49000 49100 49200 49300; do
if ! grep -ow "${x}" <<< $(netstat -tlpn | grep -iE 'service1|dotnet|httpd'); then
LOG "WARN" "Port ${x} = NOT Open"; else LOG "INFO" "Port ${x} = Open"; fi
done
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

FindInMultPaths () { args=${*:?Specify paths space delimited as args} ; dirs=( ${args} ); find "${dirs[@]}" -type f 2> /dev/null ; }
GrepFromFoundFiles () { dir=${1:?Need path as 1st arg} ; find "${dir}" -type f 2> /dev/null ; }

#############################################################
#####            BACKUP OR RESTORE FUNCTIONS             ####
#############################################################

function BackupWebData () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html'
BKUPFILE="/usr/local/backups/${FUNCNAME[0]}.$(date +'%F_%H%M').zip"
find "${WEBDATA}" -type f -printf "%h/%f\n" | zip -q "${BKUPFILE}" -@
if ! unzip -lt "${BKUPFILE}"; then LOG "ERROR" "Backup verification failed for ${WEBDATA} - ${BKUPFILE}" ; return 100; fi
LOG "INFO" "Backup Created of ${WEBDATA}: ${BKUPFILE}" ; export BKUPFILE
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function BackupSpecificFiles () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html'
BKUPFILE="/usr/local/backups/${FUNCNAME[0]}.$(date +'%F_%H%M').zip"
find "${WEBDATA}" -type f -regextype awk -iregex ".*/((file1|file2)settings|runtime|web|()).(js|json|config|htaccess)" | zip -q "${BKUPFILE}" -@
LOG "INFO" "$(unzip -ltq "${BKUPFILE}")";
LOG "INFO" "Backup created of ${WEBDATA} Specific files: ${BKUPFILE}" ;
export BKUPFILE ; LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}



############## HOW TO CALL A FUNCTION FROM CRON ##############
# m  h  dow  dom  mon    set the env with the sourced file && function
# 0  12  *   *    *    /usr/bin/env bash -c '. /usr/local/scripts/allfunctions.sh && BackupDB'
##################################################################################################################

function BackupDB () {
LOGINIT "${FUNCNAME[0]}" ; BKUPFILE="/usr/local/backups/${FUNCNAME[0]}.$(date +'%F_%H%M').sql.gz"
LOG "INFO" "GENERATING COMPRESSED BACKUP OF ALL CURRENT POSTGRES DATABASES"
su - postgres -c "pg_dumpall --clean --if-exists --username=postgres" | gzip > "${BKUPFILE}"
LOG "INFO" "$(gunzip -vt "${BKUPFILE}")"
LOG "INFO" "${BKUPFILE} - Backup file was created"; export BKUPFILE ; LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function RestoreDB () {
LOGINIT "${FUNCNAME[0]}" ; BKUPFILE="${BKUPFILE:=$1}"
while [[ -z ${BKUPFILE} || ! -f "${BKUPFILE}" ]]; do
read -p "File not or found or specified. Input /fullpath/and/filename/to/backup.sql.gz": BKUPFILE
done
export BKUPFILE
sudo su - postgres << EOF
gunzip -c "${BKUPFILE}" | psql -U postgres
EOF

LOG "INFO" "DB was restored from ${BKUPFILE}"; LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function RestoreSpecificFiles () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html' ; BKUPFILE="${BKUPFILE:=$1}"
while [[ -z ${BKUPFILE} ]] || [[ ! -f "${BKUPFILE}" ]]; do
read -p "File not found or specified. Input /fullpath/and/filename/to/Specificfiles.zip": BKUPFILE
done

unzip -o "${BKUPFILE}" -d /
LOG "INFO" "Specific files in ${WEBDATA} restored from ${BKUPFILE}"; LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function PullPatchToHere () {
LOGINIT "${FUNCNAME[0]}" ; remoteIP=$1 ; shopt -s extglob; WEBDATA='/var/www/html'
CheckappVersion ; GetIPAddress
while [[ -z ${remoteIP} ]]; do read -p "Remote IP not set. Remote Server IP to pull data from?": remoteIP ;  done
if ! nc -z "${remoteIP}" 22; then LOG "ERROR" "Cannot Ping that IP"; return 100; fi
BackupSpecificFiles ; ExecuteOnServices stop ; DeleteWebData ;
scp -r root@${remoteIP}:${WEBDATA}/!(*.log|Logs) ${WEBDATA}
RestoreSpecificFiles "${BKUPFILE}" ; ExecuteOnServices start
}

function PushPatchToThere () {
LOGINIT "${FUNCNAME[0]}" ; remoteIP=$1 ; shopt -s extglob; WEBDATA='/var/www/html'
CheckPostgresVersion ; GetIPAddress ;
while [[ -z ${remoteIP} ]]; do read -p "Remote IP not set. Remote Server IP to push data to?": remoteIP ;  done
if ! nc -z "${remoteIP}" 22; then LOG "ERROR" "Cannot Ping that IP"; return 100; fi

root@${remoteIP} << EOF
source /usr/local/scripts/allfunctions.sh
BackupSpecificFiles ;
ExecuteOnServices stop ;
DeleteWebData ;
RestoreSpecificFiles ${BKUPFILE}
EOF

scp -r root@${remoteIP}:${WEBDATA}/!(*.log|Logs) ${WEBDATA}

root@${remoteIP} << EOF
source /usr/local/scripts/allfunctions.sh ;
ExecuteOnServices restart ;
EOF

}

function PatchApp () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html' ;  zippathfile="${1}" ; CheckappVersion;

while [[ -z ${zippathfile} ]] || [[ ! -f ${zippathfile} ]]; do
read -p "Specify /fullpath/to/app-${appv1}${appv2}-x.x.x.zip": zippathfile
if ! [[ -f ${zippathfile} ]]; then LOG "WARN" "Specified zipfile - not found"; unset zippathfile; fi ;
done

zipfile="${zippathfile##*/}" ; zipdir="${zippathfile%/*}" ; unzipdir="${zipdir}/_zips"
if [[ -d "${unzipdir}" ]]; then rm -rf "${unzipdir}"; LOG "INFO" "Old ${unzipdir} Found and Deleted"; fi

if unzip -oq "${zippathfile}" -d "${zipdir}"; then LOG "INFO" "Extracted - ${zippathfile} to ${zipdir}"; fi

if [[ -n "${appv2}" ]]; then LOG "INFO" "Renaming files per v${appv2} requirements";
 find "${unzipdir}" -type f -iname "*.zip" -printf '%f\n' | while IFS=$' ' read -r x; do
   mv "${unzipdir}/${x}" "${unzipdir}/${x/www-ClientUI/ui}" 2> /dev/null
   mv "${unzipdir}/${x}" "${unzipdir}/${x,,}" 2> /dev/null
 done ;
elif [[ -n "${appv1}" ]]; then LOG "INFO" "Renaming files per v${appv1} requirements";
   find "${unzipdir}" -type f -iname "*.zip" -printf '%f\n' | while IFS=$' ' read -r x; do
    mv "${unzipdir}/${x}" "${unzipdir}/${x/ui/app}" 2> /dev/null ;
    mv "${unzipdir}/${x}" "${unzipdir}/${x,,}" 2> /dev/null
   done
fi

LOG "INFO" "Renamed zipfiles to v${appv1}${appv2} correct format";

find "${unzipdir}" -type f -iname "*.zip" -printf '%f\n' | while IFS=$' ' read -r x; do
unzip -oq "${unzipdir}/${x}" -d "${WEBDATA}/${x%.*}"; LOG "INFO" "Updated - ${WEBDATA}/${x%.*}" ;
done

LOGSTOP "${FUNCNAME[0]}" ; return 0
}

#############################################################
#####                WAITING FUNCTIONS                   ####
#############################################################

WAITASEC () { for ((x=3;x>0;x--)); do echo "Script will resume in ${x} seconds..."; sleep 1 ; done ; }
PauseAndFix () { read -p "An Error occurred, fix and press Enter to continue or CTRL+C to quit: " ; }
StopAndCheck () { read -p "Check progress then press Enter to continue or CTRL+C to quit: " ; }

#############################################################
#####        DELETING AND CLEANING FUNCTIONS             ####
#############################################################

function DeleteWebData () {
LOGINIT "${FUNCNAME[0]}"; WEBDATA='/var/www/html'
find "${WEBDATA}" -type f ! \( -regextype awk -iregex ".*/((file1|file2)settings|runtime|web|()).(js|json|config|htaccess)" \) -delete
LOG "INFO" "Deleted: ${WEBDATA} contents - excluding Specific files" ;
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function DeleteSpecificFiles () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html' ; BackupSpecificFiles
find "${WEBDATA}" -type f -regextype awk -iregex ".*/((file1|file2)settings|runtime|web).(js|json|config)" -printf "Deleting - %h/%f\n" -delete
LOG "INFO" "Deleted: ${WEBDATA} Specific files" ;
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}


function DropUsersDropDBs () {
LOGINIT "${FUNCNAME[0]}"; CheckappVersion ;
sudo su - postgres << EOF
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND datname IS NOT NULL";
EOF

LOG "INFO" "Restarting Postgres Service prior to dropping databases"
systemctl restart ${DB}
LOG "WARN" "Dropping app Databases - This will not be reversible..." ; WAITASEC

sudo su -  postgres << EOF
psql -U postgres -c '\l' | grep -Eow "app.*|gvmd" | cut -d" " -f1 > /tmp/killthese
while IFS= read -r x; do psql -U postgres << EOD
DROP DATABASE "\${x}";
EOD
done <"/tmp/killthese"
rm -f /tmp/killthese
EOF
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}

function CleanDB () {
LOGINIT "${FUNCNAME[0]}";
sudo su - postgres << EOF
vacuumdb -a -z -f  -j 5 --skip-locked -v --no-password
EOF
LOGSTOP "${FUNCNAME[0]}" ; return 0
}


function DeleteOldBackups () {
LOGINIT "${FUNCNAME[0]}" ;
if [[ -z ${BKUPDIR} ]] || [[ ! -d "${BKUPDIR}" ]]; then LOG "WARN" "BKUPDIR var not set or dir not found"; return 10; fi
find "${BKUPDIR:?}" -type f -iname "*.zip" -or -iname "*.gz" -mtime +120 -printf "INFO Deleting backup archives older than 90 days = %h/%f\n" -delete
LOGSTOP "${FUNCNAME[0]}" ; return 0
}

function CleanUp () {
LOGINIT "${FUNCNAME[0]}"; LOGSTOP "${FUNCNAME[0]}"; LOG "INFO" "Script Completed"
if [[ -n ${PIDFILE} ]] && [[ -f "${PIDFILE}" ]]; then rm -f "${PIDFILE}" ; fi
if [[ -n ${SNIPPET} ]] && [[ -f "${SNIPPET}" ]]; then
	tee -a "${LOGFILE}" <"${SNIPPET}" > /dev/null ; rm -f "${SNIPPET}" ;
fi ; exit 0
}

#############################################################
#####            SERVICES FUNCTIONS                      ####
#############################################################

function ExecuteOnServices () {
# Will stop start restart stop reload enable disable status on any number of services
LOGINIT "${FUNCNAME[0]}"; local arg="${1}" ; local arg="${arg,,}"

while ! grep -iEq 'reload|stop|start|status|enable|disable|restart' <<< "${arg}"; do
unset arg
read -p 'Select an option: reload|stop|start|status|enable|disable|restart': arg
done

CheckappVersion
if grep -i "status" <<< ${arg,,}; then
  for x in ${SERVICES}; do LOG "$(systemctl status ${x} | head -3 | awk '{print $2}' | tr '\n' ' ' | column -t)" ; done ;
else
  for x in ${SERVICES}; do systemctl ${arg,,} ${x} ;
  LOG "$(systemctl status ${x} | head -3 | awk '{print $2}' | tr '\n' ' ' | column -t)" ;  done ;
fi
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
}


##########################################################################################################################
###                             TOOLS FOR SYSADMIN USAGE                       ######
##########################################################################################################################

function SwapOffSwapOn () {
LOGINIT "${FUNCNAME[0]}"
USEDSWAP=$(free -m | grep 'Swap:' | awk '{print $3}') # 1000 = 1Gb
AVAILMEM=$(free -m | grep 'Mem:' | awk '{print $4}') #1000 = 1Gb
LOG "${FUNCNAME[0]}" "INFO" "Used Swap Size: ${USEDSWAP}. Avail RAM = ${AVAILMEM}"
LOG "${FUNCNAME[0]}" "WARN" "Swap will now be drained"
if ! swapoff -a; then LOG "${FUNCNAME[0]}" "ERROR" "Swap failed to drain"; else
LOG "${FUNCNAME[0]}" "INFO" "Swap was successfully drained"
fi

if ! swapon -a; then LOG "${FUNCNAME[0]}" "ERROR" "Swap was unable to be remounted" ; return 100; fi
LOG "${FUNCNAME[0]}" "INFO" "Swap was remounted" ; LOGSTOP "${FUNCNAME[0]}" ; return 0
}

function DrainTheSwap () {
SNIPPET='/usr/local/logs/allfunctions.log'
LOGINIT "${FUNCNAME[0]}"
USEDSWAP=$(free -m | grep 'Swap:' | awk '{print $3}') # 1000 = 1Gb
AVAILMEM=$(free -m | grep 'Mem:' | awk '{print $4}') #1000 = 1Gb
SWAPTHRES=5000 # 5Gb - THRESHOLD FOR HOW MUCH SWAP IS USED BEFORE DRAINING IT
PAD=3000 # GB PADDED,
AVAILRAM=$((AVAILMEM + PAD))
LOG "${FUNCNAME[0]}" "INFO" "Swap Size: ${USEDSWAP}. Avail RAM = ${AVAILMEM}. Swap Threshold: ${SWAPTHRES}"
# if used swap >= to 5Gb AND free ram (+3G padding) is greater than used swap; then drain it
if [[ ${USEDSWAP} -le ${SWAPTHRES} ]] || [[ ${AVAILRAM} -lt ${USEDSWAP} ]]; then
LOGSTOP "${FUNCNAME[0]}" ; return 0 ;
fi

LOG "${FUNCNAME[0]}" "WARN" "Swap will be drained"

if ! swapoff -a; then LOG "${FUNCNAME[0]}" "ERROR" "Swap failed to drain"; else
LOG "${FUNCNAME[0]}" "INFO" "Swap was successfully drained"
fi

if swapon -a; then LOG "${FUNCNAME[0]}" "INFO" "Swap was successfully remounted"; LOGSTOP "${FUNCNAME[0]}" ; return 0
else LOG "${FUNCNAME[0]}" "ERROR" "Swap was unable to be remounted" ; return 100; fi
}

################################################################################

function UpdateSpecificFilesIPAddress () {
LOGINIT "${FUNCNAME[0]}" ; WEBDATA='/var/www/html'; GetIPAddress
find "${WEBDATA}" -type f -regextype awk -iregex ".*/((file1|file2)settings|runtime|web).(js|json|config)" | while read -r x; do
LOG "INFO" "${x} - OLD Config = $(grep -iEwo "https://[0-9]+.*:[0-9]+" "${x}")"
sed -i -r "s|(^.*https://).*(:[0-9]+.*)|\1${IPADDR}\2|g" "${x}"
LOG "INFO" "${x} - NEW Config = $(grep -iEwo "https://[0-9]+.*:[0-9]+" "${x}")"
done
LOGSTOP "${FUNCNAME[0]}" ; return 0
}


##################################################################################################################
############## HOW TO CALL A FUNCTION FROM CRON - OR HOW TO SCHEDULE FUNCTIONS TO RUN IN CRONTAB #################
# cronString  SET ENVIRONMENT TO RUN A BASH COMMAND SOURCING THE FILE YOU HAVE THE FUNCTION IN && FUNCTION name
# 0 12 * * * /usr/bin/env bash -c '. /usr/local/scripts/allfunctions.sh && DrainTheSwap'
##################################################################################################################

function CreateServerList () {
unset serverlist
serverlist="1) FriendlyName: ORG_Sandbox appVersion: 2.0 HostName: ORGAPPT01 IPAddress: 10.10.10.220
2) FriendlyName: SITE1_PRIM appVersion: 2.0 HostName: ORGAPPP02 IPAddress: 10.10.10.250
3) FriendlyName: SITE1_PRIM_ARCHIVE appVersion: 1.3.6 HostName: ORGAPPP01 IPAddress: 10.10.10.251
4) FriendlyName: SITE2_SEC_1 appVersion: 1.3.6 HostName: ORGAPPP04 IPAddress: 10.10.9.251
5) FriendlyName: SITE2_SEC_2 appVersion: 2.0 HostName: ORGAPPP05 IPAddress: 10.10.9.250
6) FriendlyName: AZURE appVersion: 2.0 HostName: ORGAPPP07 IPAddress: 10.10.1.103
7) FriendlyName: OCI appVersion: 2.0 HostName: appv6 IPAddress: 10.1.1.5
8) FriendlyName: SITE1_DMZ appVersion: 2.0 HostName: ORGAPPP03 IPAddress: 192.168.1.2
9) FriendlyName: SITE2_DMZ appVersion: 2.0 HostName: BSWTFMAPPP06 IPAddress: 192.168.1.3"

# On each function run;
# CreateServerList
# readarray -t allservers< <(echo "${serverlist}")
# for i in "${!allservers[@]}"; do
# set -- ${allservers[$i]}; number=${1/)/} ; name=$3 ; Version=$5 ; LitName=$7; IPADDR=$9 ;

# printf -- "%s\n" "${allservers[@]}" # will print all lines in array
# printf -- "%s\n" "${allservers[0]}" # will print first line in array
# printf -- "%s\n" "${allservers[1]}" # will print second line in array

# printf -- "%s\n" "${allservers}" | grep '^2' - for grepping the array
export serverlist
}


#########################################################
function red() { tput setaf 1 ; }
function blue() { tput setaf 4 ; }
function yellow() { tput setaf 3 ; }
function green() { tput setaf 2 ; }
function reset() { tput sgr0 ; }
#########################################################

function systemstats() {

unset SERV_STATS
LASTBKMEN="Last successful Postgres DB Backup: $(find /var/lib/pgsql/backups -iname "*sql.gz" | awk '{print $5, $NF}' | tail -1)"
unset SERV_STATS
readarray -t SERVICES< <(printf '%s\n' postgresql-12 httpd scheduler service1 service2 service3 service4)
readarray -t SERV_STATS< <(for x in ${SERVICES[@]}; do if systemctl is-active --quiet "${x}"; then echo "$x: UP"; else echo "$x: DOWN"; fi; done)
SERVICMEN="Services Status: ${SERV_STATS[*]}"
HOST_NAME="Hostname: $(hostname)"
KERNMEN="Kernel Version: $(uname -r)"
UP_TIME="Uptime: $(uptime)"
LAST_REBOOT="Last Reboot Time: $(who -b | awk '{print $3,$4}')"
DATE_TIME="System Date and Time:\n$(timedatectl)"
MEM_SWAP="Current Memory & Swap Util:\n$(free -hm)"
LAST_LOGONS="Last Users Logged On:\n$(last -F -n3 -wx | head -n +3)"
ZOMBIE_PROCS="Zombie Processes: $(ps -A -ostat,ppid,pid,cmd | grep -e '^[[zZ]' || echo "None")"
OS_NAME="OS VERSION: $(awk '/PRETTY_NAME="/','/"/' /etc/*-release | cut -d'"' -f2)"
FILE_SYS="$(df -hlT -x "tmpfs" -x "devtmpfs")"
SEC_UPDATES="$(dnf check-update > /dev/null; dnf updateinfo | tail -n +2)"

yellow; echo -e "${LASTBKMEN}" ;
red; echo -e "${SERVICMEN}"
green; echo -e "${HOST_NAME}\t${OS_NAME}\t${KERNMEN}"
violet; echo -e "${ZOMBIE_PROCS}\t${UP_TIME}"
blue; echo -e "${LAST_REBOOT}"
violet ; echo -e "${DATE_TIME}"
red; echo -e "${MEM_SWAP}"
green; echo -e "${LAST_LOGONS}"
yellow; echo -e "${FILE_SYS}"
red; echo "${SEC_UPDATES}"
reset;
}

#########################################################

function MemHog () {
ps -eo pid,user,pcpu,pmem,command | awk '{print $1,$2,$3,$4,$5}' | grep -iv 'kworker' | awk 'NR==1{print;next} {for (i=2;i<=NF;i++) {a[$5][i]+=$i}} END{ for (d in a) {s=d; for (i=2;i<=NF;i++) {s=s" "a[e][i]}; print s}}' | sort -n -u -k 4 | column -t
}

function CpuHog () {
ps -eo pid,user,pcpu,pmem,command | awk '{print $1,$2,$3,$4}' | grep -iv 'kworker' | awk 'NR==1{print;next} {for (i=2;i<=NF;i++) {a[$5][i]+=$i}} END{ for (d in a) {s=d; for (i=2;i<=NF;i++) {s=s" "a[e][i]}; print s}}' | sort -n -u -k 3 | column -t
}

function WatchAllLogs () {
journalctl -f -o with-unit -x --no-hostname -q
}

function MEMCPULIST () {
ps -eo user,pcpu,pmem,command | awk '{print $1,$2,$3,$4}' | grep -iv 'kworker' | awk 'NR==1{print;next} {for (i=2;i<=NF;i++) {a[$4][i]+=$i}} END{ for (d in a) {s=d; for (i=2;i<=NF;i++) {s=s" "a[d][i]}; print s}}' | sort -n -u -k 2 | column -t
}

function MEMCPULISTCHOOSESORT () {
if [[ -z $1 ]]; then echo "Usage: $0 [1,2,3]"; sleep 1; fi
SNUMBER=${1:=1} ;
ps -eo pcpu,pmem,pid,user,command | grep -Eiv 'kworker|systemd|/sbin/init' | sort -k${SNUMBER} -r | head -20 | cut -c 1-140
}

#########################################################

function SCPALL () {
CreateServerList ; readarray -t allservers< <(echo "${serverlist}")
if [[ $# -ne 2 ]]; then
LOG "Usage: ${FUNCNAME[0]} [/path/to/local_file_or_dir_to_send] [/path/to/remote/destdir/]" ; return 255;
fi

TOSEND=$1 ; DESTDIR=$2

if [[ ! -f "${TOSEND}" ]] && [[ ! -d "${TOSEND}" ]]; then
LOG "${TOSEND} is not a directory or file that exists"; return 255; fi

for i in "${!allservers[@]}"; do set -- ${allservers[$i]}; name=$3 ; IPADDR=$9 ;
if ! nc -z "${IPADDR}" 22; then LOG "FAIL Host=${name} IP=${IPADDR} Port=22"; continue; fi

if [[ -d "${TOSEND}" ]]; then arg='scp -r'; else arg='scp'; fi
if ${arg} "${TOSEND}" "${IPADDR}:${DESTDIR}"; then LOG "${TOSEND} copied to ${name}";
else LOG "${TOSEND} FAILED to copy to ${name}"; fi

done
}

#########################################################

function SCPFROMALL () {
CreateServerList
readarray -t allservers< <(echo "${serverlist}")
if [[ $# -ne 2 ]]; then
LOG "Usage: ${FUNCNAME[0]} [/path/to/remote_file_or_dir_to_pull] [/path/to/local/destdir/] DIR|FILE";
return 255; fi

TOPULL=$1 ; DESTDIR=$2 ; TYPE=$3 ;
if ! grep -iq "FILE" <<< "${TYPE^^}"; then arg='scp -r'; else arg='scp'; fi

for i in "${!allservers[@]}"; do set -- ${allservers[$i]}; name=$3; IPADDR=$9 ;
if ! nc -z "${IPADDR}" 22; then LOG "FAIL Host=${name} IP=${IPADDR} Port=22"; continue; fi
if ${arg} root@"${IPADDR}":"${TOPULL}" "${DESTDIR}"; then LOG "${TOPULL} COPIED FROM = ${name}"
else LOG "${TOPULL} NOT COPIED TO  = ${name}"; fi
done
}

#########################################################


function RUNONALL () {

CreateServerList
readarray -t allservers< <(echo "${serverlist}")

ACTION="$*"

for i in "${!allservers[@]}"; do
set -- ${allservers[$i]}; name=$3 ; IPADDR=$9 ;

if ! nc -z "${IPADDR}" 22; then LOG "FAIL Host=${name} IP=${IPADDR} Port=22"; continue; else
LOG "Executing: ${ACTION} on ${name} IP=${IPADDR}" ; ssh -t -q "${IPADDR}" "${ACTION}";
fi
done
}

#########################################################

function SSHTO () {

CreateServerList
readarray -t allservers< <(echo "${serverlist}")

printf -- "%s\n" "${allservers[@]}"
read -p "Choose server by number": NUM
NUM=${NUM:?}
if [[ -z ${NUM//[!0-9]/} ]] || [[ ${#NUM} -ne 1 ]]; then echo "Invalid Option"; return; fi
SSHIP=$(printf -- "%s\n" "${allservers[@]}" | grep "^${NUM}" | awk -F' ' '{print $NF}')
echo "SSHing to ${SSHIP}"
ssh root@"${SSHIP}"
}

################################################
################ ALIASES #######################

alias sysadmintools='/usr/local/scripts/tools.sh'
alias sysadminTOOLS='/usr/local/scripts/tools.sh'

##########################################################################################################################
##########################################################################################################################


function API_GetToken () {
HOSTIP=$(ip a | grep inet | grep -Ev '127|inet6' | awk '{print $2}' | cut -d '/' -f1)
unset IP_ANSWER
read -p "Found IP = ${HOSTIP}. If correct, press Enter, otherwise type correct IP": IP_ANSWER

test -n "${IP_ANSWER}" || ( HOSTIP=${IP_ANSWER} )
TOKEN=$(curl -s "https://${HOSTIP}:49000/Connect/token" --compressed --insecure  | jq '.access_token' | tr -d \")
test -z "${TOKEN}" && ( return 100 ) || ( export TOKEN HOSTIP )
}
#############################################################

function API_GetAllScheduleTypeIDs () {
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then API_GetToken || ( LOG "Failed to get Token"; return 100 ) ; fi
ScheduleTypeIDsNames=$(curl -s "https://${HOSTIP}:49100/api/Scheduler/Scripts/List" -H "Authorization: Bearer ${TOKEN}" --compressed --insecure | jq -r '.[]|"\(.id):\(.name)"')
export ScheduleTypeIDsNames
echo "${ScheduleTypeIDsNames}"
}

#############################################################

function API_GetAllSiteIDs () {
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then API_GetToken || ( LOG "Failed to get Token"; return 100 ) ; fi

siteIDsNames=$(curl -s "https://${HOSTIP}:49200/api/Plaapp/Lookups/Sites" -H "Authorization: Bearer ${TOKEN}" --compressed --insecure  | jq -r '.[]|"\(.id):\(.name)"')
export siteIDsNames
echo "${siteIDsNames}"
}

#############################################################
function API_GetappVersion () {
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then
if ! API_GetToken; then LOG "Failed to get Token"; return 100; fi
fi

curl -s "https://${HOSTIP}:49200/api/Plaapp/version" -H "authorization: Bearer $TOKEN" --compressed --insecure ;
}

#############################################################
# use for any api call that outputs json format
function API_JSON_TEMPLATE () {
API_ADDR=$1
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then API_GetToken || ( LOG "Failed to get Token"; return 100 ) ; fi
unset jsonarray
readarray -t jsonarray< <(curl -s "${API_ADDR}" -H "authorization: Bearer ${TOKEN}" --compressed --insecure  |  jq '.' | sed -E 's/^[[:space:]]+//g' | tr -d ']"}{[' | sed -E 's/,$//g')

( IFS=$'\n'; echo "${jsonarray[*]}" ) ;
}

#############################################################

# USE FOR ANY API CALL CSV FORMAT
function API_CSV_TEMPLATE () {
API_ADDR=$1
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then API_GetToken || ( LOG "Failed to get Token"; return 100 ) ; fi


unset csvarray
readarray -t csvarray< <(curl -s "${API_ADDR}" -H "authorization: Bearer ${TOKEN}" --compressed --insecure)
usage="$(echo "Specify the field(s) you want by number, comma separated;"; grep -n "^" <<< "$(local IFS=, ; printf " %s\n" ${csvarray[0]})" ; echo "All - all fields")"

fields="$2"
test -n ${fields} || ( LOG "${usage}"; return 100 )

if grep -iq "all" <<< "${fields,,}"; then
( IFS=$'\n'; echo "${csvarray[*]}" ) ;
else ( IFS=$'\n'; echo "${csvarray[*]}" | cut -d, -f"${fields}" )
fi
}

##########################################################################################################################
##########################################################################################################################
function API_GetAllSchedules () { API_CSV_TEMPLATE "https://${HOSTIP}:48100/api/Scheduler/xxxxxxxx "$1" ; }
function API_GetPendingJobs () { API_CSV_TEMPLATE "https://${HOSTIP}:48100/api/Scheduler/Schedules/xxxxxxxx" "$1" ; }
function API_GetRunningJobs () { API_CSV_TEMPLATE "https://${HOSTIP}:48100/api/Scheduler/Jobs/Running/xxxxxxxxxx" "$1" ; }
function API_GetTargets () { API_CSV_TEMPLATE "https://${HOSTIP}:49100/api/Scheduler/Targets/Csv?xxxxxxxx" "$1" ; }
function API_GetLogicalservice1 () { API_CSV_TEMPLATE "https://${HOSTIP}:49100/api/service1/xxxxxxxxxxn" "$1" ;}
function API_GetGlobalExclusions () { API_CSV_TEMPLATE "https://${HOSTIP}:49200/api/service1/xxxxxxxxx" "$1" ; }
function API_GetBlackListedTargets () { API_CSV_TEMPLATE "https://${HOSTIP}:49200/api/service1/xxxxxxxxxxxxx" "$1" ; }
##########################################################################################################################
##########################################################################################################################
function API_GetBlackOuts () { API_JSON_TEMPLATE "https://${HOSTIP}:49100/api/Scheduler/xxxxxxxxxxxx" ; }
##########################################################################################################################
##########################################################################################################################


function API_QueryAllJobHistory () {

usage="Specify the field(s) you want pipe separated;
name|typeName|startDateTime|durationMs|durationSec
numberOfDevicesProcessed|numberOfDevicesCannotConnect
numberOfDevicesWithExceptions|statusIdentifier
jobStatusName|createdByName|id|allfields"

if [[ $# -eq 0 ]]; then echo "${usage}"; return 100; fi ; delims="$1"
if [[ -z "${TOKEN}" ]] || [[ -z "${HOSTIP}" ]]; then API_GetToken || ( LOG "Failed to get Token"; return 100 ) ; fi
readarray -t jobsarray< <(curl -s "https://${IPADDR}:49100/api/Scheduler/xxxxxxxxxxxxxxxxxxxxxxxxxx" -H "authorization: Bearer $TOKEN" --compressed --insecure | jq -r '.[]' | sed -E 's/^[[:space:]]+//g' | tr -d '}{][,"')
grep -iq "allfields" <<< "${delims,,}" \
&& ( IFS=$'\n'; echo "${jobsarray[*]}" ) \
|| ( IFS=$'\n'; echo "${jobsarray[*]}" | grep -iE '''"${delims}"''' )
}


#################################### WORK AREA ALL COMMENTED OUT #################################
: <<'END_COMMENT'
# THIS IS A MULTILINE COMMENT USING HERETO TO DEFINE WHAT VARS ARE NEEDED BY SCRIPTS SOURCING THIS FILE


# find command different ways that work

find "${WEBDATA}" -type f -iname "xxxx.json" -or -iname "xxxx.js" -or -iname "xxxx.json" -or -iname "xxx.config" \) -printf "%h/%f\n"
find "${WEBDATA}" -type f \( ! -iname "xxxx.json" ! -iname "xxxx.js" ! -iname "xxxx.json" ! -iname "xxx.config" \)
find "${WEBDATA}" -type f -regextype awk -iregex ".*/((file1|file2)settings|runtime|web).(js|json|config)"



END_COMMENT
