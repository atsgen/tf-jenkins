#!/bin/bash -eE
set -o pipefail

[ "${DEBUG,,}" == "true" ] && set -x

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

source "$my_dir/definitions"

ENV_FILE="$WORKSPACE/stackrc.$JOB_NAME.env"
source $ENV_FILE

rsync -a -e "ssh $SSH_OPTIONS" $WORKSPACE/src $IMAGE_SSH_USER@$instance_ip:./

echo "INFO: UT started"

cat <<EOF | ssh $SSH_OPTIONS $IMAGE_SSH_USER@$instance_ip
[ "${DEBUG,,}" == "true" ] && set -x
export WORKSPACE=\$HOME
export DEBUG=$DEBUG
export PATH=\$PATH:/usr/sbin

# dont setup own registry
export CONTRAIL_DEPLOY_REGISTRY=0

export REGISTRY_IP=$REGISTRY_IP
export REGISTRY_PORT=$REGISTRY_PORT
export SITE_MIRROR=http://${REGISTRY_IP}/repository

export CONTRAIL_CONTAINER_TAG=$CONTRAIL_CONTAINER_TAG

export GERRIT_PROJECT=${GERRIT_PROJECT}
export GERRIT_CHANGE_NUMBER=${GERRIT_CHANGE_NUMBER}
export GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER}

# to not to bind contrail sources to container
export CONTRAIL_DIR=""

export IMAGE=$REGISTRY_IP:$REGISTRY_PORT/tf-developer-sandbox
export DEVENVTAG=$CONTRAIL_CONTAINER_TAG

cd src/tungstenfabric/tf-dev-env
./run.sh test
EOF
result=$?

#if rsync -a -e "ssh $SSH_OPTIONS" $IMAGE_SSH_USER@$instance_ip:./src/tungstenfabric/tf-dev-env/logs.tgz $WORKSPACE/ ; then
#  pushd $WORKSPACE
#  tar -xzf logs.tgz
#  wget --recursive logs pnexus.sytes.net:8082/patchet_url/ || /bin/true
#  popd
#fi

if [[ $result != 0 ]] ; then
  echo "ERROR: UT failed"
  exit $result
fi
echo "INFO: UT finished successfully"
