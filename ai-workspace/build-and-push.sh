#!/bin/sh
set -eu

IMAGE="${1:-dockerhub.prodhub.in/prodhub-ai-workspace:opencode}"

docker build -t "$IMAGE" "$(dirname "$0")"
docker push "$IMAGE"

