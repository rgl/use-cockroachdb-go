#!/bin/bash
set -euo pipefail

CLUSTER_NAME='use-cockroachdb-go'
export KUBECONFIG="$PWD/kubeconfig.yml"
