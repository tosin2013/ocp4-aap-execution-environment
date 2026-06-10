#!/bin/bash
# Inject Automation Hub token into ansible.cfg before build
# Usage: ./inject-galaxy-token.sh <offline_token>

set -euo pipefail

OFFLINE_TOKEN="${1:-}"

if [ -z "$OFFLINE_TOKEN" ]; then
  echo "ERROR: Offline token required"
  echo "Usage: $0 <offline_token>"
  exit 1
fi

# Replace placeholder in ansible.cfg
sed -i "s/ANSIBLE_GALAXY_TOKEN_PLACEHOLDER/${OFFLINE_TOKEN}/g" ansible.cfg

echo "✓ Galaxy token injected into ansible.cfg"
echo "  Certified server: configured"
echo "  Validated server: configured"
echo "  Community server: configured"
