#!/bin/bash

# Migration script to update DNS entry references
# This script helps migrate from the old add_technitium_dns_entry.yml to the new modular approach

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "INFO" "Migrating DNS entry references to modular approach..."

# Search for references to the old playbook
OLD_PLAYBOOK="add_technitium_dns_entry.yml"
NEW_PLAYBOOK="add_dns_entry.yml"

# Find all YAML files that might reference the old playbook
YAML_FILES=$(find . -name "*.yml" -type f | grep -v ".git")

FOUND_REFERENCES=0

for file in $YAML_FILES; do
    if grep -q "$OLD_PLAYBOOK" "$file" 2>/dev/null; then
        print_status "WARN" "Found reference in: $file"
        FOUND_REFERENCES=$((FOUND_REFERENCES + 1))
        
        # Show the context
        echo "  Context:"
        grep -n -B2 -A2 "$OLD_PLAYBOOK" "$file" | sed 's/^/    /'
        echo ""
    fi
done

if [ $FOUND_REFERENCES -eq 0 ]; then
    print_status "SUCCESS" "No references to $OLD_PLAYBOOK found"
else
    print_status "INFO" "Found $FOUND_REFERENCES references to migrate"
    print_status "INFO" "Migration options:"
    echo ""
    echo "1. Replace playbook imports:"
    echo "   OLD: - import_playbook: $OLD_PLAYBOOK"
    echo "   NEW: - import_playbook: $NEW_PLAYBOOK"
    echo ""
    echo "2. Use task includes in roles:"
    echo "   - ansible.builtin.include_tasks: tasks/add_technitium_dns_entry.yml"
    echo ""
    echo "3. Use the dns-manager role:"
    echo "   - ansible.builtin.include_role:"
    echo "       name: dns-manager"
fi

# Check if the old playbook exists and suggest backup
if [ -f "playbooks/$OLD_PLAYBOOK" ]; then
    print_status "INFO" "Old playbook exists at: playbooks/$OLD_PLAYBOOK"
    print_status "INFO" "Consider backing it up before removing:"
    echo "  mv playbooks/$OLD_PLAYBOOK playbooks/${OLD_PLAYBOOK}.backup"
fi

print_status "SUCCESS" "Migration analysis complete"