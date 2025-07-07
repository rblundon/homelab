# infra-config

## Create a virtual environment for ansible-core, activate it upgrade pip

### Linux

```bash
python3 -m venv ~/venv-ansible
source ~/venv-ansible/bin/activate
pip3 install --upgrade pip
```

## Install ansible-core, proxmoxer and requests (needed by community.general.proxmox_*)

```bash
pip3 install ansible-core proxmoxer requests
ansible-galaxy collection install community.proxmox
```
