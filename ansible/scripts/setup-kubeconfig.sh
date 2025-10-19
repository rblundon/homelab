#!/bin/bash

# FastPass Homelab - Kubeconfig Setup Script
# This script makes it easy to add any cluster's kubeconfig to your local config

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
    echo "Usage: $0 <cluster_name> <host_group>"
    echo ""
    echo "Examples:"
    echo "  $0 fastpass fastpass_control_plane[0]"
    echo "  $0 hub hub_cluster"
    echo "  $0 internal internal_cluster[0]"
    echo ""
    echo "Available clusters in your homelab:"
    echo "  - fastpass (FastPass Kubernetes cluster)"
    echo "  - hub (OpenShift Hub cluster)"
    echo "  - internal (Internal OpenShift cluster)"
    echo ""
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    print_status "ERROR" "Invalid number of arguments"
    usage
fi

CLUSTER_NAME=$1
HOST_GROUP=$2

print_status "INFO" "Setting up kubeconfig for cluster: $CLUSTER_NAME"
print_status "INFO" "Target hosts: $HOST_GROUP"

# Check if inventory file exists
if [ ! -f "inventory.yml" ]; then
    print_status "ERROR" "inventory.yml not found. Please run from ansible directory."
    exit 1
fi

# Run the kubeconfig setup
print_status "INFO" "Running Ansible playbook..."

ansible-playbook -i inventory.yml \
    playbooks/examples/multi-cluster-kubeconfig.yml \
    --limit "$HOST_GROUP" \
    -e "target_cluster_hosts=$HOST_GROUP" \
    -e "target_cluster_name=$CLUSTER_NAME" \
    --tags kubeconfig

if [ $? -eq 0 ]; then
    print_status "SUCCESS" "Kubeconfig setup completed for $CLUSTER_NAME"
    print_status "INFO" "You can now use: kubectl config use-context ${CLUSTER_NAME}-admin"
    
    # Show available contexts
    echo ""
    print_status "INFO" "Available contexts:"
    kubectl config get-contexts 2>/dev/null || print_status "WARN" "kubectl not found or kubeconfig not accessible"
else
    print_status "ERROR" "Kubeconfig setup failed"
    exit 1
fi