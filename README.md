# Home Assistant Add-on: Authelia SSO

This add-on provides [Authelia](https://www.authelia.com/) (v4.38.0+) for Home Assistant, enabling Single Sign-On (SSO) and Two-Factor Authentication (TOTP) for your web services.

## Installation

1. Open Home Assistant > **Settings** > **Add-ons** > **Add-on Store**.
2. Click the menu (top right) > **Repositories**.
3. Add: `https://github.com/raphael1688dev/addon-authelia`.
4. Install **Authelia SSO**.

## Configuration

In the **Configuration** tab, you must provide the following:

* **`domain`**: Your root domain (e.g., `raphaelchen.org`).
* **`jwt_secret`**: A unique random string for JWT.
* **`session_secret`**: A unique random string for session encryption.
* **`encryption_key`**: A unique random string for database encryption.

> [cite_start]**Note**: This add-on automatically sets the portal to `https://auth.YOUR_DOMAIN`[cite: 49].

## User Management

Authelia uses a file-based user database. You must create the following file manually.

### 0. Generate a Secure Password Hash

Do not use plaintext passwords. Run the following command in your Home Assistant Terminal & SSH to generate a secure Argon2id hash:

docker exec -it addon_13365e00_authelia_sso /app/authelia crypto hash generate argon2 --password "YOUR_CHOSEN_PASSWORD"

Copy the resulting string (starting with $argon2id$) and paste it into the password: field in your users_database.yml


### 1. Create `/config/authelia/users_database.yml`
```yaml
users:
  raphael:
    displayname: "Raphael"
    password: "PASTE_YOUR_HASH_HERE"
    email: admin@raphaelchen.org
    groups:
      - admins

