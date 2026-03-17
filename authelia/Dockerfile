# 階段一：從官方映像檔提取編譯好的 Authelia 執行檔
FROM ghcr.io/authelia/authelia:latest AS authelia-core

# 階段二：使用 Home Assistant 的標準 Add-on 基礎環境
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM ${BUILD_FROM}

# 切換到 root 權限
USER root

# 現在這裡有 apk 可以用了！安裝我們需要的解析工具
RUN apk add --no-cache bash jq

# 從階段一 (authelia-core) 將純淨的執行檔複製過來
COPY --from=authelia-core /app/authelia /app/authelia

# 複製並設定啟動腳本權限
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# 啟動腳本接管
ENTRYPOINT [ "/run.sh" ]
