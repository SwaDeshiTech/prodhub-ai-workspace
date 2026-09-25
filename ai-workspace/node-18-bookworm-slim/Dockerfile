FROM node:18-bookworm-slim

ARG OPENCODE_VERSION=1.18.29

ENV PATH="/workspace/.opencode/bin:$PATH" \
    NPM_CONFIG_PROGRESS=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NODE_OPTIONS="--max-old-space-size=512"

USER root
# Base images may declare a non-root user; package installation requires root.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        bind9-utils \
        ca-certificates \
        coreutils \
        curl \
        file \
        findutils \
        gawk \
        grep \
        gzip \
        iproute2 \
        jq \
        less \
        lsof \
        net-tools \
        openssh-client \
        git \
        psmisc \
        procps \
        python3 \
        sed \
        tar \
        tree \
        unzip \
        util-linux \
        wget \
        xz-utils \
        zip \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && npm install --global opencode-ai@${OPENCODE_VERSION} \
    && rm -rf /var/lib/apt/lists/*

ENV AI_WORKSPACE_ENTRYPOINT_REF=main
COPY ai-workspace/entrypoint-bootstrap.sh /usr/local/bin/ai-workspace-bootstrap
RUN chmod 0755 /usr/local/bin/ai-workspace-bootstrap

ENTRYPOINT ["/usr/local/bin/ai-workspace-bootstrap"]
