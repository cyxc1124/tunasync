# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.26.2-bookworm AS build
ARG TARGETARCH
ARG VCS_REF=unknown
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -trimpath \
      -ldflags="-s -w -X main.githash=${VCS_REF}" -o /out/tunasync ./cmd/tunasync \
    && CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} go build -trimpath \
      -ldflags="-s -w -X main.githash=${VCS_REF}" -o /out/tunasynctl ./cmd/tunasynctl

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates tini rsync curl wget git openssh-client python3 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 tunasync \
    && useradd --uid 10001 --gid 10001 --create-home tunasync \
    && mkdir -p /data/manager /data/mirrors /data/logs /etc/tunasync \
    && chown -R 10001:10001 /data /etc/tunasync
COPY --from=build /out/ /usr/local/bin/
COPY container/manager.conf /etc/tunasync/manager.conf
USER 10001:10001
WORKDIR /data
EXPOSE 14242 6000
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/tunasync"]
CMD ["manager", "--config", "/etc/tunasync/manager.conf"]
