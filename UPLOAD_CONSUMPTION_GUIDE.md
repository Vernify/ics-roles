# ICS Ansible Collection - Upload and Consumption Guide

This guide provides step-by-step instructions for uploading the ICS Ansible Collection to Ansible Galaxy and consuming it in customer projects.

## Table of Contents

1. [Building and Publishing the Collection](#building-and-publishing)
2. [Installing the Collection](#installing-the-collection)
3. [Using the Collection in Customer Projects](#using-in-customer-projects)
4. [Version Management](#version-management)
5. [CI/CD Integration](#cicd-integration)
6. [Troubleshooting](#troubleshooting)

## Building and Publishing

### Prerequisites

```bash
# Install required tools
pip install ansible-core>=2.12
pip install ansible-builder
pip install twine  # For publishing

# Install collection dependencies
ansible-galaxy collection install -r requirements.yml
```

### Building the Collection

1. **Validate Collection Structure**
   ```bash
   # Lint the collection
   ansible-lint .
   
   # Validate collection metadata
   ansible-galaxy collection build --force
   ```

2. **Build Collection Archive**
   ```bash
   # Build the collection tarball
   ansible-galaxy collection build
   
   # This creates: ics-common-1.0.0.tar.gz
   ```

3. **Test Collection Locally**
   ```bash
   # Install locally for testing
   ansible-galaxy collection install ics-common-1.0.0.tar.gz --force
   
   # Test the collection
   ansible-playbook examples/basic_web_server_users.yml --check
   ```

### Publishing to Ansible Galaxy

#### Option 1: Ansible Galaxy Hub (Public)

1. **Create Galaxy Account**
   - Visit [galaxy.ansible.com](https://galaxy.ansible.com)
   - Create account or login with GitHub

2. **Get API Token**
   ```bash
   # Get your API token from Galaxy
   # Profile > API Key
   export ANSIBLE_GALAXY_TOKEN="your_token_here"
   ```

3. **Publish Collection**
   ```bash
   # Upload to Galaxy
   ansible-galaxy collection publish ics-common-1.0.0.tar.gz --api-key $ANSIBLE_GALAXY_TOKEN
   
   # Or configure in ansible.cfg
   ansible-galaxy collection publish ics-common-1.0.0.tar.gz
   ```

#### Option 2: Private Galaxy Server

1. **Configure Private Galaxy**
   ```bash
   # Add to ansible.cfg
   [galaxy]
   server_list = private_galaxy
   
   [galaxy_server.private_galaxy]
   url = https://galaxy.company.com/
   token = your_private_token
   ```

2. **Publish to Private Galaxy**
   ```bash
   ansible-galaxy collection publish ics-common-1.0.0.tar.gz --server private_galaxy
   ```

#### Option 3: Internal Git Repository

1. **Create Git Tags**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Use Git Installation**
   ```bash
   ansible-galaxy collection install git+https://github.com/company/ics-ansible-collection.git,v1.0.0
   ```

## Installing the Collection

### Method 1: From Ansible Galaxy

```bash
# Install latest version
ansible-galaxy collection install ics.common

# Install specific version
ansible-galaxy collection install ics.common:1.0.0

# Install with force update
ansible-galaxy collection install ics.common --force
```

### Method 2: Using Requirements File

Create `requirements.yml`:

```yaml
---
collections:
  - name: ics.common
    version: ">=1.0.0"
  - name: community.general
    version: ">=7.0.0"
  - name: ansible.posix
    version: ">=1.5.0"
```

Install:
```bash
ansible-galaxy collection install -r requirements.yml
```

### Method 3: From Git Repository

```bash
# Install from main branch
ansible-galaxy collection install git+https://github.com/company/ics-ansible-collection.git

# Install specific version/tag
ansible-galaxy collection install git+https://github.com/company/ics-ansible-collection.git,v1.0.0

# Install from specific branch
ansible-galaxy collection install git+https://github.com/company/ics-ansible-collection.git,feature-branch
```

### Method 4: Local Installation

```bash
# Install from local tarball
ansible-galaxy collection install /path/to/ics-common-1.0.0.tar.gz

# Install from local directory
ansible-galaxy collection install /path/to/collection/directory
```

## Using in Customer Projects

### Project Structure

```
customer_project/
├── ansible.cfg
├── requirements.yml
├── inventories/
│   ├── production/
│   │   ├── hosts.yml
│   │   └── group_vars/
│   └── staging/
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
│   ├── user_management.yml
│   ├── site.yml
│   └── deploy.yml
└── group_vars/
    ├── all/
    │   ├── main.yml
    │   └── vault.yml
    └── web_servers/
        └── main.yml
```

### Configuration Files

**ansible.cfg**
```ini
[defaults]
inventory = inventories/production/hosts.yml
roles_path = ~/.ansible/roles:./roles
collections_path = ~/.ansible/collections
host_key_checking = False
retry_files_enabled = False

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

**requirements.yml**
```yaml
---
collections:
  - name: ics.common
    version: ">=1.0.0"
  - name: community.general
  - name: ansible.posix
```

### Example Customer Playbook

**playbooks/user_management.yml**
```yaml
---
- name: Manage Customer A users
  hosts: customer_a_servers
  become: true
  roles:
    - ics.common.user_management
  
  vars:
    user_management_groups:
      - name: "customer_a_admins"
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart customer-app"
          - "ALL=(ALL) NOPASSWD: /opt/customer-app/scripts/deploy.sh"
    
    user_management_users:
      - name: "admin1"
        group: "customer_a_admins"
        ssh_keys:
          - "{{ vault_admin1_ssh_key }}"
```

### Deployment Commands

```bash
# Install dependencies
ansible-galaxy collection install -r requirements.yml

# Deploy user management
ansible-playbook playbooks/user_management.yml

# Deploy to specific environment
ansible-playbook -i inventories/staging playbooks/user_management.yml

# Deploy to specific hosts
ansible-playbook playbooks/user_management.yml --limit web_servers

# Dry run
ansible-playbook playbooks/user_management.yml --check
```

## Version Management

### Semantic Versioning

Follow semantic versioning (semver):
- **Major (X.0.0)**: Breaking changes
- **Minor (1.X.0)**: New features, backward compatible
- **Patch (1.0.X)**: Bug fixes, backward compatible

### Version Pinning Strategies

**Conservative (Patch updates only)**
```yaml
collections:
  - name: ics.common
    version: "1.0.*"
```

**Moderate (Minor updates)**
```yaml
collections:
  - name: ics.common
    version: ">=1.0.0,<2.0.0"
```

**Flexible (Latest compatible)**
```yaml
collections:
  - name: ics.common
    version: ">=1.0.0"
```

### Upgrade Process

1. **Test in Development**
   ```bash
   # Update to latest version in dev
   ansible-galaxy collection install ics.common --force
   ansible-playbook playbooks/user_management.yml --check
   ```

2. **Validate in Staging**
   ```bash
   # Deploy to staging
   ansible-playbook -i inventories/staging playbooks/user_management.yml
   ```

3. **Deploy to Production**
   ```bash
   # Update requirements.yml with tested version
   # Deploy to production
   ansible-playbook -i inventories/production playbooks/user_management.yml
   ```

## CI/CD Integration

### Jenkins Pipeline Example

```groovy
pipeline {
    agent any
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh '''
                    ansible-galaxy collection install -r requirements.yml --force
                '''
            }
        }
        
        stage('Lint Playbooks') {
            steps {
                sh '''
                    ansible-lint playbooks/
                '''
            }
        }
        
        stage('Deploy to Staging') {
            when { branch 'develop' }
            steps {
                withCredentials([
                    string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')
                ]) {
                    sh '''
                        echo "$VAULT_PASS" > vault_pass.txt
                        ansible-playbook -i inventories/staging playbooks/user_management.yml --vault-password-file vault_pass.txt
                        rm vault_pass.txt
                    '''
                }
            }
        }
        
        stage('Deploy to Production') {
            when { branch 'main' }
            steps {
                withCredentials([
                    string(credentialsId: 'ansible-vault-password', variable: 'VAULT_PASS')
                ]) {
                    sh '''
                        echo "$VAULT_PASS" > vault_pass.txt
                        ansible-playbook -i inventories/production playbooks/user_management.yml --vault-password-file vault_pass.txt
                        rm vault_pass.txt
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
```

### GitHub Actions Example

```yaml
name: Deploy Users

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    
    - name: Install Ansible
      run: |
        pip install ansible-core
        ansible-galaxy collection install -r requirements.yml
    
    - name: Lint Playbooks
      run: |
        pip install ansible-lint
        ansible-lint playbooks/
    
    - name: Deploy to Staging
      if: github.ref == 'refs/heads/develop'
      env:
        ANSIBLE_VAULT_PASSWORD: ${{ secrets.ANSIBLE_VAULT_PASSWORD }}
      run: |
        echo "$ANSIBLE_VAULT_PASSWORD" > vault_pass.txt
        ansible-playbook -i inventories/staging playbooks/user_management.yml --vault-password-file vault_pass.txt
        rm vault_pass.txt
    
    - name: Deploy to Production
      if: github.ref == 'refs/heads/main'
      env:
        ANSIBLE_VAULT_PASSWORD: ${{ secrets.ANSIBLE_VAULT_PASSWORD }}
      run: |
        echo "$ANSIBLE_VAULT_PASSWORD" > vault_pass.txt
        ansible-playbook -i inventories/production playbooks/user_management.yml --vault-password-file vault_pass.txt
        rm vault_pass.txt
```

## Troubleshooting

### Common Issues

#### Collection Not Found
```bash
# Check collection path
ansible-config dump | grep COLLECTIONS_PATHS

# List installed collections
ansible-galaxy collection list

# Reinstall collection
ansible-galaxy collection install ics.common --force
```

#### Version Conflicts
```bash
# Check installed versions
ansible-galaxy collection list ics.common

# Remove and reinstall
ansible-galaxy collection list
rm -rf ~/.ansible/collections/ansible_collections/ics/common
ansible-galaxy collection install ics.common:1.0.0
```

#### Role Not Found
```bash
# Verify role exists in collection
ansible-doc -l ics.common

# Check role documentation
ansible-doc ics.common.user_management
```

#### Vault Issues
```bash
# Test vault decryption
ansible-vault view group_vars/all/vault.yml

# Check vault password file
echo "password" > vault_pass.txt
ansible-playbook playbook.yml --vault-password-file vault_pass.txt
```

### Debug Commands

```bash
# Verbose output
ansible-playbook playbook.yml -vvv

# Check variables
ansible-playbook playbook.yml --extra-vars "debug=true"

# Dry run with output
ansible-playbook playbook.yml --check --diff

# List tasks
ansible-playbook playbook.yml --list-tasks

# List hosts
ansible-playbook playbook.yml --list-hosts
```

### Getting Help

1. **Documentation**: Check role README files
2. **Examples**: Review example playbooks
3. **Issues**: Report issues on GitHub
4. **Support**: Contact ICS Infrastructure Team

## Best Practices

1. **Pin Versions**: Use specific versions in production
2. **Test First**: Always test in development/staging
3. **Use Vault**: Store secrets in Ansible Vault
4. **Document Changes**: Document customizations
5. **Regular Updates**: Keep collections updated
6. **Monitor Logs**: Review deployment logs
7. **Backup Configs**: Backup before changes
