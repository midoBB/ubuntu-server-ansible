# Ansible Server Setup

This repository contains Ansible playbooks for automating the initial setup of Ubuntu servers.

## Prerequisites

- Ansible installed on your local machine
- SSH access to the target server
- `direnv` installed (recommended for environment variable management)

## Configuration

1. Create a `.env` file in the root directory with the following variables:
   ```bash
   SERVER_IP=your_server_ip
   SERVER_USER=your_ssh_username
   ```

2. If you're using `direnv`, the environment variables will be automatically loaded. Otherwise, you'll need to source them manually:
   ```bash
   source .env
   ```

## Usage

1. Verify your inventory configuration:
   ```bash
   ansible-inventory --list
   ```

2. Test the connection to your server:
   ```bash
   ansible all -m ping
   ```

3. Run the playbook:
   ```bash
   ansible-playbook site.yml
   ```

## Playbook Structure

- `site.yml`: Main playbook that orchestrates the server setup
- `inventory.yml`: Contains server configuration and connection details
- `roles/`: Contains the roles that define the server setup tasks
  - `common/`: Basic server configuration and security settings

## Customization

You can customize the server setup by modifying the variables in `site.yml`. Currently supported variables:

- `timezone`: Server timezone (default: UTC)

## Security Notes

- Make sure to keep your `.env` file secure and never commit it to version control
- The playbook uses `become: true` to execute tasks with sudo privileges
- SSH keys are recommended for authentication

## Troubleshooting

If you encounter any issues:

1. Verify your SSH connection to the server
2. Check that all environment variables are properly set
3. Ensure you have the necessary permissions on the target server
4. Review the Ansible logs for detailed error messages 