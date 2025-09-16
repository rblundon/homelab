#!/bin/bash

# FastPass Kubernetes Cluster Deployment Test Script
# This script validates the Ansible playbooks before deployment

set -e

echo "🧪 FastPass Kubernetes Cluster Deployment Test"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✅ PASS${NC}: $message"
            ;;
        "FAIL")
            echo -e "${RED}❌ FAIL${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  WARN${NC}: $message"
            ;;
    esac
}

# Test 1: Check if Ansible is installed
echo ""
echo "1. Checking Ansible installation..."
if command -v ansible-playbook &> /dev/null; then
    ANSIBLE_VERSION=$(ansible-playbook --version | head -n1)
    print_status "PASS" "Ansible found: $ANSIBLE_VERSION"
else
    print_status "FAIL" "Ansible not found. Please install Ansible."
    exit 1
fi

# Test 2: Check inventory file
echo ""
echo "2. Checking inventory file..."
if [ -f "inventory.yml" ]; then
    print_status "PASS" "Inventory file found: inventory.yml"
    
    # Check if fastpass groups exist
    if grep -q "fastpass_control_plane:" inventory.yml; then
        print_status "PASS" "fastpass_control_plane group found"
    else
        print_status "FAIL" "fastpass_control_plane group not found in inventory"
    fi
    
    if grep -q "fastpass_workers:" inventory.yml; then
        print_status "PASS" "fastpass_workers group found"
    else
        print_status "FAIL" "fastpass_workers group not found in inventory"
    fi
else
    print_status "FAIL" "Inventory file not found: inventory.yml"
    exit 1
fi

# Test 3: Check playbook files
echo ""
echo "3. Checking playbook files..."
if [ -f "playbooks/deploy-fastpass-cluster.yml" ]; then
    print_status "PASS" "Main deployment playbook found"
else
    print_status "FAIL" "Main deployment playbook not found"
fi

if [ -f "playbooks/deploy_k8s.yml" ]; then
    print_status "PASS" "Legacy deployment playbook found"
else
    print_status "WARN" "Legacy deployment playbook not found"
fi

# Test 4: Check role files
echo ""
echo "4. Checking role files..."
ROLES=(
    "playbooks/roles/kubernetes/tasks/main.yml"
    "playbooks/roles/fastpass-control-plane/tasks/main.yml"
    "playbooks/roles/fastpass-control-plane-join/tasks/main.yml"
    "playbooks/roles/fastpass-workers/tasks/main.yml"
    "playbooks/roles/fastpass-workers/tasks/node-labels.yml"
)

for role in "${ROLES[@]}"; do
    if [ -f "$role" ]; then
        print_status "PASS" "Role file found: $role"
    else
        print_status "FAIL" "Role file not found: $role"
    fi
done

# Test 5: Check group_vars
echo ""
echo "5. Checking group variables..."
if [ -f "group_vars/fastpass/vars" ]; then
    print_status "PASS" "FastPass group variables found"
    
    # Check for required variables
    if grep -q "pod_network_cidr:" group_vars/fastpass/vars; then
        print_status "PASS" "pod_network_cidr variable found"
    else
        print_status "WARN" "pod_network_cidr variable not found"
    fi
    
    if grep -q "control_plane_endpoint:" group_vars/fastpass/vars; then
        print_status "PASS" "control_plane_endpoint variable found"
    else
        print_status "WARN" "control_plane_endpoint variable not found"
    fi
else
    print_status "FAIL" "FastPass group variables not found"
fi

# Test 6: Validate playbook syntax
echo ""
echo "6. Validating playbook syntax..."
if ansible-playbook --syntax-check playbooks/deploy-fastpass-cluster.yml > /dev/null 2>&1; then
    print_status "PASS" "Main playbook syntax is valid"
else
    print_status "FAIL" "Main playbook syntax is invalid"
    echo "Running syntax check with verbose output:"
    ansible-playbook --syntax-check playbooks/deploy-fastpass-cluster.yml
fi

# Test 7: Check for common issues
echo ""
echo "7. Checking for common issues..."

# Check for hardcoded values
if grep -r "10.244.0.0/16" playbooks/ | grep -v "group_vars" > /dev/null; then
    print_status "WARN" "Hardcoded pod network CIDR found in playbooks"
else
    print_status "PASS" "No hardcoded pod network CIDR found"
fi

# Check for proper kubeconfig usage
if grep -r "kubectl --kubeconfig" playbooks/ > /dev/null; then
    print_status "PASS" "Proper kubeconfig usage found"
else
    print_status "WARN" "No explicit kubeconfig usage found"
fi

# Test 8: DNS validation
echo ""
echo "8. Validating DNS setup..."
CONTROL_PLANE_ENDPOINT="fastpass.local.mk-labs.cloud"
if nslookup "$CONTROL_PLANE_ENDPOINT" > /dev/null 2>&1; then
    print_status "PASS" "DNS resolution successful for $CONTROL_PLANE_ENDPOINT"
    
    # Get A records
    A_RECORDS=$(nslookup "$CONTROL_PLANE_ENDPOINT" | grep -A 10 "Name:" | grep "Address:" | awk '{print $2}' | sort)
    RECORD_COUNT=$(echo "$A_RECORDS" | wc -l)
    
    if [ "$RECORD_COUNT" -ge 1 ]; then
        print_status "PASS" "Found $RECORD_COUNT A record(s) for load balancing"
        echo "   DNS records:"
        echo "$A_RECORDS" | while read -r ip; do
            echo "   - $ip"
        done
    else
        print_status "WARN" "No A records found for $CONTROL_PLANE_ENDPOINT"
    fi
else
    print_status "FAIL" "DNS resolution failed for $CONTROL_PLANE_ENDPOINT"
    echo "   Please run: ./scripts/validate-dns-setup.sh for detailed DNS validation"
fi

# Test 9: Check SSH connectivity (if hosts are available)
echo ""
echo "9. Checking SSH connectivity..."
if [ -n "$1" ]; then
    echo "Testing SSH connectivity to specified host: $1"
    if ssh -o ConnectTimeout=5 -o BatchMode=yes "$1" exit 2>/dev/null; then
        print_status "PASS" "SSH connectivity to $1 successful"
    else
        print_status "FAIL" "SSH connectivity to $1 failed"
    fi
else
    print_status "WARN" "No host specified for SSH test. Use: $0 <hostname>"
fi

# Summary
echo ""
echo "=============================================="
echo "🎯 Deployment Test Summary"
echo "=============================================="
echo ""
echo "To deploy the FastPass cluster:"
echo "1. Ensure all tests above pass"
echo "2. Run: ansible-playbook -i inventory.yml playbooks/deploy-fastpass-cluster.yml"
echo ""
echo "To test with a specific host:"
echo "   $0 <hostname>"
echo ""
echo "To validate DNS setup:"
echo "   ./scripts/validate-dns-setup.sh"
echo ""
echo "To validate the deployment:"
echo "   ./scripts/manage-kubeconfigs.sh test"
echo "" 