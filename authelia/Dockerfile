ARG BUILD_FROM=ghcr.io/authelia/authelia:latest
FROM ${BUILD_FROM}

# 切換回 root 權限以執行初始化腳本與安裝套件
USER root

# 安裝 bash 與 jq (用來解析 HA 的 options.json)
RUN apk add --no-cache bash jq

# 複製並設定啟動腳本權限
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# 覆蓋原本的 Entrypoint，改由自訂腳本接管
ENTRYPOINT [ "/run.sh" ]
