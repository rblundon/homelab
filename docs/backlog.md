# mk-labs VM Provisioning Pipeline — Backlog

## Pipeline Hardening

- [ ] **Error handling on individual pipeline steps** — Each step (Terraform, Proxmox API, NetBox API) should catch failures and set NetBox status to Failed with a descriptive error in provisioning_notes
- [ ] **Terraform init check** — Verify `terraform init` has been run before `apply`, or add it to the pipeline
- [ ] **Terraform plan before apply** — Optional dry-run mode for validation without execution
- [ ] **`-state` flag deprecation** — Migrate from `-state` CLI flag to local backend `path` attribute for per-VM state isolation

## Secrets Management

- [ ] **HashiCorp Vault (or equivalent)** — Centralized secrets management to replace n8n Global Constants
- [ ] **Verify n8n Community Edition compatibility** — Confirm whether CE supports external secrets store integrations before planning migration

## Sub-workflow Refactoring (DRY)

- [ ] **DHCP: Create Reservation** — Extract Unifi DHCP step into standalone sub-workflow (inputs: hostname, mac_address, ip_address). Reusable for LXCs, printers, switches, etc.
- [ ] **DNS: Delete A Record** — Companion to the existing Create sub-workflow for VM decommissioning
- [ ] **NetBox: Register MAC Address** — Extract MAC creation + interface assignment into sub-workflow

## Ansible Integration

- [ ] **Semaphore trigger from n8n** — Call Semaphore API to launch vm-provision playbook after VM boots
- [ ] **vm-baseline role** — Packages, SSH hardening, user config, any other OS-level setup
- [ ] **Ansible sets NetBox Active** — Move final status update from n8n to Ansible (confirms OS config succeeded, not just infra provisioning)

## Infrastructure Automation

- [ ] **city-hall bootstrap playbook** — Ansible playbook to automate Terraform prerequisites: install Terraform, clone repo, `terraform init` on all modules, create `states/` directories
- [ ] **Proxmox API token management** — Document or automate token rotation

## VM Lifecycle

- [ ] **VM decommissioning pipeline** — Reverse flow triggered by NetBox status change (e.g., Active → Decommissioning):
  - [ ] Remove VM from HA affinity rule (Proxmox API)
  - [ ] Remove HA resource (Proxmox API)
  - [ ] Stop VM (Proxmox API)
  - [ ] Remove DNS A record (Technitium API — new sub-workflow: DNS: Delete A Record)
  - [ ] Remove DHCP reservation (Terraform destroy on unifi/dhcp state file)
  - [ ] Destroy VM (Terraform destroy on proxmox/vm state file)
  - [ ] Remove MAC address from NetBox
  - [ ] Clear VM resources in NetBox (CPU, memory, disk)
  - [ ] Set NetBox status to Decommissioned (or delete VM record)
  - [ ] Clean up Terraform state files
- [ ] **VM resize/update pipeline** — Handle CPU/memory changes triggered from NetBox
- [ ] **VM rebuild pipeline** — Destroy and re-provision a VM in place (same IP, hostname, fresh OS)

## NetBox Enhancements

- [ ] **Webhook idempotency** — Investigate NetBox event rule conditions to filter at the source instead of in n8n
- [ ] **Additional custom fields** — As needs arise (e.g., Ansible playbook to run, application role)

## n8n Workflow Improvements

- [ ] **Notification on failure** — Slack/email alert when pipeline fails
- [ ] **Execution logging** — Structured logging for pipeline runs
- [ ] **Parallel execution** — Run independent steps concurrently (e.g., NetBox VM update + DHCP reservation)
