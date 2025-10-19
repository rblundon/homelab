# Kubeconfig Management - Modular & Repeatable

This document explains the modular kubeconfig management system for your homelab's multiple Kubernetes clusters.

## Overview

The kubeconfig management has been refactored into reusable, modular components that can handle multiple clusters seamlessly:

- **FastPass** (Vanilla Kubernetes)
- **Hub Cluster** (OpenShift SNO)
- **Internal Cluster** (OpenShift)
- **Future clusters** (easily extensible)

## Architecture

```
ansible/playbooks/roles/
├── kubeconfig-manager/          # Core reusable role
│   ├── tasks/main.yml          # Main entry point
│   ├── tasks/merge-kubeconfig.yml  # Merging logic
│   ├── defaults/main.yml       # Default variables
│   └── README.md               # Role documentation
├── cluster-kubeconfig/         # Generic wrapper role
└── fastpass-first-control-plane/  # Uses kubeconfig-manager
```

## Quick Usage

### 1. Using the Script (Easiest)

```bash
cd ansible

# Setup FastPass cluster kubeconfig
./scripts/setup-kubeconfig.sh fastpass fastpass_control_plane[0]

# Setup Hub cluster kubeconfig  
./scripts/setup-kubeconfig.sh hub hub_cluster

# Setup Internal cluster kubeconfig
./scripts/setup-kubeconfig.sh internal internal_cluster[0]
```

### 2. Direct Ansible Usage

```bash
# Single cluster
ansible-playbook -i inventory.yml \
  playbooks/examples/multi-cluster-kubeconfig.yml \
  --limit fastpass_control_plane[0] \
  -e target_cluster_name=fastpass

# Multiple clusters at once
ansible-playbook -i inventory.yml \
  playbooks/examples/multi-cluster-kubeconfig.yml
```

### 3. In Your Own Playbooks

```yaml
- name: Setup kubeconfig for any cluster
  hosts: my_cluster_nodes[0]
  roles:
    - role: kubeconfig-manager
      vars:
        cluster_name: "my-cluster"
        kubeconfig_source_path: "/etc/kubernetes/admin.conf"
```

## Features

### ✅ **Modular & Reusable**
- Single role works with any Kubernetes cluster
- Easy to extend for new clusters
- Consistent behavior across all clusters

### ✅ **Safe Operations**
- Automatic backups before merging
- Non-destructive merging
- Preserves existing contexts

### ✅ **Multi-Cluster Ready**
- Unique naming: `cluster-name-admin`
- No conflicts between clusters
- Easy context switching

### ✅ **Homelab Optimized**
- Works with vanilla Kubernetes
- Works with OpenShift
- Handles different kubeconfig paths

## Generated Structure

After running the kubeconfig management:

```bash
~/.kube/
├── config                      # Merged config with all clusters
├── config-fastpass            # Individual cluster configs
├── config-hub
├── config-internal
└── config.backup.1697123456   # Timestamped backups
```

## Context Management

```bash
# List all available contexts
kubectl config get-contexts

# Switch between clusters
kubectl config use-context fastpass-admin
kubectl config use-context hub-admin
kubectl config use-context internal-admin

# Check current context
kubectl config current-context

# Test connectivity
kubectl cluster-info
kubectl get nodes
```

## Integration with Existing Roles

### Before (Monolithic)
```yaml
# fastpass-first-control-plane/tasks/main.yml
- name: 50+ lines of kubeconfig logic
  # Lots of repetitive code
```

### After (Modular)
```yaml
# fastpass-first-control-plane/tasks/main.yml
- name: Setup kubeconfig for FastPass cluster
  ansible.builtin.include_role:
    name: kubeconfig-manager
  vars:
    cluster_name: "{{ cluster_name }}"
```

## Adding New Clusters

To add a new cluster (e.g., "edge-cluster"):

1. **Add to inventory:**
```yaml
edge_cluster:
  hosts:
    edge-node-01:
```

2. **Use the script:**
```bash
./scripts/setup-kubeconfig.sh edge edge_cluster[0]
```

3. **Or add to playbook:**
```yaml
- name: Setup kubeconfig for Edge cluster
  hosts: edge_cluster[0]
  roles:
    - role: kubeconfig-manager
      vars:
        cluster_name: "edge"
```

## Customization

### Different Kubeconfig Paths
```yaml
- role: kubeconfig-manager
  vars:
    cluster_name: "openshift-cluster"
    kubeconfig_source_path: "/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost.kubeconfig"
```

### Custom Context Names
```yaml
- role: kubeconfig-manager
  vars:
    cluster_name: "prod"
    context_suffix: "system:admin"  # Results in "prod-system:admin"
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix ownership
   sudo chown -R $USER:$USER ~/.kube/
   ```

2. **Context Not Found**
   ```bash
   # List available contexts
   kubectl config get-contexts
   
   # Check if cluster was added
   kubectl config view
   ```

3. **Backup Recovery**
   ```bash
   # Restore from backup
   cp ~/.kube/config.backup.1697123456 ~/.kube/config
   ```

### Debug Mode
```bash
# Run with verbose output
ansible-playbook -vvv playbooks/examples/multi-cluster-kubeconfig.yml
```

## Benefits for Your Homelab

1. **Consistency**: Same process for all clusters
2. **Maintainability**: Single role to update/fix
3. **Scalability**: Easy to add new clusters
4. **Safety**: Automatic backups and safe merging
5. **Flexibility**: Works with different Kubernetes distributions

## Next Steps

1. **Test the modular approach** with your FastPass cluster
2. **Extend to Hub and Internal clusters** using the same pattern
3. **Create cluster-specific variables** in group_vars if needed
4. **Add monitoring/validation** tasks to verify kubeconfig health

This modular approach makes your homelab's multi-cluster management much more maintainable and repeatable!