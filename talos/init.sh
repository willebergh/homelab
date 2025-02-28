#!/bin/bash

set -e 

TRASH="/dev/null"

TALOS_CONF_DIR="conf"
TALOS_SECRETS="${TALOS_CONF_DIR}/secrets.yaml"

TALOS_CONTROLPLANE="${TALOS_CONF_DIR}/controlplane.yaml"
TALOS_WORKER="${TALOS_CONF_DIR}/worker.yaml"

CLUSTER_NAME="r1"
CLUSTER_ENDPOINT="https://10.0.0.60:6443"

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
  --output $TALOS_CONF_DIR > $TRASH

echo "Talos conf completed boss!"

for i in {1..3}; do
  echo "Creating machine patch for: tal-cp-${i}"
  talosctl machineconfig patch \
    $TALOS_CONTROLPLANE \
    --patch @cp${i}.yaml \
    --output "${TALOS_CONF_DIR}/cp${i}-.yaml" \
    > $TRASH
done
