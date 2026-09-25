FROM apache/kafka:4.3.1

ARG OPENCODE_VERSION=1.18.29

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/workspace/.opencode/bin:$PATH"

USER root
RUN apk add --no-cache python3 git ca-certificates procps bind-tools nodejs npm \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && npm install --global opencode-ai@${OPENCODE_VERSION}

ENV AI_WORKSPACE_ENTRYPOINT_REF=main
COPY ai-workspace/entrypoint-bootstrap.sh /usr/local/bin/ai-workspace-bootstrap
RUN chmod 0755 /usr/local/bin/ai-workspace-bootstrap

ENTRYPOINT ["/usr/local/bin/ai-workspace-bootstrap"]
