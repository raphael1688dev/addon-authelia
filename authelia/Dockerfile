# 階段一：從官方映像檔提取 Authelia
FROM ghcr.io/authelia/authelia:latest AS authelia-core

# 階段二：改用原生的 Debian 作為底層，徹底解決 glibc 相容性問題！
FROM debian:bookworm-slim

USER root

# 更新套件庫並使用 apt-get 安裝 bash 與 jq
RUN apt-get update && \
    apt-get install -y --no-install-recommends bash jq ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/*

# 複製執行檔與腳本
COPY --from=authelia-core /app/authelia /app/authelia
COPY run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT [ "/run.sh" ]
