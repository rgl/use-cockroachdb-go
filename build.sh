#!/bin/bash
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_PATH/.github/workflows/kind/env.sh"

echo 'Building the container image...'
DOCKER_BUILDKIT=1 docker build -t localhost:5001/use-cockroachdb-go .
