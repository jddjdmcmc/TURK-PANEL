# syntax=docker/dockerfile:1
FROM golang:1.26-alpine AS builder

WORKDIR /app

# Build dependencies for CGO + SQLite.
RUN apk add --no-cache gcc musl-dev sqlite-dev

# Cache Go dependencies before copying the rest of the source.
COPY go.mod go.sum ./
RUN go mod download

# IMPORTANT: copy the complete project, including config/, database/, logger/, sub/, util/, web/, xray/, etc.
COPY . .

ENV CGO_ENABLED=1

RUN go build -trimpath -ldflags="-s -w" -o /app/x-ui .

FROM alpine:3.19

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    libc6-compat \
    sqlite \
    tzdata \
    unzip \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

WORKDIR /app

COPY --from=builder /app/x-ui /app/x-ui
COPY --from=builder /app/start.sh /start.sh

# Runtime assets used by Xray.
RUN mkdir -p /app/bin \
    && curl -fsSL https://github.com/XTLS/Xray-core/releases/download/v26.7.11/Xray-linux-64.zip -o /tmp/xray.zip \
    && mkdir -p /tmp/xray \
    && unzip -q /tmp/xray.zip -d /tmp/xray \
    && mv /tmp/xray/xray /app/bin/xray-linux-amd64 \
    && chmod +x /app/bin/xray-linux-amd64 \
    && rm -rf /tmp/xray /tmp/xray.zip

# GeoIP / GeoSite data required by Xray.
RUN curl -fsSL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /app/bin/geoip.dat \
    && curl -fsSL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /app/bin/geosite.dat

RUN chmod +x /app/x-ui /start.sh \
    && mkdir -p /etc/x-ui /var/log/x-ui

EXPOSE 8080

CMD ["/start.sh"]
