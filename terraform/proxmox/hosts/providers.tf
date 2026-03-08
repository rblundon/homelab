# ─── Provider Configuration ──────────────────────────────────────────────────
# Shared provider for all host deployments.
# Sensitive values are passed via CLI at apply time.

terraform {
  required_version = ">= 1.5"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.78.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    agent = false
  }
}
