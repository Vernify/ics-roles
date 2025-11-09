# ICS Ansible Collection

This is the ICS Ansible collection, providing reusable roles and modules across multiple customers.

## Collection Overview

The `ics.common` collection provides standardized infrastructure automation components that can be deployed across different customer environments while maintaining consistency and best practices.

### Key Features

- **Multi-OS Support**: Supports CentOS 6.1, CentOS 7.x, Ubuntu 20.04/22.04/24.04, Fedora 20, Oracle Linux 8.5, Rocky Linux 9.5
- **Environment Agnostic**: Configurable for development, staging, and production environments
- **Security Focused**: Implements DevSec hardening standards
- **User Management**: Advanced user and group management with custom sudo rules
- **Vault Integration**: HashiCorp Vault integration for secret management
- **CI/CD Ready**: Jenkins pipeline integration with Terraform

## Collection Structure

```
ics/
├── common/
│   ├── galaxy.yml               # Collection metadata
│   ├── requirements.yml         # Collection dependencies
│   ├── README.md                # This file
│   ├── architecture/            # LADR documentation
│   ├── collector/               # Artifact templates (Graylog pipelines, etc.)
│   ├── examples/                # Example playbooks
│   └── roles/                   # Ansible roles
│       ├── linux_base/
│       ├── user_management/
│       ├── monitoring_common/
│       ├── monitoring_proxy/
│       ├── graphite/
│       ├── grafana/
│       └── graylog/
```

## Documentation

- **[Architecture Documentation](architecture/)**: LADR format architectural decisions

## Installation

### From Ansible Galaxy

```bash
# Install the collection
ansible-galaxy collection install ics.common

# Install with specific version
ansible-galaxy collection install ics.common:1.0.0
```

### From Git Repository

```bash
# Install directly from git
ansible-galaxy collection install git+https://github.com/your-org/ics-ansible-collection.git

# Install specific branch/tag
ansible-galaxy collection install git+https://github.com/your-org/ics-ansible-collection.git,main
```

### Using Requirements File

Create a `requirements.yml` file:

```yaml
---
collections:
  - name: ics.common
    version: ">=1.0.0"
  - name: community.general
    version: ">=3.0.0"
  - name: ansible.posix
    version: ">=1.0.0"
```

Install:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Quick Start

```yaml
---
- name: Deploy infrastructure
  hosts: all
  become: true
  roles:
    - ics.common.linux_base
    - ics.common.user_management
  vars:
    user_management_groups:
      - name: "ops_team"
        sudo_rules: ["ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *"]
    user_management_users:
      - name: "opsuser1"
        group: "ops_team"
        ssh_keys: ["{{ vault_ssh_key }}"]
```

## Available Roles

### Core Infrastructure
- **linux_base** - Base OS configuration
- **user_management** - User/group management with custom sudo rules
- **security_hardening** - DevSec hardening standards

### Monitoring Stack (v2.0.0+)
- **monitoring_common** - Docker engine, sysctl, network setup
- **monitoring_proxy** - Nginx reverse proxy for monitoring services
- **graphite** - Graphite with StatsD
- **grafana** - Grafana with persistent storage
- **graylog** - Graylog 7.x with MongoDB 7.0 and OpenSearch

### Additional Roles
- **monitoring_agent** - Telegraf, log forwarding
- **backup_client** - Backup scheduling and retention
- **web_server** - Nginx/Apache configuration

See individual role README files for detailed configuration options.

## Usage

### Requirements File

```yaml
# requirements.yml
collections:
  - name: ics.common
    version: ">=2.0.0"
```

### Inventory Structure

```
project/
├── inventories/
│   ├── production/hosts.yml
│   └── staging/hosts.yml
├── playbooks/site.yml
└── requirements.yml
```

## Secret Management

The collection supports both HashiCorp Vault and Ansible Vault for secret management. See downstream organization documentation for specific integration patterns.

## Development

### Standards
- Prefix all role variables with role name (e.g., `graylog_*`)
- Use Fully Qualified Collection Names (FQCNs)
- Ensure idempotency
- Test against supported OS list

### Building
```bash
# Build and install locally
ansible-galaxy collection build --force
ansible-galaxy collection install ics-common-*.tar.gz --force
```

## Versioning

Follows semantic versioning (MAJOR.MINOR.PATCH). Current version: 2.0.0

## License

MIT License. See LICENSE file for details.
