# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-based Ubuntu server automation repository focused on deploying and managing secure server infrastructure with containerized services. The current architecture centers around HashiCorp Vault for secret management and Podman for rootless container orchestration.

## Common Commands

### Environment Setup
```bash
# Check required environment variables are set
make check

# Lint all Ansible files with auto-fix
make lint

# Encrypt secrets file (if not already encrypted)
make vault

# Decrypt secrets file for editing
make vault-decrypt
```

### Running Playbooks
```bash
# Run the full playbook (includes environment check)
make run

# Run playbook directly
ansible-playbook -i inventory.yml site.yml --vault-password-file .vault_password

# Run specific roles only (edit site.yml first)
ansible-playbook -i inventory.yml site.yml --vault-password-file .vault_password --tags vault
```

### Required Environment Setup
The project requires a `.env` file (or direnv `.envrc`) with:
```bash
SERVER_IP=your.server.ip.address
SERVER_USER=your_ssh_user
ANSIBLE_BECOME_PASS=your_sudo_password
```

A `.vault_password` file must exist for Ansible Vault operations.

## Architecture Overview

### Current Active Roles
The repository currently runs two main roles (others are commented out in `site.yml`):

#### Vault Role (`roles/vault/`)
- **Purpose**: Deploys HashiCorp Vault for centralized secret management
- **Key Features**:
  - Raft storage backend with auto-unseal using systemd credentials
  - AppRole and UserPass authentication methods
  - Vault Agent for automatic secret retrieval
  - TLS-enabled server with self-signed certificates
- **Integration**: Provides secrets to containerized services via environment files
- **Network**: Listens on `https://127.0.0.1:8200` (cluster on 8201)

#### Podman Services Role (`roles/podman_services/`)
- **Purpose**: Deploys containerized services using Podman with systemd integration
- **Services Deployed**:
  - **PostgreSQL**: Database server (postgres:17.5-alpine3.22) on port 5432
  - **MinIO**: S3-compatible object storage (minio:latest) on ports 9000/9001
- **Network**: Uses custom bridge network `shared-network` for inter-service communication
- **Integration**: Retrieves credentials from Vault via Vault Agent

### Secret Management Flow
1. Vault stores service credentials at `secret/data/minio` and `secret/data/postgres`
2. Vault Agent retrieves secrets and generates environment files
3. Podman containers load credentials via `EnvironmentFile` systemd directive
4. Services communicate over shared network with proper authentication

### File Structure Conventions
- **Configuration**: Main variables in `vars/main.yml`, secrets in `vars/secrets.yml` (encrypted)
- **Inventory**: Uses environment variables via `{{ lookup('env', 'VAR_NAME') }}`
- **Templates**: Jinja2 templates for service configs in `roles/*/templates/`
- **Container Definitions**: Systemd Quadlet format in `roles/podman_services/templates/`

### Security Practices
- SSH on custom port 2222 with key-based authentication
- Rootless Podman containers running as `deploy` user
- Vault auto-unseal with encrypted credential storage
- AppRole authentication for service-to-service communication
- Git hooks ensure secrets remain encrypted before commits

### Development Notes
- Use `ansible-lint --fix` before committing changes
- Test role changes incrementally by commenting/uncommenting in `site.yml`
- Vault operations require admin credentials stored in `vars/secrets.yml`
- Container health checks ensure services are operational before proceeding
- All services run under the `deploy` user with systemd user session management

## Troubleshooting
- Verify environment variables are set before running playbooks
- Check Vault service status: `systemctl --user status vault` (on target server)
- Monitor container logs: `podman logs shared-postgres` or `podman logs shared-minio`
During development don't set anything to `no_log: true` in tasks
