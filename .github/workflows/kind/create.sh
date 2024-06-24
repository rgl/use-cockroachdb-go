#!/bin/bash
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_PATH/env.sh"

# see https://github.com/cockroachdb/cockroach-operator
# renovate: datasource=github-tags depName=cockroachdb/cockroach-operator
cockroach_operator_version='2.14.0'

# see https://github.com/cockroachdb/cockroach
# renovate: datasource=github-tags depName=cockroachdb/cockroach
cockroach_version='24.1.1'

echo "Creating $CLUSTER_NAME k8s..."
kind create cluster \
  --name="$CLUSTER_NAME" \
  --config="$SCRIPT_PATH/config.yml"
kubectl cluster-info

echo 'Creating the docker registry...'
# TODO create the registry inside the k8s cluster.
docker run \
  -d \
  --restart=unless-stopped \
  --name "$CLUSTER_NAME-registry" \
  --env REGISTRY_HTTP_ADDR=0.0.0.0:5001 \
  -p 5001:5001 \
  registry:2.8.3 \
  >/dev/null
while ! wget -q --spider http://localhost:5001/v2; do sleep 1; done;

echo 'Connecting the docker registry to the kind k8s network...'
# TODO isolate the network from other kind clusters with KIND_EXPERIMENTAL_DOCKER_NETWORK.
#      see https://github.com/kubernetes-sigs/kind/blob/v0.21.0/pkg/cluster/internal/providers/docker/network.go
docker network connect \
  kind \
  "$CLUSTER_NAME-registry"

# see https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-with-kubernetes
echo 'Installing the cockroachdb operator...'
kubectl apply -f "https://raw.githubusercontent.com/cockroachdb/cockroach-operator/v$cockroach_operator_version/install/crds.yaml"
kubectl apply -f "https://raw.githubusercontent.com/cockroachdb/cockroach-operator/v$cockroach_operator_version/install/operator.yaml"

echo 'Waiting for the cockroachdb operator to be ready...'
while ! kubectl rollout status --namespace=cockroach-operator-system deployment/cockroach-operator-manager; do sleep 5; done
kubectl wait --namespace=cockroach-operator-system --timeout=15m --for=condition=Ready pods --all

# TODO the above wait is not enough, because creating the CrdbCluster fails with:
#   Error from server (InternalError): error when creating "STDIN": Internal error occurred: failed calling webhook "mcrdbcluster.kb.io": failed to call webhook: Post "https://cockroach-operator-webhook-service.cockroach-operator-system.svc:443/mutate-crdb-cockroachlabs-com-v1alpha1-crdbcluster?timeout=10s": context deadline exceeded
# see https://github.com/cockroachdb/cockroach-operator/issues/957
sleep 15

echo 'Installing the example cockroachdb database...'
# see https://raw.githubusercontent.com/cockroachdb/cockroach-operator/v2.14.0/examples/example.yaml
kubectl apply -f - <<EOF
apiVersion: crdb.cockroachlabs.com/v1alpha1
kind: CrdbCluster
metadata:
  name: cockroachdb
spec:
  nodes: 3
  tlsEnabled: true
  image:
    name: cockroachdb/cockroach:v$cockroach_version
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 500m
      memory: 2Gi
  dataStore:
    pvc:
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
        volumeMode: Filesystem
EOF

echo 'Waiting for the example cockroachdb database be ready...'
kubectl wait --timeout=15m --for=condition=Initialized crdbclusters/cockroachdb
