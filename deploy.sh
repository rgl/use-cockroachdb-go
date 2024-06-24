#!/bin/bash
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_PATH/.github/workflows/kind/env.sh"

echo 'Pushing the container image...'
docker push localhost:5001/use-cockroachdb-go

echo 'Listing the remote container image tags...'
#wget -qO- http://localhost:5001/v2/_catalog | jq
wget -qO- http://localhost:5001/v2/use-cockroachdb-go/tags/list | jq

# delete the existing pod.
kubectl get pods -l app=use-cockroachdb-go -o name | while read pod_name; do
    echo "Deleting existing pod $pod_name..."
    kubectl delete "$pod_name"
done

echo 'Deploying the application...'
sed -E 's,(\simage:).+,\1 localhost:5001/use-cockroachdb-go:latest,g' \
    resources.yml \
    | kubectl apply \
        -f -

echo 'Waiting for the application to be running...'
kubectl rollout status \
    --timeout 3m \
    deployment/use-cockroachdb-go
