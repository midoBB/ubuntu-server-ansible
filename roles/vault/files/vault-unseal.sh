#!/usr/bin/env bash

# A script to auto-unseal HashiCorp Vault using credentials from systemd's $CREDENTIALS_DIRECTORY via curl.

set -euo pipefail

# Configure Vault connection details
VAULT_ADDR="https://127.0.0.1:8200"

log() {
    # Logs a message to stderr with timestamp
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# --- Main Execution ---

log "Starting Vault auto-unseal process."

# 1. Check if required tools are installed
for cmd in curl jq; do
    if ! command -v "$cmd" &>/dev/null; then
        log "ERROR: Required command '$cmd' is not installed. Please install it and try again."
        exit 1
    fi
done

# 2. Validate credentials directory
if [[ -z "${CREDENTIALS_DIRECTORY:-}" || ! -d "$CREDENTIALS_DIRECTORY" || -z "$(ls -A "$CREDENTIALS_DIRECTORY")" ]]; then
    log "ERROR: \$CREDENTIALS_DIRECTORY is not set or is empty. This script must be run via systemd with 'LoadCredential' or 'LoadCredentialEncrypted' directive."
    exit 1
fi

# 3. Check Vault seal status using curl
log "Checking Vault seal status at ${VAULT_ADDR}..."
response=$(curl -s "${VAULT_ADDR}/v1/sys/seal-status")
if [ $? -ne 0 ]; then
    log "ERROR: Failed to connect to Vault at ${VAULT_ADDR}."
    exit 1
fi

sealed=$(echo "$response" | jq -r '.sealed')
if [ "$sealed" == "false" ]; then
    log "SUCCESS: Vault is already unsealed."
    exit 0
fi

log "Vault is sealed. Beginning unseal process."
threshold=$(echo "$response" | jq -r '.t')
log "Unseal threshold: $threshold"

# 4. Attempt to unseal Vault with each key
for key_file in "$CREDENTIALS_DIRECTORY"/*; do
    key_name=$(basename "$key_file")
    unseal_key=$(cat "$key_file")
    log "Attempting to unseal with key '${key_name}'..."

    response=$(curl -s -X POST -d "{\"key\": \"$unseal_key\"}" "${VAULT_ADDR}/v1/sys/unseal")
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to send unseal request for '${key_name}'."
        continue
    fi

    sealed=$(echo "$response" | jq -r '.sealed')
    progress=$(echo "$response" | jq -r '.progress')
    log "Unseal progress: $progress/$threshold"

    if [ "$sealed" == "false" ]; then
        log "SUCCESS: Vault is now unsealed."
        exit 0
    fi
done

# 5. Final check if Vault is still sealed
log "ERROR: Vault remains sealed after attempting all available keys."
exit 1
