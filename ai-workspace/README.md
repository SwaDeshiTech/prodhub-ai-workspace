# AI workspace images

Each language-specific image contains Git, the project runtime, and a pinned OpenCode CLI (`opencode-ai@1.18.29`). The terminal always opens a shell in `/workspace/repository`; run `opencode` when you are ready to start the agent. The OpenCode command loads the workspace `.env` file before it starts, so provider keys are available even in a fresh `kubectl exec` session.

## Images

Each variant follows this tag format:

```text
dockerhub.prodhub.in/prodhub-ai-workspace:ai-workspace-<normalized-base-image>
```

For example:

| Build profile `baseImage` | AI workspace image |
| --- | --- |
| `node:18-bookworm-slim` | `...:ai-workspace-node-18-bookworm-slim` |
| `node:24.10.0-bookworm-slim` | `...:ai-workspace-node-24100-bookworm-slim` |
| `gradle:8.5-jdk21` | `...:ai-workspace-gradle-85-jdk21` |
| `golang:1.24.0-bookworm` | `...:ai-workspace-golang-1240-bookworm` |

The image variant retains the selected base image and adds Git, the OpenCode CLI, and the shared `entrypoint.sh`.

Every image Dockerfile fetches the shared entrypoint from:

`https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/main/ai-workspace/entrypoint.sh`

The `ENTRYPOINT_REF` build argument defaults to `main`, so changing this
script in GitHub is picked up by the next image build without editing every
variant Dockerfile. A release build can pin a branch or commit by passing
`--build-arg ENTRYPOINT_REF=<ref>` to Docker.

Build and optionally push a variant:

```sh
PUSH_IMAGE=true ./node-24100-bookworm-slim/build.sh
PUSH_IMAGE=true ./node-18-bookworm-slim/build.sh
PUSH_IMAGE=true ./gradle-85-jdk21/build.sh
```

## Jenkins

Use `jenkins/pipeline/ai-workspace-build.groovy` for the dedicated AI workspace
image job. Set `BUILD_PATH` to a checked-in variant directory and set
`DOCKER_IMAGE_HASH_VALUE` to the image repository. The pipeline replaces any
provided tag with a stable generic tag derived from `BUILD_PATH`, for example:

```text
BUILD_PATH=ai-workspace/node-24100-bookworm-slim
DOCKER_IMAGE_HASH_VALUE=harry2654/prodhub:aiworkspace-nodealpine-2206857-d31db0d
```

The pipeline logs in to the configured registry, runs the selected variant's
`build.sh` with `PUSH_IMAGE=true`, replaces the supplied tag with
`ai-workspace-node-24100-bookworm-slim`, and archives the generated
`artifacts/image.env`.

For AI-enabled ephemeral environments, ProdHub reads `baseImage` from the build profile and derives the corresponding `aiWorkspaceImage` automatically. The entrypoint clones into `/workspace/repository`, loads provider credentials, and keeps the container available for OpenCode and the application runtime.
