#!/bin/bash
set -e

CONFIG_DIR="/config/authelia"
CONFIG_FILE="${CONFIG_DIR}/configuration.yml"
OPTIONS_PATH="/data/options.json"

echo "[Info] Starting Authelia Add-on initialization..."

# 1. 讀取 Home Assistant 圖形介面的設定值
echo "[Info] Reading configuration from HA GUI..."
DOMAIN=$(jq --raw-output '.domain' $OPTIONS_PATH)
JWT_SECRET=$(jq --raw-output '.jwt_secret' $OPTIONS_PATH)
SESSION_SECRET=$(jq --raw-output '.session_secret' $OPTIONS_PATH)
ENCRYPTION_KEY=$(jq --raw-output '.encryption_key' $OPTIONS_PATH)

# 2. 轉換為 Authelia 支援的環境變數
export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET="$JWT_SECRET"
export AUTHELIA_SESSION_SECRET="$SESSION_SECRET"
export AUTHELIA_STORAGE_ENCRYPTION_KEY="$ENCRYPTION_KEY"

# 3. 檢查並建立持久化目錄
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# 4. 強制刷新配置範本
if [ -f "$CONFIG_FILE" ]; then
    echo "[Info] Updating configuration.yml to include required authelia_url..."
    mv "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# 5. 建立符合 v4.38+ 規格的最終配置
echo "[Info] Creating a fresh v4.38+ compatible template..."
cat <<EOF > "$CONFIG_FILE"
theme: auto
server:
  address: "tcp://0.0.0.0:9091/"
log:
  level: info
default_2fa_method: "totp"
storage:
  local:
    path: /config/authelia/db.sqlite3
session:
  cookies:
    - domain: "$DOMAIN"
      authelia_url: "http://auth.$DOMAIN" # [關鍵修正] v4.38+ 必填欄位
      name: authelia_session
      expiration: 3600
      inactivity: 300
authentication_backend:
  file:
    path: /config/authelia/users_database.yml
access_control:
  default_policy: deny
  rules:
    - domain: "*.$DOMAIN"
      policy: two_factor
notifier:
  filesystem:
    filename: /config/authelia/notification.txt
EOF

echo "[Info] Starting Authelia daemon..."
exec /app/authelia --config "$CONFIG_FILE"
