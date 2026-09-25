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

ARG ENTRYPOINT_REF=main
ADD https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/${ENTRYPOINT_REF}/ai-workspace/entrypoint.sh /usr/local/bin/ai-workspace-entrypoint
RUN chmod 0755 /usr/local/bin/ai-workspace-entrypoint

ENTRYPOINT ["/usr/local/bin/ai-workspace-entrypoint"]
