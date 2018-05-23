#!/bin/bash
if [ $# -ne 1 ]
then
    echo "Usage: spawn_router <device-name>"
    exit 0
fi

######## Spin up containers
DEVICE_NAME=$1
sudo docker rm -f $DEVICE_NAME
DOCKER_ID=`sudo docker run --name $DEVICE_NAME -dit sdnhub/netopeer /bin/bash`
echo $DOCKER_ID
echo "Spawned container with IP `sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' $DEVICE_NAME`"

######## Start netconf server with custom YANG model
sudo mkdir -p /var/lib/docker/aufs/mnt/${DOCKER_ID}/usr/local/etc/netopeer/cfgnetopeer/
sudo mkdir -p /var/lib/docker/aufs/mnt/${DOCKER_ID}/root/
sudo chmod -R 777 /var/lib/docker/aufs/mnt/${DOCKER_ID}/usr/local/etc/netopeer/cfgnetopeer/
sudo chmod -R 777 /var/lib/docker/aufs/mnt/${DOCKER_ID}/root/

sudo cp base_datastore.xml /var/lib/docker/aufs/mnt/${DOCKER_ID}/usr/local/etc/netopeer/cfgnetopeer/datastore.xml
sudo cp router.yang /var/lib/docker/aufs/mnt/${DOCKER_ID}/root/router.yang
sudo chmod -R 777 /var/lib/docker/aufs/mnt/${DOCKER_ID}/usr/local/etc/netopeer/cfgnetopeer/datastore.xml
sudo chmod -R 777 /var/lib/docker/aufs/mnt/${DOCKER_ID}/root/router.yang

sudo docker exec $DEVICE_NAME wget www.dsc.ufcg.edu.br/~reinaldo/router.yang
sudo docker exec $DEVICE_NAME pyang -f yin /root/router.yang -o /root/router.yin
sudo docker exec $DEVICE_NAME netopeer-manager add --name router --model router.yin --datastore /usr/local/etc/netopeer/cfgnetopeer/router.xml
sudo docker exec $DEVICE_NAME netopeer-server -d
