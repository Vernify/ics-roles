# User Management Role

This role provides comprehensive user and group management with customizable sudo rules per group. It allows you to define groups with specific sudo privileges and assign users to those groups to inherit the permissions.

## Description

The `user_management` role handles:
- Creation of custom groups with specific sudo rules
- User creation and assignment to groups
- SSH key management for users
- Sudoers configuration per group
- User state management (present/absent)

This role is designed to be used in customer-specific repositories where you need to manage users for specific subsets of servers with tailored permissions.

## Requirements

- Ansible 2.12 or higher
- Root or sudo access on target hosts
- Python 3 on target hosts

## Role Variables

### Required Variables

| Variable | Description |
|----------|-------------|
| `user_management_groups` | List of groups to create with sudo rules |
| `user_management_users` | List of users to create and assign to groups |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `user_management_default_shell` | `"/bin/bash"` | Default shell for created users |
| `user_management_create_home_dirs` | `true` | Create home directories for users |
| `user_management_remove_unknown_users` | `false` | Remove users not in the configuration |
| `user_management_sudoers_dir` | `"/etc/sudoers.d"` | Directory for sudoers files |

### User-Level Variables

| Variable | Type | Description |
|----------|------|-------------|
| `key_only` | Boolean | If `true`, locks password and disables expiry for SSH-only authentication |

## Variable Structure

### Minimal Configuration

The absolute minimum required to create a user is just the `name` and `group`:

```yaml
user_management_groups:
  - name: "basic_group"
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status nginx"

user_management_users:
  - name: "basic_user"
    group: "basic_group"
```

This will create:
- A user named `basic_user` with default shell (`/bin/bash`)
- Assign them to the `basic_group` 
- Create a home directory (`/home/basic_user`)
- Apply the sudo rules defined for `basic_group`

### Groups Configuration

```yaml
user_management_groups:
  - name: "admin_group"
    gid: 3001
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: ALL"
    state: present
  
  - name: "deploy_group"
    gid: 3002
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx"
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx"
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status nginx"
    state: present
  
  - name: "monitoring_group"
    gid: 3003
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *"
      - "ALL=(ALL) NOPASSWD: /bin/cat /var/log/*.log"
    state: present
```

### Users Configuration

```yaml
user_management_users:
  - name: "admin1"
    uid: 2001
    group: "admin_group"
    groups: ["wheel", "docker"]  # Additional groups (optional)
    shell: "/bin/bash"
    create_home: true
    ssh_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAA... admin1@company.com"
      - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... admin1@workstation"
    password: "{{ vault_admin1_password }}"  # Optional
    comment: "Admin User 1"
    state: present
  
  - name: "simple_user"
    group: "deploy_group"  # Minimal required configuration
  
  - name: "deploy1"
    uid: 2002
    group: "deploy_group"
    shell: "/bin/bash"
    ssh_keys:
      - "{{ vault_deploy1_ssh_key }}"
    state: present
  
  - name: "monitor1"
    uid: 2003
    group: "monitoring_group"
    shell: "/bin/bash"
    ssh_keys:
      - "ssh-rsa AAAAB3NzaC1yc2EAAA... monitor1@company.com"
    state: present
```

### Key-Only Users (SSH Authentication Only)

For users who should only authenticate via SSH keys and never use passwords:

```yaml
---
- name: Create key-only users for automation
  hosts: all
  become: true
  roles:
    - ics.common.user_management
  vars:
    user_management_groups:
      - name: "automation_users"
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status *"
          - "ALL=(ALL) NOPASSWD: /usr/bin/docker ps"
    
    user_management_users:
      - name: "jenkins_user"
        group: "automation_users"
        key_only: true  # Password set to '!' and expiry disabled
        ssh_keys:
          - "{{ vault_jenkins_ssh_key }}"
      - name: "ansible_user"
        group: "automation_users"
        key_only: true
        ssh_keys:
          - "{{ vault_ansible_ssh_key }}"
      - name: "regular_user"
        group: "automation_users"
        # No key_only flag - normal user with password/expiry rules
        password: "{{ vault_regular_password }}"
        ssh_keys:
          - "{{ vault_regular_ssh_key }}"
```

**Key-only user behavior:**
- Simply set `key_only: true` on any user
- Password is automatically set to '!' (no password authentication possible)
- Account expiry is automatically disabled (unless explicitly set)
- SSH key authentication still works normally
- Can be mixed with regular users in the same configuration
- Completely backward compatible - existing users without `key_only` are unaffected

## Example Playbooks

### Basic Usage

```yaml
---
- name: Manage users for web servers
  hosts: web_servers
  become: true
  roles:
    - ics.common.user_management
  vars:
    user_management_groups:
      - name: "web_admins"
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx"
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx"
    
    user_management_users:
      - name: "webadmin1"
        group: "web_admins"
        ssh_keys:
          - "{{ vault_webadmin1_ssh_key }}"
      - name: "webadmin2"
        group: "web_admins"
        ssh_keys:
          - "{{ vault_webadmin2_ssh_key }}"
```

### Advanced Multi-Group Configuration

```yaml
---
- name: Manage users with different privilege levels
  hosts: database_servers
  become: true
  roles:
    - ics.common.user_management
  vars:
    user_management_groups:
      - name: "db_admins"
        gid: 3001
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: ALL"
        state: present
      
      - name: "db_operators"
        gid: 3002
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart mysql"
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mysql"
          - "ALL=(ALL) NOPASSWD: /usr/bin/mysql"
        state: present
      
      - name: "db_monitors"
        gid: 3003
        sudo_rules:
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status mysql"
          - "ALL=(ALL) NOPASSWD: /bin/cat /var/log/mysql/*.log"
        state: present
    
    user_management_users:
      - name: "dbadmin1"
        uid: 2001
        group: "db_admins"
        groups: ["wheel"]
        ssh_keys:
          - "{{ vault_dbadmin1_ssh_key }}"
        comment: "Database Administrator"
      
      - name: "dbops1"
        uid: 2002
        group: "db_operators"
        ssh_keys:
          - "{{ vault_dbops1_ssh_key }}"
        comment: "Database Operator"
      
      - name: "dbmonitor1"
        uid: 2003
        group: "db_monitors"
        ssh_keys:
          - "{{ vault_dbmonitor1_ssh_key }}"
        comment: "Database Monitor"
```

### Customer-Specific Repository Usage

```yaml
# customer_a/playbooks/user_management.yml
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
          - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl status customer-app"
          - "ALL=(ALL) NOPASSWD: /opt/customer-app/scripts/deploy.sh"
    
    user_management_users:
      - name: "customer_a_user1"
        group: "customer_a_admins"
        ssh_keys:
          - "{{ vault_customer_a_user1_key }}"
      - name: "customer_a_user2"
        group: "customer_a_admins"
        ssh_keys:
          - "{{ vault_customer_a_user2_key }}"
```

## Environment-Specific Configuration

### Production Environment
```yaml
user_management_groups:
  - name: "prod_admins"
    sudo_rules:
      - "ALL=(ALL) PASSWD: ALL"  # Require password for production
  
  - name: "prod_deployers"
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp"
      - "ALL=(ALL) NOPASSWD: /opt/deploy/scripts/deploy.sh"
```

### Development Environment
```yaml
user_management_groups:
  - name: "dev_users"
    sudo_rules:
      - "ALL=(ALL) NOPASSWD: ALL"  # Full access in development
```

## Tags

The following tags are available for selective execution:

- `user_management_groups` - Group creation and sudo rules
- `user_management_users` - User creation and configuration
- `user_management_ssh_keys` - SSH key management
- `user_management_sudoers` - Sudoers configuration

### Example Tag Usage

```bash
# Create groups and sudo rules only
ansible-playbook playbook.yml --tags user_management_groups

# Manage users without changing sudo rules
ansible-playbook playbook.yml --tags user_management_users

# Update SSH keys only
ansible-playbook playbook.yml --tags user_management_ssh_keys
```

## Security Considerations

1. **Least Privilege**: Define minimal sudo rules for each group
2. **SSH Keys**: Use SSH keys instead of passwords where possible
3. **Vault Integration**: Store sensitive data in Ansible Vault
4. **Regular Audits**: Review user access regularly
5. **Group Segregation**: Use separate groups for different privilege levels

## Supported Operating Systems

| OS | Version | Status |
|----|---------|--------|
| CentOS | 6.1, 7.x | ✅ Supported |
| Ubuntu | 20.04, 22.04, 24.04 | ✅ Supported |
| Fedora | 20 Heisenburg | ✅ Supported |
| Oracle Linux | 8.5 | ✅ Supported |
| Rocky Linux | 9.5 | ✅ Supported |

## Testing

### Verify Group Creation
```bash
# Check if groups exist
getent group admin_group deploy_group

# Verify sudo rules
sudo -l -U username
```

### Verify User Configuration
```bash
# Check user details
id username

# Test SSH key access
ssh -i ~/.ssh/key username@server

# Test sudo access
sudo -l
```

## Troubleshooting

### Common Issues

1. **Sudo Rule Syntax Errors**
   - Validate sudoers syntax with `visudo -c`
   - Check for typos in command paths

2. **SSH Key Authentication Failures**
   - Verify key format and permissions
   - Check SSH daemon configuration

3. **Group Assignment Issues**
   - Ensure groups exist before creating users
   - Check for UID/GID conflicts

## Contributing

1. Follow the variable naming convention: `user_management_*`
2. Add tests for new functionality
3. Update documentation for new variables
4. Test across all supported operating systems

## License

MIT

## Author Information

This role was created by the ICS Infrastructure Team as part of the ICS Ansible Collection.
