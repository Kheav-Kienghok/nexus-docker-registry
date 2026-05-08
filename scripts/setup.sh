#!/usr/bin/env bash
set -euo pipefail

TFVARS="terraform/terraform.tfvars"

# Defaults
REGION="us-east-1"
INSTANCE_TYPE="t3.medium"
STORAGE=30
CIDR="0.0.0.0/0"
PROJECT="nexus-docker-registry"

# Load existing values from tfvars if present
if [[ -f "$TFVARS" ]]; then
  _read() { grep -E "^$1" "$TFVARS" 2>/dev/null | sed 's/.*=\s*"\?\([^"]*\)"\?/\1/' | tr -d ' ' || true; }
  [[ -n "$(_read aws_region)"       ]] && REGION="$(_read aws_region)"
  [[ -n "$(_read instance_type)"    ]] && INSTANCE_TYPE="$(_read instance_type)"
  [[ -n "$(_read root_volume_size)" ]] && STORAGE="$(_read root_volume_size)"
  [[ -n "$(_read allowed_cidr)"     ]] && CIDR="$(_read allowed_cidr)"
  [[ -n "$(_read project_name)"     ]] && PROJECT="$(_read project_name)"
fi

echo ""
echo "=============================================="
echo "  Nexus Docker Registry — Deployment Setup"
echo "=============================================="
echo ""
echo "Current settings:"
printf "  %-20s = %s\n" "aws_region"       "$REGION"
printf "  %-20s = %s\n" "instance_type"    "$INSTANCE_TYPE"
printf "  %-20s = %s GB\n" "root_volume_size" "$STORAGE"
printf "  %-20s = %s\n" "allowed_cidr"     "$CIDR"
printf "  %-20s = %s\n" "project_name"     "$PROJECT"
echo ""
read -r -p "Do you want to modify these settings? [y/N]: " MODIFY

if [[ "$MODIFY" =~ ^[Yy]$ ]]; then
  echo ""
  read -r -p "AWS Region               [$REGION]: " input
  REGION="${input:-$REGION}"

  read -r -p "Instance Type            [$INSTANCE_TYPE]: " input
  INSTANCE_TYPE="${input:-$INSTANCE_TYPE}"

  read -r -p "Root Volume Size (GB)    [$STORAGE]: " input
  STORAGE="${input:-$STORAGE}"

  read -r -p "Allowed CIDR             [$CIDR]: " input
  CIDR="${input:-$CIDR}"

  read -r -p "Project Name             [$PROJECT]: " input
  PROJECT="${input:-$PROJECT}"
fi

cat > "$TFVARS" <<EOF
aws_region       = "$REGION"
instance_type    = "$INSTANCE_TYPE"
root_volume_size = $STORAGE
allowed_cidr     = "$CIDR"
project_name     = "$PROJECT"
EOF

echo ""
echo "Settings saved to $TFVARS"
echo ""
