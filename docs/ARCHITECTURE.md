# AWX on AWS — Architecture Reference
> ACG Sandbox build · Interview showcase · Enterprise comparison

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [AWS Resources](#aws-resources)
3. [Instance Budget](#instance-budget)
4. [AWX Components on RHEL 9](#awx-components-on-rhel-9)
5. [Security Groups](#security-groups)
6. [IAM Instance Profile](#iam-instance-profile)
7. [RDS PostgreSQL](#rds-postgresql)
8. [Secrets Manager](#secrets-manager)
9. [ECR — Execution Environments](#ecr--execution-environments)
10. [Dynamic Inventory](#dynamic-inventory)
11. [Managed Nodes](#managed-nodes)
12. [GitHub Integration](#github-integration)
13. [Sandbox vs Enterprise Comparison](#sandbox-vs-enterprise-comparison)
14. [Architecture Decision Records](#architecture-decision-records)
15. [2–3 Day Build Plan](#23-day-build-plan)

---

## Architecture Overview

```
Your Browser / GitHub Actions
         |
         | HTTPS :443 (self-signed cert)
         v
┌─────────────────────────────────────────────────────────┐
│  AWS VPC  10.0.0.0/16  ·  us-east-1                    │
│                                                         │
│  ┌─── Public Subnet 10.0.1.0/24 ───────────────────┐  │
│  │  AWX Controller (t3.medium · RHEL 9)             │  │
│  │  nginx :443 → awx-web :8052                      │  │
│  │  Internet Gateway (outbound: GitHub, ECR, dnf)   │  │
│  └──────────────────────────────────────────────────┘  │
│           |  SSH/receptor to managed nodes              │
│  ┌─── Private Subnet 10.0.2.0/24 ──────────────────┐  │
│  │  RDS PostgreSQL 15   (db.t3.medium)              │  │
│  │  Secrets Manager     (SSH keys, passwords)       │  │
│  │  ECR                 (EE images)                 │  │
│  │                                                  │  │
│  │  linux-node-01   Amazon Linux 2023  t3.micro     │  │
│  │  linux-node-02   Amazon Linux 2023  t3.micro     │  │
│  │  windows-node-01 Windows Server 2022  t3.micro   │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘

GitHub (external) — AWX SCM source + GitHub Actions CI/CD
```

---

## AWS Resources

| Resource | Type / Size | Purpose | Subnet |
|---|---|---|---|
| EC2 — AWX controller | t3.medium · RHEL 9 | Runs all AWX services | Public |
| EC2 — linux-node-01 | t3.micro · Amazon Linux 2023 | Ansible target (dev) | Private |
| EC2 — linux-node-02 | t3.micro · Amazon Linux 2023 | Ansible target (prod) | Private |
| EC2 — windows-node-01 | t3.micro · Windows Server 2022 | Ansible target (WinRM) | Private |
| RDS — PostgreSQL 15 | db.t3.medium · 20 GB | AWX database backend | Private |
| Secrets Manager | — | SSH keys, passwords | — |
| ECR | — | Execution Environment images | — |
| IAM instance profile | — | EC2 permissions for AWX | — |
| VPC + subnets | 10.0.0.0/16 | Network isolation | — |
| Internet Gateway | — | Outbound from public subnet | — |
| Security groups | × 3 | Network access control | — |

---

## Instance Budget

```
1 × t3.medium   AWX controller
2 × t3.micro    Linux managed nodes
1 × t3.micro    Windows managed node
─────────────────────────────────
4 of 5          instances used  (1 spare)
```

> **ACG sandbox limit:** 5 EC2 instances max. Stopped instances count toward the limit.
> Keep all 4 running during your build window. Stop managed nodes when not testing playbooks.

---

## AWX Components on RHEL 9

AWX runs as **four systemd services** directly on the OS — no Kubernetes, no containers.

```
systemctl status awx-web       # Django app · REST API · UI  · port 8052
systemctl status awx-task      # Celery worker · job dispatch
systemctl status awx-receptor  # Execution mesh · runs playbooks · port 27199
systemctl status redis         # Queue + cache · port 6379 (local)
```

nginx sits in front as a reverse proxy, terminates TLS on `:443`, and proxies to `awx-web` on `:8052`.

### AWX installer command
```bash
# Install via AWX collection-based installer on RHEL 9
sudo dnf install -y ansible-core
ansible-galaxy collection install awx.awx
# Run the installer playbook pointing at your RDS endpoint
ansible-playbook -i inventory install.yml \
  -e pg_host=<rds-endpoint> \
  -e pg_password=<secret>
```

### Key config file
```
/etc/awx/settings.py      # Main AWX settings — DB, Redis, URLs
/etc/nginx/conf.d/awx.conf # nginx reverse proxy config
```

### Check all services are healthy
```bash
awx-manage check_license
awx-manage inventory_import --source=/path/to/inventory
curl -sk https://localhost/api/v2/ping/ | python3 -m json.tool
```

---

## Security Groups

### sg-awx-controller (attached to AWX controller EC2)
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 443 | TCP | Your IP /32 | AWX Web UI + API |
| Inbound | 22 | TCP | Your IP /32 | SSH admin access |
| Outbound | All | All | 0.0.0.0/0 | GitHub, ECR, dnf repos |

### sg-rds (attached to RDS instance)
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 5432 | TCP | sg-awx-controller | PostgreSQL from AWX only |

### sg-managed-nodes (attached to Linux + Windows EC2s)
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | sg-awx-controller | SSH from AWX controller |
| Inbound | 5985 | TCP | sg-awx-controller | WinRM HTTP (Windows) |
| Inbound | 5986 | TCP | sg-awx-controller | WinRM HTTPS (Windows) |

---

## IAM Instance Profile

Attach this policy to the AWX controller EC2 instance role. No hardcoded credentials needed — AWX uses the instance metadata service.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2DynamicInventory",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRPullEE",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerLookup",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:awx/*"
    }
  ]
}
```

---

## RDS PostgreSQL

### Terraform resource (key settings)
```hcl
resource "aws_db_instance" "awx" {
  identifier        = "awx-postgres"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t3.medium"
  allocated_storage = 20
  db_name           = "awx"
  username          = "awx"
  password          = var.db_password   # store in Secrets Manager
  db_subnet_group_name   = aws_db_subnet_group.awx.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true         # sandbox only
  publicly_accessible    = false
}
```

### AWX settings.py database block
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'awx',
        'USER': 'awx',
        'PASSWORD': '<from-secrets-manager>',
        'HOST': '<rds-endpoint>.rds.amazonaws.com',
        'PORT': '5432',
    }
}
```

---

## Secrets Manager

Store the following secrets under the prefix `awx/`:

| Secret name | Value | Used by |
|---|---|---|
| `awx/db-password` | RDS PostgreSQL password | AWX installer |
| `awx/admin-password` | AWX UI admin password | First login |
| `awx/ssh-private-key` | SSH key for managed nodes | AWX machine credential |
| `awx/winrm-password` | Windows admin password | AWX WinRM credential |

### AWX custom credential type for Secrets Manager lookup

**Input configuration (YAML):**
```yaml
fields:
  - id: secret_name
    type: string
    label: Secret Name
required:
  - secret_name
```

**Injector configuration (YAML):**
```yaml
extra_vars:
  aws_secret: !unsafe "{{ lookup('amazon.aws.aws_secret',
    secret_name, region='us-east-1') }}"
```

---

## ECR — Execution Environments

### Build and push an EE
```bash
# Install ansible-builder
pip3 install ansible-builder

# Build the EE image
ansible-builder build \
  --tag awx-ee-linux:latest \
  --file execution-environment.yml \
  --container-runtime docker

# Authenticate to ECR
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS \
    --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

# Tag and push
docker tag awx-ee-linux:latest \
  <account>.dkr.ecr.us-east-1.amazonaws.com/awx-ee-linux:latest
docker push \
  <account>.dkr.ecr.us-east-1.amazonaws.com/awx-ee-linux:latest
```

### execution-environment.yml (Linux baseline EE)
```yaml
version: 3
images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform/ee-minimal-rhel8:latest

dependencies:
  galaxy:
    collections:
      - name: ansible.posix
      - name: community.general
      - name: amazon.aws
      - name: ansible.windows

  python:
    - boto3
    - botocore
    - pywinrm
```

### Configure EE in AWX
- AWX UI → Administration → Execution Environments → Add
- Name: `ee-linux-baseline`
- Image: `<account>.dkr.ecr.us-east-1.amazonaws.com/awx-ee-linux:latest`
- Pull: Always
- Credential: ECR credential (uses instance profile)

---

## Dynamic Inventory

### aws_ec2.yml — place in AWX project SCM or configure as inventory source
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running
keyed_groups:
  - key: tags.role
    prefix: role
  - key: tags.env
    prefix: env
compose:
  ansible_host: public_ip_address
hostnames:
  - tag:Name
```

### EC2 tags to set on managed nodes

| Instance | Tags |
|---|---|
| linux-node-01 | `Name=linux-node-01` `role=linux` `env=dev` `managed_by=awx` |
| linux-node-02 | `Name=linux-node-02` `role=linux` `env=prod` `managed_by=awx` |
| windows-node-01 | `Name=windows-node-01` `role=windows` `env=dev` `managed_by=awx` |

### Resulting inventory groups in AWX
```
all
├── role_linux
│   ├── linux-node-01
│   └── linux-node-02
├── role_windows
│   └── windows-node-01
├── env_dev
│   ├── linux-node-01
│   └── windows-node-01
└── env_prod
    └── linux-node-02
```

---

## Managed Nodes

### Linux nodes — user data (Amazon Linux 2023)
```bash
#!/bin/bash
# Ensure Python is available for Ansible
dnf install -y python3
# Create ansible user with sudo
useradd -m ansible
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible
# Add AWX controller SSH public key
mkdir -p /home/ansible/.ssh
echo "<awx-controller-public-key>" >> /home/ansible/.ssh/authorized_keys
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/.ssh
```

### Windows node — user data (PowerShell)
```powershell
<powershell>
# Enable WinRM for Ansible
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Open WinRM port in Windows Firewall
netsh advfirewall firewall add rule `
  name="WinRM-HTTP" dir=in action=allow protocol=TCP localport=5985

# Set admin password (store same value in Secrets Manager)
$Password = ConvertTo-SecureString "YourStrongPassword!" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $Password
</powershell>
```

### AWX credential for Linux nodes
- Credential type: Machine
- Username: `ansible`
- SSH private key: fetched from Secrets Manager `awx/ssh-private-key`
- Privilege escalation: sudo

### AWX credential for Windows nodes
- Credential type: Machine
- Username: `Administrator`
- Password: fetched from Secrets Manager `awx/winrm-password`
- Connection: `winrm`
- Port: `5985`

---

## GitHub Integration

### AWX project setup
- SCM type: Git
- SCM URL: `https://github.com/<you>/enterprise-awx-platform`
- SCM branch: `main`
- Update on launch: enabled
- SCM credential: GitHub PAT (stored as AWX source control credential)

### GitHub Actions pipeline (`.github/workflows/ci.yml`)
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ansible-lint
        run: pip install ansible-lint
      - name: Lint
        run: ansible-lint collections/

  molecule:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: pip install molecule molecule-docker ansible-core
      - name: Run molecule
        run: |
          cd collections/kumar/enterprise/roles/os_baseline
          molecule test

  publish-collection:
    runs-on: ubuntu-latest
    needs: molecule
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Build and publish collection
        run: |
          ansible-galaxy collection build collections/kumar/enterprise/
          ansible-galaxy collection publish *.tar.gz \
            --server https://galaxy.ansible.com \
            --api-key ${{ secrets.GALAXY_API_KEY }}

  sync-awx:
    runs-on: ubuntu-latest
    needs: publish-collection
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Trigger AWX project sync
        run: |
          curl -s -X POST \
            -H "Authorization: Bearer ${{ secrets.AWX_TOKEN }}" \
            -H "Content-Type: application/json" \
            https://${{ secrets.AWX_HOST }}/api/v2/projects/<project-id>/update/
```

---

## Sandbox vs Enterprise Comparison

| Component | ACG Sandbox | Enterprise |
|---|---|---|
| AWX controller | t3.medium · single node | t3.xlarge+ · HA pair |
| Database | RDS db.t3.medium · single-AZ | RDS Multi-AZ · automated backups |
| Redis | Local systemd on controller | ElastiCache · Multi-AZ cluster |
| TLS / cert | Self-signed on nginx | ACM cert · ALB termination |
| DNS | EC2 public IP direct | Route 53 · awx.company.com |
| Network entry | Public IP + SG | ALB in public subnet · controller in private |
| Container registry | ECR (same) | ECR + Private Automation Hub |
| Secrets | Secrets Manager (same) | Secrets Manager + HashiCorp Vault / CyberArk |
| IAM | Instance profile (same pattern) | IRSA (pod-level) if EKS |
| Execution nodes | None (receptor on controller) | Dedicated nodes per network zone |
| Kubernetes | None — pure RHEL systemd | Optional — EKS if org standard |

---

## Architecture Decision Records

### ADR-001 — No Kubernetes in sandbox
**Decision:** Run AWX directly on RHEL 9 via systemd services, not on K3s or EKS.  
**Reason:** The JD does not mention Kubernetes. AWX on RHEL is the standard enterprise on-prem pattern and directly reflects the TrueSight + on-prem server context. K3s adds complexity without adding Ansible capability.  
**Enterprise equivalent:** Same RHEL systemd deployment on bare-metal VMs or VMware. EKS only if the org already runs EKS as a platform standard.

### ADR-002 — No ALB or Route 53 in sandbox
**Decision:** Access AWX via EC2 public IP with self-signed TLS cert on nginx.  
**Reason:** Route 53 requires a domain and ACM is not available in the ACG sandbox. This is a sandbox constraint, not an architectural preference.  
**Enterprise equivalent:** ALB in public subnet with ACM cert, controller in private subnet, Route 53 A alias record pointing to ALB DNS name.

### ADR-003 — Redis local, not ElastiCache
**Decision:** Redis runs as a local systemd service on the AWX controller.  
**Reason:** Saves one EC2 instance in the 5-instance budget. AWX installs Redis locally by default. Functionally identical for a single-node lab.  
**Enterprise equivalent:** ElastiCache Redis cluster (Multi-AZ, cache.r6g.large+) for resilience and separation of concerns.

### ADR-004 — RDS used (not local PostgreSQL)
**Decision:** Use RDS PostgreSQL even though it could run locally on the controller.  
**Reason:** RDS is available in the ACG sandbox (db.t3.medium, 50 GB max, no provisioned IOPS). Using RDS demonstrates the enterprise pattern and means the database survives a controller EC2 restart.  
**Enterprise equivalent:** Identical — RDS PostgreSQL Multi-AZ with automated backups and encryption at rest.

---

## 2–3 Day Build Plan

### Day 1 — Infrastructure (Terraform)
- [ ] VPC, public + private subnets, IGW, route tables
- [ ] Security groups (controller, RDS, managed nodes)
- [ ] IAM role + instance profile for AWX controller
- [ ] RDS PostgreSQL (db.t3.medium)
- [ ] ECR repository
- [ ] Secrets Manager secrets (db password, admin password, SSH key, WinRM password)
- [ ] 4 EC2 instances (controller + 3 managed nodes) with correct tags
- [ ] Verify: can SSH to controller, can reach RDS endpoint from controller

### Day 2 — AWX Setup
- [ ] Install AWX on RHEL 9 via installer (point at RDS)
- [ ] Verify all 4 systemd services are running
- [ ] Access UI at `https://<public-ip>` (accept cert warning)
- [ ] Configure Organizations: `Platform-Ops`, `AppDev`
- [ ] Configure Teams + RBAC permissions
- [ ] Add credentials: SSH machine, WinRM machine, AWS (for inventory)
- [ ] Configure dynamic inventory (`aws_ec2` plugin)
- [ ] Verify inventory shows all 3 managed nodes in correct groups
- [ ] Add GitHub SCM project, trigger sync
- [ ] Create job templates for each playbook
- [ ] Run first job — OS baseline on linux-node-01 — verify green

### Day 3 — Content + CI
- [ ] Build `ee-linux` EE with `ansible-builder`, push to ECR
- [ ] Configure EE in AWX, re-run job using ECR image
- [ ] Write + test 3 playbooks: `os_hardening.yml`, `patch_linux.yml`, `patch_windows.yml`
- [ ] Create workflow template: provision → harden → smoke test
- [ ] Wire up GitHub Actions: lint → molecule → AWX sync on merge
- [ ] `awx_config/` playbooks — manage all AWX config as code via `awx.awx` collection
- [ ] Capture screenshots: RBAC setup, workflow graph, job output, dynamic inventory
- [ ] Write README + ADR docs

---

## Quick Reference — AWX CLI Commands

```bash
# Check AWX version
awx-manage --version

# Create admin user (first time)
awx-manage createsuperuser

# Import static inventory
awx-manage inventory_import \
  --inventory-name="production" \
  --source=/path/to/hosts.ini

# Run a management command
awx-manage run_callback_receiver

# Check celery workers
awx-manage celery inspect active

# View AWX logs
journalctl -u awx-web -f
journalctl -u awx-task -f
journalctl -u awx-receptor -f

# Restart all AWX services
sudo systemctl restart awx-web awx-task awx-receptor

# Test AWX API
curl -sk -u admin:<password> \
  https://localhost/api/v2/ping/ | python3 -m json.tool
```

---

## Quick Reference — AWX REST API

```bash
# Set base vars
AWX_HOST="https://<public-ip>"
AWX_TOKEN="<your-token>"  # AWX UI → User → Tokens

# List all job templates
curl -s -H "Authorization: Bearer $AWX_TOKEN" \
  $AWX_HOST/api/v2/job_templates/ | python3 -m json.tool

# Launch a job template
curl -s -X POST \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"extra_vars": {"target_env": "dev"}}' \
  $AWX_HOST/api/v2/job_templates/<id>/launch/

# Get job status
curl -s -H "Authorization: Bearer $AWX_TOKEN" \
  $AWX_HOST/api/v2/jobs/<job-id>/ | python3 -m json.tool

# Sync a project (trigger SCM update)
curl -s -X POST \
  -H "Authorization: Bearer $AWX_TOKEN" \
  $AWX_HOST/api/v2/projects/<id>/update/

# List inventory hosts
curl -s -H "Authorization: Bearer $AWX_TOKEN" \
  $AWX_HOST/api/v2/inventories/<id>/hosts/ | python3 -m json.tool
```

---

*This document covers the ACG sandbox build. For enterprise production differences see [Sandbox vs Enterprise Comparison](#sandbox-vs-enterprise-comparison) and [Architecture Decision Records](#architecture-decision-records).*
