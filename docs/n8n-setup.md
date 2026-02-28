# n8n Setup & Dependencies

**Host:** tiki-room (10.1.71.23)  
**Install method:** Proxmox LXC via helper script  
**Version:** Community Edition

## Community Node Dependencies

The VM provisioning pipeline requires the following n8n community node:

### n8n-nodes-globals

- **Package:** [n8n-nodes-globals](https://github.com/umanamente/n8n-nodes-globals)
- **Purpose:** Stores secrets (API tokens, credentials) as encrypted global constants in n8n's credential store. Referenced by pipeline workflows to pass secrets to Terraform and NetBox API calls without persisting them on disk.
- **Install:**
  ```bash
  cd /usr/lib/node_modules/n8n
  npm install n8n-nodes-globals
  systemctl restart n8n
  ```
- **Version at time of writing:** v1.1.0

### Configuration

After installing the community node, create a **Global Constants** credential in n8n with the following key-value pairs:

| Key | Description |
|-----|-------------|
| `PROXMOX_API_URL` | Proxmox API endpoint (e.g., `https://fantasyland.local.mk-labs.cloud:8006`) |
| `PROXMOX_API_TOKEN` | Proxmox API token in format `user@realm!token-name=secret` |
| `UNIFI_USERNAME` | UDM Pro admin username |
| `UNIFI_PASSWORD` | UDM Pro admin password |
| `UNIFI_API_URL` | UDM Pro API URL (e.g., `https://10.1.0.1:443`) |
| `NETBOX_URL` | NetBox base URL (e.g., `https://fire-station`) |
| `NETBOX_API_TOKEN` | NetBox REST API token |

These constants are encrypted at rest in n8n's database and are accessible in any workflow via the Global Constants node. This avoids storing secrets on city-hall's filesystem or in Terraform `.tfvars` files.

## n8n Credentials

In addition to global constants, the following n8n credentials are used by pipeline nodes:

| Credential Type | Name | Used By | Details |
|----------------|------|---------|---------|
| SSH | city-hall SSH | Terraform apply nodes | SSH access to 10.1.71.35 for running Terraform commands |
| Header Auth | NetBox API Token | HTTP Request nodes | `Authorization: Token <token>` for NetBox API calls |

## Secrets Management Roadmap

The current approach (n8n Global Constants) is a Phase 1 solution. Future plans:

- **Phase 6+:** Evaluate HashiCorp Vault or equivalent for centralized secrets management
- **Note:** n8n Community Edition may not support external secrets store integrations — verify before planning migration

## Webhook Configuration

The pipeline is triggered by a NetBox webhook:

| Setting | Value |
|---------|-------|
| Webhook URL | `http://tiki-room:5678/webhook/vm-provision` |
| HTTP Method | POST |
| Content Type | `application/json` |
| SSL Verification | Disabled (internal VLAN) |

See NetBox Event Rule configuration in `netbox/initializers/custom_fields.yml` for the trigger conditions.
