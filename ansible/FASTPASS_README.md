# FastPass Kubernetes Cluster - Fedora Deployment Guide

## Overview

This guide covers the deployment of a Kubernetes cluster on Fedora using Ansible automation. The FastPass cluster is designed for high availability with multiple control plane nodes and worker nodes.

## Architecture

```
FastPass Cluster Architecture:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Control Plane  │    │  Control Plane  │    │  Control Plane  │
│  space-mountain │    │big-thunder-mtn  │    │ splash-mountain │
│   (Leader)      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Worker Node   │    │   Worker Node   │    │   Worker Node   │
│ haunted-mansion │    │peter-pans-flight│    │  (Future)       │
│   (backstage)   │    │   (backstage)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

### System Requirements
- **OS**: Fedora 38+ (64-bit)
- **Memory**: Minimum 2GB RAM per node
- **CPU**: Minimum 2 cores per node
- **Storage**: Minimum 10GB free space
- **Network**: All nodes must be able to communicate

### Software Requirements
- Ansible 2.15+
- Python 3.8+
- SSH access to all nodes with sudo privileges

## Quick Start

### 1. Prepare Inventory

Ensure your `inventory.yml` has the correct host groups:

```yaml
fastpass_control_plane:
  hosts:
    space-mountain:
    big-thunder-mountain:
    splash-mountain:

fastpass_workers:
  hosts:
    haunted-mansion:
    peter-pans-flight:

fastpass:
  children:
    fastpass_control_plane:
    fastpass_workers:
```

### 2. Configure Variables

Edit `group_vars/fastpass/vars` to customize your deployment:

```yaml
# Cluster Configuration
cluster_name: "fastpass"
kubernetes_version: "1.33"
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"

# Node Labels
node_labels:
  zone:
    space-mountain: "external"
    big-thunder-mountain: "external"
    splash-mountain: "external"
    haunted-mansion: "internal"
    peter-pans-flight: "internal"
```

### 3. Deploy the Cluster

```bash
# Deploy the complete cluster
ansible-playbook -i inventory.yml playbooks/deploy-fastpass-cluster.yml

# Or deploy step by step
ansible-playbook -i inventory.yml playbooks/deploy_k8s.yml
```

## Deployment Process

### Phase 1: System Preparation
- Preflight checks (OS, memory, CPU, disk space)
- Disable swap and configure kernel modules
- Install and configure containerd
- Install Kubernetes packages

### Phase 2: Control Plane Setup
- Initialize the first control plane node
- Configure API server and etcd
- Install Calico CNI
- Join additional control plane nodes

### Phase 3: Worker Node Setup
- Join worker nodes to the cluster
- Apply node labels and taints
- Verify cluster health

## Troubleshooting

### Common Issues

#### 1. Repository Errors
**Problem**: Docker CE repository not found
**Solution**: Update the repository URL in `container-runtime.yml`:
```yaml
baseurl: "https://download.docker.com/linux/fedora/{{ ansible_distribution_major_version }}/x86_64/stable"
```

#### 2. kubeadm Init Failures
**Problem**: kubeadm init fails with preflight errors
**Solution**: The playbook includes `--ignore-preflight-errors=all` flag

#### 3. Node Not Ready
**Problem**: Worker nodes stuck in NotReady state
**Solution**: Check CNI installation and network connectivity

### Debug Commands

```bash
# Check node status
kubectl get nodes -o wide

# Check pod status
kubectl get pods --all-namespaces

# Check kubelet logs
journalctl -u kubelet -f

# Check containerd status
systemctl status containerd
```

## Customization

### Network Configuration
Modify the pod and service CIDRs in `group_vars/fastpass/vars`:

```yaml
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"
```

### CNI Selection
The default CNI is Calico. To change, modify the control plane role:

```yaml
cni_plugin: "flannel"  # or "weave", "cilium"
```

### Node Labels and Taints
Configure node labels in `group_vars/fastpass/vars`:

```yaml
node_labels:
  zone:
    space-mountain: "external"
    haunted-mansion: "internal"
  environment: "production"
  cluster: "fastpass"
```

## Maintenance

### Adding New Nodes
1. Add the new node to the inventory
2. Run the preparation role: `ansible-playbook -i inventory.yml playbooks/deploy_k8s.yml --limit=new-node`
3. Join the node to the cluster

### Upgrading Kubernetes
1. Update the `kubernetes_version` variable
2. Run the preparation role on all nodes
3. Upgrade control plane nodes first
4. Upgrade worker nodes

### Backup and Recovery
- Backup `/etc/kubernetes/` directory on control plane nodes
- Backup etcd data: `etcdctl snapshot save backup.db`
- Document cluster configuration

## Security Considerations

- SELinux is set to permissive mode for compatibility
- Firewalld is disabled (configure as needed for your environment)
- Consider enabling RBAC and network policies
- Regularly update Kubernetes and system packages

## Support

For issues specific to this deployment:
1. Check the troubleshooting section
2. Review Ansible logs with `-vvv` verbosity
3. Check system logs on affected nodes
4. Verify network connectivity between nodes

## Files Structure

```
ansible/
├── group_vars/
│   └── fastpass/
│       └── vars                    # Cluster configuration
├── playbooks/
│   ├── deploy-fastpass-cluster.yml # Main deployment playbook
│   ├── deploy_k8s.yml             # Legacy deployment playbook
│   └── roles/
│       ├── kubernetes/             # System preparation
│       ├── fastpass-control-plane/ # Control plane setup
│       └── fastpass-workers/       # Worker node setup
└── inventory.yml                   # Host inventory
``` 