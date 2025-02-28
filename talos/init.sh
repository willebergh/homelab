#!/bin/bash

CLUSTER_NAME="r1"
CLUSTER_ENDPOINT="https://10.0.0.60:6443"

# gen config <NAME> <ENDPOINT>
talosctl gen config $CLUSTER_NAME $CLUSTER_ENDPOINT \
  --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.9.2 \
  --with-secrets conf/secrets.yaml \
  --force \
  --output conf