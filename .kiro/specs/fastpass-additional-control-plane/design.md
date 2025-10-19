# Design Document

## Overview

The `fastpass-additional-control-plane` Ansible role will enable the deployment of additional control plane nodes to an existing FastPass Kubernetes cluster. This role follows the established patterns from `fastpass-first-control-plane` but focuses on joining nodes to an already initialized cluster rather than initializing a new one. The role ensures high availability by creating redundant master nodes that can handle API requests, scheduling, and cluster management tasks.

The key difference from the first control plane role is that this role will use `kubeadm join` with control plane flags instead of `kubeadm init`, and it will need to retrieve join tokens and certificate keys from the existing cluster.

## Architecture

### Role Structure
The role will follow the standard Ansible role structure:
```
ansible/playbooks/roles/fastpass-additional-control-plane/
├── defaults/
│   └── main.yml
├── tasks/
│   └── main.yml
├── handlers/
│   └── main.yml (if needed)
└── meta/
    └── main.yml (if needed)
```

### Integration Points
- **DNS Management**: Uses the existing `dns-manager` role for consistent DNS record creation
- **Kubeconfig Management**: Uses the existing `kubeconfig-manager` role for local kubeconfig setup
- **Firewall Configuration**: Reuses firewall service definitions from the first control plane role
- **Cluster Integration**: Coordinates with the first control plane node to obtain join credentials

### Dependencies
- The first control plane node must be fully initialized and running
- The `dns-manager` role must be available for DNS record creation
- The `kubeconfig-manager` role must be available for kubeconfig setup
- Required Kubernetes prerequisites must be installed on target nodes

## Components and Interfaces

### Main Task Flow
1. **Pre-flight Checks**: Verify cluster readiness and node prerequisites
2. **DNS Configuration**: Set up DNS records for the new control plane node
3. **Firewall Configuration**: Open required ports for control plane services
4. **Kubelet Configuration**: Create initial kubelet configuration
5. **Join Token Retrieval**: Get join token and certificate key from first control plane
6. **Cluster Join**: Execute kubeadm join with control plane flags
7. **Service Management**: Ensure kubelet is enabled and running
8. **Kubeconfig Setup**: Configure local kubeconfig access
9. **Verification**: Validate successful cluster join

### Key Variables
- `cluster_name`: Name of the Kubernetes cluster
- `ip_address`: IP address of the current control plane node
- `first_control_plane_host`: Hostname/IP of the first control plane node
- `kubernetes_services_control_plane`: List of firewall services to open
- `join_token_ttl`: TTL for join tokens (default: 24h)
- `certificate_key_ttl`: TTL for certificate keys (default: 2h)

### External Role Interfaces
- **dns-manager**: Provides DNS record creation with `host_name` variable
- **kubeconfig-manager**: Handles kubeconfig merging with `cluster_name` variable
- **First Control Plane**: Source for join tokens and certificate keys

## Data Models

### Join Credentials Structure
```yaml
join_credentials:
  token: "abcdef.1234567890abcdef"
  discovery_token_ca_cert_hash: "sha256:..."
  certificate_key: "..."
  api_server_endpoint: "cluster-name:6443"
```

### Firewall Services
```yaml
kubernetes_services_control_plane:
  - kubernetes_API      # Port 6443
  - etcd               # Ports 2379-2380
  - kubelet            # Port 10250
  - kube-scheduler     # Port 10259
  - kube-controller-manager  # Port 10257
```

### Node Status Tracking
```yaml
node_status:
  joined: false
  kubelet_running: false
  dns_configured: false
  kubeconfig_ready: false
```

## Error Handling

### Join Token Management
- **Token Expiration**: Automatically generate new tokens if existing ones are expired
- **Certificate Key Rotation**: Handle certificate key expiration gracefully
- **Network Connectivity**: Retry join operations with exponential backoff
- **API Server Availability**: Wait for API server readiness before attempting join

### Idempotency Checks
- **Already Joined Nodes**: Skip join process if node is already part of the cluster
- **Existing Configuration**: Preserve existing kubelet configuration if valid
- **DNS Records**: Update existing DNS records instead of creating duplicates
- **Service Status**: Only restart services if configuration changes

### Failure Recovery
- **Partial Join Failures**: Clean up partial configurations and retry
- **Network Issues**: Provide clear error messages for connectivity problems
- **Permission Errors**: Validate sudo/root access before attempting operations
- **Resource Constraints**: Check system resources before proceeding

## Testing Strategy

### Unit Testing Approach
- **Task Validation**: Test individual tasks with mock data
- **Variable Validation**: Ensure required variables are properly defined
- **Conditional Logic**: Test all conditional branches in tasks
- **Error Scenarios**: Validate error handling for common failure cases

### Integration Testing
- **Multi-Node Clusters**: Test with 3 and 5 control plane node configurations
- **Network Scenarios**: Test across different network topologies
- **OS Compatibility**: Validate on supported operating systems (Ubuntu/Debian)
- **Version Compatibility**: Test with different Kubernetes versions

### Validation Checks
- **Cluster Health**: Verify all control plane nodes are healthy after join
- **API Availability**: Confirm API server is accessible from all nodes
- **Etcd Cluster**: Validate etcd cluster membership and health
- **Scheduling**: Test pod scheduling across all control plane nodes
- **Failover**: Verify cluster continues operating if one control plane fails

### Test Scenarios
1. **Fresh Join**: Join additional control plane to newly created cluster
2. **Existing Cluster**: Add control plane to cluster with existing workloads
3. **Network Partitions**: Test behavior during temporary network issues
4. **Token Expiration**: Handle expired join tokens gracefully
5. **Retry Operations**: Validate retry logic for transient failures

## Implementation Considerations

### Security
- **Token Security**: Ensure join tokens are handled securely and not logged
- **Certificate Management**: Properly manage and rotate certificate keys
- **Network Security**: Validate firewall rules don't expose unnecessary ports
- **Access Control**: Ensure proper RBAC is maintained after node joins

### Performance
- **Parallel Execution**: Support joining multiple control plane nodes simultaneously
- **Resource Usage**: Monitor CPU and memory usage during join process
- **Network Bandwidth**: Optimize data transfer during cluster join
- **Startup Time**: Minimize time to achieve cluster readiness

### Monitoring and Observability
- **Join Progress**: Provide clear progress indicators during join process
- **Health Checks**: Implement comprehensive health validation
- **Logging**: Ensure adequate logging for troubleshooting
- **Metrics**: Expose relevant metrics for monitoring cluster growth

### Compatibility
- **Kubernetes Versions**: Support current and previous Kubernetes versions
- **Operating Systems**: Maintain compatibility with Ubuntu and Debian
- **Container Runtimes**: Work with containerd runtime configuration
- **Network Plugins**: Compatible with Flannel CNI configuration