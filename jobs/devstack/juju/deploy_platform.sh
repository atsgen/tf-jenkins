#!/bin/bash -eE
set -o pipefail

[ "${DEBUG,,}" == "true" ] && set -x

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

source "$my_dir/definitions"

CLOUD=${CLOUD:-"local"}

echo "INFO: Deploy platform for $JOB_NAME"
rsync -a -e "ssh -i $WORKER_SSH_KEY $SSH_OPTIONS $SSH_EXTRA_OPTIONS" $WORKSPACE/src $IMAGE_SSH_USER@$instance_ip:./

bash -c "\
cat <<EOF | ssh -i $WORKER_SSH_KEY $SSH_OPTIONS $SSH_EXTRA_OPTIONS $IMAGE_SSH_USER@$instance_ip 
[ "${DEBUG,,}" == "true" ] && set -x
export WORKSPACE=\$HOME
export DEBUG=$DEBUG
export OPENSTACK_VERSION=$OPENSTACK_VERSION
export CONTAINER_REGISTRY="$CONTAINER_REGISTRY"
export CONTRAIL_CONTAINER_TAG="$CONTRAIL_CONTAINER_TAG$TAG_SUFFIX"
export PATH=\$PATH:/usr/sbin
cd src/tungstenfabric/tf-devstack/juju
ORCHESTRATOR=$ORCHESTRATOR CLOUD=$CLOUD ./run.sh platform
EOF" || res=1

echo "INFO: Deploy platform finished"
exit $res"
