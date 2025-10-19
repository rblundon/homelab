# Kubeconfig Manager Role

A reusable Ansible role for managing kubeconfig files across multiple Kubernetes clusters.

## Features

- Fetches kubeconfig from remote Kubernetes nodes
- Merges multiple cluster configs into a single `~/.kube/config` file
- Creates backups before merging
- Provides unique cluster, context, and user names
- Works with any Kubernetes cluster (vanilla K8s, OpenShift, etc.)

## Requirements

- Ansible 2.9+
- Access to Kubernetes cluster admin.conf file
- Local kubectl installation (optional, for testing)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `cluster_name` | `kubernetes` | Name of the cluster (required) |
| `kubeconfig_source_path` | `/etc/kubernetes/admin.conf` | Path to kubeconfig on remote host |
| `context_suffix` | `admin` | Suffix for context name |

## Example Usage

### In a playbook:

```yaml
- name: Setup kubeconfig for FastPass cluster
  hosts: fastpass_control_plane[0]
  roles:
    - role: kubeconfig-manager
      vars:
        cluster_name: "fastpass"

- name: Setup kubeconfig for Hub cluster  
  hosts: hub_cluster
  roles:
    - role: kubeconfig-manager
      vars:
        cluster_name: "hub"
        kubeconfig_source_path: "/etc/kubernetes/admin.conf"
```

### As an included role:

```yaml
- name: Manage kubeconfig
  ansible.builtin.include_role:
    name: kubeconfig-manager
  vars:
    cluster_name: "{{ my_cluster_name }}"
```

## Generated Structure

The role creates contexts with this naming pattern:
- **Cluster**: `{{ cluster_name }}`
- **Context**: `{{ cluster_name }}-admin`
- **User**: `{{ cluster_name }}-admin`

## File Structure

```
~/.kube/
├── config                    # Merged kubeconfig
├── config-fastpass          # Individual cluster configs
├── config-hub
├── config-internal
└── config.backup.1234567890 # Timestamped backups
```

## Dependencies

None

## License

MIT

## Author

mk-labs