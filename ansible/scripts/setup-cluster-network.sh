#!/bin/bash

# FastPass Homelab - Cluster Network Setup Script
# This script sets up DNS (via Technitium) and load balancer configuration for any Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}ℹ️  INFO${NC}: $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ SUCCESS${NC}: $message"
            ;;
        "ERROR")
            echo -e "${RED}❌ ERROR${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ;;
    esac
}

# Usage function
usage() {
    echo "Usage: $0 <cluster_name> <cluster_endpoint> <control_plane_group>"
    echo ""
    echo "Examples:"
    echo "  $0 fastpass fastpass.local.mk-labs.cloud fastpass_control_plane"
    echo "  $0 hub hub.local.mk-labs.cloud hub_cluster"
    echo "  $0 internal internal.local.mk-labs.cloud internal_cluster"
    echo ""
    echo "This script will:"
    echo "  1. Create DNS entry for the cluster endpoint"
    echo "  2. Configure Traefik load balancer"
    echo "  3. Test connectivity"
    echo ""
    exit 1
}

# Check arguments
if [ $# -ne 3 ]; then
    print_status "ERROR" "Invalid number of arguments"
    usage
fi

CLUSTER_NAME=$1
CLUSTER_ENDPOINT=$2
CONTROL_PLANE_GROUP=$3

print_status "INFO" "Setting up network for cluster: $CLUSTER_NAME"
print_status "INFO" "Endpoint: $CLUSTER_ENDPOINT"
print_status "INFO" "Control plane group: $CONTROL_PLANE_GROUP"

# Check if inventory file exists
if [ ! -f "inventory.yml" ]; then
    print_status "ERROR" "inventory.yml not found. Please run from ansible directory."
    exit 1
fi

# Create temporary playbook
TEMP_PLAYBOOK=$(mktemp /tmp/cluster-network-setup-XXXXXX.yml)
cat > "$TEMP_PLAYBOOK" << EOF
---
- name: Setup network infrastructure for $CLUSTER_NAME
  hosts: ${CONTROL_PLANE_GROUP}[0]
  gather_facts: true
  tasks:
    - name: Setup cluster network infrastructure
      ansible.builtin.include_role:
        name: cluster-network-setup
      vars:
        cluster_name: "$CLUSTER_NAME"
        cluster_endpoint: "$CLUSTER_ENDPOINT"
        cluster_vip: "{{ ansible_default_ipv4.address }}"
        control_plane_nodes: "{{ groups['$CONTROL_PLANE_GROUP'] }}"
EOF

print_status "INFO" "Running network setup playbook..."

# Run the network setup
if ansible-playbook -i inventory.yml "$TEMP_PLAYBOOK"; then
    print_status "SUCCESS" "Network setup completed for $CLUSTER_NAME"
    
    # Test connectivity
    print_status "INFO" "Testing connectivity to $CLUSTER_ENDPOINT:6443..."
    if timeout 10 bash -c "</dev/tcp/$CLUSTER_ENDPOINT/6443"; then
        print_status "SUCCESS" "Connectivity test passed"
    else
        print_status "WARN" "Connectivity test failed - may need time to propagate"
    fi
    
    print_status "INFO" "Network setup complete. You can now:"
    echo "  1. Deploy your cluster"
    echo "  2. Test with: kubectl --server=https://$CLUSTER_ENDPOINT:6443 cluster-info"
    
else
    print_status "ERROR" "Network setup failed"
    exit 1
fi

# Cleanup
rm -f "$TEMP_PLAYBOOK"