# Proxmox

In this iteration of my homelab, core services are running as VMs in Proxmox.

The proxmox cluster will be installed via ISO Image and manually configured. (Future iterations will gitops this configuration via Ansible playbooks.)

## Primary Networking

| Hostname    | VLAN | IP Address       | NIC             | Notes                    |
|-------------|------|------------------|-----------------|--------------------------|
| pve01       |   71 | 10.1.71.51       | On-board 1 GbE  | VLAN set on switch port  |
| pve02       |   71 | 10.1.71.52       | On-board 1 GbE  | VLAN set on switch port  |
| pve03       |   71 | 10.1.71.53       | On-board 1 GbE  | VLAN set on switch port  |

## Additional Networking

| Hostname    | VLAN | IP Address         | NIC          | Notes                        |
|-------------|------|--------------------|--------------|------------------------------|
| pve01       |   22 |  10.10.22.51       | PCIe 10 GbE  | Cluster Network, VLAN tagged |
| pve01       |  121 | 10.10.121.51       | PCIe 10 GbE  | Storage Network, VLAN tagged |
| pve02       |   22 |  10.10.22.52       | PCIe 10 GbE  | Cluster Network, VLAN tagged |
| pve02       |  121 | 10.10.121.52       | PCIe 10 GbE  | Storage Network, VLAN tagged |
| pve03       |   22 |  10.10.22.53       | PCIe 10 GbE  | Cluster Network, VLAN tagged |
| pve03       |  121 | 10.10.121.53       | PCIe 10 GbE  | Storage Network, VLAN tagged |

## Hosted Services

- Recursive DNS (Unbound)
- Authoritative DNS (FreeIPA)
- Identity Management (FreeIPA)
- iPXE (Matchbox)
- VM Backup (Proxmox Backup)
- VM Tempalate Creation (Terraform/Packer)
