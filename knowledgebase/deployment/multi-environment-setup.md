# Multi-Environment Setup Guide

This guide demonstrates how to set up the ICS Ansible Collection for multi-environment deployments across development, staging, and production environments.

> **Prerequisites**: Before proceeding, ensure you have installed the ICS Ansible Collection. See the main [README.md](../../README.md) for installation instructions and basic usage.

## Overview

This comprehensive guide covers:
- Complete directory structure for multi-environment setups
- Environment-specific configurations for production, staging, and development
- Sample inventory files and group variables
- Example playbooks with environment-aware configurations
- Deployment commands and validation procedures
- Best practices and troubleshooting tips

## Directory Structure

```
customer_project/
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   ├── web_servers.yml
│   │   │   └── vault.yml
│   │   └── host_vars/
│   ├── staging/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   └── vault.yml
│   │   └── host_vars/
│   └── development/
│       ├── hosts.yml
│       ├── group_vars/
│       │   ├── all.yml
│       │   └── vault.yml
│       └── host_vars/
├── playbooks/
│   ├── site.yml
│   ├── web_servers.yml
│   ├── database_servers.yml
│   └── monitoring.yml
├── requirements.yml
├── ansible.cfg
└── .ansible-lint
```

## Environment Configuration

### Production Environment

**inventories/production/hosts.yml**
```yaml
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
        db02.customer.com:
          ansible_host: 10.1.1.21
    monitoring:
      hosts:
        monitor01.customer.com:
          ansible_host: 10.1.1.30
  vars:
    environment: production
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/customer_prod_key
```

**inventories/production/group_vars/all.yml**
```yaml
---
# Environment settings
environment_type: production

# Base configuration
linux_base_timezone: "Africa/Johannesburg"
linux_base_ntp_servers:
  - ntp1.customer.com
  - ntp2.customer.com
linux_base_packages:
  - htop
  - vim
  - curl
  - wget
  - rsync

# Security settings (production hardened)
security_hardening_ssh_port: 2222
security_hardening_fail2ban_enabled: true
security_hardening_firewall_enabled: true
security_hardening_password_policy_enabled: true

# Monitoring configuration  
monitoring_agent_graphite_server: "{{ vault_graphite_server }}"
monitoring_agent_graylog_server: "{{ vault_graylog_server }}"
monitoring_agent_telegraf_interval: "10s"

# Backup configuration
backup_client_schedule: "0 2 * * *"
backup_client_retention_days: 90
backup_client_encryption_enabled: true
```

### Staging Environment

**inventories/staging/hosts.yml**
```yaml
all:
  children:
    web_servers:
      hosts:
        web01-staging.customer.com:
          ansible_host: 10.2.1.10
    db_servers:
      hosts:
        db01-staging.customer.com:
          ansible_host: 10.2.1.20
  vars:
    environment: staging
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/customer_staging_key
```

**inventories/staging/group_vars/all.yml**
```yaml
---
# Environment settings
environment_type: staging

# Base configuration
linux_base_timezone: "Africa/Johannesburg"
linux_base_packages:
  - htop
  - vim
  - curl
  - wget

# Security settings (relaxed for testing)
security_hardening_ssh_port: 22
security_hardening_fail2ban_enabled: true
security_hardening_firewall_enabled: false

# Monitoring configuration  
monitoring_agent_graphite_server: "{{ vault_staging_graphite_server }}"
monitoring_agent_graylog_server: "{{ vault_staging_graylog_server }}"
monitoring_agent_telegraf_interval: "30s"

# Backup configuration
backup_client_schedule: "0 3 * * *"
backup_client_retention_days: 30
```

### Development Environment

**inventories/development/hosts.yml**
```yaml
all:
  children:
    web_servers:
      hosts:
        web01-dev.customer.com:
          ansible_host: 10.3.1.10
    db_servers:
      hosts:
        db01-dev.customer.com:
          ansible_host: 10.3.1.20
  vars:
    environment: development
    ansible_user: ansible
    ansible_ssh_private_key_file: ~/.ssh/customer_dev_key
```

**inventories/development/group_vars/all.yml**
```yaml
---
# Environment settings
environment_type: development

# Base configuration
linux_base_timezone: "Africa/Johannesburg"
linux_base_packages:
  - htop
  - vim
  - curl
  - wget
  - git
  - python3-pip

# Security settings (minimal for development)
security_hardening_ssh_port: 22
security_hardening_fail2ban_enabled: false
security_hardening_firewall_enabled: false

# Monitoring configuration (optional)
monitoring_agent_enabled: false

# Backup configuration (minimal)
backup_client_enabled: false
```

## Playbook Examples

### Site Playbook

**playbooks/site.yml**
```yaml
---
- name: Apply base configuration to all servers
  hosts: all
  become: true
  roles:
    - ics.common.linux_base

- name: Apply security hardening
  hosts: all
  become: true
  roles:
    - ics.common.security_hardening
  when: environment_type != "development"

- name: Configure monitoring
  hosts: all
  become: true
  roles:
    - ics.common.monitoring_agent
  when: monitoring_agent_enabled | default(true)

- name: Configure backup clients
  hosts: all
  become: true
  roles:
    - ics.common.backup_client
  when: backup_client_enabled | default(true)

- name: Configure web servers
  import_playbook: web_servers.yml

- name: Configure database servers
  import_playbook: database_servers.yml
```

### Web Server Playbook

**playbooks/web_servers.yml**
```yaml
---
- name: Configure web servers
  hosts: web_servers
  become: true
  roles:
    - ics.common.web_server

  vars:
    web_server_type: nginx
    web_server_ssl_enabled: "{{ environment_type == 'production' }}"
    web_server_ssl_cert_path: "/etc/ssl/certs/{{ inventory_hostname }}.crt"
    web_server_ssl_key_path: "/etc/ssl/private/{{ inventory_hostname }}.key"
    
    # Environment-specific configurations
    web_server_worker_processes: "{{ 
      {'production': 'auto', 'staging': '2', 'development': '1'}[environment_type] 
    }}"
    
    web_server_worker_connections: "{{ 
      {'production': '1024', 'staging': '512', 'development': '256'}[environment_type] 
    }}"
```

## Deployment Commands

### Production Deployment
```bash
# Full site deployment
ansible-playbook -i inventories/production playbooks/site.yml

# Web servers only
ansible-playbook -i inventories/production playbooks/web_servers.yml

# Specific host
ansible-playbook -i inventories/production playbooks/site.yml --limit web01.customer.com

# Dry run
ansible-playbook -i inventories/production playbooks/site.yml --check
```

### Staging Deployment
```bash
# Deploy to staging
ansible-playbook -i inventories/staging playbooks/site.yml

# Test web server configuration
ansible-playbook -i inventories/staging playbooks/web_servers.yml --check
```

### Development Deployment
```bash
# Deploy to development
ansible-playbook -i inventories/development playbooks/site.yml

# Skip certain roles for development
ansible-playbook -i inventories/development playbooks/site.yml --skip-tags security,backup
```

## Environment Validation

### Pre-deployment Checks
```bash
# Verify connectivity
ansible -i inventories/production all -m ping

# Check privilege escalation
ansible -i inventories/production all -m setup --become

# Validate inventory
ansible-inventory -i inventories/production --list
```

### Post-deployment Validation
```bash
# Check service status
ansible -i inventories/production web_servers -m service -a "name=nginx state=started"

# Verify configurations
ansible -i inventories/production all -m command -a "systemctl status telegraf"

# Run configuration tests
ansible-playbook -i inventories/production playbooks/validate.yml
```

## Best Practices

1. **Environment Isolation**: Keep environments completely separate
2. **Variable Hierarchies**: Use group_vars and host_vars appropriately
3. **Vault Files**: Separate vault files per environment
4. **Testing**: Always test in development before staging
5. **Rollback Plans**: Maintain rollback procedures for production
6. **Documentation**: Document environment-specific configurations

## Troubleshooting

### Common Issues

1. **SSH Key Mismatches**: Ensure correct keys for each environment
2. **Variable Conflicts**: Check variable precedence across environments
3. **Network Access**: Verify firewall rules between environments
4. **Vault Password**: Ensure correct vault passwords for each environment
