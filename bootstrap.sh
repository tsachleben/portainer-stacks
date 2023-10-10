#!/bin/bash

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <target_host> <target_hostname> <wg_addr> <docker_subnet>"
    echo
    echo "Optional Environment Vars:"
    echo " - TLD: Top-level domain (default: example.com)"
    exit 1
fi
TGT_HOST=$1
FQDN=$2.${TLD:-example.com}
WG_ADDRESS=$3
DOCKER_SUBNET=$4

ssh $TGT_HOST << EOF
set -e
echo # Machine Configuration
sudo hostnamectl hostname $FQDN
echo
echo

echo # Updates and Package installation
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y net-tools wireguard-tools docker.io
echo
echo

echo # Setup Wireguard Networking
echo "100     wg" | sudo tee /etc/iproute2/rt_tables

WG_PRIVKEY=\$(wg genkey)
echo Node WG Pubkey: \$(echo \$WG_PRIVKEY | wg pubkey)

### TODO: Revise?
sudo tee /etc/wireguard/wg0.conf << WGCONF
[Interface]
PrivateKey=\$WG_PRIVKEY
Address=$WG_ADDRESS
ListenPort=20920

# IPv4 forwarding & routing
PreUp = ip rule add iif wg0 table wg
PostDown = ip rule del iif wg0 table wg

# IPv6 forwarding & routing
PreUp = ip -6 rule add iif wg0 table wg
PostDown = ip -6 rule del iif wg0 table wg

# Routing to Docker Bridge
PreUp = iptables -N DOCKER-USER || true
PreUp = iptables -I DOCKER-USER -i wg0 -d $DOCKER_SUBNET -j ACCEPT
PostDown = iptables -D DOCKER-USER -i wg0 -d $DOCKER_SUBNET -j ACCEPT
WGCONF

### TODO: Lookup + Configure WG Peers?
sudo systemctl enable --now wg-quick@wg0.service
echo
echo

echo # Setup Docker Network Bridge
sudo docker network create -d bridge \
    --subnet $DOCKER_SUBNET \
    -o com.docker.network.bridge.name=wg_bridge wg_bridge
echo
echo

echo # Create + Start Portainer Instance
sudo docker volume create portainer_data
sudo docker run -d \
    --name portainer \
    --restart=always \
    --network wg_bridge \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    docker.io/portainer/portainer-ce:latest
PORTAINER_IP=\$(docker inspect -f '{{.NetworkSettings.Networks.wg_bridge.IPAddress}}' portainer)
PORTAINER_ADMIN=admin
PORTAINER_PASS=\$(python3 -c 'import random; print("".join(random.choices("abcdefghijklmnopqrstuvwxyz1234567890", k=16)));')
curl -X POST -H "Content-Type: application/json" \
    -d "{\"username\":\"\$PORTAINER_ADMIN\",\"password\":\"\$PORTAINER_PASS\"}" \
    http://\$PORTAINER_IP:9000/api/users/admin/init
echo Portainer auth: \$PORTAINER_ADMIN:\$PORTAINER_PASS 
echo
echo
EOF
