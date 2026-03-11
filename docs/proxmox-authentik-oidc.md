# Proxmox VE + Authentik OIDC Integration Guide

## Overview

This guide configures SSO for the `magic-kingdom` Proxmox cluster using Authentik as the OpenID Connect identity provider. The realm configuration is cluster-wide (stored in `/etc/pve/domains.cfg`), so it only needs to be applied to one node.

**Components:**
- **Authentik** — `authentik.local.mk-labs.cloud` (behind lightning-lane/Traefik at `10.1.71.35`)
- **Proxmox cluster** — `main-street-usa` (.11), `tomorrowland` (.12), `fantasyland` (.13)

---

## Part 1: Create a User in Authentik

Before configuring the OIDC provider, create a dedicated user for yourself. Do not use the built-in `akadmin` account for day-to-day logins.

1. Log in to Authentik admin at `https://authentik.local.mk-labs.cloud/if/admin/` as `akadmin`
2. Go to **Directory → Users → Create**
3. Set:
   - Username: `rblundon`
   - Email: your email
   - Name: your display name
   - Is active: checked
4. Set a password
5. Optionally create a `proxmox-admins` group under **Directory → Groups** and add `rblundon` to it

> **Note:** Keep `rblundon` as a regular user (not an Authentik admin). Authentik admin privileges and Proxmox admin privileges are separate concerns. Use `akadmin` for Authentik configuration, and `rblundon` for logging into services.

---

## Part 2: Create the Authentik OIDC Provider (Manual)

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

## Part 3: Store Credentials in Ansible Vault

```bash
cd ~/homelab/ansible

# Create the vault file (if it doesn't exist)
ansible-vault create group_vars/proxmox/vault.yml

# Add these variables:
vault_proxmox_oidc_client_id: "<client-id-from-step-11>"
vault_proxmox_oidc_client_key: "<client-secret-from-step-11>"
```

---

## Part 4: Run the Ansible Playbook (First Pass — Realm Only)

The playbook has two stages: realm creation and ACL assignment. On the first run, the ACL task will fail because the user `rblundon@authentik` doesn't exist in Proxmox yet — it gets auto-created on first login. **This is expected.**

```bash
cd ~/homelab/ansible
ansible-playbook -i inventory.yml playbooks/configure_proxmox_oidc.yml
```

Expected result:
- ✅ "Add OIDC realm for Authentik" — **changed**
- ⏭️ "Update OIDC realm for Authentik" — **skipped** (realm was just created)
- ❌ "Configure ACL entries for OIDC users" — **failed** (user doesn't exist yet, this is OK)

---

## Part 5: First Login (Creates the User in Proxmox)

This step is required before ACLs can be assigned. The first OIDC login triggers Proxmox's autocreate, which adds the user to `/etc/pve/user.cfg`.

1. **Log out of Authentik** first — go to `https://authentik.local.mk-labs.cloud/if/flow/default-invalidation-flow/` to end any existing session (otherwise it may auto-login as `akadmin`)
2. **Open** `https://main-street-usa.local.mk-labs.cloud:8006`
3. **Change the realm dropdown** from `Linux PAM` to `authentik`
4. **Click Login** — you'll be redirected to Authentik
5. **Sign in as `rblundon`** (not `akadmin`)
6. You'll be redirected back to Proxmox, logged in as `rblundon@authentik`

> **Note:** At this point you'll be logged in but with **no permissions**. This is expected — the ACL hasn't been applied yet. You can verify the user was created by logging in as `root@pam` and checking Datacenter → Permissions → Users.

> **Gotcha:** If you're already logged into Authentik as `akadmin` in the same browser, the OIDC flow will auto-login as `akadmin` instead of `rblundon`. Use a private/incognito window or log out of Authentik first.

---

## Part 6: Run the Ansible Playbook (Second Pass — ACL)

Now that `rblundon@authentik` exists in Proxmox, re-run the playbook to apply permissions:

```bash
ansible-playbook -i inventory.yml playbooks/configure_proxmox_oidc.yml
```

Expected result:
- ⏭️ "Add OIDC realm for Authentik" — **skipped** (realm already exists)
- ✅ "Update OIDC realm for Authentik" — **changed** (updates config)
- ✅ "Configure ACL entries for OIDC users" — **changed** (grants Administrator)

After this, log out and log back in via the Authentik realm. You'll now have full `Administrator` access.

---

## Part 7: DNS Records (if not already created)

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
- The redirect URIs in Authentik must exactly match the URL you access Proxmox from, including port and no trailing slash

**Auto-logging in as the wrong Authentik user**
- If you're signed into Authentik as `akadmin` in your browser, the OIDC redirect will auto-login as `akadmin`. Log out of Authentik first at `https://authentik.local.mk-labs.cloud/if/flow/default-invalidation-flow/` or use a private/incognito window.

**User logs in but has no permissions**
- The ACL task requires the user to exist in Proxmox first (created by the first OIDC login with `autocreate` enabled). Run the playbook a second time after the first login. Verify with:
  ```bash
  pveum user list
  pveum acl list
  ```

**"too many arguments" error from pveum**
- The `--scopes` value must be a single quoted string: `'openid email profile'`. The Ansible tasks use `ansible.builtin.shell` (not `command`) to preserve quoting.

**"Unknown option: username-claim" on pveum realm modify**
- `--username-claim` is only valid on `pveum realm add`, not `pveum realm modify`. If you need to change it, delete the realm and re-add it:
  ```bash
  pveum realm remove authentik
  # Then re-run the playbook
  ```

---

## Ansible Implementation Notes

- The tasks use `ansible.builtin.shell` instead of `ansible.builtin.command` because `command` splits multi-word arguments (like `openid email profile`) into separate args, breaking `pveum`
- `no_log: true` is set on realm tasks to keep the client secret out of Ansible output — temporarily set to `false` when debugging
- `pveum realm modify` does not support `--username-claim` — this can only be set during `pveum realm add`
- The playbook targets only `main-street-usa` since realm config is cluster-wide via pmxcfs

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
