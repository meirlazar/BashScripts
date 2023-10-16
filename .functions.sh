#!/bin/bash

# functions fun stuff and all things functions

##############################################################################
# Get System Information
function downloadallfromwebsite () {
wget -Pedr -nH --user "${1:?"Error: Requires: username as 1st argument"}" --password "${2:?"Error: Requires: password as 2nd argument"}" http://"${3:?"Error: Requires: websitename as 3rd argument"}"
}
##############################################################################

function RUNONALL () {
listofips="x.x.x.x y.y.y.y z.z.z.z"
username=${USER}
CMD=${@:?"Error: Requires: command to run as argument"}
for x in ${listofips} ; do 
ssh -q -t -oLogLevel=error -p 6${x##*.}  ${username}@${x} "${CMD}" 
done
}


##############################################################################
function pause () {
read -p "Press Enter to Continue..."
}
##############################################################################

function portcheck () {
IP=${1?Specify IP}
PORT=${2?Specify Port}
if nc -v -4 -z -w 5 -n "$IP" "$PORT" > /dev/null 2>&1; then
echo "$(date +'%F %T') - INFO - IP=${IP} Port=${PORT} Connectivity Passed"
else
echo "$(date +'%F %T') - ERROR IP=${IP} Port=${PORT} Connectivity Failed"
fi
}
##############################################################################
function MYSYSTEMDEVS () {
echo "use systool -b devicebusname -v for info about devices and systool -c deviceclassname -v for device classes";
sleep 3;
echo "Here are all the devices in a file - ${PWD}/systemlistinfo";
systool > "${PWD}"/systemlistinfo ;
cat systemlistinfo | tr '\t\n' ' ' | sed "s|Supported.*:|\n {&} \n|g"
}

##############################################################################
function unifi_resetfactoryforboth () {
sshpass -p changemetopasswordused ssh -oStrictHostKeyChecking=no ubnt@x.x.x.x 'mca-cli-op set-default'
sleep 30
set-inform 'http://x.x.x.x:8080/inform'
# ssh to device, set-inform http://ip:port/inform
}
##############################################################################
# SCANNING
##############################################################################

function FIXXAUTHORITY () {
nohup /usr/lib/xorg/Xorg vt1 -displayfd 3 -auth /run/user/121/gdm/Xauthority -background none -noreset -keeptty -verbose 3 > /dev/null 2>&1 &
nohup /usr/lib/xorg/Xorg vt2 -displayfd 3 -auth /run/user/1000/gdm/Xauthority -background none -noreset -keeptty -verbose 3 > /dev/null 2>&1 &
}

##############################################################################
function SCANDHCP () {
sudo nmap -sn ${1:?"Error: Requires: 1st 3 octets of network segment as argument"}.1-254 | awk '/Nmap scan/{gsub(/[()]/,"",$NF); print $NF}'
}
##############################################################################
function SCANSTATICS () {
sudo nmap -sn ${1:?"Error: Requires: 1st 3 octets of network segment as argument"}.1-254 | awk '/Nmap scan/{gsub(/[()]/,"",$NF); print $NF}'
}
##############################################################################
function SCANPRINTERS () {
sudo nmap ${1:?"Error: Requires: 1st 3 octets of network segment as argument"}.1-254 -p 9100
}
##############################################################################
function nslookupall () {
if [[ $# -ne 1 ]]; then  echo "Needs an IP address to lookup"; return; fi
ip=$1
for x in x.x.x.x x.x.x.y x.y.x.y ; do
result=$(nslookup "$ip" $x | grep -iE "Address|name")
result1=$(nslookup "$ip".home.local $x  | grep -iE "Address|name") 
echo -e "${result}\n${result1}" | sort -u | grep -Ev "^$|0.0.0.0" 
done
}

##############################################################################
function CreateHostsFile () {
# change dns servers ip addresses to local dns servers in your environment 
SUBS='192.168.0.0/24 192.168.1.0/24 192.168.2.0/24 192.168.3.0/24' # change to network segments used in your environment
for x in ${SUBS}; do 
sudo nmap -sn --resolve-all --dns-servers=192.168.1.1,192.168.1.2 "${x}" | grep -i 'nmap scan' | cut -d" " -f5- | tr -d '()' | awk '{print $2,$1}' | sed "s/^ //g"
done
}
##############################################################################
function TALK () {
STRINGS=$*
curl --request POST \
	--url 'https://voicerss-text-to-speech.p.rapidapi.com/?key=undefined' \
	--header 'content-type: application/x-www-form-urlencoded' \
	--header 'x-rapidapi-host: voicerss-text-to-speech.p.rapidapi.com' \
	--header 'x-rapidapi-key: yourapiketorsecret' \
	--data 'src=$STRINGS' \
	--data hl=en-us \
	--data r=0 \
	--data c=mp3 \
	--data f=32khz_16bit_stereo
}
##############################################################################
##############################################################################

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

##############################################################################
function FINDLARGFILES () {
DIR=$1
SIZE=$2
if [[ $# -ne 2 ]]; then 
echo "Usage: ${FUNCNAME[0]} [ /path/to/check (default ./) ] [ files larger than size [M|G] (default 2G) ]"; 
fi

find ${DIR:=$PWD} -type f -size +${SIZE:=2G} 2> /dev/null | while read name; do ls -alh "${name}" 2>/dev/null; done | sort -nr -k5 | head -30
}
##############################################################################
function PROPANEUSEPERHR () {
HORSEPOWER=500 #1 HORSEPOWER WILL PRODUCE 500W OF ENERGY PER HOUR. THE DUROMAX HAS 7 HORSEPOWER
BTU_PER_HOUR=10000 #EACH HORSEPOWER USES 10k BTU PER HOUR
BTU_PER_GAL=91500 #Propane contains 92,000 BTU per gallon
PROPANE_WT_PER_GAL=4.25 #Propane weights 4.2 pounds per gallon
BTU_HR="0.29307107"
read -p "How many horsepower is the generator?": GEN_HRSPOWER
read -p "What is the load (Total wattage)?": POWER_USED
# Calculates the amount of total power (W) that the generator can generate per hour.
TOTAL_WATTAGE_GENERATED=$((GEN_HRSPOWER * HORSEPOWER))
# Calculates the amount of BTUs the generator can generate per hour.
BTU_LOAD=$(echo "0.29307107 * ${POWER_USED}" | bc)
# Calculates how much propane will be used by the load per hour
PROPANE_USED=$((BTU_PER_GAL / BTU_LOAD))
# Calculates how many
#BTU_TO_WATTS=$(0.29307107)
echo "Your generator is a ${GEN_HRSPOWER} horsepower generator"
echo "It can produce ${TOTAL_WATTAGE_GENERATED}Watts/hour"
echo "It uses"
echo "A Load of ${BTU_LOAD} will use ${PROPANE_USED} gallons of propane each hour"
}
##############################################################################
function TOTALPOWERUSED () {
read -r -p "What is the total W of the generator": TOTALWATT
read -r -p "What is the amount of propane used at half load": PROPANE_LOAD
read -p "How many refrigerators" :FRIG
POWERARRAY[1]=$((FRIG * 850))
read -p "How many individual lights" :LIGHTS
POWERARRAY[2]=$((LIGHTS * 10))
read -p "How many computers" :COMPUTERS
POWERARRAY[3]=$((COMPUTERS * 450))
read -p "How many TVs" :TVS
POWERARRAY[4]=$((TVS * 100))
POWERARRAY[5]=160 #router+unifi repeater
#POWERARRAY[6]
#POWERARRAY[7]
#POWERARRAY[8]
read -a POWERARRAY
tot=0
for i in "${POWERARRAY[@]}"; do
  let TOTALPOWER+=$i
done
echo "Total: $TOTALPOWER Watts"
}

##############################################################################
# Screen functions and aliases
function NEWSCREEN () {
if ! [[ $# = 1 ]]; then echo "Requires a name for the new screen as the 1st argument"; return; fi
screen -S "$1"
}
##############################################################################
alias SCREENLIST='screen -ls'
##############################################################################
function SCREENREATTACH () {
if [[ $(screen -ls | tail -1 | cut -d " " -f1) -gt 1 ]] && [[ $# -ne 1 ]]; then
# screen -ls | grep -Ev 'There|Sockets'
screen -ls | tail -n +2 | head -n +2
echo "Requires a name for the screen that you want to reattach as the 1st argument"; return;
elif [[ $(screen -ls | tail -1 | cut -d " " -f1) -gt 1 ]]; then screen -r "$1";
else screen -r
fi
}
##############################################################################
#alias SCREENDETACH='
alias SCREENKILL='exit'
##############################################################################
function SWAPUSED () {
SUM=0
OVERALL=0
for DIR in `find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"`
do
    PID=`echo "$DIR" | cut -d / -f 3`
    PROGNAME=`ps -p "$PID" -o comm --no-headers`
    for SWAP in `grep VmSwap "$DIR"/status 2>/dev/null | awk '{ print $2 }'`
    do
        let SUM=$SUM+$SWAP
    done
    if (( $SUM > 0 )); then
        echo "PID=$PID swapped $SUM KB ($PROGNAME)"
    fi
    let OVERALL=$OVERALL+$SUM
    SUM=0
done
echo "Overall swap used: $OVERALL KB"
}
##############################################################################
function SLEEPALLVMS () {
	ACTIVE=$(VBoxManage list runningvms | cut -d '"' -f2)
	for VM in $ACTIVE; do VBoxManage controlvm "$VM" savestate; done
}
##############################################################################
function TIMETOMONEY () {
read -p "Hourly Salary?": HSALARY
read -p "Hours worked": HOURS
read -p "Minutes worked": MINUTES
MSALARY=$(echo "scale=2; $HSALARY/60" | bc)
MINUTES_WORKED=$(echo "scale=2; $HOURS*60+$MINUTES" | bc)
PAYMENT=$(echo "scale=2; $MINUTES_WORKED*$MSALARY" | bc)
echo "Paid per hour: $ $HSALARY"
echo "Paid per minute: $ $MSALARY"
echo "Worked $MINUTES_WORKED minutes"
echo "Payment will be $ $PAYMENT"
}
##############################################################################
# Determine what my pay increase by percentage is.
function PercentageIncrease () {
read -p 'What is your new annual salary (Do not use $ or ,)': NEW
read -p 'What is your last years annual salary?(Do not use $ or ,)': OLD
DIFF=$(echo "scale=2; $NEW-$OLD" | bc)
X=$(echo "scale=5; $DIFF/$OLD" | bc)
PERCENT=$(echo "scale=2; $X*100" | bc)
echo "You have been given $PERCENT % increase"
}
##############################################################################
function TIMERANGETOMONEY () {
read -p "Hourly Salary?": HSALARY
IFS=: read -p "START TIME 24HR FORMAT HH:MM": STARTHR STARTMIN
IFS=: read -p "END TIME 24HR FORMAT HH:MM": ENDHR ENDMIN
TOTAL_START_MIN=$((10#$STARTHR*60 + 10#$STARTMIN))
TOTAL_END_MIN=$((10#$ENDHR*60 + 10#$ENDMIN))
MINUTES_WORKED=$((TOTAL_END_MIN - TOTAL_START_MIN))
MSALARY=$(echo "scale=4; $HSALARY/60" | bc)
PAYMENT=$(echo "scale=2; $MINUTES_WORKED*$MSALARY" | bc)
PAYMENT=$(printf '%.*f\n' 2 "$PAYMENT")
printf "Worked: %s minutes\nPaid: $%s/hr\nPaid: $%s/min\nTotal Owed: $%s\n"  ${MINUTES_WORKED} "${HSALARY}" "${MSALARY}" "${PAYMENT}"
}
##############################################################################
function FIXSWAP () { sudo swapoff -a && sudo swapon -a ; }
function scanmynetwork () { sudo nmap -sP "${1}"/24 ; }
##############################################################################
function CHECKSTATES () {
ARDS=$(ls /dev/ttyUSB*)
while true; do
for X in $ARDS; do STATE=$(cat < "$X"); echo "$X - $STATE"; done
done
}
##############################################################################
function SWAPUSED () {
SUM=0
OVERALL=0
if [[ -f $HOME/swapcount.txt ]]; then rm -f "$HOME"/swapcount.txt; fi
for DIR in $(find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"); do
    PID=$(echo "$DIR" | cut -d / -f 3)
    PROGNAME=$(ps -p "$PID" -o comm --no-headers)
    for SWAP in $(grep VmSwap "$DIR"/status 2>/dev/null | awk '{ print $2 }')
    do
       let SUM=$SUM+$SWAP; SUM=$(echo $SUM | awk '{print $1=$1/1024}')
    done
    if [[ $SUM -gt 0 ]]; then echo "$SUM MB - $PROGNAME - PID=$PID" >> "$HOME"/swapcount.txt
    fi
    let OVERALL=$OVERALL+$SUM
    OVERALL=$(echo $OVERALL | awk '{print $1=$1/1024}')
    SUM=0
done
cat "$HOME"/swapcount.txt | sort -n
echo "Overall swap used: $OVERALL MB"
}
##############################################################################
function MYIP () {
IP=$(w3m -dump https://www.iplocation.net/find-ip-address | grep -w "IP Address Details" -A2 | tail -1 | cut -d "[" -f 1)
LOCAT=$(w3m -dump https://www.iplocation.net/find-ip-address | grep -w "IP Location" | head -2 | tail -1 | cut -d "[" -f 1)
OS=$(w3m -dump https://www.iplocation.net/find-ip-address | grep -w "OS")
PROXY=$(w3m -dump https://www.iplocation.net/find-ip-address | grep -w "Proxy" | head -2 | tail -1)
echo -e "$IP\n$LOCAT\n$OS\n$PROXY\n"
}
##############################################################################

function BITCOIN_NOTIFY () {
read -p "How much do you have?": QTY
read -p "When the total gets to what to notify?": MYPRICE
PRICE=$(w3m -dump https://coinmarketcap.com/currencies/bitcoin/ | grep -w "Bitcoin (BTC)" -A2 | grep "USD" | cut -f 4 -d ' ')
TOTAL=$(echo "scale=2; $QTY*$PRICE" | bc)
TOTAL=$(printf "%0.2f\n" "$TOTAL")

while [[ "$MYPRICE" > "$TOTAL" ]]; do
PRICE=$(w3m -dump https://coinmarketcap.com/currencies/bitcoin/ | grep -w "Bitcoin (BTC)" -A2 | grep "USD" | cut -f 4 -d ' ')
TOTAL=$(echo "scale=2; $QTY*$PRICE" | bc)
TOTAL=$(printf "%0.2f\n" "$TOTAL")
echo "$TOTAL is not at your price $MYPRICE"
sleep 60
clear
done
zenity --warning --title "$(date +"%A, %D %r")" --text "Bitcoin total is now at $TOTAL"
}
##############################################################################

function MYRIPPLE () {
read -p "How many Ripple (XRP) do you own": QTY
read -p "What did you pay for each one": IPRICE
PRICE=$(w3m -dump https://coinmarketcap.com/currencies/ripple/ | grep -w "Ripple (XRP) Ripple (XRP)" -A2 | grep "USD" | cut -f 4 -d ' ')
IVAL=$(echo "scale=2; $QTY*$IPRICE" | bc)
VAL=$(echo "scale=2; $QTY*$PRICE" | bc)
PROFIT=$(echo "scale=2; $VAL-$IVAL" | bc)
echo "The current price of XRP is $PRICE USD"
echo "You bought your $QTY Ripple(s) for the price of: $IVAL USD"
echo "Your $QTY Ripple you own is worth a total of: $VAL USD"
echo "Your total profit made is: $PROFIT USD"
}

##############################################################################

function MYDOGE () {
read -p "How many DogeCoins do you own": QTY
PRICE=$(w3m -dump https://coinmarketcap.com/currencies/dogecoin/ | grep -w "Dogecoin (DOGE)" -A2 | grep "USD" | cut -f 4 -d ' ')
VAL=$(echo "scale=2; $QTY*$PRICE" | bc)
echo "The current price of DOGE is $PRICE USD"
echo "Your $QTY Dogecoins you own is worth a total of: $VAL USD"
}
##############################################################################

function RIPPLE () {
PRICE=$(w3m -dump https://coinmarketcap.com/currencies/ripple/ | grep -w "Ripple (XRP) Ripple (XRP)" -A2 | grep "USD" | cut -f 4 -d ' ')
echo "The current price of XRP is $PRICE USD"
}

##############################################################################
function forecast () {
w3m -dump "http://www.weather.com/weather/print/$1" | grep -A 26 "$1" | sed -n '/%$/s/\[.*\]//p'
}
##############################################################################
function MAKEDRIVEIMAGE () {
read -p "Specify the drive or partition to take an image of, i.e. /dev/sdd": DRIVE
SIZE=$(sudo fdisk -l "$DRIVE" | head -1 | awk '{print $5}')
#read -p "Specify the total size of this drive or partition is in G": SIZE
read -p "Specify the location and filename of the image to make, ie. /home/username/test.gz": FILE
sudo dd if="$DRIVE" conv=sync,noerror bs=128K | pv -s "$SIZE" | gzip --fast > "$FILE"
}
##############################################################################
function RESTOREDRIVEIMAGE () {
read -p "Specify the drive or partition to drop the image on, i.e. /dev/sdd": DRIVE
#read -p "Specify the total size of this file in G": SIZE
read -p "Specify the location and filename of the image ie. /home/username/test.gz": FILE
SIZE=$(stat -c %s FILE)
gunzip -c "$FILE" | pv -s "$SIZE" | sudo dd of="$DRIVE"
}
##############################################################################
function WRITEISOTOUSB () {
read -p "Specify the location and filename of the ISO file ie. /home/username/ubuntu.iso": FILE
read -p "Specify the USB drive (target), i.e. /dev/sdd": DRIVE
SIZE=$(stat -c %s "${FILE}")
sudo umount "${DRIVE}" && echo "Umounted the USB Drive"
dd bs=4M if="${FILE}" | pv -s "${SIZE}" | sudo dd of="${DRIVE}"
}
##############################################################################
function SLEEPALLACTIVEVMS () {
UP_VMS=$(vboxmanage list runningvms | cut -d '"' -f2)
for x in ${UP_VMS}; do
echo "Saving the state of $x"
vboxmanage controlvm "$x" savestate
done
}
##############################################################################
function attacksite () {
if ! [[ $# -eq 1 ]]; then echo "Pls specify a target http site to attack"; return; fi
sudo anonsurf start
goldeneye "$1"
}
##############################################################################

function pingflood () {
if ! [[ $# -eq 1 ]]; then echo "Pls specify a target Ip or host to flood ping"; return; fi
sudo ping -i 0 "$1"
}
##############################################################################
# Define (Definition)

# Define a word - USAGE: define dog
function define () {
w3m -dump "http://www.google.com/search?hl=en&q=define%3A+${1}&btnG=Google+Search" |
grep -m 3 -w "*"  | sed 's/;/ -/g' | cut -d- -f1 > /home/meir/templookup.txt
                        if [[ -s  /tmp/templookup.txt ]] ;then
                                until ! read response
                                        do
                                        echo "${response}"
                                        done < /tmp/templookup.txt
                                else
                                        echo "Sorry $USER, I can't find the term \"${1} \""
                        fi
rm -f /tmp/templookup.txt
}
##############################################################################


function ii()   # get current host related info
{
  echo -e "\nYou are logged on ${RED}$HOST"
  echo -e "\nAdditionnal information:$NC " ; uname -a
  echo -e "\n${RED}Users logged on:$NC " ; w -h
  echo -e "\n${RED}Current date :$NC " ; date
  echo -e "\n${RED}Machine stats :$NC " ; uptime
  echo -e "\n${RED}Memory stats :$NC " ; free
  my_ip 2>&- ;
  echo -e "\n${RED}Local IP Address :$NC" ; echo "${MY_IP:-"Not connected"}"
  echo -e "\n${RED}ISP Address :$NC" ; echo "${MY_ISP:-"Not connected"}"
  echo
}

##############################################################################
function repeat()	# repeat n times command
{
    local i max
    max=$1; shift;
    for ((i=1; i <= max ; i++)); do  # --> C-like syntax
        eval "$@";
    done
}
##############################################################################

function ask()
{
    echo -n "$@" '[y/n] ' ; read ans
    case "$ans" in
        y*|Y*) return 0 ;;
        *) return 1 ;;
    esac
}


# Define a word - USAGE: define dog
define () {
w3m -dump "http://www.google.com/search?hl=en&q=define%3A+${1}&btnG=Google+Search" | grep -m 3 -w "*"  | sed 's/;/ -/g' | cut -d- -f1 > /tmp/templookup.txt
if [[ -s  /tmp/templookup.txt ]] ;then
until ! read response
do
echo "${response}"
done < /tmp/templookup.txt
else
echo "Sorry $USER, I can't find the term ${1}"
fi
rm -f /tmp/templookup.txt
}
##############################################################################

superzip () {
read -p "Full path of folder with .7z at end":  name
read -p "Where is the file/folder located?": location
7z a -t7z "$name" "$location" -mx9
}

##############################################################################
# This is for encoding wmv to avi
mencoder-auto () {
read -p "name of file?": filename
mencoder "$filename" -ofps 23.976 -ovc lavc -oac copy -o "$filename".avi
}


##############################################################################



function NETWORK_TEST () {
service network restart
echo "Testing connectivity to the gateway"

if ping -c 3 192.168.1.1 > /dev/null 2>&1; then  # gw ip address
echo "Successfull communication with the gateway"
else
echo -e "FAILED to communicate with the gateway\nCheck your network settings, this is a fatal error."
exit
fi

echo "Testing connectivity to the Internet"
if ping -c 3 www.google.com > /dev/null 2>&1 ; then echo "Successfully communicated with google.com"; NET_TEST=1
else
echo -e "FAILED to ping google.com\nScript must halt, check your DNS settings"; exit
fi

}
##############################################################################

function SCANPORTS () {
echo "Scanning TCP ports..."
for p in {1..1023}
do
  (echo >/dev/tcp/localhost/"$p") >/dev/null 2>&1 && echo "$p open"
done
}
##############################################################################

function NETWORK_TEST () {
service networking restart
sleep 5
NETRESULT=$(curl --silent --head http://www.google.com)
if [[ -z $NETRESULT ]]; then echo "FAILED to ping google.com"; echo "Script must halt, check your DNS settings"; else echo "It worked!!!!"; fi
}
##############################################################################


function KEYLESS () {
read -p "Please enter the remote hostname": REMOTEPC
echo "Your current system's hostname is $HOSTNAME"
read -p "Please enter the username that will be authenticated on the remote system": REMOTEUSER
read -p "Please Enter the Port the remote computer's ssh is listening on, default is 22": PORT
if [ ! -f ~/.ssh/id_rsa ];
then
	echo "Hit the Enter key when prompted for RSA Key passwords"
	ssh-keygen -t rsa -b 4096
fi

ssh-copy-id -p "$PORT" "$REMOTEUSER@$REMOTEPC"
if [ $? -eq 0 ];
then
	echo "Success, the script will now close."
else
	echo "Failed to create a keyless ssh login, please run the script again."
fi
}
##############################################################################


function RECORDSCREEN () { simplescreenrecorder --start-hidden --start-recording  --settingsfile=${HOME}/.ssr/${USER}settings.conf & }

function RECORDSCREEN () {
OPTS=$1
unset STARTREC
if [[ $# -eq 0 ]]; then	read -p "Record The (Right) Screen Now - Y/N?":  STARTREC
	if [[ ${STARTREC^^} == "Y" ]]; then
	simplescreenrecorder --start-hidden --start-recording  --settingsfile=${HOME}/.ssr/${USER}settings.conf &
       	fi
fi
case ${OPTS^^} in
	SHOW ) simplescreenrecorder window-show ;;
	HIDE ) simplescreenrecorder window-hide ;;
	QUIT ) simplescreenrecorder quit ;;
	START )  simplescreenrecorder record-start ;;
        PAUSE ) simplescreenrecorder record-pause ;;
	CANCEL ) simplescreenrecorder record-cancel ;;
	SAVE ) simplescreenrecorder record-save ;;
	* ) echo -e "Usage: $0 ARG" ;
	    echo -e "SHOW - Show Window\nHIDE - Hide Window\nQUIT - Quit the program\nSTART - Start recording" ;
	    echo -e "PAUSE - Pause Recording\CANCEL - Cancel Recording\nSAVE - Save Recording" ;
	    return ;;
	esac
}

##############################################################################


function YATZEE () {
DIE1=0; DIE2=1; DIE3=2 DIE4=3 DIE5=4
COUNT=0
until [[ $DIE1 -eq $DIE2 ]] && [[ $DIE2 -eq $DIE3 ]] && [[ $DIE3 -eq $DIE4 ]] && [[ $DIE4 -eq $DIE5 ]]; do
	COUNT=$((COUNT+1))
	DIE1=$(echo $RANDOM | cut -c1)
	DIE2=$(echo $RANDOM | cut -c1)
	DIE3=$(echo $RANDOM | cut -c1)
	DIE4=$(echo $RANDOM | cut -c1)
	DIE5=$(echo $RANDOM | cut -c1)
	echo "$DIE1 - $DIE2 - $DIE3 - $DIE4 - $DIE5"
done

echo "YATZEE - rolled $COUNT times"
}
##############################################################################

function ROLL () {
ATTEMPT=0
while [[ $ATTEMPT -lt 1 ]] && [[ $ATTEMPT -gt 6 ]]; do
ATTEMPT=$(echo $RANDOM | cut -c1)
done
}
##############################################################################

function LOG () {
LOGFILE=./testlog.log
printf "%b\n" "$(date +"%b/%d/%Y:%H:%M:%S") $*" >> $LOGFILE
}

##############################################################################
alias SHOWRUNNINGVMS='echo $(vboxmanage list runningvms | cut -d " " -f1)'
alias SLEEPVM='VBoxManage list runningvms | cut -d"\"" -f2 2> /dev/null | while read -r VM; do VBoxManage controlvm ${VM} savestate; done'
alias RESUMEVM='vboxmanage startvm "vmname" --type headless'
alias STARTTHEVM='nohup vboxmanage startvm "vmname" --type headless > /dev/null 2>&1 &'
alias STARTALLVMS='VBoxManage list vms | cut -d"\"" -f2 2> /dev/null | while read -r VM; do VBoxManage startvm ${VM} --type headless &; done'
alias whatprovides='dpkg -S'
alias fixkeyboard='setxkbmap'

##############################################################################

function MEMCPULIST () {
ps -eo user,pcpu,pmem,command | awk '{print $1,$2,$3,$4}' | grep -iv 'kworker' | awk 'NR==1{print;next} {for (i=2;i<=NF;i++) {a[$4][i]+=$i}} END{ for (d in a) {s=d; for (i=2;i<=NF;i++) {s=s" "a[d][i]}; print s}}' | sort -n -u -k 2 | column -t
}

function MEMCPULISTCHOOSESORT () {
if [[ -z $1 ]]; then echo "Usage: $0 [1,2,3]"; sleep 1; fi  
SNUMBER=${1:=1}
ps -eo pcpu,pmem,pid,user,command | grep -Eiv 'kworker|systemd|/sbin/init' | sort -k${SNUMBER} -r | head -20 | cut -c 1-140
}
##############################################################################
function LOOKFORSTRINGREMOVEANDAPPENDAFTERLINE () {
read -p 'First String to look for': STRING1
read -p 'Second String to look for': STRING2
read -p "String to add after entire line": ADD
read -p "File to change": FILENAME
readarray -t arr1 <<< $(cat ${FILENAME} | grep -iE "${STRING1}.*${STRING2}.*"); 
for x in "${arr1[@]}"; do 
set -- ${x}; 
CLEAN=$(echo ${@^^} | sed -E "s/${STRING1}.${STRING2}. //g") 
echo "${CLEAN} ${ADD}"; 
done
}


function CLEARSWAP () {
SWAPUSED=$(free -m | awk '{print $3}' | tail -1)
if [[ ${SWAPUSED} -gt 100 ]]; then echo "Clearing swap of ${SWAPUSED}MB";  swapoff -a && sudo swapon -a; else echo "Only ${SWAPUSED}MB of swap used."; fi
}
##############################################################################

# alias sshyitztunnel1='ssh -D 5222 amaadmin@amabstracts.publicvm.com -N'
alias PUSH='git add *; git commit -m "updated $date"; git push origin master'

function flipvideo () {
read -p "Path of file": FPATH1
read -p "Filename": ORIG
read -p "Output filename": NEW
echo "0 = 90CounterCLockwise and Vertical Flip
1 = 90Clockwise
2 = 90CounterClockwise
3 = 90Clockwise and Vertical Flip
4 = 180 rotation"

read -p "What number to use for flipping": FLIP

case $FLIP in
1 | 2 | 3 ) ffmpeg -i "$FPATH1"/"$ORIG" -vf "transpose=$FLIP" -r 30 -qscale 0 -acodec copy "$FPATH1"/"$NEW";;
4 ) ffmpeg -i "$FPATH1"/"$ORIG" -vf "vflip,hflip" -r 30 -qscale 0 -acodec copy "$FPATH1"/"$NEW";;
esac
if [[ $? = 0 ]]; then echo "SUCCESS!"; fi
}
##############################################################################

function removegnomeextension () {
	FOUND[1]=$(sudo find "/usr/share/gnome-shell/extensions" -type d -iname "*${1}*" 2>/dev/null)
	FOUND[2]=$(find "${HOME}/.local/share/gnome-shell/extensions" -type d -iname "*${1}*"  2>/dev/null)
for dir in "${FOUND[@]}"; do
	read -p "Delete the directory - $dir (Y/N)": DELETEIT
	if [[ ${DELETEIT^^} == "Y" ]]; then sudo rm -rf "${dir}" && echo "${dir} deleted"; fi
unset DELETEIT
done
}


##############################################################################




function EML () {
if [[ "$#" -ne 1 ]]; then clear; echo "Usage: EML {filename.eml}"; return; fi

munpack "$1"
}
##############################################################################

alias ll='ls -alh'

function SCANMYSSH () {
read -p "Specify the port(s) to check separate each by a comma (default 22,80,443)": PORTS
if [[ -z $PORTS ]]; then PORTS="22,80,443"; fi
echo -e "Choices are;\n- Dell\n- Hewlett Packard\n- QEMU - virtual machine\n- B-Link - IP CAMS"
read -p "Choose which type of computer to look for": PCTYPE
PORTNO=$(echo $PORTS | wc -w)
PORTNO=$(( PORTNO + 3 ))
sudo nmap -p$PORTS 192.1.1.1/8 | grep -B$PORTNO "$PCTYPE" | grep -v "closed"
}
##############################################################################
alias SUSPEND='sudo pm-suspend'
alias FINDHOSTNAMES='nmap -sL 192.1.1.0/8 | grep "("'
function SCANPORTS () {
echo "Scanning TCP ports..."
for p in {1..10000}
do
  (echo >/dev/tcp/localhost/"$p") >/dev/null 2>&1 && echo "$p open"
done
}
##############################################################################


#alias virt-manager='ssh 192.168.1.15 -X "virt-manager"'

function AUTOLOGIN () {
echo "[SeatDefaults]
greeter-session=lightdm-gtk-greeter
autologin-user=username" > /usr/share/lightdm/lightdm.conf.d/60-lightdm-gtk-greeter.conf
}
##############################################################################


function FIXBROKENPKGS () {
sudo cp "/etc/apt/sources.list" "/etc/apt/sources.list{,.backup}.$(date "+%F_%T")";
grep -v '^#' /etc/apt/sources.list | perl -ne '$H{$_}++ or print' > /tmp/sources.list && sudo mv /tmp/sources.list /etc/apt/sources.list
sudo apt update --fix-missing
sudo apt install --fix-broken
sudo apt install -f
sudo dpkg --configure -a
sudo dpkg -l | grep ^..R
sudo apt clean
sudo apt autoremove
sudo apt autoclean
sudo apt check
sudo apt update
sudo apt upgrade -y
sudo rm /var/lib/apt/lists/lock
sudo rm /var/cache/apt/archives/lock
}

function FINDDUPSBYSIZE () {
awk '{
  size = $1
  a[size]=size in a ? a[size] RS $2 : $2
  b[size]++ }
  END{for(x in b)
        if(b[x]>1)
          printf "Duplicate Files By Size: %d Bytes\n%s\n",x,a[x] }' <(find . -type f -exec du -b {} +)
}

function DELBGPIC () {
PIDFILE=${HOME}/change_bg.pid
# WALLPAPERDIR="/path/to/wallpapers"
PIC=$(tail -1 $PIDFILE | awk '{print $2}')
read -p "Delete $PIC (Y/N)": DELPIC
if [[ ${DELPIC^} == "Y" ]]; then rm -f "${PIC}" && echo "${PIC} deleted"; fi
}

function FINDDUPSBYMD5 () {
awk '{
  md5=$1
  a[md5]=md5 in a ? a[md5] RS $2 : $2
  b[md5]++ }
  END{for(x in b)
        if(b[x]>1)
          printf "Duplicate Files (MD5:%s):\n%s\n",x,a[x] }' <(find . -type f -exec md5sum {} +)
}


FINDDUPSBYSAMENAME () {
awk -F'/' '{
  f = $NF
  a[f] = f in a? a[f] RS $0 : $0
  b[f]++ }
  END{for(x in b)
        if(b[x]>1)
          printf "Duplicate Filename: %s\n%s\n",x,a[x] }' <(find . -type f)
}


function FIND_PROG_USING_THIS_RESOURCE () {
STRING=$1
ps -eo user,pid,cmd -q "$(pgrep -f "${STRING}" 2> /dev/null | xargs)"
}


alias RESETMENUBAR='mate-panel --reset'
function FIXKERNELPANIC () {
	echo "First boot to another kernel, then run this function"
	echo "hit ctrl+c if you haven't yet booted to another kernel"
	pause
	ls -al /boot
	read -p "Type the latest kernel numbers (4.18.0-20-generic)": KERNEL
	sudo update-initramfs -u -k "$KERNEL"
	sudo update-grub
	echo "Reboot now and boot to the original kernel"
}
##############################################################################

function CHECKMEM () {
if ! [[ $# = 1 ]]; then echo "Usage:  CHECKMEM processname"; return; else
ps -eo size,pid,user,command | awk '{ hr=$1/1024 ; printf("%13.6f Mb ",hr) } { for ( x=4 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' | sort -n | grep "$1"
fi
}
##############################################################################

# Check_port <address> <port>
function check_port() {
#if [ "$(which nc)" != "" ]; then
#    tool=nc
if [ "$(which curl)" != "" ]; then
     tool=curl
elif [ "$(which telnet)" != "" ]; then
     tool=telnet
elif [ -e /dev/tcp ]; then
      if [ "$(which gtimeout)" != "" ]; then
       tool=gtimeout
      elif [ "$(which timeout)" != "" ]; then
       tool=timeout
      else
       tool=devtcp
      fi
fi
echo "Using $tool to test access to $1:$2"
case $tool in
#nc) nc -v -z -w2 $1 $2 ;;
curl) curl --connect-timeout 10 http://"$1":"$2" ;;
telnet) telnet "$1" "$2" ;;
gtimeout)  gtimeout 1 bash -c "</dev/tcp/${1}/${2} && echo Port is open || echo Port is closed" || echo Connection timeout ;;
timeout)  timeout 1 bash -c "</dev/tcp/${1}/${2} && echo Port is open || echo Port is closed" || echo Connection timeout ;;
devtcp)  /dev/tcp/"${1}"/"${2}" && echo Port is open || echo Port is closed ;;
*) echo "no tools available to test $1 port $2";;
esac

}
##############################################################################

function zippassword () {
if [[ $# -eq 0 ]]; then
read -r -p "What format, zip, 7z, etc.": EXT
read -r -p "/path/and/file_or_dir_Name to zip": ZIPDATA
read -r -p "Password to encrypt": PASS
elif [[ $# -ne 3 ]]; then
echo -e '$@ usage:\n$@ <format (zip, 7z, etc)> </path/to/data> <password to encrypt>'
return
fi

EXT=${EXT:=$1}
ZIPDATA=${ZIPDATA:=$2}
PASS=${PASS:="$3"}

EXT=${EXT:?UNSET}
ZIPDATA=${ZIPDATA:?UNSET}
PASS=${PASS:?UNSET}


echo "CREATING ARCHIVE: ${ZIPDATA}.${EXT}"
echo "FILES TO ADD TO ARCHIVE: ${ZIPDATA}"
echo "ENCRYPTION PASSWORD: ${PASS}"

sleep 2
if 7za a -t"${EXT}" "${ZIPDATA}.${EXT}" "${ZIPDATA}"/* -p"${PASS}"; then echo "COMPLETED SUCCESSFULLY..."; fi
sleep 2

echo "TESTING THE INTEGRITY OF THE ARCHIVE"
if 7za t -r "${ZIPDATA}.${EXT}" -p"${PASS}"; then echo "COMPLETED SUCCESSFULLY..."; fi

echo "LISTING CONTENTS OF THE ARCHIVE..."
7za l -slt "${ZIPDATA}.${EXT}"
}

##############################################################################

function findhere () {
	find . -iname "*${1}*" -print
}

alias init5='sudo systemctl isolate graphical.target'
alias init3='sudo systemctl isolate multi-user.target'
alias init0='sudo systemctl isolate poweroff.target'
alias init6='sudo systemctl isolate reboot.target'

alias init5default='sudo systemctl {enable,set-default} graphical.target'
alias init3default='sudo systemctl {enable,set-default} multi-user.target'

##############################################################################

function NORMALIZE () {
if ! [[ $# = 1 ]]; then echo "Usage:  NORMALIZE /path/to/oggfiles"; return; fi
find "$1" -type f -name "*.ogg" | while read -r output; do
name=$(basename "$output"); thedir=$(dirname "$output");
sox --norm "$output" /tmp/"$name"; mv -vf /tmp/"$name" "$output";
done
}
##############################################################################

function FIXSLOWMOUSE () {
sudo modprobe drm_kms_helper
echo N | sudo tee /sys/module/drm_kms_helper/parameters/poll
echo "drm_kms_helper" | sudo tee -a /etc/modprobe.d/local.conf
echo 'drm_kms_helper' | sudo tee -a /etc/modules-load.d/local.conf
echo "options drm_kms_helper poll=N" | sudo tee -a /etc/modprobe.d/local.conf
}

##############################################################################
function generaterandom () {
menu="Choose a number and the number of random characters, i.e., 3 25;
1 ) date +%s | sha256sum | base64 | head -c 32 ; echo
2 ) < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;
3 ) openssl rand -base64 32
4 ) tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1
5 ) strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo
6 ) < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6
7 ) dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev
8 ) </dev/urandom tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c8; echo ""
9 ) randpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;}
10 ) date | md5sum"
echo "$menu"
read -p "Choose": CHOICE
set -- "${CHOICE}"
case $1 in
1 ) date +%s | sha256sum | base64 | head -c "$2" ; echo ;;
2 ) < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"$2" ; echo;;
3 ) openssl rand -base64 "$2" ;;
4 ) tr -cd '[:alnum:]' < /dev/urandom | fold -w"$2" | head -n1 ;;
5 ) strings /dev/urandom | grep -o '[[:alnum:]]' | head -n "$2" | tr -d '\n'; echo;;
6 ) < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"$2" ;;
7 ) dd if=/dev/urandom bs=1 count="$2" 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev ;;
8 ) </dev/urandom tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c"$2"; echo "" ;;
9 ) < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"$2";echo;;
10 ) date | md5sum | fold -w"$2" ;;
esac
}
#####################################################
function REMOVELOOKLIKEWINDOWS () {
sudo apt purge ukui-desktop-environment ubuntukylin-default-settings peony-common
}
##############################################################################

function KILLZOMBIES () {
readarray -t ZOMBIES< <(ps -aux | grep Z | awk '{print $2}'| grep -v PID)

for zombie in "${ZOMBIES[@]}"; do
unset parentzombie
parentzombie=$(ps -o ppid= -p "$zombie")
if [[ -n ${parentzombie} ]]; then sudo kill -HUP "${parentzombie}"; fi
done
}
##############################################################################

function RATIOFINDER () {
read -r -p "How much of the 1st ingredient": AMT_INGR1
read -r -p "What is the measurement format or type for the 1st ingredient (oz, ml, lb, etc.)": FORMAT_INGR
read -r -p "What is the object, liquid, or powder of 1st ingredient (i.e., water, sand, sugar, etc.)": TYP_INGR1

read -r -p "How much of the 2nd ingredient": AMT_INGR2
echo "The measurement format or type for the 2nd ingredient must be the same format (oz, ml, lb, etc.)";
read -r -p "What is the object, liquid, or powder of 2nd ingredient (i.e., water, sand, sugar, etc.)": TYP_INGR2

CALC=$(echo "scale=2; $AMT_INGR2/$AMT_INGR1" | bc)
echo -e "RATIO\n1 part - $TYP_INGR1\n${CALC} parts - ${TYP_INGR2}"
}

alias UPDATEALL='sudo apt update; sudo apt upgrade -y; sudo apt autoremove -y; sudo apt autoclean -y; sudo snap refresh'

function reverseorder () {
ARGS=${*:?"ERROR NEEDS STRINGS AS ARGUMENTS"}
test $# -ge 4 ||  echo 'Usage: $0 [word|letter|line] word1 word2 etc'
case $1 in
word ) printf '%s\n' "$@" | tac | tr '\n' ' ' ; echo ;;
letter ) echo "$@" | sed 's/.\{1\}/& /g' | tac | tr '\n' ' ' | sed 's/ //g'; echo ;;
line ) echo "$@" | tac ;;
esac
}

##############################################################################

# Ansible shortcuts
function ANSIBLE_RUNALL () {
	ansible all -a "$@" -u username
}
##############################################################################

function ANSIBLEAPTMODULE () {
	ansible all -m apt -a "name=$1 state=latest" -u username
}
##############################################################################

function removeoldkernels () {
v="$(uname -r | awk -F '-virtual' '{ print $1}')"
i="linux-headers-virtual|linux-image-virtual|linux-headers-generic-hwe-|linux-image-generic-hwe-|linux-headers-${v}|linux-image-$(uname -r)|linux-image-generic|linux-headers-generic"
dpkg --list | egrep -i 'linux-image|linux-headers' | awk '/ii/{ print $2}' | egrep -v "$i"
sudo apt-get --purge remove $(dpkg --list | egrep -i 'linux-image|linux-headers' | awk '/ii/{ print $2}' | egrep -v "$i")
}
