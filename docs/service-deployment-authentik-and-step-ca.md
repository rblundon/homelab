# Deploying Authentik (guest-relations) & Smallstep step-ca (turnstile)

## Overview

This guide documents the full deployment process for two services in the mk-labs homelab:

- **Authentik** — Identity provider and SSO platform, running on `guest-relations` (10.1.71.40)
- **Smallstep step-ca** — SSH Certificate Authority, running on `turnstile` (10.1.71.34)

Both follow the same provisioning pattern: Terraform creates the VM → Ansible configures the OS and deploys the application → Traefik provides reverse proxy and TLS termination (Authentik only; step-ca is accessed directly) → Authentik OIDC applications are codified as blueprints.

**Prerequisites:**

- Proxmox cluster (`magic-kingdom`) operational
- `city-hall` VM with Terraform CLI, Ansible CLI, Boilerplates CLI, and GitHub CLI (`gh`) installed
- `lightning-lane` (10.1.71.35) running Traefik with Cloudflare DNS-01 wildcard certs
- `monorail` (10.1.71.20) running Technitium DNS for `local.mk-labs.cloud`
- Ansible vault configured at `ansible/group_vars/all/vault`

---

## Part 1: Deploying Authentik (guest-relations)

Authentik is a Tier 1 service — it runs outside Kubernetes because other services depend on it for authentication. As of version 2025.10, Redis is no longer required — all caching, tasks, and WebSocket connections have been migrated to PostgreSQL. It runs three containers: server, worker, and PostgreSQL.

### 1.1 Create the Terraform tfvars

Create `terraform/proxmox/hosts/tfvars/guest-relations.tfvars`:

```hcl
# guest-relations — Authentik Identity Provider / SSO
# VM ID convention: third_octet × 1000 + fourth_octet = 71040

hostname      = "guest-relations"
vm_id         = 71040
ip_address    = "10.1.71.40"
target_node   = "main-street-usa"
template_name = "ubuntu-24.04-medium"

# Bootstrap mode — no n8n/NetBox pipeline available yet
started  = true
use_dhcp = false
```

> **Note:** The medium template (2 vCPU / 4GB RAM / 16GB disk) is used because Authentik runs PostgreSQL alongside the application containers.

### 1.2 Provision the VM with Terraform

```bash
cd terraform/proxmox/hosts
terraform apply \
  -var-file="tfvars/guest-relations.tfvars" \
  -state="states/guest-relations.tfstate" \
  -var="proxmox_api_url=https://main-street-usa.local.mk-labs.cloud:8006" \
  -var="proxmox_api_token=terraform@pve!automation=<token>"
```

After Terraform completes, create a DHCP reservation in UniFi for `10.1.71.40` and start the VM.

### 1.3 Create DNS records on monorail

On `monorail` (Technitium DNS), create:

- **A record:** `guest-relations.local.mk-labs.cloud` → `10.1.71.40` (direct access)
- **A record:** `authentik.local.mk-labs.cloud` → `10.1.71.35` (points to lightning-lane for Traefik routing)

> **Critical rule:** All services behind Traefik must have their service DNS pointing to `lightning-lane` (10.1.71.35), not the backend VM's IP. Traefik routes based on the `Host()` header.

### 1.4 Generate the Compose stack with Boilerplates

On `city-hall`, generate the Authentik boilerplate:

```bash
boilerplates compose generate authentik
```

Use these settings during generation:

- `traefik_enabled: false` (Authentik is on a different VM than Traefik, so Docker labels won't work — we use Traefik's dynamic file config instead)

The boilerplate auto-generates three secrets:

- `AUTHENTIK_SECRET_KEY`
- `DATABASE_PASSWORD`
- `AUTHENTIK_ADMIN_PASSWORD`

Save these somewhere safe — the admin password is needed for first login.

Commit the generated files to `boilerplates/authentik/` at the repo root. Review the `compose.yaml` for any `None` placeholder values left by the boilerplate (timezone, network names, etc.) and fix them.

> **Post-2025.10:** If the boilerplate generates a Redis service, remove it. Authentik 2025.10+ no longer requires Redis. If upgrading from an older version and you see an orphan `authentik-redis` container warning, clean it up with `docker compose down --remove-orphans && docker compose up -d`.

### 1.5 Store secrets in Ansible Vault

Add Authentik secrets and OIDC blueprint credentials to `ansible/group_vars/all/vault`:

```bash
ansible-vault edit ansible/group_vars/all/vault
```

Add:

```yaml
# Authentik application secrets
authentik_secret_key: "<generated-secret-key>"
authentik_admin_password: "<generated-admin-password>"
authentik_database_password: "<generated-database-password>"

# OIDC client credentials for blueprints (pre-generated)
vault_proxmox_oidc_client_id: "<pre-generated-client-id>"
vault_proxmox_oidc_client_secret: "<pre-generated-client-secret>"
vault_stepca_oidc_client_id: "<pre-generated-client-id>"
vault_stepca_oidc_client_secret: "<pre-generated-client-secret>"
```

Pre-generate client IDs and secrets:

```python
python3 -c "
import secrets, string
def gen_id(): return secrets.token_hex(20)
def gen_secret(): return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(128))
print(f'Client ID:     {gen_id()}')
print(f'Client Secret: {gen_secret()}')
"
```

### 1.6 Create Authentik Blueprints

Blueprints are declarative YAML files that codify Authentik OIDC providers and applications. They are mounted into the Authentik container and applied automatically.

> **Critical:** Blueprint files must use the `.yaml` extension, not `.yml`. Authentik's blueprint discovery only scans for `.yaml` files.

> **Critical:** Use the `!Env` YAML tag to reference environment variables in blueprints, not `${VAR}` shell-style substitution. Example: `client_id: !Env STEPCA_OIDC_CLIENT_ID`

Create `boilerplates/authentik/blueprints/step-ca.yaml`:

```yaml
version: 1
metadata:
  name: mk-labs-step-ca
  labels:
    blueprints.goauthentik.io/instantiate: "true"
entries:
  - model: authentik_providers_oauth2.oauth2provider
    id: step-ca-provider
    state: present
    identifiers:
      name: "Provider for step-ca"
    attrs:
      authorization_flow: !Find [authentik_flows.flow, [slug, default-provider-authorization-implicit-consent]]
      invalidation_flow: !Find [authentik_flows.flow, [slug, default-provider-invalidation-flow]]
      client_type: confidential
      client_id: !Env STEPCA_OIDC_CLIENT_ID
      client_secret: !Env STEPCA_OIDC_CLIENT_SECRET
      redirect_uris:
        - url: "http://127.0.0.1:10000"
          matching_mode: strict
      sub_mode: hashed_user_id
      property_mappings:
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, openid]]
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, email]]
        - !Find [authentik_providers_oauth2.scopemapping, [scope_name, profile]]
      signing_key: !Find [authentik_crypto.certificatekeypair, [name, authentik Self-signed Certificate]]

  - model: authentik_core.application
    id: step-ca-application
    state: present
    identifiers:
      slug: step-ca
    attrs:
      name: "step-ca"
      provider: !KeyOf step-ca-provider
      group: "Infrastructure"
      policy_engine_mode: any
```

Create `boilerplates/authentik/blueprints/proxmox.yaml` following the same pattern, with `PROXMOX_OIDC_CLIENT_ID` / `PROXMOX_OIDC_CLIENT_SECRET` env vars and redirect URIs for each Proxmox node (`https://<hostname>:8006`, no trailing slash).

### 1.7 Update the Compose file for blueprints

The `compose.yaml` needs two additions to both the `authentik` (server) and `authentik_worker` services:

1. A volume mount for custom blueprints: `./blueprints:/blueprints/custom:ro`
2. Environment variables for OIDC credentials consumed by blueprints via `!Env`:

```yaml
environment:
  # ... existing vars ...
  - PROXMOX_OIDC_CLIENT_ID=${PROXMOX_OIDC_CLIENT_ID}
  - PROXMOX_OIDC_CLIENT_SECRET=${PROXMOX_OIDC_CLIENT_SECRET}
  - STEPCA_OIDC_CLIENT_ID=${STEPCA_OIDC_CLIENT_ID}
  - STEPCA_OIDC_CLIENT_SECRET=${STEPCA_OIDC_CLIENT_SECRET}
volumes:
  # ... existing volumes ...
  - ./blueprints:/blueprints/custom:ro
```

The `.env` file (templated by Ansible) provides the actual values from vault.

### 1.8 Create the Ansible role and inventory

**Inventory entry** — add to `ansible/inventory.yml`:

```yaml
authentik_server:
  hosts:
    guest_relations:
      ansible_host: 10.1.71.40
      ansible_become: true
```

**Host vars** — create `ansible/host_vars/guest_relations/vars`:

```yaml
---
ip_address: 10.1.71.40
app_role: identity_provider
app_name: authentik
app_deployment: docker_compose
```

**Ansible role** — create `ansible/roles/authentik/` with:

- `tasks/main.yml` — creates the application directory, copies `compose.yaml` from `boilerplates/authentik/`, syncs the `blueprints/` directory, templates the `.env` file with vault secrets including OIDC credentials, and starts the stack
- `defaults/main.yml` — sets `authentik_base_dir: /opt/docker/authentik`
- `handlers/main.yml` — `restart authentik` handler using `docker_compose_v2`
- `templates/env.j2` — injects all secrets from vault including blueprint OIDC credentials

**Playbook** — create `ansible/playbooks/deploy_authentik.yml`:

```yaml
---
- name: Deploy Authentik identity provider
  hosts: authentik_server
  become: true
  roles:
    - common
    - docker-host
    - authentik
```

### 1.9 Deploy with Ansible

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/deploy_authentik.yml
```

This runs three roles in sequence: `common` (hostname, timezone, base packages, Chrony NTP pointing to sundial) → `docker-host` (Docker CE, adds `wed` user to docker group) → `authentik` (Compose stack + blueprints).

Authentik will discover and apply the blueprints within a minute of startup. Verify in the admin UI under **Customization → Blueprints** and **Applications → Applications**.

### 1.10 Create the Traefik dynamic config

Create `boilerplates/traefik/dynamic/authentik.yml`:

```yaml
http:
  routers:
    authentik:
      rule: "Host(`authentik.local.mk-labs.cloud`)"
      entryPoints:
        - websecure
      service: authentik
      tls:
        certResolver: cloudflare
      middlewares:
        - security-headers

  services:
    authentik:
      loadBalancer:
        servers:
          - url: "http://10.1.71.40:8000"

  middlewares:
    authentik-forwardauth:
      forwardAuth:
        address: "http://10.1.71.40:8000/outpost.goauthentik.io/auth/nginx"
        trustForwardHeader: true
        authResponseHeaders:
          - X-authentik-username
          - X-authentik-groups
          - X-authentik-email
          - X-authentik-name
          - X-authentik-uid
          - X-authentik-jwt
          - X-authentik-meta-jwks
          - X-authentik-meta-outpost
          - X-authentik-meta-provider
          - X-authentik-meta-app
          - X-authentik-meta-version
```

Deploy to lightning-lane:

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/update_traefik_routes.yml
```

### 1.11 Verify the deployment

Check all three containers are healthy on guest-relations:

```bash
ssh wed@guest-relations.local.mk-labs.cloud docker ps
```

Expected output: `authentik-server`, `authentik-worker`, and `authentik-postgres` all with status `Up ... (healthy)`.

Access `https://authentik.local.mk-labs.cloud` and log in with:

- Username: `akadmin`
- Password: the `AUTHENTIK_ADMIN_PASSWORD` from vault

### 1.12 Create your user in Authentik

Do not use `akadmin` for day-to-day logins. Create a dedicated user:

1. Log in as `akadmin` at `https://authentik.local.mk-labs.cloud/if/admin/`
2. Go to **Directory → Users → Create**
3. Set username to `rblundon`, fill in email and display name, mark as active
4. Set a password
5. Optionally create a `proxmox-admins` group under **Directory → Groups** and add `rblundon` to it

> Keep `rblundon` as a regular user (not an Authentik admin). Use `akadmin` for Authentik administration, `rblundon` for logging into downstream services. These are separate privilege domains.

---

## Part 2: Configuring Proxmox OIDC with Authentik

This configures SSO for the `magic-kingdom` Proxmox cluster using Authentik as the OIDC identity provider. The realm configuration is cluster-wide (stored in `/etc/pve/domains.cfg`), so it only needs to run against one node.

> **Note:** The Proxmox OIDC application is codified as a blueprint (see Part 1.6). The provider and application are created automatically when Authentik starts with the blueprint mounted. The steps below cover the Proxmox-side realm configuration only.

### 2.1 Store credentials in Ansible Vault

The Proxmox OIDC client credentials are the same pre-generated values used in the blueprint. Store them in `ansible/group_vars/proxmox/vault.yml`:

```bash
ansible-vault create group_vars/proxmox/vault.yml
```

```yaml
vault_proxmox_oidc_client_id: "<same-client-id-as-blueprint>"
vault_proxmox_oidc_client_key: "<same-client-secret-as-blueprint>"
```

### 2.2 Run the Ansible playbook (first pass — realm only)

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/configure_proxmox_oidc.yml
```

**The ACL task will fail on the first run.** This is expected — the user `rblundon@authentik` doesn't exist in Proxmox until the first OIDC login (the realm is configured with `--autocreate 1`).

### 2.3 First OIDC login

1. Open `https://main-street-usa.local.mk-labs.cloud:8006`
2. Change the realm dropdown to **authentik**
3. Click Login — you'll be redirected to Authentik
4. Sign in as `rblundon`

> **Gotcha:** If you're already logged into Authentik as `akadmin`, you'll be auto-logged in as akadmin. Log out of Authentik first at `https://authentik.local.mk-labs.cloud/if/flow/default-invalidation-flow/` or use an incognito window.

### 2.4 Run the Ansible playbook (second pass — ACL)

```bash
ansible-playbook -i inventory.yml playbooks/configure_proxmox_oidc.yml
```

The ACL task grants `rblundon@authentik` the `Administrator` role at path `/`.

### 2.5 Ansible implementation notes

- Tasks use `ansible.builtin.shell` (not `command`) because `command` splits multi-word `--scopes` arguments into separate args, breaking `pveum`
- `--username-claim` is only valid on `pveum realm add`, not `pveum realm modify`
- `no_log: true` is set on realm tasks to keep the client secret out of Ansible output
- The playbook targets only `main-street-usa` since realm config is cluster-wide via pmxcfs

---

## Part 3: Deploying step-ca (turnstile)

step-ca is a lightweight SSH Certificate Authority that issues short-lived certificates authenticated via OIDC through Authentik. It eliminates SSH key management — no more `authorized_keys` files across hosts.

> **History:** The `turnstile` hostname was originally assigned to Authentik. Authentik was renamed to `guest-relations`, freeing `turnstile` for step-ca.

### 3.1 Create the Terraform tfvars

Create `terraform/proxmox/hosts/tfvars/turnstile.tfvars`:

```hcl
# turnstile — Smallstep step-ca SSH Certificate Authority
# VM ID convention: 71000 + 34 = 71034

hostname      = "turnstile"
vm_id         = 71034
ip_address    = "10.1.71.34"
target_node   = "fantasyland"
clone_node    = "fantasyland"
template_name = "ubuntu-24.04-small"
datastore     = "liberty-tree"
vlan_id       = 71
bridge        = "vmbr0"
dns_servers   = ["10.1.71.1"]
search_domain = "local.mk-labs.cloud"
```

### 3.2 Provision the VM with Terraform

```bash
cd terraform/proxmox/hosts
terraform apply \
  -var-file="tfvars/turnstile.tfvars" \
  -state="states/turnstile.tfstate" \
  -var="proxmox_api_url=https://fantasyland.local.mk-labs.cloud:8006" \
  -var="proxmox_api_token=terraform@pve!automation=<token>"
```

Create a DHCP reservation in UniFi for `10.1.71.34` and start the VM.

### 3.3 Create DNS record on monorail

- **A record:** `turnstile.local.mk-labs.cloud` → `10.1.71.34` (direct access — step-ca is NOT behind Traefik)

> **Note:** Unlike other services, step-ca is accessed directly on port 9000, not through Traefik. The `step` CLI needs to talk to the CA API with its own TLS trust chain.

### 3.4 Create the Ansible role and inventory

**Vault secrets** — create `ansible/host_vars/turnstile/vault`:

```yaml
stepca_ca_password: "<strong-password>"
stepca_oidc_client_id: "<same-client-id-as-blueprint>"
stepca_oidc_client_secret: "<same-client-secret-as-blueprint>"
```

**Host vars** — create `ansible/host_vars/turnstile/vars`:

```yaml
---
ip_address: 10.1.71.34
app_role: ssh_certificate_authority
app_name: step-ca
app_deployment: docker_compose

stepca_hostname: turnstile.local.mk-labs.cloud
stepca_dns_names: "turnstile.local.mk-labs.cloud,10.1.71.34"
stepca_ssh_enabled: true
stepca_listen_port: 9000

stepca_oidc_provisioner_name: authentik
stepca_oidc_configuration_endpoint: "https://authentik.local.mk-labs.cloud/application/o/step-ca/.well-known/openid-configuration"
stepca_oidc_listen_address: ":10000"
stepca_oidc_domains:
  - "local.mk-labs.cloud"
  - "protonmail.com"
```

> **Important:** The `stepca_oidc_domains` list must include every email domain that users in Authentik have. step-ca validates the OIDC token's email claim against this list and rejects any domain not listed.

**Ansible role** includes `templates/patch_oidc_provisioner.py.j2` which patches `ca.json` post-init to ensure the OIDC provisioner has correct domains, client ID, and secret. This is idempotent and eliminates the need for manual `step ca provisioner add`.

> **Init container gotcha:** The step-ca data directory must be owned by UID 1000 (`step` user), not root.

### 3.5 Deploy with Ansible

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/deploy_step_ca.yml
```

Note the CA fingerprint from the init output.

### 3.6 Bootstrap your workstation

```bash
step ca bootstrap --ca-url https://turnstile.local.mk-labs.cloud:9000 --fingerprint <ca-fingerprint>
```

Ensure your SSH agent is running:

```bash
eval "$(ssh-agent -s)"
```

### 3.7 Daily SSH workflow

```bash
step ssh login rblundon@local.mk-labs.cloud --provisioner authentik
```

This opens your browser to Authentik, you authenticate, and step-ca issues a short-lived SSH certificate (default 16 hours) loaded into your SSH agent.

Verify:

```bash
step ssh list
ssh-add -l
```

---

## Part 4: Host enrollment for step-ca

Host enrollment configures VMs to trust SSH certificates signed by step-ca and to present their own CA-signed host certificates.

### 4.1 Group variables

Add to `ansible/group_vars/all/`:

```yaml
# step-ca client configuration
step_ca_url: "https://turnstile.local.mk-labs.cloud:9000"
step_ca_fingerprint: "<root-ca-fingerprint>"
step_ca_provisioner_name: "admin"

# Principal-to-user mapping
step_ca_principal_mappings:
  - local_user: wed
    principals:
      - ryan.blundon@protonmail.com
      - ryan.blundon
      - ryanblundon
  - local_user: rblundon
    principals:
      - ryan.blundon@protonmail.com
      - ryan.blundon
      - ryanblundon
```

> **Why principal mappings?** The SSH certificate contains principals derived from your Authentik email (e.g., `ryan.blundon@protonmail.com`). When you `ssh wed@host`, sshd checks if any of `wed`'s authorized principals match the certificate. Without this mapping, certificate auth silently falls through to password auth.

### 4.2 What the enrollment role does

The `step_ca_client.yml` tasks:

1. **Install step CLI** — from Smallstep's apt repository
2. **Bootstrap CA trust** — `step ca bootstrap` to trust the CA's root certificate
3. **Configure user certificate trust** — writes SSH user CA public key, adds `TrustedUserCAKeys` to sshd_config
4. **Create authorized principals directory** — `/etc/ssh/auth_principals/`
5. **Create authorized principals files** — maps certificate principals to local users (e.g., `/etc/ssh/auth_principals/wed`)
6. **Configure AuthorizedPrincipalsFile** — adds `AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u` to sshd_config
7. **Sign host certificate** — generates a one-time token (delegated to Ansible controller) and signs the host's ECDSA key
8. **Configure sshd for host certificate** — adds `HostCertificate` and `HostKey` directives
9. **Automated renewal** — systemd timer for weekly host certificate renewal using SSHPOP

### 4.3 Enroll a host

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/deploy_common.yml -e target=scrim
```

> **Note:** The enrollment role requires Ubuntu (uses apt). Fedora hosts will fail on the step CLI install task.

> **Note:** The `step` CLI must be installed and bootstrapped on the Ansible controller (`city-hall`) for the `delegate_to: localhost` token generation tasks.

### 4.4 Test SSH with certificates

```bash
step ssh login rblundon@local.mk-labs.cloud --provisioner authentik
ssh scrim
```

Verify certificate authentication:

```bash
ssh -v scrim 2>&1 | grep -E "Offering|certificate|CERT"
```

### 4.5 SSH config for short hostnames

If `local.mk-labs.cloud` is configured as a DNS search domain on your workstation, short hostnames resolve automatically.

Recommended `~/.ssh/config`:

```
# mk-labs hosts — certificate auth via step-ca
Host *.local.mk-labs.cloud
    User wed

# Short name resolution for mk-labs hosts
Host !10.1.71.* !*.local.mk-labs.cloud *
    Match exec "nslookup %h.local.mk-labs.cloud >/dev/null 2>&1"
    HostName %h.local.mk-labs.cloud
    User wed

# Fallback key auth for hosts not yet enrolled
Host city-hall
    HostName city-hall
    User wed
    IdentityFile ~/.ssh/ansible
```

> Do NOT use `IdentitiesOnly yes` for mk-labs hosts — this prevents SSH from offering the certificate from the agent.

---

## Appendix A: Troubleshooting

### Authentik

**Connection reset when hitting authentik.local.mk-labs.cloud** — verify DNS resolves to `10.1.71.35` (lightning-lane), check Traefik dashboard for router errors, verify Traefik can reach backend.

**Auto-logged in as akadmin instead of rblundon** — log out of Authentik at the invalidation flow URL or use incognito.

**Orphan Redis container warning** — run `docker compose down --remove-orphans && docker compose up -d`. Redis was removed in Authentik 2025.10.

### Authentik Blueprints

**Blueprints not discovered** — verify `.yaml` extension (not `.yml`). Check volume mount with `docker exec authentik-worker ls -la /blueprints/custom/`.

**OIDC client ID is literal `${VAR}` text** — use `!Env VAR_NAME` YAML tag, not `${VAR_NAME}`. Verify env vars in container with `docker exec authentik-worker env | grep STEPCA`.

### Proxmox OIDC

**"too many arguments" from pveum** — use `ansible.builtin.shell` with single-quoted `--scopes 'openid email profile'`.

**"Unknown option: username-claim" on modify** — only valid on `pveum realm add`. Delete realm and re-add.

**ACL update failed: user does not exist** — expected on first run. Log in via OIDC first, then re-run.

**Redirect URI mismatch** — must exactly match including `:8006` port and no trailing slash.

### step-ca

**"email is not allowed"** — add the user's email domain to `stepca_oidc_domains` in host_vars.

**"permission denied" during init** — fix data directory ownership: `sudo chown -R 1000:1000 /opt/docker/step-ca/data`.

**"no such file or directory: password"** — secrets directory and password file must be created before init runs.

**REMOTE HOST IDENTIFICATION HAS CHANGED** — clear old key: `ssh-keygen -f ~/.ssh/known_hosts -R <hostname>`. Goes away permanently once host certificates are enrolled.

### SSH Certificate Authentication

**Certificate offered but server rejects it** — check `AuthorizedPrincipalsFile` directive in sshd_config, verify `/etc/ssh/auth_principals/<user>` exists with matching principals, inspect cert with `step ssh list --raw | step ssh inspect`.

**"Could not open a connection to your authentication agent"** — start agent with `eval "$(ssh-agent -s)"`, re-run `step ssh login`.

**Short hostname asks for password but FQDN works** — ensure search domain is configured, ensure no `IdentitiesOnly yes` blocking the agent cert.

---

## Appendix B: File reference

```
homelab/
├── terraform/proxmox/hosts/
│   ├── tfvars/
│   │   ├── guest-relations.tfvars
│   │   └── turnstile.tfvars
│   └── states/                         (gitignored)
├── boilerplates/
│   ├── authentik/
│   │   ├── compose.yaml                (with blueprints volume mount)
│   │   └── blueprints/
│   │       ├── proxmox.yaml            (must be .yaml not .yml)
│   │       └── step-ca.yaml            (must be .yaml not .yml)
│   └── traefik/
│       └── dynamic/
│           └── authentik.yml
├── ansible/
│   ├── inventory.yml
│   ├── roles/
│   │   ├── common/
│   │   │   ├── tasks/
│   │   │   │   ├── main.yml
│   │   │   │   └── step_ca_client.yml
│   │   │   └── handlers/main.yml
│   │   ├── docker-host/
│   │   ├── authentik/
│   │   │   ├── tasks/main.yml
│   │   │   ├── defaults/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   └── templates/env.j2
│   │   ├── step-ca/
│   │   │   ├── tasks/main.yml
│   │   │   ├── defaults/main.yml
│   │   │   ├── handlers/main.yml
│   │   │   └── templates/
│   │   │       ├── compose.yaml.j2
│   │   │       ├── env.j2
│   │   │       └── patch_oidc_provisioner.py.j2
│   │   └── proxmox/
│   │       ├── defaults/main.yml
│   │       └── tasks/
│   │           ├── main.yml
│   │           └── oidc.yml
│   ├── host_vars/
│   │   ├── guest_relations/vars
│   │   └── turnstile/
│   │       ├── vars
│   │       └── vault                   (encrypted)
│   ├── group_vars/
│   │   ├── all/
│   │   │   ├── vault                   (encrypted)
│   │   │   └── step_ca.yml
│   │   └── proxmox/
│   │       ├── oidc.yml
│   │       └── vault.yml               (encrypted)
│   └── playbooks/
│       ├── deploy_authentik.yml
│       ├── deploy_step_ca.yml
│       ├── deploy_common.yml
│       ├── enroll_step_ca_client.yml
│       ├── configure_proxmox_oidc.yml
│       └── update_traefik_routes.yml
└── docs/guides/
    └── service-deployment-authentik-and-step-ca.md
```

---

## Appendix C: Key decisions and learnings

- **Boilerplate-first for Compose** — if a Boilerplates CLI template exists, use it. Ansible copies the generated files; it does not template them. Only the `.env` is templated to inject vault secrets. step-ca has no boilerplate, so Ansible templates the compose file directly.
- **Traefik routing for cross-host services** — Docker labels only work when the service and Traefik share a Docker network (same host). For services on separate VMs, use Traefik's dynamic file configuration with the backend's raw IP and port.
- **DNS always points to lightning-lane** — service hostnames resolve to `10.1.71.35`, not to the backend VM. Exception: step-ca is accessed directly (port 9000) because the `step` CLI needs to trust the CA's own certificate chain.
- **Two-pass playbook for Proxmox OIDC** — the ACL task requires the user to exist in Proxmox, but the user is only created on first OIDC login. Run the playbook once (realm creation), log in, then run again (ACL assignment).
- **`pveum` CLI quirks** — multi-word `--scopes` arguments need `ansible.builtin.shell` with single-quoted values; `--username-claim` is only valid on `realm add`, not `realm modify`.
- **Naming convention** — Authentik was renamed from `turnstile` to `guest-relations` to free the `turnstile` hostname for step-ca. Service-facing DNS was unaffected because it points to Traefik, not the VM.
- **Authentik blueprints** — use `.yaml` extension (not `.yml`), use `!Env VAR_NAME` tag (not `${VAR_NAME}`) for environment variable substitution, mount at `/blueprints/custom:ro` in both server and worker containers.
- **Redis removed in Authentik 2025.10** — all caching uses PostgreSQL. Remove Redis from compose if upgrading.
- **Pre-generated OIDC credentials** — client IDs and secrets are pre-generated and stored in vault, shared between the blueprint (provider side) and the consuming service's vault (client side).
- **OIDC domain validation in step-ca** — the `--domain` flag restricts which email domains are accepted. Every Authentik user's email domain must be listed.
- **SSH principal mapping** — certificates contain principals derived from the OIDC email. `AuthorizedPrincipalsFile` maps certificate principals to local users. Without this, certificate auth silently falls through to password auth.
- **step-ca data directory ownership** — container runs as UID 1000. Directories created by Ansible as root cause "permission denied" during init.
