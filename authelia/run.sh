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

# 2. 轉換為 Authelia v4.38+ 支援的新版環境變數
export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET="$JWT_SECRET"
export AUTHELIA_SESSION_SECRET="$SESSION_SECRET"
export AUTHELIA_SESSION_COOKIES_0_DOMAIN="$DOMAIN"

# 3. 檢查並建立持久化目錄
if [ ! -d "$CONFIG_DIR" ]; then
    echo "[Info] Creating Authelia config directory at $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
fi

# 4. 建立符合新版格式的基礎配置範本
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[Info] No configuration.yml found. Creating a default template..."
    cat <<EOF > "$CONFIG_FILE"
theme: auto
server:
  address: "tcp://0.0.0.0:9091/"
log:
  level: info
default_2fa_method: "totp"
storage:
  encryption_key: "a_very_long_and_random_string_for_database_encryption_please_change"
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
notifier:
  filesystem:
    filename: /config/authelia/notification.txt
EOF
    echo "[Info] Default configuration.yml created."
fi

echo "[Info] Starting Authelia daemon..."
exec /app/authelia --config "$CONFIG_FILE"
