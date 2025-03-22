# Prepare matchbox to install hub cluster

## Modify config file for OpenShift Automated Installer

- 03-matchbox/install-config
- 03-matchbox/agent-config

## Install Ansible pre-requisites

```bash
ansible-galaxy collection install -r
```

## Run installation playbook

```bash
ansible-playbook install.yml
```
