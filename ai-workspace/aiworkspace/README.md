# Dedicated AI workspace image

This image is used by the standalone `aiworkspace` Helm chart. It includes Node.js,
Python, Git, OpenCode, and the shared workspace entrypoint.

Build it from the `prodhub-ai-workspace` root context:

```sh
PUSH_IMAGE=true ./ai-workspace/aiworkspace/build.sh
```

Override the published image when required:

```sh
IMAGE_TAG=dockerhub.prodhub.in/prodhub-ai-workspace:aiworkspace-1.0.1 PUSH_IMAGE=true ./ai-workspace/aiworkspace/build.sh
```
