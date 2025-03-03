#!/bin/bash

set -e 

TRASH="/dev/null"

TALOS_CONF_DIR="conf"
TALOS_SECRETS="${TALOS_CONF_DIR}/secrets.yaml"
TALOS_CONFIG="${TALOS_CONF_DIR}/talosconfig"

TALOS_CONTROLPLANE="${TALOS_CONF_DIR}/controlplane.yaml"
TALOS_WORKER="${TALOS_CONF_DIR}/worker.yaml"

CLUSTER_NAME="r1"
CLUSTER_ENDPOINT="https://10.0.0.60:6443"

declare -a CONTROLPLANE_IPS=(
  "10.0.0.61"
  "10.0.0.62"
  "10.0.0.63"
)

declare -a WORKER_IPS=(
  "10.0.0.64"
  "10.0.0.65"
)


if [ ! -e $TALOS_CONF_DIR ]; then
    echo "Cluster conf dir not found, creating..."
    mkdir -p $TALOS_CONF_DIR > $TRASH
    echo "Created new conf dir at: ${TALOS_CONF_DIR}"
fi

if [ ! -e $TALOS_SECRETS ]; then
    echo "Secrets not found, generating..."
    talosctl gen secrets -o $TALOS_SECRETS > $TRASH
    echo "New secrets at: ${TALOS_SECRETS}"
fi

echo "Creating talos config with FORCE"

# gen config <NAME> <ENDPOINT>
talosctl gen config $CLUSTER_NAME $CLUSTER_ENDPOINT \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.9.2 \
  --with-secrets $TALOS_SECRETS \
  --force \
  --output $TALOS_CONF_DIR \
  > $TRASH

echo "Talos conf completed boss!"


for (( i=0; i<${#CONTROLPLANE_IPS[@]}; i++ )); do
  ADDRESS="${CONTROLPLANE_IPS[$i]}"
  
  CP_INDEX=$((i+1))
  CP_FILENAME="cp${CP_INDEX}.yaml"

  echo "Creating machine patch for: ${ADDRESS}"
  talosctl machineconfig patch \
    $TALOS_CONTROLPLANE \
    --patch "@patches/${CP_FILENAME}" \
    --output "${TALOS_CONF_DIR}/${CP_FILENAME}" \
    > $TRASH

  echo "Generated machine config from patch"
  echo "Applying new config to ${ADDRESS} in 5 sec...";
  sleep 5

  talosctl apply-config \
      --insecure \
      --nodes $ADDRESS \
      --file "${TALOS_CONF_DIR}/${CP_FILENAME}" \
      > $TRASH
done


JOINED_CP_IPS="$(IFS=" "; echo "${CONTROLPLANE_IPS[*]}")"
CONTROLPLANE_ONE=${CONTROLPLANE_IPS[0]}

talosctl config endpoint $CONTROLPLANE_ONE \
  --talosconfig=$TALOS_CONFIG

talosctl config node $CONTROLPLANE_ONE \
  --talosconfig=$TALOS_CONFIG

talosctl bootstrap  \
  --nodes $CONTROLPLANE_ONE \
  --endpoints $CONTROLPLANE_ONE \
  --talosconfig=./conf/talosconfig



  # talosconfig apply-config --nodes 10.0.0.64 --file ./conf/worker.yaml --talosconfig=./conf/talosconfig
  # talosctl machineconfig patch ./conf/worker.yaml --patch @w2.yaml --output ./conf/w2.yaml