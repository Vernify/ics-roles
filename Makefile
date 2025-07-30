# Makefile for ICS Ansible Collection
.PHONY: help build install test lint clean publish

# Variables
COLLECTION_NAME = ics-common
VERSION = $(shell grep version galaxy.yml | awk '{print $$2}' | tr -d '"')
COLLECTION_FILE = $(COLLECTION_NAME)-$(VERSION).tar.gz

# Default target
help:
	@echo "Available targets:"
	@echo "  build     - Build the collection tarball"
	@echo "  install   - Install collection locally"
	@echo "  test      - Run tests on the collection"
	@echo "  lint      - Run ansible-lint on the collection"
	@echo "  clean     - Clean build artifacts"
	@echo "  publish   - Publish to Ansible Galaxy"
	@echo "  examples  - Run example playbooks (dry-run)"
	@echo "  deps      - Install collection dependencies"

# Install dependencies
deps:
	@echo "Installing collection dependencies..."
	ansible-galaxy collection install -r requirements.yml

# Lint the collection
lint:
	@echo "Running ansible-lint..."
	ansible-lint .

# Build the collection
build: clean lint
	@echo "Building collection $(COLLECTION_NAME) version $(VERSION)..."
	ansible-galaxy collection build --force

# Install collection locally
install: build
	@echo "Installing collection locally..."
	ansible-galaxy collection install $(COLLECTION_FILE) --force

# Test the collection
test: install
	@echo "Testing collection..."
	@echo "Running basic syntax checks..."
	ansible-playbook examples/basic_web_server_users.yml --syntax-check
	ansible-playbook examples/database_server_users.yml --syntax-check
	ansible-playbook examples/environment_specific_users.yml --syntax-check

# Run example playbooks (dry-run)
examples: install
	@echo "Running example playbooks (dry-run)..."
	@echo "Note: These will fail without proper inventory/variables"
	-ansible-playbook examples/basic_web_server_users.yml --check || true
	-ansible-playbook examples/database_server_users.yml --check || true

# Publish to Ansible Galaxy
publish: build test
	@echo "Publishing $(COLLECTION_FILE) to Ansible Galaxy..."
	@if [ -z "$(ANSIBLE_GALAXY_TOKEN)" ]; then \
		echo "Error: ANSIBLE_GALAXY_TOKEN environment variable not set"; \
		exit 1; \
	fi
	ansible-galaxy collection publish $(COLLECTION_FILE) --api-key $(ANSIBLE_GALAXY_TOKEN)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(COLLECTION_NAME)-*.tar.gz
	rm -rf build/

# Development setup
dev-setup:
	@echo "Setting up development environment..."
	pip install ansible-core ansible-lint
	$(MAKE) deps

# Version bump (requires VERSION parameter)
version-bump:
	@if [ -z "$(NEW_VERSION)" ]; then \
		echo "Error: NEW_VERSION parameter required. Usage: make version-bump NEW_VERSION=1.1.0"; \
		exit 1; \
	fi
	@echo "Updating version to $(NEW_VERSION)..."
	sed -i.bak 's/version: .*/version: $(NEW_VERSION)/' galaxy.yml
	rm galaxy.yml.bak
	@echo "Version updated to $(NEW_VERSION). Don't forget to commit and tag!"

# Quick validation
validate:
	@echo "Quick validation of collection structure..."
	@ansible-galaxy collection build --force > /dev/null && echo "✓ Collection builds successfully" || echo "✗ Collection build failed"
	@ansible-lint . > /dev/null 2>&1 && echo "✓ Lint checks passed" || echo "✗ Lint checks failed"
	@test -f roles/user_management/README.md && echo "✓ Role documentation exists" || echo "✗ Role documentation missing"
