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

### Complete Role Inventory
The repository contains **23 distinct roles** providing comprehensive server automation. Currently **14 roles** are active in `site.yml`:

#### Foundation Roles
- **common** - System foundation (timezone, hostname, basic packages)
- **deploy** - Creates deploy user with sudo privileges and SSH key management
- **ssh** - Hardened SSH configuration on custom port 2222
- **ufw** - Firewall configuration with deny-by-default policy
- **unattended_upgrades** - Automatic security updates configuration

#### Infrastructure & Security Roles
- **ubuntu_pro** - Ubuntu Pro subscription management
- **crowdsec** - Community-driven intrusion detection and prevention
- **tailscale** - VPN mesh networking for secure remote access
- **podman** - Rootless container runtime setup and configuration

#### Web Services
- **caddy** - Reverse proxy with automatic HTTPS and security headers
- **analytics** - Vince Analytics self-hosted web analytics

#### Core Service Roles (Active)

##### Vault Role (`roles/vault/`)
- **Purpose**: Deploys HashiCorp Vault for centralized secret management
- **Key Features**:
  - Raft storage backend with auto-unseal using systemd credentials
  - AppRole and UserPass authentication methods
  - Vault Agent for automatic secret retrieval
  - TLS-enabled server with self-signed certificates
- **Integration**: Provides secrets to containerized services via environment files
- **Network**: Listens on `https://127.0.0.1:8200` (cluster on 8201)

##### Podman Services Role (`roles/podman_services/`)
- **Purpose**: Deploys containerized services using Podman with systemd integration
- **Services Deployed**:
  - **PostgreSQL**: Database server (postgres:17.5-alpine3.22) on port 5432
  - **MinIO**: S3-compatible object storage (minio:latest) on ports 9000/9001
- **Network**: Uses custom bridge network `shared-network` for inter-service communication
- **Integration**: Retrieves credentials from Vault via Vault Agent

##### Backup Role (`roles/backup/`)
- **Purpose**: Comprehensive backup solution for all services with local and offsite storage
- **Local Backups**:
  - **Vault**: Raft snapshots using `vault operator raft snapshot`
  - **PostgreSQL**: Database dumps using `pg_dump` via container exec
  - **MinIO**: Object storage backups using `mc mirror` with compression
- **Offsite Backups**: 
  - **NAS**: Restic backups over SSH/SFTP
  - **Google Drive**: Restic backups via rclone integration
- **Scheduling**: Automated daily backups with systemd timers
- **Retention**: Local (30 days), Offsite (7 daily + 12 monthly)
- **Storage**: Local backups in `/opt/backups/`, encrypted offsite repositories

### Complete Infrastructure Analysis

#### Available Roles (Not Currently Active)
The repository contains additional roles for future deployment:
- **Additional service roles** - Various infrastructure components ready for activation
- **Monitoring roles** - Prepared for observability stack implementation
- **Additional security roles** - Enhanced security configurations

#### Network Architecture
- **SSH Access**: Custom port 2222 with key-based authentication only
- **Firewall**: UFW with deny-by-default, allowing HTTP/HTTPS/SSH/Tailscale
- **Container Networking**: Isolated bridge network `shared-network` for service isolation
- **TLS Configuration**: Vault runs with self-signed certificates in system trust store
- **VPN Access**: Tailscale mesh networking for secure remote administration

#### Security Implementation
- **Rootless Containers**: All services run under non-privileged `deploy` user
- **Privilege Separation**: Distinct service users and minimal sudo access
- **Secret Management**: Centralized Vault-based credential distribution
- **Intrusion Detection**: CrowdSec with collections for SSH, HTTP, Caddy, PostgreSQL
- **Automatic Updates**: Unattended upgrades for security patches
- **Git Security**: Pre-commit hooks ensure encrypted secrets

### Secret Management Flow
1. Vault stores service credentials at `secret/data/minio` and `secret/data/postgres`
2. Vault Agent retrieves secrets and generates environment files
3. Podman containers load credentials via `EnvironmentFile` systemd directive
4. Services communicate over shared network with proper authentication

### Backup Architecture
The backup system operates on a multi-tiered approach:

**Local Backup Schedule:**
- **02:00** - Vault raft snapshots (encrypted, stored in `/opt/backups/vault/`)
- **03:00** - PostgreSQL dumps (compressed SQL, stored in `/opt/backups/postgres/`)  
- **04:00** - MinIO data mirrors (compressed tar.gz, stored in `/opt/backups/minio/`)
- **05:00** - Offsite backup sync (restic to NAS + Google Drive)

**Offsite Backup Strategy:**
- **Primary**: NAS via SSH/SFTP using restic for encryption and deduplication
- **Secondary**: Google Drive via rclone backend with restic encryption
- **Retention**: 7 daily snapshots + 12 monthly snapshots per repository
- **Security**: Repository-level encryption with restic password protection

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

## Backup Configuration

### Required Secrets for Backup Role
Add these variables to `vars/secrets.yml` (encrypted with ansible-vault):

```yaml
# Restic repository encryption
restic_password: "your-strong-restic-password"

# NAS backup configuration  
nas_ssh_host: "nas.example.com"
nas_ssh_user: "backup"
nas_ssh_port: 22
nas_backup_path: "/volume1/backups/server"
nas_ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  your-ssh-private-key-content
  -----END OPENSSH PRIVATE KEY-----

# rclone configuration for Google Drive
rclone_config: |
  [gdrive]
  type = drive
  client_id = your-google-client-id
  client_secret = your-google-client-secret
  token = {"access_token":"...","token_type":"Bearer",...}
```

### Backup Management Commands
```bash
# Check backup status
systemctl status vault-backup.timer postgres-backup.timer minio-backup.timer offsite-backup.timer

# View backup logs
journalctl -u vault-backup.service -f
journalctl -u postgres-backup.service -f  
journalctl -u minio-backup.service -f
journalctl -u offsite-backup.service -f

# Manual backup execution
systemctl start vault-backup.service
systemctl start postgres-backup.service
systemctl start minio-backup.service
systemctl start offsite-backup.service

# List restic snapshots
restic -r sftp:backup@nas:/volume1/backups/server snapshots
restic -r rclone:gdrive:backups/server snapshots

# Restore from backup (example)
restic -r sftp:backup@nas:/volume1/backups/server restore latest --target /tmp/restore
```

## Troubleshooting
- Verify environment variables are set before running playbooks
- Check Vault service status: `systemctl --user status vault` (on target server)
- Monitor container logs: `podman logs shared-postgres` or `podman logs shared-minio`
- Monitor backup timers: `systemctl list-timers *backup*`
- Check backup storage space: `df -h /opt/backups`
During development don't set anything to `no_log: true` in tasks

## Critical Issues & Configuration Gaps

### Known Issues Requiring Attention

#### High Priority Fixes
1. **MinIO Service Restart Bug** (`roles/podman_services/tasks/minio.yml:110`)
   - Currently restarts 'vault' service instead of 'vault-agent'
   - Fix: Change `name: vault` to `name: vault-agent`

2. **TLS Certificate Validation** (`roles/vault/templates/vault-agent.hcl.j2`)
   - Vault Agent configured with `tls_skip_verify = true`
   - Consider implementing proper certificate validation

#### Configuration Gaps
1. **Missing Variables** in `vars/main.yml`:
   - `caddy_server_sites` - Required for Caddy virtual host configuration
   - Various analytics admin credentials
   - Complete backup offsite credentials

2. **Incomplete Secrets** in `vars/secrets.yml`:
   - Analytics admin password
   - Complete rclone Google Drive configuration
   - NAS SSH credentials for backups

### Future Enhancements (Per todo.md)
- **Monitoring Stack**: Grafana, Prometheus, Alertmanager, Loki, Blackbox Exporter
- **Website Deployments**: Automated deployment pipeline
- **CI/CD Integration**: Webhook-based update system

### Deployment Dependencies
The roles have clear dependency chains that must be followed:
1. **System Foundation**: common → deploy → ssh → ufw → unattended_upgrades
2. **Security Layer**: ubuntu_pro → crowdsec → tailscale
3. **Container Platform**: podman → vault → vault-agent
4. **Service Layer**: podman_services → analytics → caddy
5. **Backup System**: backup (requires all services operational)

### Service Health Dependencies
- **Vault Agent**: Must generate environment files before containers start
- **Container Health**: Services have health checks but may need startup delays
- **Secret Availability**: Services depend on Vault Agent secret templating
