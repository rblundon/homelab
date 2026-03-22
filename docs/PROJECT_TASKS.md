# mk-labs Project Tasks

> **Project Goal:** Build the NetBox automation pipeline and validate it end-to-end by deploying Nextcloud as the first workload, with external access via Cloudflare Tunnel.
>
> **Pipeline flow:** NetBox (`fire-station`) → n8n (`tiki-room`) → Terraform (`city-hall`) → Ansible/Semaphore (`imagineering`) → Proxmox (`magic-kingdom`)
>
> **Status key:** `[ ]` = To do · `[x]` = Done · `[~]` = In progress · `[-]` = Skipped/Deferred

---

## Phase 0: Repository Restructuring ✅

| # | Task | Done By | Status |
|---|------|---------|--------|
| 0.1 | ~~Create `archive/pre-mk-labs` branch from current `main`~~ | — | `[x]` |
| 0.2 | ~~Restructure repo to new directory layout (terraform/, ansible/, n8n/, netbox/, boilerplates/, packer/, talos/, docs/)~~ | — | `[x]` |
| 0.3 | ~~Validate existing Terraform modules and Ansible roles still work from new paths~~ | — | `[x]` |
| 0.4 | ~~Update `ansible.cfg` roles_path for new directory structure~~ | — | `[x]` |

---

## Phase 1: NetBox Deployment & Data Model

> **Depends on:** Phase 0

### 1A: Deploy NetBox (`fire-station`) ✅

> **Note:** `fire-station` LXC deployed via Proxmox helper script. NetBox is configured and working.

| # | Task | Done By | Status |
|---|------|---------|--------|
| 1.1 | ~~Provision `fire-station` (10.1.71.34)~~ — LXC already running | Helper script | `[x]` |
| 1.2 | ~~Deploy NetBox on `fire-station`~~ — installed via helper script | Helper script | `[x]` |
| 1.3 | ~~NetBox configured and operational~~ | Manual | `[x]` |
| 1.4 | Add Traefik dynamic config for `netbox.local.mk-labs.cloud` → `fire-station` | Ansible | `[-]` |
| 1.5 | Create DNS CNAME on `monorail` pointing to `lightning-lane` | Ansible | `[-]` |
| 1.6 | Verify NetBox accessible via `netbox.local.mk-labs.cloud` | Manual | `[-]` |

> **Note:** Tasks 1.4–1.6 deferred. Helper-script Apache install conflicts with Traefik reverse proxy (double Host header issue). NetBox accessible directly at `fire-station.local.mk-labs.cloud`. Will resolve when NetBox is rebuilt as a Compose stack (see P.10).

### 1B: Configure NetBox Data Model

| # | Task | Done By | Status |
|---|------|---------|--------|
| 1.7 | ~~Create `netbox/initializers/custom_fields.yml` in repo~~ | Manual | `[x]` |
| 1.8 | ~~Add custom fields to VM object: `proxmox_template` (selection), `proxmox_node` (selection), `vm_role` (text)~~ — applied from initializers | NetBox | `[x]` |
| 1.9 | ~~Create `netbox/initializers/vlans.yml` — define all VLANs from master table~~ | Manual | `[x]` |
| 1.10 | ~~Create `netbox/initializers/prefixes.yml` — define IP prefixes~~ | Manual | `[x]` |
| 1.11 | Import existing infrastructure into NetBox (Proxmox hosts, existing VMs, IPs) | Manual | `[ ]` |
| 1.12 | Configure NetBox webhook: `VM Staged Trigger` — POST to `http://tiki-room:5678/webhook/vm-provision` on VM status change to `Staged` | NetBox | `[ ]` |
| 1.13 | Test webhook fires correctly on VM status change | Manual | `[ ]` |

---

## Phase 2: Terraform VM Module

> **Depends on:** Phase 0 (repo structure)
> **Note:** `terraform/proxmox/vm/` module exists with `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`. A `test-pipeline-vm` has been run. UDM DHCP module also exists at `terraform/unifi/dhcp/`.

| # | Task | Done By | Status |
|---|------|---------|--------|
| 2.1 | ~~Write `variables.tf`: hostname, ip, vlan, template, proxmox_node~~ | Manual | `[x]` |
| 2.2 | ~~Write `main.tf` using bpg/proxmox provider for VM resource~~ | Manual | `[x]` |
| 2.3 | ~~Test `terraform apply` manually with hardcoded values~~ (`test-pipeline-vm` state exists) | Manual | `[x]` |
| 2.4 | Validate cloud-init baseline config (hostname, SSH key, networking) | Manual | `[ ]` |
| 2.5 | Configure Terraform state backend on `city-hall` | Manual | `[ ]` |

---

## Phase 3: Ansible Baseline Role & Semaphore

> **Depends on:** Phase 0 (repo structure)
> **Note:** `common` role exists (hostname, chrony, packages, sudo). `dns-manager` role exists. `docker-host` role exists. Playbooks for DNS entry creation exist. Semaphore (`imagineering`) is deployed via helper script but not yet configured.

| # | Task | Done By | Status |
|---|------|---------|--------|
| 3.1 | Configure NetBox dynamic inventory plugin (`netbox.yml`) | Manual | `[ ]` |
| 3.2 | ~~Write/update `vm-baseline` role: packages, SSH hardening, Chrony → `sundial`~~ (`common` role exists) | Manual | `[x]` |
| 3.3 | ~~Add DNS registration task to role (Technitium API on `monorail`)~~ (`dns-manager` role + `add_technitium_dns_entry` task exist) | Manual | `[x]` |
| 3.4 | Add NetBox status update task — set VM to `Active` via API on success | Manual | `[ ]` |
| 3.5 | Add NetBox status update task — set VM to `Failed` via API on error | Manual | `[ ]` |
| 3.6 | Redeploy Semaphore (`imagineering`) as VM with Boilerplates Compose stack, then configure: connect to GitHub repo, create job template for `day0_baseline` | Manual | `[ ]` |
| 3.7 | Test Ansible playbook end-to-end via Semaphore manual trigger | Manual | `[ ]` |

---

## Phase 4: n8n Orchestration Workflow

> **Depends on:** Phases 1, 2, 3

### 4A: Deploy & Configure n8n (`tiki-room`) ✅

> **Note:** `tiki-room` and n8n deployed via helper script, configured and working. `imagineering` (Semaphore) deployed via helper script but not yet configured.

| # | Task | Done By | Status |
|---|------|---------|--------|
| 4.1 | ~~Provision `tiki-room` (10.1.71.36)~~ — already running | Helper script | `[x]` |
| 4.2 | ~~Deploy and configure n8n on `tiki-room`~~ — working | Helper script | `[x]` |
| 4.3 | ~~Add Traefik dynamic config for `n8n.local.mk-labs.cloud` → `tiki-room`~~ | Ansible | `[x]` |

### 4B: Build the Provisioning Workflow

> **Note:** `n8n/workflows/VM Provisioning Pipeline.json` and `DNS: Create A Record.json` already exported to repo.

| # | Task | Done By | Status |
|---|------|---------|--------|
| 4.4 | Create n8n webhook node to receive NetBox payload | n8n | `[ ]` |
| 4.5 | Add validation logic: VM status = `Staged`, hostname present, IP assigned, VLAN assigned, `proxmox_template` populated, `proxmox_node` populated | n8n | `[ ]` |
| 4.6 | Add Terraform trigger: SSH to `city-hall`, run `terraform apply` with variables from payload | n8n | `[ ]` |
| 4.7 | Add Semaphore trigger: call Semaphore API to launch `vm-baseline` job template | n8n | `[ ]` |
| 4.8 | Add error handling: set NetBox VM status to `Failed` on any pipeline error | n8n | `[ ]` |
| 4.9 | ~~Export n8n workflow JSON and commit to `n8n/workflows/vm-provisioning.json`~~ (initial export exists) | Manual | `[x]` |

---

## Phase 5: Pipeline Validation — Nextcloud as First Workload

> **Depends on:** Phases 1–4

### 5A: Hostname & IP Allocation

> **Decided:** Hostname `the-grid` · IP `10.1.71.128` · VM ID `71128` · DNS `the-grid.local.mk-labs.cloud` · External `the-grid.mk-labs.cloud`

| # | Task | Done By | Status |
|---|------|---------|--------|
| 5.1 | ~~Select themed hostname for Nextcloud VM~~ → `the-grid` | Manual | `[x]` |
| 5.2 | ~~Allocate IP address from General Applications block (10.1.71.128/25)~~ → `10.1.71.128` | Manual | `[x]` |
| 5.3 | Add hostname and IP to master allocation table in `Homelab_Technical_Decision_Points.md` | Manual | `[ ]` |

### 5B: Pipeline Run

| # | Task | Done By | Status |
|---|------|---------|--------|
| 5.4 | Create Nextcloud VM record in NetBox with all required fields (hostname, IP, VLAN, template, node) — status: `Planned` | NetBox | `[ ]` |
| 5.5 | Set VM status to `Staged` in NetBox to trigger pipeline | NetBox | `[ ]` |
| 5.6 | Verify n8n receives webhook and validates payload | n8n | `[ ]` |
| 5.7 | Verify Terraform provisions VM on Proxmox | Terraform | `[ ]` |
| 5.8 | Verify Ansible configures OS baseline and registers DNS | Ansible | `[ ]` |
| 5.9 | Verify NetBox status updates to `Active` | NetBox | `[ ]` |
| 5.10 | SSH into Nextcloud VM and confirm baseline config | Manual | `[ ]` |

---

## Phase 6: Nextcloud Application Deployment

> **Depends on:** Phase 5 (VM is Active)

### 6A: Compose Stack

| # | Task | Done By | Status |
|---|------|---------|--------|
| 6.1 | Generate Nextcloud Compose file via Boilerplates CLI | Boilerplates | `[ ]` |
| 6.2 | Configure Compose stack: Nextcloud, PostgreSQL, Redis | Manual | `[ ]` |
| 6.3 | Configure NFS mount from `emporium` for Nextcloud user data | Ansible | `[ ]` |
| 6.4 | Deploy Nextcloud containers | Ansible | `[ ]` |
| 6.5 | Verify Nextcloud is running and accessible on VM IP | Manual | `[ ]` |

### 6B: Internal Access (Traefik)

| # | Task | Done By | Status |
|---|------|---------|--------|
| 6.6 | Add Traefik dynamic config for `the-grid.local.mk-labs.cloud` → Nextcloud VM | Ansible | `[ ]` |
| 6.7 | Create DNS record on `monorail` pointing `the-grid.local.mk-labs.cloud` to `lightning-lane` (10.1.71.35) | Ansible | `[ ]` |
| 6.8 | Verify Nextcloud accessible via `the-grid.local.mk-labs.cloud` | Manual | `[ ]` |

### 6C: Authentik OIDC Integration

| # | Task | Done By | Status |
|---|------|---------|--------|
| 6.9 | Create OAuth2/OIDC provider in Authentik (`guest-relations`) for Nextcloud | Manual | `[ ]` |
| 6.10 | Create Authentik application entry for Nextcloud | Manual | `[ ]` |
| 6.11 | Install and configure `user_oidc` app in Nextcloud | Manual | `[ ]` |
| 6.12 | Test SSO login to Nextcloud via Authentik | Manual | `[ ]` |

### 6D: Nextcloud Client Setup

| # | Task | Done By | Status |
|---|------|---------|--------|
| 6.13 | Install Nextcloud desktop client and connect to instance | Manual | `[ ]` |
| 6.14 | Configure file sync folders | Manual | `[ ]` |
| 6.15 | Test file upload/download/sync | Manual | `[ ]` |

---

## Phase 7: Cloudflare Tunnel — External Access

> **Depends on:** Phase 6 (Nextcloud running internally)

### 7A: Cloudflare Zero Trust Setup

| # | Task | Done By | Status |
|---|------|---------|--------|
| 7.1 | Log into Cloudflare Zero Trust dashboard (or set up if first time) | Manual | `[ ]` |
| 7.2 | Create a new Cloudflare Tunnel (named, e.g., `mk-labs-tunnel`) | Cloudflare | `[ ]` |
| 7.3 | Note tunnel token/credentials for `cloudflared` configuration | Manual | `[ ]` |

### 7B: Deploy `cloudflared`

| # | Task | Done By | Status |
|---|------|---------|--------|
| 7.4 | Add `cloudflared` container to Nextcloud's Compose stack (or deploy centrally — decide placement) | Manual | `[ ]` |
| 7.5 | Configure tunnel to route `the-grid.mk-labs.cloud` → `http://localhost:80` (or Traefik) | Manual | `[ ]` |
| 7.6 | Deploy `cloudflared` container | Ansible | `[ ]` |
| 7.7 | Verify tunnel status in Cloudflare dashboard (healthy/connected) | Manual | `[ ]` |

### 7C: DNS & Access Policies

| # | Task | Done By | Status |
|---|------|---------|--------|
| 7.8 | Verify Cloudflare auto-creates CNAME for `the-grid.mk-labs.cloud` → tunnel | Cloudflare | `[ ]` |
| 7.9 | Configure Cloudflare Access policy for `the-grid.mk-labs.cloud` (optional: OIDC via Authentik, IP allowlist, or open) | Cloudflare | `[ ]` |
| 7.10 | Test external access to `the-grid.mk-labs.cloud` from outside the network | Manual | `[ ]` |
| 7.11 | Test Nextcloud desktop/mobile client sync via external URL | Manual | `[ ]` |

---

## Phase 8: Documentation & Cleanup

| # | Task | Done By | Status |
|---|------|---------|--------|
| 8.1 | Update `Homelab_Technical_Decision_Points.md` — add Nextcloud to master hostname table | Manual | `[ ]` |
| 8.2 | Add operational runbook: Section 5.3 — Adding a new service via the NetBox pipeline | Manual | `[ ]` |
| 8.3 | Add operational runbook: Section 5.4 — Configuring Cloudflare Tunnel for external services | Manual | `[ ]` |
| 8.4 | Document Nextcloud-specific gotchas and config notes | Manual | `[ ]` |
| 8.5 | Document pipeline lessons learned and any deviations from the PRD | Manual | `[ ]` |
| 8.6 | Create `docs/guides/nextcloud-deployment.md` | Manual | `[ ]` |
| 8.7 | Create `docs/guides/cloudflare-tunnel-setup.md` | Manual | `[ ]` |

---

## Parking Lot

> Items that came up during planning but aren't part of the current scope. Add things here as they arise.

| # | Item | Notes |
|---|------|-------|
| P.1 | Nextcloud migration to Kubernetes (`fastpass`) | Revisit once TalosOS cluster is stable and ArgoCD patterns established |
| P.2 | `cloudflare-tunnel-ingress-controller` for Kubernetes | Replaces Compose-based `cloudflared` when workloads move to K8s |
| P.3 | Cloudflare Access + Authentik OIDC integration | Layer Authentik as an identity provider in Cloudflare Access policies |
| P.4 | Pipeline notifications (email/messaging on success/failure) | Deferred per PRD — add n8n notification nodes once core pipeline stable |
| P.5 | Remote Terraform state backend | Migrate from local state on `city-hall` to S3-compatible backend on `emporium` |
| P.6 | n8n Git sync (paid tier) | Currently using manual JSON export/commit workflow |
| P.7 | NetBox template auto-sync from Proxmox API | `proxmox_template` dropdown currently maintained manually |
| P.8 | Additional Cloudflare Tunnel services | Pattern established with Nextcloud; extend to other external-facing services |
| P.9 | Nextcloud: Photos backup, Calendar & Contacts | Expand Nextcloud scope beyond file sync |
| P.10 | Ansiblize NetBox LXC (`fire-station`) | Create Ansible role for NetBox Apache vhost config, `wed` user setup, and baseline config. Currently helper-script deployed with no `wed` user. Apache `ServerName` was manually changed from `netbox.example.com` to `netbox.local.mk-labs.cloud`. |
| P.11 | `add_service_route.yml` — remove stale CNAMEs | When a dynamic config is removed from `boilerplates/traefik/dynamic/`, the corresponding CNAME on `monorail` should be cleaned up. Currently the playbook only creates, never deletes. |
| P.12 | Rename existing deploy playbooks to day0/day1 convention | `deploy_authentik.yml` → `day1_deploy_authentik.yml`, `deploy_traefik.yml` → `day1_deploy_traefik.yml`, etc. New playbooks already follow the convention. |
| P.13 | Evaluate external secrets manager | Explore Infisical, HashiCorp Vault, or Doppler to replace Ansible Vault encrypted files. Would provide audit logging, rotation, access control. Consolidate centralized vs distributed vault question at the same time. |
