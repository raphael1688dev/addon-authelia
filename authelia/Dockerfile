# 階段一：從官方映像檔提取 Authelia (明確指定 4.38.0 版本)
FROM ghcr.io/authelia/authelia:4.38.0 AS authelia-core

# 階段二：改用與 Authelia 原生環境相同的最新版 Alpine Linux
FROM alpine:3.19

USER root

# 因為回到 Alpine 了，我們再次使用 apk 安裝必要的套件
RUN apk add --no-cache bash jq ca-certificates tzdata

# 複製執行檔與腳本
COPY --from=authelia-core /app/authelia /app/authelia
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT [ "/run.sh" ]
