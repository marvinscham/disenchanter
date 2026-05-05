FROM mcr.microsoft.com/devcontainers/go:1.23-bookworm

RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends \
        bumpversion \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/disenchanter
COPY go.mod go.sum ./
RUN go mod download

WORKDIR /workspaces/disenchanter
