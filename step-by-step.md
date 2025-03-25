# Almost automated step by step walkthrough of full lab deployment

This ~~is~~ *will be* the complete walkthrough of the deployment of my homelab.

- On a PC/laptop, clone this git repo
- Create your vault file for secrets (and store somewhere safe)

  ```bash
  echo 'master-ansible-password' > ~/.vault_pass.txt
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

<https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs/resources/network>

## [Storage](01-storage/README.md) *Manual*

## [Proxmox](02-proxmox/README.md) *Manual*

<https://registry.terraform.io/providers/bpg/proxmox/latest>

## [Unbound DNS](03-unbound-dns/README.md) *Manual*

---

## Build infra01

- From laptop run ansible playbook to:

  ```bash
  cd homelab
  ansible-playbook -i inventory.yml 03-infra01-server/install.yml
  ```

  - Install ansible-core
  - Copy .vault_pass.txt from laptop and set env variable
  - Clone git repo
  - Install ansible required packages

  ```bash
  scp ~/.vault_pass.txt infra01:.
  ssh infra01

  cd homelab
  ansible-galaxy collection install -r requirements.yml
  ansible-playbook -i inventory.yml 10-sno-hub-cluster/install.yml
  ```

Other needed software:
- ~~kustomize~~
- git
- oc
- ansible
- terraform

## [FreeIPA](04-free-ipa/README.md) *Manual*

## [Templates](05-templates/README.md) *Manual*

## [Matchbox](06-matchbox/README.md) *Manual*

- Downloading the Agent-based Installer

---

## [Hub Cluster](10-sno-hub-cluster/README.md) *In Progress*

- Prepare matchbox to install hub cluster

  Running this playbook will configure Matchbox to wait for the sno-cluster to boot via iPXE and will install Single Node OpenShift.  All configuration files are built from templates driven from Ansible variables.

    ```bash
    cd homelab
    ansible-playbook -i inventory.yml 10-sno-hub-cluster/install.yml
    ```

- PXE boot the SNO host

  Boot host to boot options menu:

  - \<F12\> for Dell 7050

  Select NIC with matching MAC to boot from

- Monitor installation process

  ```bash
  openshift-install --dir homelab/10-sno-hub-cluster/03-openshift-image agent wait-for bootstrap-complete --log-level=debug
  ```

- Admin password and kubeconfig are in the homelab/10-sno-hub-cluster/03-openshift-image/auth directory
- Bootstrap ACM

  Running this playbook will configure Matchbox to wait for the sno-cluster to boot via iPXE and will install Single Node OpenShift.  All configuration files are built from templates driven from Ansible variables.

  ```bash
  ansible-playbook -i inventory.yml 10-sno-hub-cluster/install2.yml
  ```

10-sno-hub-cluster/05-bootstrap-acm/bootstrap.sh

## Internal Cluster *TBD*

(Deployed in conjunction with ACM)

## External Cluster *TBD*

(Deployed in conjunction with ACM)
