# ProdHub AI Workspace

Container images and shared runtime scripts for ProdHub AI workspaces.

## Contents

- ai-workspace/entrypoint.sh is the shared workspace startup script.
- ai-workspace/<variant>/Dockerfile and build.sh define the supported language
  and datastore workspace images.
- ai-workspace/build.sh builds the default OpenCode workspace image.
- ai-workspace/build-and-push.sh builds and publishes an image locally.

Every variant Dockerfile fetches the shared entrypoint from this repository's
GitHub main branch:

https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/main/ai-workspace/entrypoint.sh

To build a variant, run:

IMAGE_TAG=harry2654/prodhub:ai-workspace-golang-1230-bookworm ./ai-workspace/golang-1230-bookworm/build.sh

Set PUSH_IMAGE=true to publish the image after building. Image tags follow:

<registry>/<repository>:ai-workspace-<variant>

## Jenkins

The root `Jenkinsfile` builds, smoke-tests, and publishes every workspace image. Each image runs in its own failure boundary: a failed build or push is recorded and skipped, and the remaining images continue. The Jenkins build finishes as `UNSTABLE` when one or more images fail and archives both the successful image manifest and failure report.
