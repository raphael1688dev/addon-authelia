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

* **`domain`**: Your root domain (e.g., `example.com`).
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
    email: admin@example.com
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

If you are hosting both external services (e.g., `xc.example.com`) and internal services (e.g., `local.example.com`), routing internal traffic to an external auth portal is a security risk. Authelia's Multi-Domain capabilities allow you to split these into completely isolated authentication zones.

### 1. Authelia Configuration (`configuration.yml`)
You must define separate cookies and access control policies for both environments in your `/config/authelia/configuration.yml`:

```yaml
session:
  cookies:
    # External Network (Covers example.com and xc.example.com)
    - domain: "example.com"
      authelia_url: "[https://auth.example.com](https://auth.example.com)"
      name: authelia_session_ext
      expiration: 3600
      inactivity: 300

    # Internal Network (Strictly for local.example.com)
    - domain: "local.example.com"
      authelia_url: "[https://auth.local.example.com](https://auth.local.example.com)"
      name: authelia_session_int
      expiration: 3600
      inactivity: 300

access_control:
  default_policy: deny
  rules:
    - domain: "*.example.com"
      policy: two_factor
    - domain: "*.local.example.com"
      policy: two_factor
```

### 2. NGINX Integration

You will need to configure separate Auth Portals and Service Blocks for both the External and Internal tenants.

#### A. External Tenant Configuration

**1. External Auth Portal (`auth.example.com`):**
```nginx
server {
    listen 443 ssl;
    server_name auth.example.com;
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

**2. External Protected Service (e.g., `xc.example.com`):**
```nginx
server {
    listen 443 ssl;
    server_name xc.example.com;
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
        error_page 401 =302 [https://auth.example.com/?rd=$scheme://$http_host$request_uri](https://auth.example.com/?rd=$scheme://$http_host$request_uri);
        
        proxy_pass http://YOUR_EXTERNAL_BACKEND;
    }
}
```

#### B. Internal Tenant Configuration

**1. Internal Auth Portal (`auth.local.example.com`):**
```nginx
server {
    listen 443 ssl;
    server_name auth.local.example.com;
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

**2. Internal Protected Service (`local.example.com`):**
```nginx
server {
    listen 443 ssl;
    server_name local.example.com;
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
        error_page 401 =302 [https://auth.local.example.com/?rd=$scheme://$http_host$request_uri](https://auth.local.example.com/?rd=$scheme://$http_host$request_uri);
        
        proxy_pass http://YOUR_INTERNAL_BACKEND;
    }
}
```

## NGINX Proxy Manager (NPM) Integration

If you are using **NGINX Proxy Manager (NPM)**, you cannot modify the full `nginx.conf` or use standard `server` blocks, as NPM generates these automatically via its GUI. 

To achieve the **Dual-Tenant Architecture** (automatically routing internal domains to the internal auth portal and external domains to the external auth portal) without breaking NPM's routing, you must use the **Advanced** tab.

### Stage 1: Create the Auth Portals in NPM

First, create two standard Proxy Hosts in NPM to act as your centralized authentication guards. You do not need any custom advanced configurations for these.

**1. External Auth Portal**
* **Domain Names:** `auth.YOUR_DOMAIN.com` (e.g., `auth.example.com`)
* **Scheme:** `http`
* **Forward Hostname / IP:** `YOUR_HA_IP` (e.g., `172.30.33.12` or `homeassistant`)
* **Forward Port:** `9091`
* **SSL:** Enable "Force SSL"

**2. Internal Auth Portal**
* **Domain Names:** `auth.local.YOUR_DOMAIN.com` (e.g., `auth.local.example.com`)
* **Scheme:** `http`
* **Forward Hostname / IP:** `YOUR_HA_IP`
* **Forward Port:** `9091`
* **SSL:** Enable "Force SSL"

### Stage 2: Protect Your Services (The Advanced Tab)

For any service you want to protect behind Authelia (e.g., `frigate.local.example.com` or `xc.example.com`), set up the Proxy Host normally in the NPM GUI (pointing to the real backend service). 

Then, go to the **Advanced** tab of that Proxy Host and paste the following snippet into the `Custom Nginx Configuration` field:

```nginx
# =========================================================
# 1. Dynamic Domain Extraction (Multi-Tenant Support)
# Extracts the root/tenant domain for dynamic routing.
# =========================================================
set $tenant_domain "";
if ($host ~* ^[^.]+\.(.+)$) {
    set $tenant_domain $1;
}

# =========================================================
# 2. Interception & Dynamic Routing
# Placed at the server level to be inherited by NPM's location /
# =========================================================
auth_request /internal/authelia/authz;

# Dynamically redirects to [https://auth.local.example.com](https://auth.local.example.com) or [https://auth.example.com](https://auth.example.com)
error_page 401 =302 https://auth.$tenant_domain/?rd=$scheme://$http_host$request_uri;

# Pass the authenticated user to the backend service
auth_request_set $user $upstream_http_remote_user;
proxy_set_header Remote-User $user;

# =========================================================
# 3. Internal Authelia Verification Endpoint
# =========================================================
location /internal/authelia/authz {
    internal;
    
    # Replace with your Home Assistant IP or Docker hostname
    proxy_pass http://homeassistant:9091/api/verify;
    
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

**Why this works in NPM:**
* **Perfect Inheritance:** We place the `auth_request` and `error_page` directives at the root of the custom configuration (Server level). NPM automatically inherits these rules into its auto-generated `location /` block.
* **No `location /` Conflicts:** We do not manually declare `location /`, which prevents the dreaded "Duplicate location" error in NPM.
* **Universal Snippet:** Thanks to the Regex domain extraction, you can paste this exact same snippet into *any* subdomain's Advanced tab without changing a single line of code!
