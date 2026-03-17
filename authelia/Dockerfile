ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest

# 階段一：提取 Authelia
FROM ghcr.io/authelia/authelia:latest AS authelia-core

# 階段二：使用 HA 的基礎映像檔
FROM ${BUILD_FROM}

USER root

# 補上 bash, jq，以及 Authelia 執行必需的 C 函式庫相容套件與憑證
RUN apk add --no-cache bash jq libc6-compat gcompat ca-certificates tzdata

# 複製執行檔與腳本
COPY --from=authelia-core /app/authelia /app/authelia
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT [ "/run.sh" ]
