# ADR: VM Provisioning Pipeline Flow

**Status:** Accepted  
**Date:** February 2026  
**Supersedes:** PRD v1.0 Section 3.2 (adds DHCP step, adjusts tool boundaries)  
**Last Updated:** February 28, 2026 — revised flow for DHCP-before-boot, HA affinity via Proxmox API, secrets via n8n globals

## Context

The mk-labs homelab needs an automated VM provisioning pipeline triggered by a single operator action. The original PRD defined the flow; this ADR documents the adjusted architecture where n8n owns all orchestration including DHCP reservation (previously Ansible-rendered Terraform templates).

## Decision

### System Context

| Tool | Host | IP Address | Role in Pipeline |
|------|------|-----------|-----------------|
| NetBox | fire-station | 10.1.71.102 | Source of truth — VM records, IP allocation, VLAN data, webhook emitter |
| n8n | tiki-room | 10.1.71.23 | Event orchestration, payload validation, pipeline sequencing |
| Terraform | city-hall | 10.1.71.35 | Proxmox VM lifecycle + Unifi DHCP reservations (repo: /opt/git/homelab) |
| Ansible / Semaphore | imagineering | 10.1.71.22 | OS configuration, DNS record creation, NetBox status updates |
| Proxmox | fantasyland | 10.1.71.13 | Target hypervisor for all new VM deployments |

### Status State Machine

```
PLANNED  →(operator)→  STAGED  →(pipeline)→  ACTIVE
                                    |
                                on error
                                    ↓
                                  FAILED
```

- **Planned**: All fields populated, operator not yet ready. No trigger.
- **Staged**: Operator validated and ready. Triggers pipeline.
- **Active**: Set by Ansible on successful OS config + DNS registration.
- **Failed**: Set by n8n or Ansible on any error. Manual investigation.

### Provisioning Flow (Revised)

| # | System | Action | Detail |
|---|--------|--------|--------|
| **1** | NetBox | Operator sets VM status to Staged | Triggers webhook to n8n on tiki-room |
| **2** | n8n | Receive & validate webhook payload | Check: hostname, IP, template, proxmox_node, proxmox_datastore all present. Status must be exactly Staged. On failure → set NetBox status to Failed, stop. |
| **3** | n8n → city-hall | SSH to city-hall, run `terraform apply` (proxmox/vm) | Creates VM clone on fantasyland in **stopped** state. Uses `-state=states/{hostname}.tfstate` for per-VM state isolation. Passes secrets from n8n Global Constants via `-var` flags. |
| **4** | n8n | Parse Terraform output for MAC address | Reads `mac_address` from `terraform output -json`. |
| **5** | n8n → NetBox | Write MAC address to VM interface | PATCH to NetBox API to update VM interface record with MAC. |
| **6** | n8n → city-hall | SSH to city-hall, run `terraform apply` (unifi/dhcp) | Creates static DHCP reservation on UDM Pro. Uses `-state=states/{hostname}.tfstate`. MAC and IP passed as variables. |
| **7** | n8n → Proxmox API | Add VM to HA resource + node affinity rule | POST to `/cluster/ha/resources` to register VM as HA resource. PUT to `/cluster/ha/rules/{prefer_node}` to add VM to the target node's affinity rule. |
| **8** | n8n → Proxmox API | Start VM | POST to `/nodes/{node}/qemu/{vmid}/status/start`. VM boots and receives IP via DHCP (reservation already in place). |
| **9** | n8n → imagineering | Call Semaphore API to trigger Ansible | Launches vm-provision playbook with VM details as extra vars. |
| **10** | Ansible | OS configuration & DNS record creation | Applies vm-baseline role: packages, SSH keys, Technitium DNS A record creation. |
| **11** | Ansible → NetBox | Set VM status to Active | Final step of playbook updates NetBox VM status via API. |
| **ERR** | n8n / Ansible | Any step fails | NetBox VM status set to Failed. Pipeline halts. No cleanup — operator investigates manually. |

### Key Design Decisions

**VM created in stopped state (Step 3)**
Cloud-init uses `ip=dhcp`. The DHCP reservation must exist on the UDM Pro before the VM's first boot, otherwise the VM gets a random DHCP lease instead of its assigned IP. The VM stays stopped until after the Unifi DHCP reservation is confirmed (Step 6).

**HA affinity via Proxmox API, not Terraform (Step 7)**
Proxmox 9.x replaced HA groups with HA node affinity rules. The bpg/proxmox Terraform provider does not yet support these (tracked in bpg/terraform-provider-proxmox#2097). n8n calls the Proxmox API directly to add the VM to the appropriate `prefer_{node}` affinity rule. This also handles VM migration from fantasyland (clone source) to the target node.

**Per-VM Terraform state files (Steps 3, 6)**
Each VM gets its own state file via `-state=states/{hostname}.tfstate` to avoid state conflicts when managing multiple VMs. The `states/` directory is in `.gitignore`.

**Secrets via n8n Global Constants**
All secrets (Proxmox API token, Unifi credentials, NetBox API token) are stored in n8n's encrypted credential store using the `n8n-nodes-globals` community node. Secrets are passed to Terraform via `-var` flags in SSH commands. No secrets are stored on city-hall's filesystem. See `docs/n8n-setup.md` for details.

### Tool Responsibility Boundary (Adjusted)

| Tool | Owns | Does Not Own |
|------|------|-------------|
| **Terraform** | Proxmox VM lifecycle (bpg/proxmox), UDM Pro DHCP reservations (unifi provider) | OS config, DNS records, application deployment, NetBox data, HA placement |
| **Ansible** | OS configuration, DNS A records (Technitium API), NetBox status updates | Infrastructure provisioning, DHCP reservations, event orchestration |
| **n8n** | Event orchestration, API glue, pipeline sequencing, HA affinity rule management, triggering all Terraform and Ansible steps, secrets distribution | Configuration management, infrastructure state |
| **NetBox** | Source of truth for all assets | Execution of any automation — it only holds data |

### Dependencies

| Component | Dependency | Purpose |
|-----------|-----------|---------|
| n8n | n8n-nodes-globals (community node) | Encrypted secrets storage for pipeline credentials |
| Terraform (proxmox/vm) | bpg/proxmox provider >= 0.74.0 | Proxmox VM lifecycle management |
| Terraform (unifi/dhcp) | paultyng/unifi provider >= 0.41.0 | UDM Pro DHCP static reservations |
| Proxmox | API token: terraform@pve!terraform-token | Terraform + n8n API access (requires VM.GuestAgent.Audit for Proxmox 9) |
| NetBox | Event Rule + Webhook (VM Staged Trigger) | Pipeline trigger on status change to Staged |
| NetBox | REST API token | n8n reads/writes VM data |

### Change from PRD v1.0

**What changed (original):** DHCP reservation moved from "existing Terraform/UDM Pro integration" (out of scope) to an explicit pipeline step owned by n8n.

**What changed (this revision):**
1. VM is created in **stopped** state. DHCP reservation is created before VM boots.
2. HA node affinity rule assignment added as an explicit step (Proxmox API, not Terraform).
3. VM start is a separate explicit step after HA rule assignment.
4. Secrets managed via n8n Global Constants instead of filesystem-based `.tfvars` files.
5. Per-VM Terraform state files via `-state` flag.

**Why:** Cloud-init uses `ip=dhcp`, so the DHCP reservation must exist before first boot. The bpg/proxmox Terraform provider doesn't support Proxmox 9 HA affinity rules, so n8n handles placement via API. Secrets in n8n's credential store keeps city-hall stateless.

### Git Repository Structure

```
homelab/
├── ansible/
│   ├── inventory/
│   │   ├── netbox.yml              # NetBox dynamic inventory plugin
│   │   └── static.yml              # Legacy static inventory
│   ├── playbooks/
│   │   ├── vm-provision.yml        # Main playbook (Semaphore trigger)
│   │   ├── add_technitium_dns_entry.yml
│   │   ├── add_dhcp_reservation.yml
│   │   ├── update-linux-os.yml
│   │   └── set_hostname.yml
│   ├── roles/
│   │   ├── vm-baseline/            # NEW — packages, SSH, DNS, NetBox status
│   │   ├── dns-manager/            # Existing Technitium DNS role
│   │   ├── common/                 # Base system config
│   │   ├── haproxy/
│   │   ├── n8n/
│   │   ├── observer/
│   │   └── time-sync/
│   ├── tasks/                      # Shared task files
│   ├── group_vars/
│   ├── host_vars/
│   ├── templates/
│   ├── scripts/
│   ├── ansible.cfg
│   └── requirements.yml
│
├── terraform/
│   ├── proxmox/
│   │   └── vm/
│   │       ├── main.tf             # bpg/proxmox VM resource (creates stopped)
│   │       ├── variables.tf        # hostname, ip, template, proxmox_node
│   │       ├── outputs.tf          # vm_id, mac_address
│   │       ├── providers.tf
│   │       ├── terraform.tfvars.example
│   │       └── states/             # Per-VM state files (.gitignore)
│   ├── unifi/
│   │   └── dhcp/
│   │       ├── main.tf             # Unifi user resource (DHCP reservation)
│   │       ├── variables.tf        # hostname, mac, ip
│   │       ├── providers.tf
│   │       ├── terraform.tfvars.example
│   │       └── states/             # Per-VM state files (.gitignore)
│   └── dns/
│       ├── dns.tf                  # Existing DNS terraform
│       └── provider.tf
│
├── packer/
│   ├── ubuntu-24.04/               # Ubuntu template build
│   └── fedora-42/                  # Fedora template build
│
├── n8n/
│   └── workflows/
│       └── vm-provisioning.json    # Exported n8n workflow
│
├── netbox/
│   └── initializers/
│       ├── custom_fields.yml
│       ├── vlans.yml
│       └── prefixes.yml
│
├── docs/
│   ├── decisions/
│   │   ├── vm-provisioning-flow.md # This document
│   │   └── tool-responsibility-matrix.md
│   └── n8n-setup.md               # n8n dependencies and configuration
│
├── README.md
├── LICENSE
└── .gitignore
```

## Consequences

- **Positive:** Single visual workflow in n8n shows entire pipeline. Ansible simplified to pure configuration management. Terraform usage consistent (always invoked via n8n SSH, never rendered from templates). Secrets never stored on disk outside n8n's encrypted database. Per-VM state files prevent conflicts.
- **Negative:** n8n becomes a critical dependency — if tiki-room is down, no provisioning. Two separate `terraform apply` calls per VM (Proxmox + Unifi) instead of one. HA rule management is imperative API calls rather than declarative Terraform.
- **Mitigated by:** n8n workflow JSON committed to Git. Both Terraform modules can be run manually from city-hall if n8n is unavailable. HA rules can be managed via `ha-manager` CLI on any Proxmox node.
