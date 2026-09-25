FROM typesense/typesense:30.2

ARG OPENCODE_VERSION=1.18.29

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/workspace/.opencode/bin:$PATH"

USER root
# Base images may declare a non-root user; package installation requires root.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 git ca-certificates procps bind9-utils nodejs npm \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && npm install --global opencode-ai@${OPENCODE_VERSION} \
    && rm -rf /var/lib/apt/lists/*

ENV AI_WORKSPACE_ENTRYPOINT_REF=main
COPY ai-workspace/entrypoint-bootstrap.sh /usr/local/bin/ai-workspace-bootstrap
RUN chmod 0755 /usr/local/bin/ai-workspace-bootstrap

ENTRYPOINT ["/usr/local/bin/ai-workspace-bootstrap"]
