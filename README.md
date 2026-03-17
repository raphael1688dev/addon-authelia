# Home Assistant Add-on: Authelia SSO

This add-on brings [Authelia](https://www.authelia.com/), an open-source authentication and authorization server, to Home Assistant. It provides Two-Factor Authentication (TOTP) and Single Sign-On (SSO) for your applications behind a reverse proxy.

## Installation

1. Navigate to your Home Assistant instance.
2. Go to **Settings** > **Add-ons** > **Add-on Store**.
3. Click the three dots (top right) and select **Repositories**.
4. Add your GitHub repository URL: `https://github.com/raphael1688dev/addon-authelia`.
5. After the store reloads, find **Authelia SSO** and click **Install**.

## Configuration

Before starting the add-on, you **must** configure the following parameters in the **Configuration** tab:

* **`domain`**: Your root domain (e.g., `raphaelchen.org`).
* **`jwt_secret`**: A long, random string used for identity verification.
* **`session_secret`**: A long, random string used to encrypt session data.
* **`encryption_key`**: A long, random string used for database encryption (Required).

> **⚠️ Important Note (v4.38+ Changes)**: 
> Per Authelia v4.38.0 specifications, this add-on automatically configures the portal URL as `https://auth.YOUR_DOMAIN`. Ensure your DNS and Reverse Proxy (NGINX) are configured to point this subdomain to your instance.

## Persistent Storage & User Management

On the first successful start, the add-on creates a configuration folder at `/config/authelia/` in your Home Assistant directory.

### Defining Users
You must manually create the file `/config/authelia/users_database.yml` to define your accounts. 
Example:
```yaml
users:
  usera:
    displayname: "usera"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..." # Use an argon2 hasher
    email: usera@example.com
    groups:
      - admins
