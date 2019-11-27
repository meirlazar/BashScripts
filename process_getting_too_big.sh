
#!/bin/bash

# Notify me that a process is using a lot of memory, ram or swap.

function SWAPCHECK () {

for DIR in $(find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"); do 
	SWAP=$(grep VmSwap $DIR/status 2>/dev/null | awk '{print $2}')
	if [[ $SWAP > 0 ]]; then 
		TOTALSWAP=$(( TOTALSWAP + SWAP ))
		SWAP=$(echo $SWAP | awk '{ split( "KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }')
		PID=$(echo $DIR | cut -d"/" -f3)
		PROGNAME=$(ps -p $PID -o comm --no-headers)
		printf "%-10s%-25s%-15s%s\n" "$PID" "$PROGNAME" "$SWAP"
	fi
	echo $TOTALSWAP > /tmp/totalswapused
done
}





function sysmon_main() {
	RAWIN=$(ps -o pid,user,%mem,command ax | grep -v PID | awk '/[0-9]*/{print $1 ":" $2 ":" $4}')
	for i in $RAWIN; do 
		PID=$(echo $i | cut -d: -f1)
		OWNER=$(echo $i | cut -d: -f2)
		COMMAND=$(echo $i | cut -d: -f3)
		MEMORY=$(pmap $PID | tail -n 1 | awk '/[0-9]K/{print $2}' | sed  s/K// | awk '{ suffix="MGT"; for(i=0; $1>1024 && i < length(suffix); i++) $1/=1024; print int($1) substr(suffix, i, 1), $3; }')
		printf "%-10s%-15s%-15s%s\n" "$PID" "$OWNER" "$MEMORY" "$COMMAND"
	done 
}

clear
echo "--------------------- SWAP UTILIZATION ---------------------------"
printf "%-10s%-25s%-15s%s\n" "PID" "COMMAND" "SWAP USED"
SWAPCHECK | sort -bnr -k3 | head -15
echo -e "TOTAL SWAP USED: $(cat /tmp/totalswapused | awk '{ split( "KB MB GB" , v ); s=1; while( $1>1024 ){ $1/=1024; s++ } print int($1) v[s] }')\n"

echo "--------------------- MEMORY UTILIZATION ---------------------------"
printf "%-10s%-15s%-15s%s\n" "PID" "OWNER" "MEMORY" "COMMAND"
sysmon_main | sort -bnr -k3 | head -15

