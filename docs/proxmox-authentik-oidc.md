# Proxmox VE + Authentik OIDC Integration Guide

## Overview

This guide configures SSO for the `magic-kingdom` Proxmox cluster using Authentik as the OpenID Connect identity provider. The realm configuration is cluster-wide (stored in `/etc/pve/domains.cfg`), so it only needs to be applied to one node.

**Components:**
- **Authentik** — `authentik.local.mk-labs.cloud` (behind lightning-lane/Traefik)
- **Proxmox cluster** — `main-street-usa` (.11), `tomorrowland` (.12), `fantasyland` (.13)

---

## Part 1: Create the Authentik OIDC Provider (Manual)

1. **Log in** to Authentik admin at `https://authentik.local.mk-labs.cloud/if/admin/`

2. **Navigate to** Applications → Applications → **Create with Provider**

3. **Application settings:**
   - Name: `Proxmox VE`
   - Slug: `proxmox` (this becomes part of the issuer URL)
   - Group: `Infrastructure` (optional, for organization)
   - Launch URL: `https://main-street-usa.local.mk-labs.cloud:8006`

4. **Click Next** → Select **OAuth2/OpenID Connect**

5. **Provider settings:**
   - Name: `Provider for Proxmox VE` (or accept auto-generated)
   - Authorization flow: `default-provider-authorization-implicit-consent`
   - Client type: `Confidential`

6. **Redirect URIs** (Strict) — add one per Proxmox node:
   ```
   https://main-street-usa.local.mk-labs.cloud:8006
   https://tomorrowland.local.mk-labs.cloud:8006
   https://fantasyland.local.mk-labs.cloud:8006
   ```
   > **Important:** No trailing slash. Include the `:8006` port.

7. **Signing Key:** Select your certificate (not the default self-signed — use one generated from your Cloudflare wildcard or create a dedicated one in Authentik under System → Certificates)

8. **Scopes:** Ensure these are selected:
   - `openid`
   - `email`
   - `profile`

9. **Subject mode:** `Based on the User's username`

10. **Click Submit**

11. **Record the credentials:**
    - Go to the newly created provider → copy **Client ID** and **Client Secret**
    - The **Issuer URL** will be: `https://authentik.local.mk-labs.cloud/application/o/proxmox/`

---

## Part 2: Store Credentials in Ansible Vault

```bash
cd ~/homelab/ansible

# Create the vault file (if it doesn't exist)
ansible-vault create group_vars/proxmox/vault.yml

# Add these variables:
vault_proxmox_oidc_client_id: "<client-id-from-step-11>"
vault_proxmox_oidc_client_key: "<client-secret-from-step-11>"
```

---

## Part 3: Run the Ansible Playbook

```bash
cd ~/homelab/ansible
ansible-playbook -i inventory.yml playbooks/configure_proxmox_oidc.yml
```

This will:
- Add the `authentik` OIDC realm to Proxmox (or update it if it already exists)
- Grant `rblundon@authentik` the `Administrator` role at the root path

---

## Part 4: Verify

1. **Open** any Proxmox node's web UI (e.g., `https://main-street-usa.local.mk-labs.cloud:8006`)
2. **On the login screen**, select **Realm → authentik** from the dropdown
3. **Click Login** — you'll be redirected to Authentik
4. **Authenticate** with your Authentik credentials
5. **You should be redirected** back to Proxmox, logged in as `rblundon@authentik`

---

## Part 5: DNS Records (if not already created)

On `monorail` (Technitium DNS), ensure each Proxmox node has an A record:

```
main-street-usa.local.mk-labs.cloud.   A   10.1.71.11
tomorrowland.local.mk-labs.cloud.      A   10.1.71.12
fantasyland.local.mk-labs.cloud.       A   10.1.71.13
```

Also ensure `authentik.local.mk-labs.cloud` points to `lightning-lane` (`10.1.71.35`).

---

## Troubleshooting

**"OIDC request failed (500)"**
- Proxmox must be able to reach Authentik's HTTPS endpoint. Verify from a Proxmox node:
  ```bash
  curl -s https://authentik.local.mk-labs.cloud/application/o/proxmox/.well-known/openid-configuration | jq .
  ```
- If using a non-public CA, add it to each Proxmox host:
  ```bash
  cp your-ca.crt /usr/local/share/ca-certificates/
  update-ca-certificates
  ```

**"User name too long" error**
- Ensure `username-claim` is set to `username`, not `sub` (the default `sub` generates a UUID that exceeds Proxmox's username length limit)

**Redirect URI mismatch**
- The redirect URIs in Authentik must exactly match the URL you access Proxmox from, including port and absence of trailing slash

**User logs in but has no permissions**
- The ACL task in the playbook grants `Administrator` to `rblundon@authentik`. Verify with:
  ```bash
  pveum acl list
  pveum user list
  ```

---

## File Reference

```
ansible/
├── roles/proxmox/
│   ├── defaults/main.yml           # Default OIDC variables
│   └── tasks/
│       ├── main.yml                # Includes oidc.yml
│       └── oidc.yml                # OIDC realm + ACL tasks
├── group_vars/proxmox/
│   ├── oidc.yml                    # OIDC config values
│   └── vault.yml                   # Client ID/Secret (encrypted)
└── playbooks/
    └── configure_proxmox_oidc.yml  # Run against main-street-usa
```
