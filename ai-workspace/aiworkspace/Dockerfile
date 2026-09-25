FROM node:24.10.0-bookworm-slim

ARG OPENCODE_VERSION=1.18.29

ENV PATH="/workspace/.opencode/bin:${PATH}" \
    NPM_CONFIG_PROGRESS=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false

USER root
# Base images may declare a non-root user; package installation requires root.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 git ca-certificates procps bind9-utils \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && npm install --global opencode-ai@${OPENCODE_VERSION} \
    && rm -rf /var/lib/apt/lists/*

ARG ENTRYPOINT_REF=main
ADD https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/${ENTRYPOINT_REF}/ai-workspace/entrypoint.sh /usr/local/bin/ai-workspace-entrypoint
RUN chmod 0755 /usr/local/bin/ai-workspace-entrypoint

ENTRYPOINT ["/usr/local/bin/ai-workspace-entrypoint"]
