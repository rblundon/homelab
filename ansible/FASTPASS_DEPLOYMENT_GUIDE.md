# FastPass Kubernetes Cluster - Complete Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying a complete Kubernetes cluster on Fedora using Ansible automation. The FastPass cluster is designed for high availability with multiple control plane nodes and worker nodes.

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

### 1. Validate Your Setup

Before deploying, run the validation script:

```bash
cd ansible
./scripts/test-fastpass-deployment.sh
```

This will check:
- ✅ Ansible installation
- ✅ Inventory configuration
- ✅ Playbook files
- ✅ Role files
- ✅ Group variables
- ✅ Playbook syntax
- ✅ Common issues

### 2. Deploy the Cluster

```bash
# Deploy the complete cluster
ansible-playbook -i inventory.yml playbooks/deploy-fastpass-cluster.yml
```

## Deployment Process

The deployment follows this sequence:

### Phase 1: System Preparation
- **Hosts**: All FastPass nodes
- **Tasks**: 
  - Preflight checks (OS, memory, CPU, disk space)
  - Disable swap and configure kernel modules
  - Install and configure containerd
  - Install Kubernetes packages

### Phase 2: Control Plane Initialization
- **Hosts**: First control plane node (`space-mountain`)
- **Tasks**:
  - Initialize the Kubernetes cluster
  - Configure API server and etcd
  - Install Flannel CNI
  - Generate join commands

### Phase 3: Additional Control Plane Nodes
- **Hosts**: Remaining control plane nodes (`big-thunder-mountain`, `splash-mountain`)
- **Tasks**:
  - Join additional control plane nodes
  - Configure high availability

### Phase 4: Worker Nodes
- **Hosts**: Worker nodes (`haunted-mansion`, `peter-pans-flight`)
- **Tasks**:
  - Join worker nodes to the cluster
  - Apply node labels and taints

### Phase 5: Validation
- **Hosts**: First control plane node
- **Tasks**:
  - Verify all nodes are ready
  - Check all pods are running
  - Display final cluster status

## Configuration

### Inventory Structure

Ensure your `inventory.yml` has the correct structure:

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

### Group Variables

Key variables in `group_vars/fastpass/vars`:

```yaml
# Cluster Configuration
cluster_name: "fastpass"
kubernetes_version: "1.33"
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"

# Control Plane Configuration
control_plane_endpoint: "fastpass.local.mk-labs.cloud"
control_plane_port: "6443"

# CNI Configuration
cni_plugin: "flannel"

# Node Labels
node_labels:
  zone:
    # Control Plane nodes (masters) - no zone labels needed
    # space-mountain: (control plane - no zone label)
    # big-thunder-mountain: (control plane - no zone label)
    # splash-mountain: (control plane - no zone label)
    
    # Worker nodes
    haunted-mansion: "backstage"      # Internal/backstage workloads
    peter-pans-flight: "backstage"    # Internal/backstage workloads
    # Future node: "on-stage"         # External/on-stage workloads (future)
```

## Troubleshooting

### Common Issues

#### 1. Swap Enabled
**Problem**: `running with swap on is not supported`
**Solution**: The playbook automatically disables swap, but if it persists:
```bash
# On the problematic node
sudo swapoff -a
sudo systemctl restart kubelet
```

#### 2. CNI Not Ready
**Problem**: `Network plugin returns error: cni plugin not initialized`
**Solution**: The playbook installs Flannel automatically. If issues persist:
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

#### 3. Control Plane Endpoint Issues
**Problem**: `unable to add a new control plane instance to a cluster that doesn't have a stable controlPlaneEndpoint`
**Solution**: The playbook uses the first control plane node as the endpoint. For production, consider using a load balancer.

#### 4. Permission Issues
**Problem**: `User "kubernetes-admin" cannot create resource "secrets"`
**Solution**: The playbook uses super-admin.conf for proper permissions.

### Debug Commands

```bash
# Check node status
kubectl get nodes -o wide

# Check pod status
kubectl get pods --all-namespaces

# Check kubelet logs
journalctl -u kubelet -f

# Check API server logs
kubectl logs -n kube-system kube-apiserver-space-mountain

# Check CNI status
kubectl get pods -n kube-flannel
```

## Post-Deployment

### 1. Verify Cluster Health

```bash
# Check all nodes are ready
kubectl get nodes -o wide

# Check all pods are running
kubectl get pods --all-namespaces

# Test cluster connectivity
kubectl cluster-info
```

### 2. Manage Kubeconfig

Use the provided script to manage different cluster configurations:

```bash
# Switch to FastPass cluster
./scripts/manage-kubeconfigs.sh fastpass

# Check status
./scripts/manage-kubeconfigs.sh status

# Test connectivity
./scripts/manage-kubeconfigs.sh test
```

### 3. Deploy Applications

Your cluster is now ready for workloads:

```bash
# Deploy a test application
kubectl run nginx --image=nginx --port=80

# Create a service
kubectl expose pod nginx --port=80 --type=NodePort

# Check the service
kubectl get svc nginx
```

## Maintenance

### Adding New Nodes

1. Add the new node to the inventory
2. Run the preparation role:
   ```bash
   ansible-playbook -i inventory.yml playbooks/deploy_k8s.yml --limit=new-node
   ```
3. Join the node to the cluster manually or extend the playbook

### Upgrading Kubernetes

1. Update the `kubernetes_version` variable
2. Run the preparation role on all nodes
3. Upgrade control plane nodes first
4. Upgrade worker nodes

### Backup and Recovery

- Backup `/etc/kubernetes/` directory on control plane nodes
- Backup etcd data: `etcdctl snapshot save backup.db`
- Document cluster configuration

## Architecture

```
FastPass Cluster Architecture:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Control Plane  │    │  Control Plane  │    │  Control Plane  │
│  space-mountain │    │big-thunder-mtn  │    │ splash-mountain │
│   (Masters)     │    │   (Masters)     │    │   (Masters)     │
│  No Zone Label  │    │  No Zone Label  │    │  No Zone Label  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Worker Node   │    │   Worker Node   │    │   Worker Node   │
│ haunted-mansion │    │peter-pans-flight│    │  (Future)       │
│   (Backstage)   │    │   (Backstage)   │    │   (On-Stage)    │
│ zone=backstage  │    │ zone=backstage  │    │ zone=on-stage   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

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
│       ├── fastpass-control-plane-join/ # Additional control plane nodes
│       └── fastpass-workers/       # Worker node setup
├── scripts/
│   ├── test-fastpass-deployment.sh # Validation script
│   └── manage-kubeconfigs.sh      # Kubeconfig management
└── inventory.yml                   # Host inventory
``` 