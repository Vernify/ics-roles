# auditd

Configures Linux audit daemon with automatic rsyslog forwarding for centralized log management.

## Features

- Installs and configures auditd
- Configurable audit rules
- Automatic rsyslog forwarding to syslog (default: local6)
- Supports custom audit rules per environment

## Configuration

```yaml
auditd_forward_to_rsyslog: true  # Forward to syslog
auditd_rsyslog_facility: local6
auditd_rsyslog_tag: auditd
auditd_rules:
  - name: sudo
    rule: '-a always,exit -F arch=b64 -S execve -F path=/usr/bin/sudo -F key=sudo'
```

See `defaults/main.yml` for all available options.
