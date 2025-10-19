# DNS Management Refactor - Modular & Repeatable

This document explains the refactoring of DNS management from standalone playbooks to modular, reusable tasks.

## 🎯 **What Changed**

### **Before (Monolithic)**
```yaml
# Standalone playbook: add_technitium_dns_entry.yml
- name: Add entry to Technitium DNS
  hosts: all
  tasks:
    - name: Create DNS entry
      effectivelywild.technitium_dns.technitium_dns_add_record:
        # ... hardcoded parameters
```

### **After (Modular)**
```yaml
# Reusable task: tasks/add_technitium_dns_entry.yml
- name: Create DNS entry for {{ dns_record_name }}
  effectivelywild.technitium_dns.technitium_dns_add_record:
    # ... parameterized with variables
```

## 📁 **New Structure**

```
ansible/
├── playbooks/
│   ├── tasks/
│   │   └── add_technitium_dns_entry.yml    # ✅ Reusable task file
│   ├── add_dns_entry.yml                   # ✅ New playbook using task
│   ├── add_technitium_dns_entry.yml.backup # 📦 Backed up old version
│   └── roles/
│       └── dns-manager/                    # ✅ Enhanced role
│           ├── tasks/main.yml              # Uses task file
│           └── defaults/main.yml           # Technitium defaults
└── scripts/
    └── migrate-dns-references.sh           # ✅ Migration helper
```

## 🚀 **Usage Examples**

### **1. In Playbooks (Direct Task Include)**
```yaml
- name: Add DNS entry for my server
  hosts: my_servers
  tasks:
    - name: Create DNS entry
      ansible.builtin.include_tasks: tasks/add_technitium_dns_entry.yml
      vars:
        dns_record_name: "{{ inventory_hostname }}"
        dns_zone: "{{ base_domain }}"
        dns_ip_address: "{{ ansible_default_ipv4.address }}"
```

### **2. Using the DNS Manager Role**
```yaml
- name: Setup cluster DNS
  hosts: control_plane[0]
  roles:
    - role: dns-manager
      vars:
        cluster_endpoint: "my-cluster.local.mk-labs.cloud"
        cluster_vip: "10.1.71.100"
```

### **3. Using the New Playbook**
```yaml
# Import the new modular playbook
- import_playbook: add_dns_entry.yml
```

### **4. In Cluster Network Setup**
```yaml
- name: Setup complete cluster network
  ansible.builtin.include_role:
    name: cluster-network-setup
  vars:
    cluster_name: "fastpass"
    cluster_endpoint: "fastpass.local.mk-labs.cloud"
    cluster_vip: "10.1.71.53"
```

## 🔧 **Migration Guide**

### **Automatic Migration**
```bash
# Run the migration script to find references
./scripts/migrate-dns-references.sh
```

### **Manual Updates**

1. **Replace playbook imports:**
   ```yaml
   # OLD
   - import_playbook: add_technitium_dns_entry.yml
   
   # NEW
   - import_playbook: add_dns_entry.yml
   ```

2. **Use task includes in roles:**
   ```yaml
   - ansible.builtin.include_tasks: tasks/add_technitium_dns_entry.yml
     vars:
       dns_record_name: "my-server"
       dns_ip_address: "10.1.71.100"
   ```

3. **Use the dns-manager role:**
   ```yaml
   - ansible.builtin.include_role:
       name: dns-manager
   ```

## 📋 **Variable Reference**

### **Task Variables (`tasks/add_technitium_dns_entry.yml`)**
| Variable | Default | Description |
|----------|---------|-------------|
| `dns_record_name` | `inventory_hostname` | DNS record name |
| `dns_zone` | `base_domain` | DNS zone |
| `dns_ip_address` | `ip_address` | IP address for A record |
| `dns_record_type` | `A` | DNS record type |
| `dns_ttl` | `360` | TTL in seconds |
| `dns_create_ptr` | `true` | Create PTR record |
| `dns_debug` | `true` | Show debug output |

### **DNS Manager Role Variables**
| Variable | Default | Description |
|----------|---------|-------------|
| `cluster_endpoint` | - | Full cluster FQDN |
| `cluster_vip` | - | Cluster VIP address |
| `dns_management_enabled` | `true` | Enable DNS management |
| `use_hosts_file_fallback` | `true` | Add to /etc/hosts |
| `dns_ttl` | `360` | DNS TTL |
| `create_ptr_record` | `true` | Create PTR record |

## 🎯 **Benefits**

### ✅ **Modularity**
- Single task file used across multiple contexts
- Consistent DNS management approach
- Easy to maintain and update

### ✅ **Flexibility**
- Works in playbooks, roles, and standalone
- Parameterized for different use cases
- Supports multiple DNS providers (extensible)

### ✅ **Maintainability**
- One place to update DNS logic
- Clear variable interface
- Better error handling and debugging

### ✅ **Integration**
- Seamlessly integrates with cluster setup
- Works with existing homelab infrastructure
- Compatible with Traefik load balancer setup

## 🔄 **Integration with Cluster Setup**

The DNS management now integrates seamlessly with your cluster deployment:

```yaml
# In fastpass-first-control-plane role
- name: Setup network infrastructure for FastPass cluster
  ansible.builtin.include_role:
    name: cluster-network-setup
  vars:
    cluster_name: "{{ cluster_name }}"
    cluster_endpoint: "{{ control_plane_endpoint }}"
    cluster_vip: "{{ ansible_default_ipv4.address }}"
    control_plane_nodes: "{{ groups['fastpass_control_plane'] }}"
```

This automatically:
1. ✅ Creates DNS entry for `fastpass.local.mk-labs.cloud`
2. ✅ Configures Traefik load balancer
3. ✅ Tests connectivity
4. ✅ Provides fallback to /etc/hosts

## 🚀 **Next Steps**

1. **Test the refactored approach** with your FastPass cluster
2. **Extend to other clusters** (Hub, Internal) using the same pattern
3. **Add support for other DNS providers** if needed
4. **Create monitoring** for DNS health checks

This modular approach makes your homelab's DNS management much more maintainable and repeatable across all your Kubernetes clusters!