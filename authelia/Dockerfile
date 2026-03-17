# 必須放在最頂端！這樣變數才能在全域生效
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest

# 階段一：提取 Authelia
FROM ghcr.io/authelia/authelia:latest AS authelia-core

# 階段二：使用 HA 的基礎映像檔，並呼叫剛才的變數
FROM ${BUILD_FROM}

USER root
RUN apk add --no-cache bash jq

COPY --from=authelia-core /app/authelia /app/authelia
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT [ "/run.sh" ]
