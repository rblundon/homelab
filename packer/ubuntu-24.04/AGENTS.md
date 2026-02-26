# AGENTS.md file

## Project overview

- Hashicorp Packer files to build Ubuntu 24.04.03 tmeplate VMs for Proxmox
- Cloudinit is used to configure the OS

## Code style guidelines

- Proxmox variables are set in proxmox.pkrvrs.hcl
- General OS variables are set in ubuntu-24.04.pkrvars.hcl
- VM specific variables are set in vm-[<size>].pkrvars.hcl

## Dev environment tips

## Program excecution

```bash
packer build -var-file ./ubuntu-24.04.pkrvars.hcl \
-var-file ./proxmox.pkrvars.hcl \
-var-file ./vm-small.pkrvars.hcl \
-var 'ssh_password=<ssh_password>' \
-var 'proxmox_password=<proxmox_password>' .
```

## Testing instructions

## PR instructions

- Title format: [<project_name>] <Title>

## Security considerations
