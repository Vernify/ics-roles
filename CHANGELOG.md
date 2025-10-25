# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

## [2.0.0] - 2025-10-26

- monitoring_proxy: Added support for deriving site FQDNs from `monitoring_proxy_domain` (defaults to `ansible_domain`); assertion if missing when `server_name` not provided.
- monitoring_proxy: `monitoring_proxy_network` now defaults to `monitoring_common_network_name` when available.
- monitoring_common: Ensures Docker network exists via `monitoring_common_network_name` (unchanged default `monitoring`).
- New role: `storage_grow_pv` to rescan block devices, grow partitions with `growpart`, and `pvresize` when a disk has a single PV; skips multi-PV disks.
- Defaults: Improved cross-org defaults; domains are no longer hardcoded in roles.
