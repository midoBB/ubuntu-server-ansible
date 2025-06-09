# Ansible Ubuntu Server Automation

This repository contains Ansible playbooks and roles to automate the initial and ongoing setup of Ubuntu servers, with a focus on security, maintainability, and modern best practices.

## Features

- **Common server hardening**: Timezone, hostname, essential packages
- **Deploy user**: Creates a dedicated deploy user with SSH key authentication and passwordless sudo for specific commands
- **SSH hardening**: Secure, templated `sshd_config` with custom port, strong ciphers, and user restrictions
- **Firewall (UFW)**: Installs and configures UFW, allows only required ports (SSH, HTTP, HTTPS, custom TCP/UDP)
- **Unattended Upgrades**: Automatic security updates, configurable origins, blacklists, and reboot policy
- **Ubuntu Pro**: Registers the server with Ubuntu Pro for extended security and livepatch (requires token)
- **Podman**: Installs and configures rootless Podman for container workloads, including user socket and storage
- **Caddy**: Installs and configures Caddy web server with per-site reverse proxy, HTTPS, and security headers

## Prerequisites

- Ansible 2.11+ installed on your local machine
- SSH access to the target Ubuntu LTS server
- `direnv` (recommended) for environment variable management
- Ubuntu Pro token (if using Ubuntu Pro features)

## Configuration

1. **Environment variables**: Create a `.env` file in the root directory with at least:
   ```bash
   SERVER_IP=your.server.ip.address
   SERVER_USER=your_ssh_user
   ANSIBLE_BECOME_PASS=your_sudo_password
   ```
   > **Note:** `.env` is ignored by git. Use `.envrc` and `direnv` to auto-load variables.

2. **Inventory**: Edit `inventory.yml` to reference your server using environment variables.

3. **Secrets**: Place sensitive variables in `vars/secrets.yml` (encrypted with Ansible Vault).

## Usage

1. **Check environment**:
   ```bash
   make check
   ```
2. **Lint playbooks**:
   ```bash
   make lint
   ```
3. **Encrypt/decrypt secrets**:
   ```bash
   make vault         # Encrypt vars/secrets.yml
   make vault-decrypt # (implement as needed)
   ```
4. **Run the playbook**:
   ```bash
   make run
   # or directly:
   ansible-playbook -i inventory.yml site.yml --ask-become-pass
   ```

## Playbook Structure

- `site.yml`: Main playbook, includes all roles
- `inventory.yml`: Inventory file (uses env vars)
- `vars/`: Main and secrets variables
- `roles/`:
  - `common`: Timezone, hostname, base packages
  - `deploy`: Deploy user, SSH key, sudoers
  - `ssh`: Hardened SSH config
  - `ufw`: Firewall configuration
  - `unattended_upgrades`: Automatic security updates
  - `ubuntu_pro`: Ubuntu Pro registration and services
  - `podman`: Rootless Podman setup
  - `caddy`: Caddy web server and reverse proxy

## Customization

Edit `vars/main.yml` to customize:

- `server_hostname`: Hostname
- `timezone`: Timezone
- `deploy_user_name`, `deploy_user_ssh_public_key`, etc.
- `ssh_port`, `ufw_tcp_ports`, `ufw_udp_ports`, `ufw_ssh_allowed_ips`
- `caddy_server_log_dir`, `caddy_server_sites`, etc.

## Security Notes

- Never commit `.env` or secrets to version control
- All privileged tasks use `become: true`
- SSH keys are required for deploy user
- SSH root login and password auth are disabled by default

## Troubleshooting

1. Check SSH connectivity and environment variables
2. Ensure `.vault_password` file exists for secrets
3. Review Ansible logs for errors
4. Use `make lint` to check for YAML/Ansible issues

## License

MIT License. 