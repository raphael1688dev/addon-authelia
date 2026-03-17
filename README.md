# Home Assistant Add-on: Authelia SSO

This add-on brings [Authelia](https://www.authelia.com/) (v4.38.0+) to Home Assistant, providing a high-performance Single Sign-On (SSO) and Two-Factor Authentication (2FA) portal for your web services.

## Features
* **Single Sign-On**: Log in once to access multiple subdomains (e.g., `local.yourdomain.com` and `xc.yourdomain.com`).
* **2FA Support**: Native support for TOTP (Google Authenticator, Authy, etc.).
* **Active Protection**: Integration with NGINX via `auth_request`.

## Installation

1. Go to **Settings** > **Add-ons** > **Add-on Store** in Home Assistant.
2. Click the three-dot menu (top right) and select **Repositories**.
3. Add your GitHub URL: `https://github.com/raphael1688dev/addon-authelia`.
4. Click **Add**, then search for **Authelia SSO** in the store and click **Install**.

## Configuration

Navigate to the **Configuration** tab and fill in the following required fields before starting the add-on:

* **`domain`**: Your root domain (e.g., `raphaelchen.org`).
* **`jwt_secret`**: A unique, long random string for identity verification.
* **`session_secret`**: A unique, long random string for session encryption.
* **`encryption_key`**: A unique, long random string for database encryption (Mandatory in v4.38+).

> **Note**: This add-on automatically configures the portal URL as `https://auth.YOUR_DOMAIN`. Ensure this subdomain is pointed to your NGINX instance with a valid SSL certificate.

## User Management

Authelia uses a file-based user database. Follow these steps to set up your first user:

### 0. Generate a Secure Password Hash

Do not use plaintext passwords. Run the following command in your Home Assistant Terminal & SSH to generate a secure Argon2id hash:
```
docker exec -it addon_13365e00_authelia_sso /app/authelia crypto hash generate argon2 --password "YOUR_CHOSEN_PASSWORD"
```

Copy the resulting string (starting with $argon2id$) and paste it into the password: field in your users_database.yml

### 1. Create the Database File
Create a file at `/config/authelia/users_database.yml` and add the following structure:
```yaml
users:
  raphael:
    displayname: "Raphael"
    password: "PASTE_YOUR_GENERATED_HASH_HERE"
    email: admin@raphaelchen.org
    groups:
      - admins
```

## First Login & Two-Factor Authentication (2FA)

By default, this add-on does not use a real SMTP server to send emails. Instead, it uses a local filesystem notifier to securely store output messages. 

When you log in for the first time, Authelia will require you to register a 2FA device. A prompt will say: *"In order to perform this action policy enforcement requires additional identity verification and a One-Time Code has been sent to your email."*

**How to retrieve your One-Time Code (or Registration Link):**
1. **Do not close** the Authelia login dialog in your browser.
2. Open your Home Assistant **File Editor** or **VS Code** add-on.
3. Navigate to the `/config/authelia/` directory.
4. Open the file named **`notification.txt`**.
5. Inside this file, you will find the simulated email containing your **6-digit One-Time Code** or a direct registration link.
6. Enter the code in your browser, or open the link in a new tab to scan the QR code with your authenticator app (e.g., Google Authenticator, Authy).

## Advanced: Dual-Tenant Architecture (Internal vs. External Network Separation)

If you are hosting both external services (e.g., `xc.raphaelchen.org`) and internal services (e.g., `local.raphaelchen.org`), routing internal traffic to an external auth portal is a security risk. Authelia's Multi-Domain capabilities allow you to split these into completely isolated authentication zones.

### 1. Authelia Configuration (`configuration.yml`)
You must define separate cookies and access control policies for both environments in your `/config/authelia/configuration.yml`:

```yaml
session:
  cookies:
    # External Network (Covers raphaelchen.org and xc.raphaelchen.org)
    - domain: "raphaelchen.org"
      authelia_url: "[https://auth.raphaelchen.org](https://auth.raphaelchen.org)"
      name: authelia_session_ext
      expiration: 3600
      inactivity: 300

    # Internal Network (Strictly for local.raphaelchen.org)
    - domain: "local.raphaelchen.org"
      authelia_url: "[https://auth.local.raphaelchen.org](https://auth.local.raphaelchen.org)"
      name: authelia_session_int
      expiration: 3600
      inactivity: 300

access_control:
  default_policy: deny
  rules:
    - domain: "*.raphaelchen.org"
      policy: two_factor
    - domain: "*.local.raphaelchen.org"
      policy: two_factor
```

### 2. NGINX Integration

You will need to configure separate Auth Portals and Service Blocks for both the External and Internal tenants.

#### A. External Tenant Configuration

**1. External Auth Portal (`auth.raphaelchen.org`):**
```nginx
server {
    listen 443 ssl;
    server_name auth.raphaelchen.org;
    # (Insert SSL config here)

    location / {
        proxy_pass http://HA_IP:9091;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**2. External Protected Service (e.g., `xc.raphaelchen.org`):**
```nginx
server {
    listen 443 ssl;
    server_name xc.raphaelchen.org;
    # (Insert SSL config here)

    location /internal/authelia/authz {
        internal;
        proxy_pass http://HA_IP:9091/api/verify;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
    }

    location / {
        auth_request /internal/authelia/authz;
        # Redirect to the EXTERNAL portal
        error_page 401 =302 [https://auth.raphaelchen.org/?rd=$scheme://$http_host$request_uri](https://auth.raphaelchen.org/?rd=$scheme://$http_host$request_uri);
        
        proxy_pass http://YOUR_EXTERNAL_BACKEND;
    }
}
```

#### B. Internal Tenant Configuration

**1. Internal Auth Portal (`auth.local.raphaelchen.org`):**
```nginx
server {
    listen 443 ssl;
    server_name auth.local.raphaelchen.org;
    # (Insert SSL config here)

    location / {
        proxy_pass http://HA_IP:9091;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**2. Internal Protected Service (`local.raphaelchen.org`):**
```nginx
server {
    listen 443 ssl;
    server_name local.raphaelchen.org;
    # (Insert SSL config here)

    location /internal/authelia/authz {
        internal;
        proxy_pass http://HA_IP:9091/api/verify;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $http_host;
    }

    location / {
        auth_request /internal/authelia/authz;
        # Redirect to the INTERNAL portal
        error_page 401 =302 [https://auth.local.raphaelchen.org/?rd=$scheme://$http_host$request_uri](https://auth.local.raphaelchen.org/?rd=$scheme://$http_host$request_uri);
        
        proxy_pass http://YOUR_INTERNAL_BACKEND;
    }
}
```
