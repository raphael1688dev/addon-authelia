# Home Assistant Add-on: Authelia SSO

This Add-on brings [Authelia](https://www.authelia.com/), an open-source authentication and authorization server, directly into your Home Assistant environment. It provides Two-Factor Authentication (TOTP) and Single Sign-On (SSO) for your reverse-proxied applications.

## Installation

1. Navigate to your Home Assistant instance.
2. Go to **Settings** > **Add-ons** > **Add-on Store**.
3. Click the three dots (top right) and select **Repositories**.
4. Add the URL of this GitHub repository.
5. Reload the page, find **Authelia SSO**, and click **Install**.

## Configuration

Before starting the Add-on, go to the **Configuration** tab and set the following parameters:

* **`domain`**: The root domain of your applications (e.g., `your-domain.com`).
* **`jwt_secret`**: A long, random string used for identity verification.
* **`session_secret`**: A long, random string used to encrypt session data.

*Note: These GUI settings will automatically override the respective values in your `configuration.yml` via environment variables.*

## Persistent Storage & Users

Upon the first start, the Add-on creates a default configuration folder at `/config/authelia/` in your Home Assistant directory. 

You will need to manually create the `users_database.yml` file in that directory to define your users and passwords. You can generate a password hash using Authelia's built-in hashing tool or standard argon2 generators.

Example `/config/authelia/users_database.yml`:
```yaml
users:
  admin:
    displayname: "Administrator"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."
    email: admin@your-domain.com
    groups:
      - admins
