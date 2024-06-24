#!/bin/bash
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_PATH/env.sh"

echo 'Destroying k8s...'
kind delete cluster --name "$CLUSTER_NAME"

echo 'Destroying the docker registry...'
docker rm -f "$CLUSTER_NAME-registry"
