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

# 2. 轉換為 Authelia 的環境變數 (將自動覆蓋 configuration.yml 的值)
export AUTHELIA_SESSION_DOMAIN="$DOMAIN"
export AUTHELIA_JWT_SECRET="$JWT_SECRET"
export AUTHELIA_SESSION_SECRET="$SESSION_SECRET"

# 3. 檢查並建立持久化目錄
if [ ! -d "$CONFIG_DIR" ]; then
    echo "[Info] Creating Authelia config directory at $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# 4. 建立基礎配置範本 (未被環境變數覆蓋的部分)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[Info] No configuration.yml found. Creating a default template..."
    cat <<EOF > "$CONFIG_FILE"
theme: auto
server:
  host: 0.0.0.0
  port: 9091
log:
  level: info
default_2fa_method: "totp"
storage:
  local:
    path: /config/authelia/db.sqlite3
session:
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
EOF
    echo "[Info] Default configuration.yml created."
fi

echo "[Info] Starting Authelia daemon..."
exec /app/authelia --config "$CONFIG_FILE"
