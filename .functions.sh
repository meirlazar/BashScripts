#!/bin/bash

# functions fun stuff and all things functions

##############################################################################
# Get System Information
function downloadallfromwebsite () {
wget -Pedr -nH --user "${1}" --password "${2}" http://"${3}"
}
##############################################################################

function RUNONALL () {
CMD=$@
for x in 192.168.1.44 192.168.1.45 192.168.1.21 ; do 
ssh -q -t -oLogLevel=error -p 6${x##*.}  meir@${x} "${CMD}" 
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
# mac address for LIVINGROOMUNIFIAP - 74:ac:b9:c3:6b:fd
# mac address for DOWNSTAIRSSECONDARYAP - b4:fb:e4:43:df:8f
##############################################################################
function unifi_resetfactoryforboth () {
sshpass -p 5LPc0C7xx5IKdhyX ssh -oStrictHostKeyChecking=no ubnt@192.168.1.3 'mca-cli-op set-default'
sleep 30
set-inform 'http://192.168.1.21:8080/inform'
# ssh to device, set-inform http://ip:port/inform
}
##############################################################################
function unpoller () {
/opt/google/chrome/chrome "http://192.168.1.21:3000/d/OjEdBlMnz/unifi-poller-client-insights-influxdb?orgId=1&from=now-6h&to=now-5s&var-Controller=All&var-Site=All&var-AP=All&var-Switch=All&var-Wireless=All&var-Wired=All&var-Identifier=$tag_name%20$tag_mac"
/opt/google/chrome/chrome "http://192.168.1.21:3000/d/O4NHB_Mnk/unifi-poller-network-sites-influxdb?orgId=1&from=now-3h&to=now-5s"
/opt/google/chrome/chrome "http://192.168.1.21:3000/d/wFVvf_Gnz/unifi-poller-uap-insights-influxdb?orgId=1&refresh=30s"
}
##############################################################################
function watchallofmyoffice () {
nohup /media/dockerfiles/webcamstreamer/workingsilent.sh > /dev/null 2>&1 &
ssh officelaptop 'nohup /home/meir/dockerfiles/webcamstreamer/workingsilent.sh > /dev/null 2>&1 &'
}

# readarray -t IPS< <(sudo nmap -Pn 192.168.0.1/24 -p 554,1935,80,8080  | grep "report" | cut -d " " -f5)
# SCANNING
##############################################################################
function RANDPRON () {
while true; do
DIR="/media/DATALVM/PRON"
readarray -t VID< <(find $DIR -maxdepth 3 -type f | shuf -n100)
totem "${VID}"
done
}

function FIXXAUTHORITY () {
nohup /usr/lib/xorg/Xorg vt1 -displayfd 3 -auth /run/user/121/gdm/Xauthority -background none -noreset -keeptty -verbose 3 > /dev/null 2>&1 &
nohup /usr/lib/xorg/Xorg vt2 -displayfd 3 -auth /run/user/1000/gdm/Xauthority -background none -noreset -keeptty -verbose 3 > /dev/null 2>&1 &
}

##############################################################################
function SCANDHCP () {
sudo nmap -sn 192.168.45.1-254 | awk '/Nmap scan/{gsub(/[()]/,"",$NF); print $NF}'
sudo nmap -sn 192.168.21.1-254 | awk '/Nmap scan/{gsub(/[()]/,"",$NF); print $NF}'
}
##############################################################################
function SCANSTATICS () {
sudo nmap -sn 192.168.1.1-254 | awk '/Nmap scan/{gsub(/[()]/,"",$NF); print $NF}'
}
##############################################################################
function SCANPRINTERS () {
sudo nmap 192.168.9.1-254 -p 9100
}
##############################################################################
function nslookupall () {
if [[ $# -ne 1 ]]; then  echo "Needs an IP address to lookup"; return; fi
ip=$1
for x in 192.168.1.1 192.168.1.21 192.168.1.45 ; do
result=$(nslookup "$ip" $x | grep -iE "Address|name")
result1=$(nslookup "$ip".home.local $x  | grep -iE "Address|name") 
echo -e "${result}\n${result1}" | sort -u | grep -Ev "^$|0.0.0.0" 
done
}

##############################################################################
function CreateHostsFile () {

SUBS='192.168.0.0/24 192.168.1.0/24 192.168.2.0/24 192.168.9.0/24'
for x in ${SUBS}; do 
sudo nmap -sn --resolve-all --dns-servers=192.168.1.1,192.168.1.21 "${x}" | grep -i 'nmap scan' | cut -d" " -f5- | tr -d '()' | awk '{print $2,$1}' | sed "s/^ //g"
done
}
##############################################################################
function TALK () {
STRINGS=$*
curl --request POST \
	--url 'https://voicerss-text-to-speech.p.rapidapi.com/?key=undefined' \
	--header 'content-type: application/x-www-form-urlencoded' \
	--header 'x-rapidapi-host: voicerss-text-to-speech.p.rapidapi.com' \
	--header 'x-rapidapi-key: 139c604fe9mshcbe439dda3ef3a8p122b5cjsnb41f6370126a' \
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
read -p "How many horsepower is the generator (Duromax is 7)?": GEN_HRSPOWER
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
function TRIMTHEFAT () {
export LIST="slack teams remmina atop"
for x in ${LIST}; do pkill -f "$x" || echo "Failed to kill $x" && echo "Killed $x";
for y in $(pgrep -f "$x"); do pkill -f "$y" || echo "Failed to kill $y" && echo "Killed $y";
done
done
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
function OLDTIMERANGETOMONEY () {
read -p "Hourly Salary?": HSALARY
read -p "START TIME 24HR FORMAT HH:MM": STARTTIME
read -p "END TIME 24HR FORMAT HH:MM": ENDTIME
# Convert start and end times to total minutes
IFS=: read STARTHR STARTMIN <<< "$STARTTIME"
IFS=: read ENDHR ENDMIN <<< "$ENDTIME"
TOTAL_START_MIN=$((10#$STARTHR*60 + 10#$STARTMIN))
TOTAL_END_MIN=$((10#$ENDHR*60 + 10#$ENDMIN))
MINUTES_WORKED=$((TOTAL_END_MIN - TOTAL_START_MIN))
MSALARY=$(echo "scale=10; $HSALARY/60" | bc)
PAYMENT=$(echo "scale=2; $MINUTES_WORKED*$MSALARY" | bc)
PAYMENT=$(printf '%.*f\n' 2 "$PAYMENT")
echo "Worked $MINUTES_WORKED minutes"
echo "Paid per hour:   $ $HSALARY"
echo "Paid per minute: $ $(printf '%.*f\n' 2 "$MSALARY")"
echo "Payment will be $ $PAYMENT"
}
##############################################################################
function FIXSWAP () { sudo swapoff -a && sudo swapon -a ; }
function scanmynetwork () { sudo nmap -sP "${1}"/24 ; }
##############################################################################
# this will allow an ext for anyones name no matter where you are
function ARD_OUTPUT () {
touch /home/meir/output1.log /home/meir/output2.log
ts ["%b %d %Y %H:%M:%S"] </dev/ttyUSB0 > /home/meir/output1.log &
ts ["%b %d %Y %H:%M:%S"] </dev/ttyUSB1 > /home/meir/output2.log &
tail -f tail -f /home/meir/output1.log /home/meir/output2.log
}
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
read -p "Specify the location and filename of the image to make, ie. /home/meir/test.gz": FILE
sudo dd if="$DRIVE" conv=sync,noerror bs=128K | pv -s "$SIZE" | gzip --fast > "$FILE"
}
##############################################################################
function RESTOREDRIVEIMAGE () {
read -p "Specify the drive or partition to drop the image on, i.e. /dev/sdd": DRIVE
#read -p "Specify the total size of this file in G": SIZE
read -p "Specify the location and filename of the image ie. /home/meir/test.gz": FILE
SIZE=$(stat -c %s FILE)
gunzip -c "$FILE" | pv -s "$SIZE" | sudo dd of="$DRIVE"
}
##############################################################################
function WRITEISOTOUSB () {
read -p "Specify the location and filename of the ISO file ie. /home/meir/ubuntu.iso": FILE
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
# This program will tell you how much your silver is worth
#silver ()
#{
#echo " Please tell me how many ounces you have of silver "
#read silver
#echo " Please tell me how many ounces you have of gold "
#read gold
#date='date +"%y %b"'
#Prices='w3m -dump "http://www.monex.com/monex/controller?pageid=prices" >  gold.txt | grep -i
#Bullion'
#echo $Prices
#}

##############################################################################
#Times - the zmanim of Baltimore
function Times () { w3m -dump "http://www.luach.com/posts/Region/baltimore" | grep -m 13 -w Zmanim -A 13; }
##############################################################################
# Define (Definition)

# Define a word - USAGE: define dog
function define () {
w3m -dump "http://www.google.com/search?hl=en&q=define%3A+${1}&btnG=Google+Search" |
grep -m 3 -w "*"  | sed 's/;/ -/g' | cut -d- -f1 > /home/meir/templookup.txt
                        if [[ -s  /home/meir/templookup.txt ]] ;then
                                until ! read response
                                        do
                                        echo "${response}"
                                        done < /home/meir/templookup.txt
                                else
                                        echo "Sorry $USER, I can't find the term \"${1} \""
                        fi
rm -f /home/meir/templookup.txt
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

##############################################################################

# This is cool additions to the Bash shell.
# Weather, Stock, Translate (spanish, french), Define (definitions).
#

# Weather by us zip code - Can be called two ways # weather 50315 # weather "Des Moines"
#weather ()
#{
#declare -a WEATHERARRAY
#WEATHERARRAY=( "w3m -dump
#"http://www.google.com/search?hl=en&lr=&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&q=weather+${1}&btnG=Search"
#| grep -A 20
#-m 1
#$echo ${WEATHERARRAY[@]}
#}

#alias temp=weather


#stock ()
#{
#stockname="w3m -dump http://finance.yahoo.com/q?s=${1} | grep -i ":${1})" | sed -e 's/Delayed.*$//"
#stockadvise="${stockname} - delayed quote."
#declare -a STOCKINFO
#STOCKINFO=('w3m -dump http://finance.yahoo.com/q?s=${1} | egrep -i "Last Trade:|Change:|52wk Range:"')
#stockdata='echo ${STOCKINFO[@]}'
#        if [[ ${#stockname} != 0 ]] ;then
#                echo "${stockadvise}"
#                echo "${stockdata}"
#                        else
#                        stockname2=${1}
#                        lookupsymbol='w3m -dump -nolist http://finance.yahoo.com/lookup?s="${1}" | grep -A 1 -m 1 "Portfolio" | grep -v "Portfolio" | sed 's/\(.*\)Ad$
#                                if [[ ${#lookupsymbol} != 0 ]] ;then
#                                echo "${lookupsymbol}"
#                                        else
#                                        echo "Sorry $USER, I can not find ${1}."
#                                fi
#}

##############################################################################

# Translate

#Translate a Word  - USAGE: translate house spanish  # See dictionary.com for available languages (there are many).
#translate ()
#{
#TRANSLATED='w3m -dump "http://dictionary.reference.com/browse/${1}" | grep -i -m 1 -w "${2}:" | sed 's/^[ \t]*//;s/[ \t]*$//'
#if [[ ${#TRANSLATED} != 0 ]] ;then
#        echo "\"${1}\" in ${TRANSLATED}"
#       else	echo "Sorry, I can not translate \"${1}\" to ${2}"
#fi
#}
##############################################################################
# Define (Definition)

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
#echo "full path of wmv file (excluding the name of file)?"
#read path
read -p "name of file?": filename
mencoder "$filename" -ofps 23.976 -ovc lavc -oac copy -o "$filename".avi
}

##############################################################################
function shabbos_old () {
START=$(w3m -dump "http://www.hebcal.com/shabbat/?geo=zip&zip=21209&m=72" | grep -w "Candle lighting" | cut -f 9 -d ' ')
END=$(w3m -dump "http://www.hebcal.com/shabbat/?geo=zip&zip=21209&m=72" | grep -w "Candle lighting" -A2| tail -1  | cut -f 10 -d ' ')
echo Shabbos starts at "$START"
echo Havdalah is at "$END"
}
##############################################################################

function shabbos () {
END=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "Havdala" | awk '{print $2$3}')
START=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "candle lighting" | awk '{print $4$5}')
echo Shabbos starts at "$START"
echo Havdalah is at "$END"
}
##############################################################################

function fasttimes () {
END=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "Tzeis 595°" | grep -ioEw "[0-9]+:[0-9]+\s+[aA|pP][mM]" | xargs)
START=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "Alos HaShachar" | grep -ioEw "[0-9]+:[0-9]+\s+[aA|pP][mM]" | xargs)
echo Fast Starts at "$START"
echo Fast Ends at "$END"
}

function fasttimesyomkippur () {
SHKIA=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "Shkia" | grep -ioEw "[0-9]+:[0-9]+\s+[aA|pP][mM]" | xargs)
START=$(date --date="${SHKIA} -18 min" +'%l:%M %p')
END=$(w3m -dump "https://www.ou.org/zmanim/baltimore-md-us/" | grep -w "Tzeis Hakochavim (42 minutes)" | grep -ioEw "[0-9]+:[0-9]+\s+[aA|pP][mM]" | xargs)

echo Fast Starts at "$START"
echo Fast Ends at "$END"
}


##############################################################################



function NETWORK_TEST () {
service network restart
echo "Testing connectivity to the gateway"

if ping -c 3 192.1.1.1 > /dev/null 2>&1; then
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

SIDDURDIR="/media/ALLDATA2/00_NZBS/Torah/Text/Siddurim"

function prayearlymorning () {
acroread /a page=2 $SIDDURDIR/The-Morning-Blessings-Nusaḥ-Ha-Ari-ḤaBaD1.pdf
}
##############################################################################

function praySHEMA () {
acroread /a page=18 $SIDDURDIR/Shaḥarit-Morning-Nusaḥ-Ha-Ari-ḤaBaD.pdf
}
##############################################################################

function prayMinchah () {
acroread /a page=5 $SIDDURDIR/Minḥah-Afternoon-Nusaḥ-Ha-Ari-ḤaBaD.pdf
}
##############################################################################

alias SCRIPTS='cd /media/ALLDATA2/M_J/Meir/vcProjects/BashScripts'
alias vco='/media/ALLDATA2/00_NZBS/M_J/MEIR/vcProjects/BashScripts/vco'
alias fixperms='ssh -t nas "sudo chmod 777 -R /media/ALLDATA2/00_NZBS/M_J/MEIR/CollabraLink/ /media/ALLDATA2/00_NZBS/M_J/MEIR/vcProjects/" && echo done'
function whatprovides () { sudo apt-file search "${1}" ; }

function RECORDSCREEN () { simplescreenrecorder --start-hidden --start-recording  --settingsfile=/home/meir/.ssr/meirsettings.conf & }

function RECORDSCREEN () {
OPTS=$1
unset STARTREC
if [[ $# -eq 0 ]]; then	read -p "Record The (Right) Screen Now - Y/N?":  STARTREC
	if [[ ${STARTREC^^} == "Y" ]]; then
	simplescreenrecorder --start-hidden --start-recording  --settingsfile=/home/meir/.ssr/meirsettings.conf &
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


function LIMIT () {

if [[ "$#" -ne 2 ]]; then

clear

cat << EOF
To use this command, type in the following format;
LIMIT PCNAME AMOUNT_OF_MINUTES_BEFORE_LOCKING
For example; LIMIT KIDS1 30
This will give 30 minutes to KIDS1 (Refael's pc) before locking.
EOF

else

if [[ "$1" = "KIDS1" ]]; then KIDPC=192.168.1.201
elif [[ "$1" =  "KIDS2" ]]; then KIDPC=192.168.1.202
elif [[ "$1" = "KIDS3" ]]; then KIDPC=192.168.1.203
fi

ssh $KIDPC "at now +$2 minutes <<< 'DISPLAY=:0 gnome-screensaver-command -l'"

fi
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
: <<'END_COMMENT'
# multiline comment starts here
This is a heredoc (<<) redirected to a NOP command (:). The ' ' around END_COMMENT disables BASH command and var execution/expansion.
function dmiready () {
# DMI resources
/opt/google/chrome/chrome  --profile-directory="Profile 4" --new-window "https://dminc-cp.deltekenterprise.com/cpweb/cploginform.htm?1641966778"
/opt/google/chrome/chrome "https://outlook.office.com/mail/inbox/id/AAQkADMxY2YwOTJmLTk3MzYtNGU1NC1hNjJhLTBkYzI5ODQ1M2I5MgAQAPQEpdrgMc9BiSwvlldAEy0%3D"
/opt/google/chrome/chrome "https://outlook.office.com/calendar/view/week"
/opt/google/chrome/chrome "https://teams.microsoft.com/_#/conversations/19:meeting_YzBjYWQyZjUtYTY1Yi00M2UyLThmZjktMGRlYmQzMWUzNWJh@thread.v2?ctx=chat"
/opt/google/chrome/chrome "https://myapplications.microsoft.com/"
/opt/google/chrome/chrome "https://docs.google.com/document/d/1teEWB9vGua1PgLW_N-TW5rN5XVhfts5WBRMMCttMtGk/edit#"
# WMATA online resources
/opt/google/chrome/chrome "https://wmata.service-now.com/workingremotely"
/opt/google/chrome/chrome "https://outlook.office.com/mail/MSLazar@wmata.com/"
}
END_COMMENT
# multiline comment ends here

##############################################################################
# COLLABRALINK
: <<'END_COMMENT'
# multiline comment starts here
function clready () {
env DISPLAY=:0 /opt/google/chrome/chrome  --profile-directory="Profile 2" --new-window "https://mail.google.com/mail/u/0/#inbox"
env DISPLAY=:0 /opt/google/chrome/chrome "https://calendar.google.com/calendar/u/0/r?pli=1"
env DISPLAY=:0 /opt/google/chrome/chrome "https://drive.google.com/drive/my-drive"
env DISPLAY=:0 /opt/google/chrome/chrome "https://myapplications.microsoft.com/"
env DISPLAY=:0 /opt/google/chrome/chrome "https://collabralink-cp.costpointfoundations.com/cpweb/cploginform.htm?1516388599"
env DISPLAY=:0 /opt/google/chrome/chrome "https://meet.google.com/cxm-dayh-hgn?authuser=1&hs=122"
}
END_COMMENT
# multiline comment ends here
##############################################################################
alias SHOWRUNNINGVMS='echo $(vboxmanage list runningvms | cut -d " " -f1)'
alias SLEEPVM='VBoxManage list runningvms | cut -d"\"" -f2 2> /dev/null | while read -r VM; do VBoxManage controlvm ${VM} savestate; done'
alias RESUMEVM='vboxmanage startvm "Windows10_NGDC" --type headless'
alias STARTTHEVM='nohup vboxmanage startvm "Windows10_NGDC" --type headless > /dev/null 2>&1 &'
alias STARTALLVMS='VBoxManage list vms | cut -d"\"" -f2 2> /dev/null | while read -r VM; do VBoxManage startvm ${VM} --type headless &; done'
alias whatprovides='dpkg -S'
alias fixkeyboard='setxkbmap'
alias siddur_morn='acroread /a page=2 /media/ALLDATA2/00_NZBS/Torah/Text/Siddurim/The-Morning-Blessings-Nusah-Ha-Ari-HaBaD1.pdf'

# multiline comment starts here
: <<'END_COMMENT'
function siddur () {
SIDDURDIR="/media/ALLDATA2/00_NZBS/Torah/Text/Siddurim"
LATESTSHEMA=$(w3m -dump http://www.myzmanim.com/day.aspx?vars=42795595 | grep -i -A 8 "today" | grep Shema | awk '{print $2}')

MORNINGHOUR=$(w3m -dump http://www.myzmanim.com/day.aspx?vars=42795595 | grep -i -A 8 "today" | grep Shema | awk '{print $2}' | cut -d ":" -f1)
MONRINGMIN=$(w3m -dump http://www.myzmanim.com/day.aspx?vars=42795595 | grep -i -A 8 "today" | grep Shema | awk '{print $2}' | cut -d ":" -f2)
EARLYMORN=echo "$MONRINGMIN-30" | bc

LATESTMINCHA=$(w3m -dump http://www.myzmanim.com/day.aspx?vars=42795595 | grep -i -A 8 "today" | grep Sunset | awk '{print $2}')
MAARIVTIME=$(w3m -dump http://www.myzmanim.com/day.aspx?vars=42795595 | grep -i -A 8 "today" | grep Nightfall | awk '{print $2}')
acroread /a page=2 $SIDDURDIR/The-Morning-Blessings-Nusah-Ha-Ari-HaBaD1.pdf
}
END_COMMENT
# multiline comment ends here
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

alias proxyme_on='source ~/nordvpn_proxy.env'
alias proxyme_off='source ~/no_proxy.env'


function proxyme () {
# donot use except for status
#export http_proxy=http://192.168.1.45:8118
#export https_proxy=http://192.168.1.45:8118
#export ftp_proxy="http://192.168.1.45:8118
if [[ $# -eq 1 ]]; then PARAM=$1; else PARAM=ON; fi
case "${PARAM^^}" in
ON|1|SET|START|VPN )
	nc -w3 192.168.1.45 8118 || echo "proxy not running"; return;
	source ~/nordvpn_proxy.env
	bash ~/nordvpn_proxy.env
        # export {HTTP,HTTPS,FTP,SOCKS}_PROXY="http://192.168.1.45:8118/" ;
	# export NO_PROXY='localhost,127.0.0.1,::1,.example.com' ;
	# export {http,https,ftp,socks}_proxy="http://192.168.1.45:8118/" ;
        # export no_proxy='localhost,127.0.0.1,::1,.example.com' ;
	gsettings set org.gnome.system.proxy.http host '192.168.1.45';
	gsettings set org.gnome.system.proxy.http port '8118' ;
	gsettings set org.gnome.system.proxy.http host '192.168.1.45';
	gsettings set org.gnome.system.proxy.http port '8118' ;
	gsettings set org.gnome.system.proxy.ftp host '192.168.1.45';
	gsettings set org.gnome.system.proxy.ftp port '8118' ;

	#Setting the Dynamic socks proxy
	gsettings set org.gnome.system.proxy.socks host '192.168.1.45';
	gsettings set org.gnome.system.proxy.socks port '8118' ;

	#Setting Mode
	gsettings set org.gnome.system.proxy mode 'manual' ;;

OFF|0|UNSET|STOP|MANUAL )
	source ~/no_proxy.env
	#unset {HTTP,HTTPS,FTP,SOCKS}_PROXY ;
	#unset {http,https,ftp,socks}_proxy ;
	gsettings set org.gnome.system.proxy mode 'none';;
STATUS|3|QUERY )
	if [[ -n "${HTTP_PROXY}" ]];
	then echo "You are using NORDVPN proxy - IP=$(curl -s ifconfig.me)" ;
	else echo "No proxy set. IP=$(curl -s ifconfig.me)" ;
	fi ;;
esac
}

function removegnomeextension () {
	FOUND[1]=$(sudo find "/usr/share/gnome-shell/extensions" -type d -iname "*${1}*" 2>/dev/null)
	FOUND[2]=$(find "${HOME}/.local/share/gnome-shell/extensions" -type d -iname "*${1}*"  2>/dev/null)
for dir in "${FOUND[@]}"; do
	read -p "Delete the directory - $dir (Y/N)": DELETEIT
	if [[ ${DELETEIT^^} == "Y" ]]; then sudo rm -rf "${dir}" && echo "${dir} deleted"; fi
unset DELETEIT
done
}


function KIDSLOOKUP () {
KIDS="kids1 kids2 kids3 kids4 kids5 kids6"
for pc in ${KIDS}; do
echo "${pc}.home.local = $(nslookup "${pc}".home.local 192.168.1.45 | tail -2 | cut -d' ' -f2 | head -1)"
done
}

##############################################################################

#alias WATCH='/home/meir/.motion/monitorwebcam.sh &'
#alias STOPWATCH='pkill -f monitorwebcam.sh'

: <<'END_COMMENT'
# multiline comment starts here
function HIDE () {
mv /home/meir/.motion/oldconfigs /home/meir/.motion/.oldconfigs
chmod 001 /home/meir/.motion/.oldconfigs
}
##############################################################################

function UNHIDE () {
mv /home/meir/.motion/.oldconfigs /home/meir/.motion/oldconfigs
chmod 777 /home/meir/.motion/oldconfigs
}
##############################################################################


function MOTIONDETECT () {
nohup python /media/ALLDATA3/Installs/Detect_Motion/MeirRoom/MotionDetector_Meir_Room.py > /dev/null 2>&1 &
}
##############################################################################

function MOTIONSTOP () {
pkill -f /media/ALLDATA3/Installs/Detect_Motion
caja /media/ALLDATA3/Installs/Detect_Motion/MeirRoom
}
END_COMMENT
# multiline comment ends here
##############################################################################


function EML () {
if [[ "$#" -ne 1 ]]; then clear; echo "Usage: EML {filename.eml}"; return; fi

munpack "$1"
}
##############################################################################

alias ll='ls -alh'

function SCANMYSSH () {
read -p "Specify the port(s) to check separate each by a comma (default 22,613,2222)": PORTS
if [[ -z $PORTS ]]; then PORTS="22,613,2222"; fi
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

function weedmath {
read -r -p "Enter the dollar amount given": MONEY
read -r -p "Enter the amount of money for an eighth": EIGHTH
GRAM=$(echo "scale=3;$EIGHTH/3.5" | bc)
GIVE=$(echo "scale=2;$MONEY/$GRAM" | bc)
echo "It costs ""$GRAM"" USD per gram"
echo "For $MONEY USD, give $GIVE grams"
}
##############################################################################
: <<'END_COMMENT'
# multiline comment starts here
##############################################################################

function doorbell () {

if [[ $# -ne 1 ]] || ! [[ $1 =~ ^[0-9]+$ ]]; then
clear
echo  "Type doorbell with one of these numbers;"
echo -e "0 - Show Status\n1 - ALL Alerts\n2 - NO Alerts"
echo -e "3 - PopUp\n4 - Audio\n5 - Text Message"
echo -e "6 - PopUp+Audio\n7 - Audio+Text\n8 - PopUp+Text"
echo -e "9 - Snooze alerts for 24 hours"
fi

DIR="/media/RAID0/MEDIA/Meir/Doorbell"

case $1 in
0 ) ls -1 $DIR | grep -v ".sh" || echo "No Alerts";;
1 ) rm -f $DIR/Snooze; touch $DIR/Audio $DIR/PopUp $DIR/Text;;
2 ) rm -f $DIR/Audio $DIR/PopUp $DIR/Text;;
3 ) touch $DIR/PopUp; rm -f $DIR/Audio $DIR/Text;;
4 ) touch $DIR/Audio; rm -f $DIR/PopUp $DIR/Text;;
5 ) touch $DIR/Text; rm -f $DIR/PopUp $DIR/Audio;;
6 ) touch $DIR/PopUp $DIR/Audio; rm -f $DIR/Text;;
7 ) touch $DIR/Audio $DIR/Text; rm -f $DIR/PopUp;;
8 ) touch $DIR/PopUp $DIR/Text; rm -f $DIR/Audio;;
9 ) touch $DIR/Snooze;;
esac
}
##############################################################################

function mailalert () {

if [[ $# -ne 1 ]] || ! [[ $1 =~ ^[0-9]+$ ]]; then
clear
echo  "Type mailalert with one of these numbers;"
echo -e "0 - Show Status\n1 - ALL Alerts\n2 - NO Alerts"
echo -e "3 - PopUp\n4 - Audio\n5 - Text Message"
echo -e "6 - PopUp+Audio\n7 - Audio+Text\n8 - PopUp+Text"
echo -e "9 - Snooze alerts for 4 hours"
fi

DIR="/media/RAID0/MEDIA/Meir/Mail"

case $1 in
0 ) ls -1 $DIR | grep -v ".sh" || echo "No Alerts";;
1 ) rm -f $DIR/Snooze; touch $DIR/Audio $DIR/PopUp $DIR/Text;;
2 ) rm -f $DIR/Audio $DIR/PopUp $DIR/Text;;
3 ) touch $DIR/PopUp; rm -f $DIR/Audio $DIR/Text;;
4 ) touch $DIR/Audio; rm -f $DIR/PopUp $DIR/Text;;
5 ) touch $DIR/Text; rm -f $DIR/PopUp $DIR/Audio;;
6 ) touch $DIR/PopUp $DIR/Audio; rm -f $DIR/Text;;
7 ) touch $DIR/Audio $DIR/Text; rm -f $DIR/PopUp;;
8 ) touch $DIR/PopUp $DIR/Text; rm -f $DIR/Audio;;
9 ) touch $DIR/Snooze;;
esac
}
##############################################################################


function SAMETIME () {
if [[ $# -ne 1 ]] || ! [[ $1 =~ ^[0-3]+$ ]]; then
clear
echo  "Type mailalert with one of these numbers;"
echo "0 - Show Status"
echo "1 - Text Alerts"
echo "2 - NO Alerts"
echo "3 - Snooze alerts for 1 hour"
fi

DIR="/media/ALLDATA2/00_NZBS/M_J/MEIR/IBM_Job/SametimeAlert"

case $1 in
0 ) ls -1 $DIR; if [[ $(ls -1 $DIR | wc -l) = 0 ]]; then echo "No Alerts"; fi ;;
1 ) touch $DIR/Text;;
2 ) rm -f $DIR/Text;;
3 ) touch $DIR/Snooze;;
esac
}
END_COMMENT
# multiline comment ends here
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
PIDFILE=/home/meir/PIDS/change_bg.pid
# WALLPAPERDIR="/media/ALLDATA2/Pictures/MISC/Wallpaper"
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

function TWOFACTOR () {
read -p "Passphrase": PASS
clear
echo "Type in the secret info into the vim session and save"
sleep 2
vim -c 'startinsert' ~/TWOFA.gpg +1
if ! [[ -f ~/TWOFA.gpg ]]; then return; fi
#echo "$PASS" | gpg --batch --yes --passphrase-fd 0 --decrypt ~/TWOFA.gpg
echo "$PASS" | gpg --batch --no-tty --passphrase-fd 0 --decrypt -o ~/TWOFA_DECRYPT.txt ~/TWOFA.gpg
clear
echo "Copy the output below to the window and press enter"
echo -e "\n\n"
cat ~/TWOFA_DECRYPT.txt
cat ~/TWOFA_DECRYPT.txt | xclip
echo -e "\n\n"
read -p "Hit Enter to clear the screen and delete files"
clear
rm -f ~/TWOFA_DECRYPT.txt ~/TWOFA.gpg
}
##############################################################################


alias RESETMENUBAR='mate-panel --reset'
alias shuls='firefox "https://www.ohelmoshebaltimore.com" "http://www.pikesvillejewish.com/"'

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
read -r -p "Password to encrypt, default is S@1Gd0cs@_$(date '+%Y')": PASS
PASS=${PASS:=S@1Gd0cs@_$(date '+%Y')}
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

alias BACKUPFILES='cd "/media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/Backup and Restore" && ./Backup_ANY_DATA.sh'

function DILUTION () {
read -r -p "What is the % of active ingredient in the solution?": PREMIXPER
read -r -p "What is the % you are trying to reach?": POSTMIXPER
read -r -p "How many oz of mixed liquid do you want as the end result?:" TOTALVOL
#POSTMIXCONCENTRATION=$(echo "$PREMIXPER/$TOTALVOL" | bc)
#$TOTALVOL x $PREMIXPER

#echo "Mix $ACTIVECHEM oz with $SOLVENT oz to make $TOTALVOL
# work in progress....
}
##############################################################################

function findhere () {
	find . -iname "*${1}*" -print
}
##############################################################################
alias PVZ='/home/meir/Desktop/Games/Completed_Plants_vs_Zombies/run.sh'
alias HIBERNATE='/media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/Hibernation/hibernate.sh'

alias FIXSOUND='sudo alsa force-reload; pulseaudio -k; sleep 5; pulseaudio --start'
alias RESTARTSOUND='pulseaudio -k; pulseaudio --start'

##############################################################################
alias meeting='/usr/bin/vlc --started-from-file --start-time=$(shuf --input-range=10-60 -n1) /home/meir/Videos/faketeamsmeeting'

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

function TEMPSAVE_GROUPFILES_INTO_DIRS () {
# creates a dir for each uniq file in this tempsave folder for easier finding later
# This can take a long time depending on how many files
MAINDIR='/media/ALLDATA2/M_J/Meir/vcProjects/BashScripts/TEMPSAVE'
ALLFILES=$(find ${MAINDIR} -maxdepth 1 -type f -printf "%f\n")

while IFS= read -r x; do 
	NEWDIR=$(echo ${x} | sed -E 's/.[0-9]+-[0-9]+-[0-9]+.*//g')
	test -d "${MAINDIR}/${NEWDIR}" || mkdir "${MAINDIR}/${NEWDIR}"; 
	mv -f "${MAINDIR}/${x}" "${MAINDIR}/${NEWDIR}"
done <<< "${ALLFILES}"
}




#alias printf='printf "%s\n"'

function startbarrier () {
	for x in $(pgrep -f barrier); do echo "removing old instance -${x}"; kill -9 "${x}"; done
nohup barrier -f --debug INFO --name linuxgamer2 --disable-crypto -c /home/meir/barrierconfig --address 192.168.1.44:24800 > /dev/null 2>&1 &
}


alias CHECKTIME='timedatectl status'
alias ADJUSTTIME='sudo ntpdate 192.168.1.21'
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
	ansible all -a "$@" -u meir
}
##############################################################################

function ANSIBLEAPTMODULE () {
	ansible all -m apt -a "name=$1 state=latest" -u meir
}
##############################################################################

function removeoldkernels () {
v="$(uname -r | awk -F '-virtual' '{ print $1}')"
i="linux-headers-virtual|linux-image-virtual|linux-headers-generic-hwe-|linux-image-generic-hwe-|linux-headers-${v}|linux-image-$(uname -r)|linux-image-generic|linux-headers-generic"
dpkg --list | egrep -i 'linux-image|linux-headers' | awk '/ii/{ print $2}' | egrep -v "$i"
sudo apt-get --purge remove $(dpkg --list | egrep -i 'linux-image|linux-headers' | awk '/ii/{ print $2}' | egrep -v "$i")
}
