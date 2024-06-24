#!/bin/bash
SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_PATH/.github/workflows/kind/env.sh"

SOURCE_URL="https://github.com/$GITHUB_REPOSITORY"

if [[ "$GITHUB_REF" =~ \/v([0-9]+(\.[0-9]+)+(-.+)?) ]]; then
    SOURCE_VERSION="${BASH_REMATCH[1]}"
else
    echo "ERROR: Unable to extract semver version from GITHUB_REF."
    exit 1
fi

SOURCE_REVISION="$GITHUB_SHA"

IMAGE="ghcr.io/$GITHUB_REPOSITORY:$SOURCE_VERSION"

echo 'Tagging the container image...'
docker tag localhost:5001/use-cockroachdb-go "$IMAGE"

echo 'Pushing the container image...'
docker push "$IMAGE"
