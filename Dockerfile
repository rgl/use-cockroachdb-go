# syntax=docker.io/docker/dockerfile:1.8

FROM golang:1.22-bookworm AS builder
WORKDIR /src
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 go build -ldflags="-s"

# NB we use the buster-slim (instead of scratch) image so we can enter the container to execute bash etc.
FROM debian:bookworm-slim
RUN <<EOF
#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y --no-install-recommends \
    wget \
    openssl \
    ca-certificates
rm -rf /var/lib/apt/lists/*
EOF
EXPOSE 4000
COPY --from=builder /src/use-cockroachdb-go /usr/local/bin/
# NB 65534:65534 is the uid:gid of the nobody:nogroup user:group.
# NB we use a numeric uid:gid to easy the use in kubernetes securityContext.
#    k8s will only be able to infer the runAsUser and runAsGroup values when
#    the USER intruction has a numeric uid:gid. otherwise it will fail with:
#       kubelet Error: container has runAsNonRoot and image has non-numeric
#       user (nobody), cannot verify user is non-root
USER 65534:65534
ENTRYPOINT ["use-cockroachdb-go"]
