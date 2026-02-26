# mk-labs

Automated infrastructure provisioning and configuration for a personal homelab, built on GitOps practices with clear tool responsibility boundaries.

## Architecture

A single operator action — setting a VM record's status to **Staged** in NetBox — triggers a fully automated provisioning pipeline:
```
NetBox (webhook) → n8n (validate & orchestrate) → Terraform (create VM + DHCP)
                                                 → Ansible (OS config + DNS + status update)
```

| Tool | Host | IP | Responsibility |
|------|------|----|---------------|
| NetBox | fire-station | 10.1.71.102 | Source of truth — VM records, IP allocation, VLAN data |
| n8n | tiki-room | 10.1.71.23 | Event orchestration, validation, pipeline sequencing |
| Terraform | city-hall | 10.1.71.35 | Proxmox VM lifecycle, Unifi DHCP reservations |
| Ansible / Semaphore | imagineering | 10.1.71.22 | OS configuration, DNS records, NetBox status updates |
| Proxmox | fantasyland | 10.1.71.13 | Target hypervisor |

All systems on the Server Trusted VLAN (10.1.71.0/24).

## Repository Structure
```
homelab/
├── ansible/
│   ├── inventory/          # NetBox dynamic inventory + static
│   ├── playbooks/          # Runnable playbooks (vm-provision, DNS, OS updates)
│   ├── roles/              # vm-baseline, dns-manager, common, haproxy, n8n, observer, etc.
│   ├── tasks/              # Shared includable task files
│   ├── group_vars/         # Group variable definitions
│   ├── host_vars/          # Per-host variable definitions
│   ├── templates/          # Jinja2 templates
│   └── ansible.cfg
│
├── terraform/
│   ├── proxmox/vm/         # bpg/proxmox provider — VM creation from templates
│   ├── unifi/dhcp/         # Unifi provider — DHCP static reservations on UDM Pro
│   └── dns/                # DNS record management
│
├── packer/
│   ├── ubuntu-24.04/       # Ubuntu 24.04 VM template (small → xlarge-plus sizes)
│   └── fedora-42/          # Fedora 42 VM template
│
├── n8n/
│   └── workflows/          # Exported n8n workflow JSON (vm-provisioning)
│
├── netbox/
│   └── initializers/       # Custom fields, VLANs, IP prefixes as code
│
└── docs/
    └── decisions/          # Architecture decision records
```

## Pipeline Flow

| # | System | Action |
|---|--------|--------|
| 1 | NetBox | Operator sets VM status to Staged → webhook fires |
| 2 | n8n | Validates payload (hostname, IP, VLAN, template, proxmox_node) |
| 3 | n8n → city-hall | SSH + `terraform apply` — creates VM on Proxmox |
| 4 | n8n | Queries Proxmox API for MAC address |
| 5 | n8n → NetBox | Writes MAC to VM interface record |
| 6 | n8n → city-hall | SSH + `terraform apply` — creates DHCP reservation on UDM Pro |
| 7 | n8n → imagineering | Triggers Ansible via Semaphore API |
| 8 | Ansible | OS baseline, SSH hardening, Technitium DNS A record |
| 9 | Ansible → NetBox | Sets VM status to Active |

On any failure, NetBox status is set to **Failed**. No auto-retry — operator investigates.

## Hardware

- 7× Dell 7050 SFF
- 3× Minisforum TH60
- 2× Minisforum MS01
- Synology DS1621+
- Ubiquiti UDM Pro

## Software Stack

- **Virtualization**: Proxmox
- **Automation**: Terraform, Ansible, n8n, Semaphore
- **DNS**: Technitium (authoritative), Unbound (recursive)
- **IPAM/DCIM**: NetBox
- **Networking**: Ubiquiti UDM Pro
- **Templates**: Packer (Ubuntu 24.04, Fedora 42)

## Getting Started

See [docs/decisions/vm-provisioning-flow.md](docs/decisions/vm-provisioning-flow.md) for the full architecture decision record.

Previous OpenShift/ACM/Fastpass content is preserved in the `archive/pre-mk-labs` branch.

## Security

No sensitive data is stored in this repository. Secrets are managed via Ansible Vault and environment variables on pipeline hosts.

---

**Status**: 🚧 Active Development — VM Provisioning Pipeline

**Last Updated**: February 2026
