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
│   ├── knowledgebase/           # Documentation and best practices
│   │   └── deployment/          # Deployment guides and procedures
│   ├── examples/                # Example playbooks
│   ├── plugins/
│   │   ├── modules/             # Custom modules
│   │   ├── inventory/           # Inventory plugins
│   │   └── filter/              # Filter plugins
│   └── roles/
│       ├── linux_base/          # Base Linux configuration
│       ├── user_management/     # User and group management
│       └── monitoring_agent/    # Monitoring setup
```

## Documentation

- **[Multi-Environment Setup Guide](knowledgebase/deployment/multi-environment-setup.md)**: Complete guide for setting up development, staging, and production environments
- **[Architecture Documentation](architecture/)**: LADR format architectural decisions
- **[Upload and Consumption Guide](UPLOAD_CONSUMPTION_GUIDE.md)**: Instructions for building and distributing the collection

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

### User Management

The primary use case for this collection is user management across customer environments:

```yaml
---
- name: Manage Customer A users
  hosts: customer_a_servers
  become: true
  roles:
    - ics.common.user_management
  
  vars:
    # Define groups with specific sudo rules
    user_management_groups:
      - name: "customer_a_admins"
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart customer-app"
          - "ALL=(ALL) NOPASSWD: /opt/customer-app/scripts/deploy.sh"
    
    # Define users and assign them to groups
    user_management_users:
      - name: "admin1"
        group: "customer_a_admins"
        ssh_keys:
          - "{{ vault_admin1_ssh_key }}"
      - name: "admin2"
        group: "customer_a_admins"
        ssh_keys:
          - "{{ vault_admin2_ssh_key }}"
```

### Basic Server Setup

```yaml
---
- name: Configure base server infrastructure
  hosts: all
  become: true
  roles:
    - ics.common.linux_base
    - ics.common.user_management

  vars:
    # Environment configuration
    environment_type: "{{ environment | default('dev') }}"
    
    # Base configuration
    linux_base_timezone: "Africa/Johannesburg"
    linux_base_packages:
      - htop
      - vim
      - curl
      - wget
    
    # User management
    user_management_groups:
      - name: "ops_team"
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart *"
    
    user_management_users:
      - name: "opsuser1"
        group: "ops_team"
        ssh_keys:
          - "{{ vault_opsuser1_ssh_key }}"
```

## Role Documentation

### New roles in 2.0.0 (monitoring stack)

The collection now includes reusable roles for the monitoring stack, enabling consistent deployments across organizations:

- ics.common.monitoring_common — prepares host (Docker engine, sysctl, network, named volumes)
- ics.common.monitoring_proxy — Nginx reverse proxy for Graphite, Grafana, Graylog (renamed from nginx to avoid collisions)
- ics.common.graphite — Graphite with StatsD
- ics.common.grafana — Grafana with persistent storage
- ics.common.graylog — Graylog 6.x with MongoDB and OpenSearch (single-node)

### user_management

**Primary Role**: Advanced user and group management with custom sudo rules per group.

Provides comprehensive user management including:
- Group creation with custom sudo rules
- User creation and assignment to groups
- SSH key management
- Sudoers configuration per group
- Multi-environment support

**Key Variables:**
- `user_management_groups`: List of groups with sudo rules
- `user_management_users`: List of users to create and assign to groups

**Example Usage:**
```yaml
user_management_groups:
  - name: "db_admins"
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mysql"
      - "ALL=(ALL) NOPASSWD: /usr/bin/mysql"

user_management_users:
  - name: "dbadmin1"
    group: "db_admins"
    ssh_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAA..."
```

### linux_base

Provides base Linux system configuration including:
- Package management
- User management
- System services
- Locale configuration
- Time synchronization

**Variables:**
- `linux_base_packages`: List of packages to install
- `linux_base_timezone`: System timezone
- `linux_base_users`: List of users to create

### security_hardening

Implements security hardening based on DevSec standards:
- SSH hardening
- Firewall configuration
- File system security
- Audit logging
- Fail2ban configuration

**Variables:**
- `security_hardening_ssh_port`: SSH port (default: 22)
- `security_hardening_fail2ban_enabled`: Enable fail2ban (default: true)
- `security_hardening_firewall_rules`: Custom firewall rules

### monitoring_agent

Configures monitoring agents for the stack:
- Telegraf for metrics collection
- Log forwarding to Graylog
- Grafana dashboard configuration

**Variables:**
- `monitoring_agent_graphite_server`: Graphite server endpoint
- `monitoring_agent_graylog_server`: Graylog server endpoint
- `monitoring_agent_telegraf_plugins`: Additional Telegraf plugins

### backup_client

Configures backup clients:
- Backup schedules
- Retention policies
- Encryption configuration

**Variables:**
- `backup_client_schedule`: Backup schedule (cron format)
- `backup_client_retention_days`: Retention period
- `backup_client_encryption_key`: Encryption key (use Ansible Vault)

### web_server

Configures web servers (Nginx/Apache):
- SSL/TLS configuration
- Virtual hosts
- Security headers
- Performance tuning

**Variables:**
- `web_server_type`: nginx or apache
- `web_server_ssl_enabled`: Enable SSL
- `web_server_vhosts`: Virtual host configurations

## Environment Configuration

The ICS Collection supports multi-environment deployments across development, staging, and production environments with different configuration levels per environment.

For detailed multi-environment setup with complete examples, see: [Multi-Environment Setup Guide](knowledgebase/deployment/multi-environment-setup.md)

### Basic Directory Structure

```
customer_project/
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   ├── staging/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── development/
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
│   ├── site.yml
│   ├── web_servers.yml
│   └── database_servers.yml
├── requirements.yml
└── ansible.cfg
```

### Sample Inventory

```yaml
# inventories/production/hosts.yml
all:
  children:
    web_servers:
      hosts:
        web01.customer.com:
          ansible_host: 10.1.1.10
        web02.customer.com:
          ansible_host: 10.1.1.11
    db_servers:
      hosts:
        db01.customer.com:
          ansible_host: 10.1.1.20
  vars:
    environment: production
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/customer_key
```

### Basic Group Variables

```yaml
# inventories/production/group_vars/all.yml
---
# Environment settings
environment_type: production

# Base configuration
linux_base_timezone: "Africa/Johannesburg"
linux_base_ntp_servers:
  - ntp1.customer.com
  - ntp2.customer.com

# Security settings
security_hardening_ssh_port: 2222
security_hardening_fail2ban_enabled: true

# Monitoring configuration  
monitoring_agent_graphite_server: "{{ vault_graphite_server }}"
monitoring_agent_graylog_server: "{{ vault_graylog_server }}"

# Backup configuration
backup_client_schedule: "0 2 * * *"
backup_client_retention_days: 30
```

## Vault Integration

### HashiCorp Vault Setup

The collection supports HashiCorp Vault for secret management:

```yaml
# Example vault variable usage
monitoring_agent_api_key: "{{ lookup('hashi_vault', 'secret=kv/monitoring:api_key') }}"
backup_client_encryption_key: "{{ lookup('hashi_vault', 'secret=kv/backup:encryption_key') }}"
```

### Ansible Vault

For Ansible Vault integration:

```bash
# Create encrypted variables
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml
```

## CI/CD Integration

### Jenkins Pipeline Example

```groovy
def secrets = [
  [path: 'kv/customer', engineVersion: 2, secretValues: [
    [envVar: 'ANSIBLE_VAULT_PASSWORD', vaultKey: 'ansible_vault_password']
  ]]
]

def configuration = [
  vaultUrl: 'http://vault.company.com:8200',
  vaultCredentialId: 'vault-approle-creds',
  engineVersion: 2
]

pipeline {
  agent any
  stages {
    stage('Deploy Infrastructure') {
      steps {
        withVault([configuration: configuration, vaultSecrets: secrets]) {
          sh '''
            echo "$ANSIBLE_VAULT_PASSWORD" > vault_pass.txt
            ansible-playbook -i inventories/production playbooks/site.yml --vault-password-file vault_pass.txt
            rm vault_pass.txt
          '''
        }
      }
    }
  }
}
```

### Terraform Integration

```hcl
# Example Terraform resource
resource "null_resource" "ansible_provisioning" {
  triggers = {
    instance_ids = join(",", [aws_instance.web.*.id])
  }

  provisioner "local-exec" {
    command = <<EOF
      sleep 30
      ansible-playbook -i inventories/production \
        -e "target_host=${aws_instance.web.private_ip}" \
        playbooks/web_servers.yml
    EOF
  }
}
```

## Development Guidelines

### Role Development

1. **Variable Naming**: All role variables must be prefixed with the role name
   ```yaml
   # ✓ Correct
   linux_base_packages: []
   
   # ✗ Incorrect  
   packages: []
   ```

2. **FQCN Usage**: Always use Fully Qualified Collection Names
   ```yaml
   # ✓ Correct
   - name: Install package
     ansible.builtin.package:
       name: htop
   
   # ✗ Incorrect
   - name: Install package  
     package:
       name: htop
   ```

3. **OS Support**: Test against all supported operating systems
4. **Idempotency**: Ensure all tasks are idempotent
5. **Documentation**: Update role README.md with variables and examples

### Testing

```bash
# Lint collection
ansible-lint roles/

# Test role
molecule test -s role_name

# Test collection
ansible-test sanity
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-role`
3. Follow the coding guidelines
4. Add tests for new functionality
5. Update documentation
6. Submit a pull request

## Versioning

This collection follows semantic versioning:
- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

## Support

For issues and questions:
- Create GitHub issues for bugs
- Use GitHub discussions for questions
- Contact the ICS team for enterprise support

## License

This collection is licensed under the MIT License. See LICENSE file for details.


## Versions
This first release is tagged as follow:

```
git tag -a v1.0.0 -m "Initial release of ICS Ansible Collection

Features:
- User management role with comprehensive user/group operations
- Sudo rules management with granular permissions
- SSH key assignment and management
- Cross-platform support (CentOS, Ubuntu, Rocky Linux, Oracle Linux, Fedora)
- Comprehensive documentation and examples
- Best practices implementation following Ansible Galaxy standards"
```

Followed by `git push origin v1.0.0`
