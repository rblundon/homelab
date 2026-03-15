# ─── turnstile ───────────────────────────────────────────────────────────────
# Smallstep step-ca SSH Certificate Authority
# Provisioned manually (pre-pipeline bootstrap)
#
# Apply:
#   cd terraform/proxmox/hosts
#   terraform apply \
#     -var-file="tfvars/turnstile.tfvars" \
#     -state="states/turnstile.tfstate" \
#     -var="proxmox_api_url=https://main-street-usa.local.mk-labs.cloud:8006" \
#     -var="proxmox_api_token=terraform@pve!terraform-token=<token>"
# turnstile — Smallstep step-ca SSH Certificate Authority
# Provisioned manually (pre-pipeline bootstrap)

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
