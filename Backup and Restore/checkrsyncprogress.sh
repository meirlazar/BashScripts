#!/bin/bash

usage()
{
   echo "usage: $0 PID BASEMSIZE [DELAY[s|m|h]]"
}

if [ $# -lt 2 ]; then
   usage
   exit 1
elif [ $# -eq 3 ]; then
   DELAY=$3
else
   DELAY=5s
fi

PID=$1
PBASE=`echo "scale=2; $2/1024"|bc`

R_PID=$PID
W_PID=$PID

R_SPEED_MAX=0
W_SPEED_MAX=0
R_SPEED_CUM=0
W_SPEED_CUM=0
R_SPEED_AVG=0
W_SPEED_AVG=0

ETA=0
ETA_H=0
ETA_M=0
ETA_S=0

while [ ! -r /proc/$PID/io ];
do
   clear
   echo "Waiting for process with PID=$PID to appear!"
   sleep 1
done

B_READ_PREV=`cat /proc/$R_PID/io|awk '$1 ~ /^read_bytes/ {print $2}'`
B_WRITE_PREV=`cat /proc/$W_PID/io|awk '$1 ~ /^write_bytes/ {print $2}'`
T1=`date +%s.%N`

count=0
while true
do
   [ ! -r /proc/$PID/io ] && break
   clear
   B_READ=`cat /proc/$R_PID/io|awk '$1 ~ /^read_bytes/ {print $2}'`
   B_WRITE=`cat /proc/$W_PID/io|awk '$1 ~ /^write_bytes/ {print $2}'`
   BL_READ=`echo "scale=2; ($B_READ-$B_READ_PREV)/1048576"|bc`
   BL_WRITE=`echo "scale=2; ($B_WRITE-$B_WRITE_PREV)/1048576"|bc`
   GB_DONE=`echo "scale=2; $B_WRITE/1073741824"|bc`
   PDONE=`echo "scale=2; $GB_DONE*100/$PBASE"|bc`
   T2=`date +%s.%N`
   TLOOP=`echo "scale=2; ($T2-$T1)/1"|bc`
   R_SPEED=`echo "scale=2; $BL_READ/$TLOOP"|bc`
   W_SPEED=`echo "scale=2; $BL_WRITE/$TLOOP"|bc`

   if [ $count -ge 1 ]; then
      R_SPEED_CUM=`echo "scale=2; $R_SPEED_CUM+$R_SPEED"|bc`
      R_SPEED_AVG=`echo "scale=2; $R_SPEED_CUM/$count"|bc`
      W_SPEED_CUM=`echo "scale=2; $W_SPEED_CUM+$W_SPEED"|bc`
      W_SPEED_AVG=`echo "scale=2; $W_SPEED_CUM/$count"|bc`
      [ `echo "scale=2; $W_SPEED > $W_SPEED_MAX"|bc` -eq 1 ] && W_SPEED_MAX=$W_SPEED
      [ `echo "scale=2; $R_SPEED > $R_SPEED_MAX"|bc` -eq 1 ] && R_SPEED_MAX=$R_SPEED
   fi

   if [ `echo "scale=2; $W_SPEED_AVG > 0"|bc` -eq 1 ]; then
      ETA=`echo "scale=2; (($PBASE-$GB_DONE)*1024)/$W_SPEED_AVG"|bc`
      ETA_H=`echo "scale=0; $ETA/3600"|bc`
      ETA_M=`echo "scale=0; ($ETA%3600)/60"|bc`
      ETA_S=`echo "scale=0; ($ETA%3600)%60"|bc`
   fi

   echo "Monitoring PID: $PID"
   echo
   echo "Read:       $BL_READ MiB in $TLOOP s"
   echo "Write:      $BL_WRITE MiB in $TLOOP s"
   echo
   echo "Read Rate:  $R_SPEED MiB/s ( Avg: $R_SPEED_AVG, Max: $R_SPEED_MAX )"
   echo "Write Rate: $W_SPEED MiB/s ( Avg: $W_SPEED_AVG, Max: $W_SPEED_MAX )"
   echo
   echo "Done: $GB_DONE GiB / $PBASE GiB ($PDONE %)"
   [ `echo "scale=2; $ETA > 0"|bc` -eq 1 ] && printf "ETA: %02d:%02d:%05.2f (%.2fs)\n" $ETA_H $ETA_M $ETA_S $ETA
   echo "Elapsed: `ps -p $PID -o etime=`"

   T1=`date +%s.%N`
   sleep $DELAY
   B_READ_PREV=$B_READ
   B_WRITE_PREV=$B_WRITE
   ((count++))
done
echo "----- Finished -------------------------------------------------------------------"
