# Almost automated step by step walkthrough of full lab deployment

This ~~is~~ *will be* the complete walkthrough of the deployment of my homelab.

- On a PC/laptop, clone this git repo
- Create your vault file for secrets (and store somewhere safe)

  ```bash
  vi ~/.vault_pass.txt
  chmod 644 ~/.vault_pass.txt
  ```

- Add "export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt" to your shell profile.
- Create vault file

  ```bash
  cd homelab/group_vars/all
  ansible-vault create vault
  ```

- Modify ansible variables for your environment

## [Network](00-network/README.md) *Manual*

## [Storage](01-storage/README.md) *Manual*

## [Proxmox](02-proxmox/README.md) *Manual*

## [Unbound DNS](03-unbound-dns/README.md) *Manual*

---

## Build infra01

- Copy .vault_pass.txt from laptop and set env variable
- Clone git repo
- Install ansible required packages

  ```bash
  cd homelab
  ansible-galaxy collection install -r
  ```

## [FreeIPA](04-free-ipa/README.md) *Manual*

## [Templates](05-templates/README.md) *Manual*

## [Matchbox](06-matchbox/README.md) *Manual*

- Downloading the Agent-based Installer

---

## [Hub Cluster](10-sno-hub-cluster/README.md) *In Progress*

### Prepare matchbox to install hub cluster

- Modify config file for OpenShift Automated Installer

  (In the future these will be template files and all the customization will be done through Ansible)

  - 03-matchbox/install-config
  - 03-matchbox/agent-config
  - 03-matchbox/variables.tf
  - 03-matchbox/provider.tf
  - 03-matchbox/terraform.tfvars
  - 03-matchbox/groups.tf
  - 03-matchbox/profiles.tf

  ```bash
  cd homelab
  ansible-playbook -i inventory.yml 10-sno-hub-cluster/install.yml
  ```

## Internal Cluster *TBD*

(Deployed in conjunction with ACM)

## External Cluster *TBD*

(Deployed in conjunction with ACM)
