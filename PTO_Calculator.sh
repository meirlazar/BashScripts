#!/bin/bash

# Written by Meir Lazar
# Version 3.3 12/02/2019

# Purpose: This script, using the PTO accrual rate and the amount of PTO you currently have saved up, will calculate how much PTO you will have at every pay period, both in hours and days.
# It will also show which Jewish Observant Holidays will be taken off and calculate your PTO based on that data.

# Further versions will have Federal Holidays automatically shown in the script, as well as stop dates.

# 6.67 hours of accural per pay period (1-15, 16-30)
# 24 pay periods x 6.67 = 160 hours of PTO 
# 160 hrs / 8hrs per day = 20 days of PTO 
# 20 days / 5 Workdays per week = 4 weeks of PTO per calendar year

#######################################################################################################
#######################################################################################################
	
# User defined Variables 
	
# Accural rates per pay period (15th and the last day of month)
ACCRATE=6.67   # This is the amount of PTO (in hours) that you accrue per pay period - CHANGE IT

#######################################################################################################
#######################################################################################################


# User Questions
read -p "What is the amount of PTO you currently have?": CURRPTO
IFS=: read -p "Type the starting date MM:DD:YYYY to check the relevant Jewish Holidays and your PTO balance": MONTH DAY YEAR 
if [[ -z $MONTH ]] || [[ -z $DAY ]] || [[ -z $YEAR ]]; then IFS=: read MONTH DAY YEAR <<< $(date +"%m:%d:%y"); fi
read -p "What is the total amount of hours that can be rolled over to next year?": ROLLHOURS
clear

#######################################################################################################
#######################################################################################################

function FIX () {
if [[ $1 -lt 10 ]]; then echo "$1" | sed 's/^/0/'; else echo "$1"; fi
}
#######################################################################################################
#######################################################################################################

function FIXADD () {
	RESULT=$(echo "$1 + $2" | bc)
if [[ $RESULT -lt 10 ]]; then echo "$RESULT" | sed 's/^/0/'; else echo "$RESULT"; fi
}

#######################################################################################################
#######################################################################################################

# Takes a dump of all Jewish Holidays on the specified calendar year
ALLJEWISHHOLIDAYS=$(lynx -dump "http://jewishholidaysonline.com/$YEAR" | grep -E "Monday,|Tuesday,|Wednesday,|Thursday,|Friday,|Saturday,|Sunday," | awk -v YEAR=$YEAR -F',' -v OFS='\t' '{print $1 $2 " "YEAR $3 $4 $5}')

TMPDAY=$(FIX $DAY)
TMPMONTH=$(FIX $MONTH)
FULLMONTH=$(date -d "$YEAR-$TMPMONTH-$TMPDAY" '+%B')

#######################################################################################################

while [[ -z $JEWISHHOLIDAYS ]]; do 
	JEWISHHOLIDAYS=$(echo "${ALLJEWISHHOLIDAYS}" | grep -w -A 100 "${FULLMONTH} ${TMPDAY}")
	TMPDAY=$(FIXADD $TMPDAY 1) 
	if [[ "${TMPDAY}" = "31" ]]; then 
		TMPDAY=01
		TMPMONTH=$(FIXADD $TMPMONTH 1)
		if [[ "${TMPMONTH}" = "12" ]]; then echo "No Jewish Holidays left this Year"; break; fi
		FULLMONTH=$(date -d "$YEAR-$TMPMONTH-$TMPDAY" '+%B')
	fi
done

# List of dates in an array (in the Jewish calendar) that Observant Jews are not allowed to work so must take PTO. 

JHOLIDAYS[1]="14th of Adar"  # Purim day
JHOLIDAYS[2]="15th of Nisan" # 1st day of passover
JHOLIDAYS[3]="16th of Nisan" # 2nd day of Passover
JHOLIDAYS[4]="21st of Nisan" # 7th day of Passover 
JHOLIDAYS[5]="22nd of Nisan" # 8th day of Passover
JHOLIDAYS[6]="6th of Sivan" # 1st day of Shavuot
JHOLIDAYS[7]="7th of Sivan" # 2nd day of Shavuot
JHOLIDAYS[8]="1st of Tishrei" # 1st day of Rosh Hashanah
JHOLIDAYS[9]="2nd of Tishrei" # 2nd day of Rosh Hashanah
JHOLIDAYS[10]="10th of Tishrei" # Yom Kippur day
JHOLIDAYS[11]="15th of Tishrei" # 1st day of Sukkot
JHOLIDAYS[12]="16th of Tishrei" # 2nd day of Sukkot
JHOLIDAYS[13]="22nd of Tishrei" # Shmini Atzeret
JHOLIDAYS[14]="23rd of Tishrei" # Simchat Torah


for item in "${JHOLIDAYS[@]}"; do 
OFF=$(echo "${JEWISHHOLIDAYS}" | grep -w "$item" | head -1 | grep -E "Monday|Tuesday|Wednesday|Thursday|Friday")
if [[ -n $OFF ]]; then count=$(( count + 1)); WORKDAYSOFF[$count]="${OFF}"; fi
done

#######################################################################################################
#######################################################################################################

# Print to screen all info calculated so far

echo "--------------------------------------------------"
echo "${#JHOLIDAYS[*]} days of holidays occur in $YEAR"
echo "${#WORKDAYSOFF[*]} Jewish holidays occur on weekdays in $YEAR"
echo "--------------------------------------------------"

echo -e "\n-----------------------------------------------------------"
echo "------------ PTO DAYS TO REQUEST OFF IN $YEAR --------------"
echo "-----------------------------------------------------------"
for x in "${WORKDAYSOFF[@]}"; do echo "$x"; done
echo "-----------------------------------------------------------"

# PRINT THE TOTAL PTO HOURS AND DAYS FOR THIS YEAR

JHOLPTOHOURS=$(echo "${#WORKDAYSOFF[*]} * 8" | bc)
echo -e "\n$JHOLPTOHOURS hours of PTO will be used for Jewish Holidays"
echo -e "${#WORKDAYSOFF[*]} days of PTO will be used for Jewish Holidays"
echo "--------------------------------------------------"

#######################################################################################################

# This part shows each pay date (till the end of the Gregorian year) with the amount of PTO accrued

echo -e "\n---------- ACCRUAL SCHEDULE FOR REMAINDER OF $YEAR ----------"
for (( m=$MONTH; m<13; m++ )); do 
	if [[ "$m" == "12" ]]; then YEAR=$(( YEAR + 1 )); NEXTMO=01; else NEXTMO=$(( m + 1)); fi

	# if day is before the 15th
	if [[ ${DAY} > 15 ]]; then 
		CURRPTO=$(echo "scale=2; $CURRPTO + $ACCRATE" | bc)
		LASTDAY=$(date -d "$YEAR-$NEXTMO-01 -1 day" +%d)
		echo "On $m/$LASTDAY/$YEAR - Total Accrued = $CURRPTO"
		unset DAY
		continue
	fi

	# 15th of the month
	CURRPTO=$(echo "scale=2; $CURRPTO + $ACCRATE" | bc)
	echo "On $m/15/$YEAR - Total Accrued = $CURRPTO"


	# Last day of the month
	CURRPTO=$(echo "scale=2; $CURRPTO + $ACCRATE" | bc)
	LASTDAY=$(date -d "$YEAR-$NEXTMO-01 -1 day" +%d)
	echo "On $m/$LASTDAY/$YEAR - Total Accrued = $CURRPTO"
done

#######################################################################################################
#######################################################################################################

# This section shows the total hours/days of PTO accrued through the end of the Gregorian year, then shows the difference once the Jewish Holidays have been substracted.

# Print the total PTO hours/days
PTOHOURS=$CURRPTO
PTODAYS=$(echo "scale=2; $PTOHOURS / 8" | bc)
echo -e "\n$PTOHOURS Hours - Total time (Hours) of PTO accrued by the end of the year"
echo -e "$PTODAYS Days - Total time (Days) of PTO accrued by the end of the year\n"


# Print the PTO hours/days after the Jewish Holidays have been subtracted
PTOHOURSLEFT=$(echo "scale=2; $PTOHOURS - $JHOLPTOHOURS" | bc)
PTODAYSLEFT=$(echo "scale=2; $PTOHOURSLEFT / 8" | bc)
echo "$PTOHOURSLEFT Hours - Balance of time (hours) of PTO left over by the end of the year after Jewish Holidays have been subtracted"
echo -e "$PTODAYSLEFT Days - Balance of time (days) of PTO left over by the end of the year after Jewish Holidays have been substracted\n"

#######################################################################################################
#######################################################################################################

# ROLLHOURS is used to calculate how many days/hours must be used by year's end.

ROLLHOURSLEFT=$(echo "scale=2; $PTOHOURSLEFT - $ROLLHOURS" | bc)
ROLLDAYSLEFT=$(echo "scale=2; $ROLLHOURSLEFT / 8" | bc)
ROLLDAYS=$(echo "scale=2; $ROLLHOURS / 8" | bc)
echo -e "\nYou must use a minimum of $ROLLHOURSLEFT hours before the end of $YEAR to be left with $ROLLHOURS hours of PTO for next year"
echo -e "You must use a minimum of $ROLLDAYSLEFT days before the end of $YEAR to be left with $ROLLDAYS days of PTO for next year"



