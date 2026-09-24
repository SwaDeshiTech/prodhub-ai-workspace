#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
image_tag="${IMAGE_TAG:-${DOCKER_IMAGE_HASH_VALUE:-prodhub-ai-workspace:${BUILD_NUMBER:-local}}}"
artifacts_dir="${script_dir}/artifacts"

mkdir -p "${artifacts_dir}"

docker build -t "${image_tag}" "${script_dir}"

if [[ "${PUSH_IMAGE:-false}" == "true" ]]; then
  docker push "${image_tag}"
fi

printf 'AI_WORKSPACE_IMAGE=%q\n' "${image_tag}" > "${artifacts_dir}/image.env"
printf 'AI_WORKSPACE_IMAGE=%s\n' "${image_tag}"

