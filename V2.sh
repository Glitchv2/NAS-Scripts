#!/bin/bash/
#set -x

#Setting variables:
#Logging enabled? [yes] or [no]
#Not used as of right now, will be logging to /Scripts/NAS-Scripts/logging
logging="no"

sysctl hw.model | awk {'first = $1; $1=""; print $0'}|sed 's/^ //g'
sysctl hw.machine | awk {'first = $1; $1=""; print $0'}|sed 's/^ //g'

#Sets CPU core count
corecount="$(sysctl hw.ncpu | awk '{print $2}')"

#Catches if script was unable to count cpu's
if [ "$corecount" -gt 0 ] ; then
    continue
else
    echo "Could not count cores!"
      while true; do
        read -p " Would you like to continue?" yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) echo "Ending my life!"
        esac
        exit 126 && echo $?
      done
fi

#Checks both 'da' and 'ada' for drives.
da="$(ls /dev/ | grep -c '\bda[0-9]\b')"
ada="$(ls /dev/ | grep -c '\bada[0-9]\b')"

#Drive count var
drivecount="0"

#Which device? [da] or [ada]
drivelocal=""

#checks if 'da' has a drive count
#if 'da' has a count, sets variable to count
#else if 'da' is Zero/Null checks 'ada'
#if 'ada' has a count, sets variable to count
#else unable to count drive, asks to continue

if [ $da -gt 0 ] ; then
  drivecount="$(camcontrol devlist | grep -c \<ATA)"
  echo "Using 'da' drive count"
  drivelocal="da"
  continue
elif [ $ada -gt 0 ] ; then
  drivecount="$(camcontrol devlist | grep -c \<ATA)"
  echo "Using 'ada' drive count"
  drivelocal="ada"
  continue
else
  echo "Unable to count drives!"
        while true; do
        read -p " Would you like to continue?" yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) echo "Ending my life!"
        esac
        exit 126 && echo $?
      done
fi

#Catches if script was unable to count drives
if [ "$drivecount" -gt 0 ] ; then
    continue
    else
    echo "Could not count drives!"
      while true; do
        read -p " Would you like to continue?" yn
        case $yn in
          [Yy]* ) break;;
          [Nn]* ) echo "Ending my life!"
        esac
        exit 126 && echo $?
      done
fi

#Sets the date that the script started running
TOD=`date "+DATE: %m-%d-%Y%nTime: %H:%M:%S"`

#Sets the date for the log file
logdate=`date "+%m-%d-%Y"`

#Sets the time for the log file contents
logtime=`date "+%m-%d-%Y  %H:%M:%S"`

#Now to actually do some things!

echo "Processor Core Count: " $corecount

#greps all tempatures from all cores, adds together, then divides by number of cores
sysctl -a | grep "dev.cpu.*.temperature" | awk '{print $2}' | awk -v corecount="$corecount" '{ SUM+= $1/corecount} END { print "Average Core temp: " SUM "C"}'

echo "Number of Drives: " $drivecount
uptime | awk '{print "System Load  1 minute: " $10}'
uptime | awk '{print "System Load  5 minute: " $11}'
uptime | awk '{print "System Load 15 minute: " $12}'

#Pause 2 sec, do things look right?
sleep 2


#Loop checks da0 - da${drivecount}
for x in $( seq 0 $drivecount ); do
	#First check if drive is awake or not, dumping all messages to /dev/null, but still retaining error code
	smartctl -n standby /dev/${drivelocal}${x} >> /dev/null
	
	#Check exit code of above command, if exit code does not equal 0, then skip drive
	if [ $? -ne "0" ]; then #Do not attempt to test the drive and keep the drive asleep.
		echo "${drivelocal}${x} is currently asleep and was not tested!"
		echo ""
		continue
	else  #Drive is awake and ready to be tested
		#Prints the drive number, date, and time
		echo "${drivelocal}${x}"
		#Print Device Model
		smartctl -a /dev/${drivelocal}${x} | grep -e "Device Model:"
		#Print the Temp of the drive.
		smartctl -a /dev/${drivelocal}${x} | grep -e "194 Temp*" | awk '{print "Temp: " $10 "C"}'
		
		#Print the Hours on of the drive.
		smartctl -a /dev/${drivelocal}${x} | grep -e "  9 Power_On" | awk '{print "Hours: " $10 }'
		smartctl -a /dev/${drivelocal}${x} | grep -e "  9 Power_On" | awk '{print "Days: " $10/24 }'
		smartctl -a /dev/${drivelocal}${x} | grep -e "  9 Power_On" | awk '{print "Years: " $10/24/365 }'
		#Prints out important drive SMART info.
		smartctl -a /dev/${drivelocal}${x} | grep -i -e "  9 Power_On" -e "  1 raw_read" -e "  5 reallocated" -e "  7 seek" -e " 10 spin" -e "197 current_pending" -e "198 offline_un" -e "199 _UDMA_CRC"
		echo ""
		echo ""
		echo ""
	fi
done

#echo "dev/da1"
#smartctl -a /dev/da1 | grep -e "Device Model:"
#smartctl -a /dev/da0 | grep -e "194 Temp*" | awk '{print "Temp: " $10 "C"}'

exit 0
