# Makefile for Ansible project

# Inventory and playbook files
INVENTORY := inventory.yml
PLAYBOOK  := site.yml
SECRETS_FILE := vars/secrets.yml

.PHONY: check lint vault vault-decrypt run

# -----------------------------------------------------------------------------
# check: Ensure required environment variables are set
# -----------------------------------------------------------------------------
check:
	@if [ -z "$$SERVER_IP" ]; then \
		echo "Error: SERVER_IP is not set"; \
		exit 1; \
	fi
	@if [ -z "$$SERVER_USER" ]; then \
		echo "Error: SERVER_USER is not set"; \
		exit 1; \
	fi
	@if [ -z "$$ANSIBLE_BECOME_PASS" ]; then \
		echo "Error: ANSIBLE_BECOME_PASS is not set"; \
		exit 1; \
	fi
	@if [ ! -f ".vault_password" ]; then \
		echo "Error: vault password file not found"; \
		exit 1; \
	fi
# -----------------------------------------------------------------------------
# lint: Run ansible-lint and auto-fix all YAML files
# -----------------------------------------------------------------------------
lint:
	ansible-lint --fix **/*.yml

# -----------------------------------------------------------------------------
# vault: Encrypt vars/secrets.yml if not already encrypted
# -----------------------------------------------------------------------------
vault:
	@if [ ! -f "$(SECRETS_FILE)" ]; then \
		echo "Error: $(SECRETS_FILE) does not exist"; \
		exit 1; \
	fi
	@if [ ! -f ".vault_password" ]; then \
		echo "Error: vault password file not found"; \
		exit 1; \
	fi
	@if head -n 1 $(SECRETS_FILE) | grep -q '\$$ANSIBLE_VAULT'; then \
		echo "$(SECRETS_FILE) is already encrypted"; \
	else \
		ansible-vault encrypt $(SECRETS_FILE) --vault-password-file .vault_password; \
	fi

# -----------------------------------------------------------------------------
# vault-decrypt: Decrypt vars/secrets.yml if encrypted
# -----------------------------------------------------------------------------
vault-decrypt:
	@if [ ! -f "$(SECRETS_FILE)" ]; then \
		echo "Error: $(SECRETS_FILE) does not exist"; \
		exit 1; \
	fi
	@if [ ! -f ".vault_password" ]; then \
		echo "Error: vault password file not found"; \
		exit 1; \
	fi
	@if head -n 1 $(SECRETS_FILE) | grep -q '\$$ANSIBLE_VAULT'; then \
		ansible-vault decrypt $(SECRETS_FILE) --vault-password-file .vault_password; \
	else \
		echo "$(SECRETS_FILE) is not encrypted"; \
	fi

# -----------------------------------------------------------------------------
# run: Execute the playbook (requires check to pass first)
# -----------------------------------------------------------------------------
run: check
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)
