#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
image_tag="${IMAGE_TAG:-dockerhub.prodhub.in/prodhub-ai-workspace:ai-workspace-qdrant-v1190}"

docker build -f "${script_dir}/Dockerfile" -t "${image_tag}" "${repo_root}"

if [[ "${PUSH_IMAGE:-false}" == "true" ]]; then
  docker push "${image_tag}"
fi

printf 'AI_WORKSPACE_IMAGE=%s\n' "${image_tag}"


