#!/bin/bash -eE
set -o pipefail

[ "${DEBUG,,}" == "true" ] && set -x

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

source "$my_dir/definitions"
source "$WORKSPACE/global.env"
source "$WORKSPACE/stackrc.$JOB_NAME.env" || /bin/true
source "${WORKSPACE}/deps.${JOB_NAME}.${JOB_RND}.env" || /bin/true
source "${WORKSPACE}/vars.${JOB_NAME}.${JOB_RND}.env" || /bin/true

rsync -a -e "ssh -i ${WORKER_SSH_KEY} ${SSH_OPTIONS}" "$my_dir/../../mirrors/mirror-pip.conf" ${IMAGE_SSH_USER}@${instance_ip}:./pip.conf
rsync -a -e "ssh -i ${WORKER_SSH_KEY} ${SSH_OPTIONS}" "$my_dir/../../mirrors/mirror-docker-daemon.json" ${IMAGE_SSH_USER}@${instance_ip}:./docker-daemon.json


cat <<EOF | ssh -i $WORKER_SSH_KEY $SSH_OPTIONS $IMAGE_SSH_USER@$instance_ip
sudo cp -f ./pip.conf /etc/pip.conf
sudo mkdir -p /etc/docker/
sudo cp -f ./docker-daemon.json /etc/docker/daemon.json
#sudo kill -SIGHUP $(pidof dockerd)
EOF
