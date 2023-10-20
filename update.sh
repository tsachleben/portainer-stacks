#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <target_host>"
    exit 1
fi
TGT_HOST=$1

ssh $TGT_HOST << EOF
set -e

sudo docker image pull portainer/portainer-ce:latest
OLD_OLD_PORTAINER=\$(sudo docker ps -aq -f name=portainer.bak)
[[ -z "\$OLD_OLD_PORTAINER" ]] || docker rm \$OLD_OLD_PORTAINER
sudo docker stop portainer
sudo docker rename portainer portainer.bak
sudo docker update --restart no portainer.bak
sudo docker run -d \
    --name portainer \
    --restart=always \
    --network wg_bridge \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    docker.io/portainer/portainer-ce:latest
EOF
