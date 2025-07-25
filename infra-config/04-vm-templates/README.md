# Steps for creating VM templates with Hashicorp Packer

As this is one of the early steps, the assumption is made that these commands will be run on a jumpbox/laptop.

Templates will always live on <template-node> within the cluster.

Steps to install Packer:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

fedora-<version>/
├── fedora-<version>.pkr.hcl # Main build definition(s)
├── variables.pkr.hcl        # Variable declarations and default values
├── <image_name>.pkrvars.hcl # (Optional) Specific variable values for a particular image
├── files/                   # Files to load on VM
│   └── ansible.pub         # public key for ansible user
├── scripts/                 # Directory for shell scripts
│   ├── cleanup.sh          # Clean up the template
│   └── setup.yml           # Ansible playbook
├── httpd/                   # Subdirectory for kickstart configiration
│   └── ks.cfg              # Source block for Apache image
└── README.md

# Disable the firewall before starting

```bash
sudo systemctl stop firewalld
```

# Create templates

```bash
packer build -var-file ./fedora-42-small.pkrvars.hcl -var-file ./proxmox.pkvars.hcl -var 'ssh_password=<wed ssh password>' -var 'proxmox_password=<proxmox user password>' .
packer build -var-file ./fedora-42-medium.pkrvars.hcl -var-file ./proxmox.pkvars.hcl -var 'ssh_password=<wed ssh password>' -var 'proxmox_password=<proxmox user password>' .
packer build -var-file ./fedora-42-large.pkrvars.hcl -var-file ./proxmox.pkvars.hcl -var 'ssh_password=<wed ssh password>' -var 'proxmox_password=<proxmox user password>' .
packer build -var-file ./fedora-42-xlarge.pkrvars.hcl -var-file ./proxmox.pkvars.hcl -var 'ssh_password=<wed ssh password>' -var 'proxmox_password=<proxmox user password>' .
```
