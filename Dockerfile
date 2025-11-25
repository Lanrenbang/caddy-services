# syntax=docker/dockerfile:latest

# General base layer
FROM --platform=$BUILDPLATFORM golang:alpine AS base
ARG TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
## Shared Go cache
ENV GOMODCACHE=/go/pkg/mod GOCACHE=/root/.cache/go-build
RUN apk add --no-cache ca-certificates git tzdata jq libcap mailcap && \
  update-ca-certificates && \
  adduser -D -u 65532 -h /home/nonroot -s /sbin/nologin nonroot

# envwarp - Get
FROM base AS envwarp-src
ARG SRC_REPO=Lanrenbang/envwarp
ARG SRC_RELEASE=https://api.github.com/repos/${SRC_REPO}/releases/latest \
    SRC_GIT=https://github.com/${SRC_REPO}.git
WORKDIR /src
ADD ${SRC_RELEASE} /tmp/latest-release.json
RUN --mount=type=cache,id=gitcache,target=/root/.cache/git \
    set -eux; \
    SRC_TAG=$(jq -r '.tag_name' /tmp/latest-release.json); \
    if [ -z "$SRC_TAG" ] || [ "$SRC_TAG" = "null" ]; then \
      echo "Error: Failed to get tag_name from GitHub API." >&2; \
      exit 1; \
    fi; \
    echo "Fetching tag: $SRC_TAG"; \
    git init .; \
    git remote add origin "$SRC_GIT"; \
    git fetch --depth=1 origin "$SRC_TAG"; \
    git checkout --detach FETCH_HEAD; \
    if git describe --tags --always 2>/dev/null | grep -qv '^[0-9a-f]\{7\}$'; then \
      echo "Tags found, skipping fetch"; \
    else \
      echo "Fetching full history for tags..."; \
      git fetch --unshallow || true; \
      git fetch --tags --force; \
    fi

# envwarp - Build
FROM base AS envwarp-build
WORKDIR /src
COPY --from=envwarp-src /src/ .
RUN --mount=type=cache,id=gomodcache,target=/go/pkg/mod \
    --mount=type=cache,id=gobuildcache,target=/root/.cache/go-build \
    go build -o /out/envwarp -trimpath -tags=osusergo,netgo -buildvcs=false \
      -ldflags "-X main.version=$(git describe --tags --always --dirty | cut -c2-) -s -w -buildid=" .


# caddy - Get
FROM base AS caddy-src
ARG SRC_REPO=caddyserver/caddy
ARG SRC_RELEASE=https://api.github.com/repos/${SRC_REPO}/releases/latest \
    SRC_GIT=https://github.com/${SRC_REPO}.git
WORKDIR /src
ADD ${SRC_RELEASE} /tmp/latest-release.json

COPY .modules /tmp/modules.list
RUN cat > main.go <<'EOF'
package main

import (
    caddycmd "github.com/caddyserver/caddy/v2/cmd"

    _ "github.com/caddyserver/caddy/v2/modules/standard"

    // __PLUGIN_IMPORTS__
)

func main() {
    caddycmd.Main()
}
EOF

RUN go mod init caddy && go mod edit -require="github.com/caddyserver/caddy/v2@$(jq -r '.tag_name' /tmp/latest-release.json)"
RUN set -Eeuo pipefail; \
  # Standardize .modules and remove CR.
  sed -e 's/\r$//' /tmp/modules.list > /tmp/modules.clean; \
  : > /tmp/imports.gen; \
  while IFS= read -r line || [ -n "$line" ]; do \
    # Skip blanks and comments
    [ -z "$line" ] && continue; \
    case "$line" in \#*) continue;; esac; \
    mod="${line%%@*}"; ver="${line#*@}"; \
    # blank import
    printf '    _ "%s"\n' "$mod" >> /tmp/imports.gen; \
    # If @version is specified, then pinned in go.mod.
    if [ "$mod" != "$ver" ]; then \
      go mod edit -require="$mod@$ver"; \
    fi; \
  done < /tmp/modules.clean; \

  # import plugins
  awk '1;/\/\/ __PLUGIN_IMPORTS__/ { system("cat /tmp/imports.gen"); next }' \
    ./main.go > ./main.go.new && mv ./main.go.new ./main.go

RUN echo "--- main.go ---"; \
  cat ./main.go; \
  echo "--- go.mod ---"; \
  cat ./go.mod

# caddy - Build
FROM base AS caddy-build
WORKDIR /src
COPY --from=caddy-src /src/ .
RUN --mount=type=cache,id=gomodcache,target=/go/pkg/mod \
    --mount=type=cache,id=gobuildcache,target=/root/.cache/go-build \
    go mod tidy && \
    go build -o /out/caddy -trimpath -tags=osusergo,netgo,nobadger,nomysql,nopgx -buildvcs=false \
      -ldflags "-s -w -buildid=" .

RUN mkdir -p /tmp/etc/templates /tmp/etc/caddy /tmp/share/caddy/ /tmp/data/caddy/ /tmp/config/caddy/
# tmp-data
# FROM base AS tmp-data

# Build finally image
FROM scratch

LABEL org.opencontainers.image.title="caddy-services" \
      org.opencontainers.image.authors="bobbynona" \
      org.opencontainers.image.vendor="L.R.B" \
      org.opencontainers.image.source="https://github.com/Lanrenbang/caddy-services" \
      org.opencontainers.image.url="https://github.com/Lanrenbang/caddy-services"

COPY --from=base /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=base /etc/passwd /etc/passwd
COPY --from=base /etc/group /etc/group
COPY --from=base /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=envwarp-build --chown=0:0 --chmod=755 /out/envwarp /usr/local/bin/envwarp
COPY --from=caddy-build --chown=0:0 --chmod=755 /out/caddy /usr/local/bin/caddy

COPY --from=caddy-build --chown=65532:65532 --chmod=0775 /tmp/etc /usr/local/etc/
COPY --from=caddy-build --chown=65532:65532 --chmod=0775 /tmp/share /usr/share/
COPY --from=caddy-build --chown=65532:65532 --chmod=0775 /tmp/data /data
COPY --from=caddy-build --chown=65532:65532 --chmod=0775 /tmp/config /config

VOLUME /usr/local/etc/templates
VOLUME /data
VOLUME /config

ARG TZ=Etc/UTC
ENV TZ=$TZ
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

ENTRYPOINT [ "/usr/local/bin/envwarp" ]

