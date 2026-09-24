FROM node:18-alpine

ARG OPENCODE_VERSION=1.18.29

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/root/.opencode/bin:$PATH" \
    NPM_CONFIG_PROGRESS=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_FUND=false \
    NODE_OPTIONS="--max-old-space-size=512"

RUN apk add --no-cache \
        bash \
        busybox-extras \
        ca-certificates \
        coreutils \
        curl \
        file \
        findutils \
        gawk \
        git \
        grep \
        gzip \
        iproute2 \
        jq \
        less \
        lsof \
        net-tools \
        openssh-client \
        procps-ng \
        psmisc \
        python3 \
        py3-pip \
        sed \
        tar \
        tree \
        unzip \
        util-linux \
        wget \
        xz \
        zip \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && npm install --global opencode-ai@${OPENCODE_VERSION}

ARG ENTRYPOINT_REF=main
ADD https://raw.githubusercontent.com/SwaDeshiTech/prodhub-ai-workspace/${ENTRYPOINT_REF}/ai-workspace/entrypoint.sh /usr/local/bin/ai-workspace-entrypoint
RUN chmod 0755 /usr/local/bin/ai-workspace-entrypoint

ENTRYPOINT ["/usr/local/bin/ai-workspace-entrypoint"]
