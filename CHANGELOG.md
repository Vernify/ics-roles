# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2025-11-09

## [3.1.1] - 2025-11-29

### Changed
- Release bump and metadata updates (version 3.1.1).
- Only pass groups if defined.


### Added
- **monitoring_backup** role - Automated backup and restoration for Grafana and Graylog
  - Grafana: API-based dashboard export, provisioning files, optional database backup
  - Graylog: OpenSearch snapshots and MongoDB data backup
  - Retention policies: daily/weekly/monthly with configurable retention
  - Optional AES-256-CBC encryption
  - Verification, monitoring, and restoration scripts
  - Comprehensive logging with logrotate integration
- **Knowledge base** - Created knowledgebase directory with operational documentation
  - monitoring-backup-guide.md with detailed backup/restore procedures
- **meta/runtime.yml** - Added required collection runtime metadata

### Fixed
- **graylog** role - Fixed undefined `monitoring_domain` variable
  - Changed to `graylog_domain` with sensible default (`ansible_domain`)
  - Prevents runtime errors when `monitoring_domain` not defined in inventory
- **telegraf_base** role - Fixed ansible-lint violations
  - Proper variable naming with role prefix
  - Replaced curl with get_url module
  - Fixed truthy values (yes/no → true/false)
- **monitoring_backup** role - Fixed loop variable naming
  - Added proper loop_var prefixes to comply with ansible-lint
- **Documentation** - Updated README.md to accurately reflect all available roles
- **Architecture** - Removed references to non-existent LADR documents

## [1.2.0] - 2025-08-10

- **`telegraf_base` role** for cross-platform Telegraf monitoring
  - Support for Ubuntu, SLES, and Rocky Linux
- **Cross-platform support** - improved OS detection and package management

## [1.1.1] - 2025-08-05

### Added
- **User audit and exempt groups** in `user_management` role
  - `user_management_audit_exempt_groups` for organization-wide admin exemptions


## [1.1.0] - 2025-08-05

### Added
  - Password locking and expiry management for key-only users
  - Example playbook for mixed user types

## [1.0.0] - Initial Release
- `user_management` role with group/user management, SSH keys, and sudo configuration
- Comprehensive documentation and examples

## [3.1.0] - 2025-11-09

## [2.0.0] - 2025-10-26

### Added
- monitoring_proxy: Added support for deriving site FQDNs from `monitoring_proxy_domain` (defaults to `ansible_domain`); assertion if missing when `server_name` not provided.
- monitoring_proxy: `monitoring_proxy_network` now defaults to `monitoring_common_network_name` when available.
- monitoring_common: Ensures Docker network exists via `monitoring_common_network_name` (unchanged default `monitoring`).
- New role: `storage_grow_pv` to rescan block devices, grow partitions with `growpart`, and `pvresize` when a disk has a single PV; skips multi-PV disks.
- Defaults: Improved cross-org defaults; domains are no longer hardcoded in roles.

### Fixed
- `storage_grow_pv` compatibility with Ansible 2.14.x
  - Use `ansible.builtin.shell` for PKNAME lookup with pipes and `head -n1`.
  - Remove unsupported `warn` parameter from command/shell usages to avoid errors like "Unsupported parameters for (ansible.legacy.command) module: warn".

 
