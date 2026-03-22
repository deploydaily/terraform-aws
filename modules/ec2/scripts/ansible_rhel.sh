#!/bin/bash
set -euxo pipefail

exec > >(tee /var/log/user-data.log) 2>&1

echo "Starting Ansible control node setup on RHEL 9"

dnf install -y git python3 python3-pip ansible-core

mkdir -p /opt/ansible/{playbooks,inventory,roles}

cat >/opt/ansible/inventory/hosts.ini <<'EOF'
[local]
localhost ansible_connection=local
EOF

chown -R ec2-user:ec2-user /opt/ansible

echo "Ansible control node setup completed successfully"

ansible --version