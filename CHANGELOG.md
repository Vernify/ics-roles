# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-08-05

### Added
- **User audit and exempt groups functionality** in `user_management` role
  - New `user_management_audit_exempt_groups` variable to exempt organization-wide admin groups from cleanup/audit alerts
  - Comprehensive user audit reporting that always runs for monitoring and alerting integration
  - Structured audit facts (`user_management_audit_results`) for integration with monitoring systems
  - Security alerting for exempt group members not managed in code
  - Support for layered user management (org-wide + project-specific users)

### Enhanced
- **Improved cleanup logic** - now reuses audit logic to properly handle exempt groups
- **Key-only user functionality** - simplified to use only `key_only: true` per user (removed global variables)
- **Documentation** - comprehensive coverage of audit, exempt groups, and monitoring integration
- **Code quality** - fixed ansible-lint issues (loop variable prefix, trailing spaces)

### Changed
- Simplified key-only user implementation - removed global `user_management_key_only_*` variables
- Users with `key_only: true` now automatically get password set to '!' and expiry disabled
- Cleanup tasks now reuse audit logic instead of duplicating user identification logic
- Enhanced audit output to include exempt groups and security alerts

### Technical Details
- Backward compatible - all existing functionality preserved
- Exempt groups feature is opt-in via `user_management_audit_exempt_groups: []`
- Audit always runs and provides structured output for monitoring integration
- Security-focused design alerts on exempt users not managed in code

## [1.1.0] - 2025-08-05

### Added
- **Key-only user functionality** in `user_management` role
  - New `key_only` user attribute to create SSH-only authentication users
  - New role variables:
    - `user_management_key_only_password_lock` (default: `false`) - Set password to '!' for key_only users
    - `user_management_key_only_disable_expiry` (default: `false`) - Disable account expiry for key_only users
  - Key-only users have password set to '!' to exempt them from password expiry rules
  - Key-only users can have account expiry disabled when enabled
  - SSH key authentication continues to work normally for key-only users
- Documentation for key-only user functionality in role README
- Example playbook demonstrating key-only users (`examples/key_only_users.yml`)

### Changed
- Enhanced user creation logic in `user_management` role to support key-only users
- Updated "lock inactive users" task to avoid conflicts with key-only users
- Improved user password handling to conditionally set '!' password for key-only users
- Enhanced user expiry logic to conditionally disable expiry for key-only users

### Technical Details
- Feature is completely opt-in with defaults set to `false` for backward compatibility
- Existing implementations are 100% unaffected unless explicitly enabling new functionality
- Key-only users use '!' password instead of `password_lock: true` for better vendor account compatibility
- No breaking changes to existing role functionality

### Documentation
- Updated role README with key-only user configuration examples
- Added comprehensive documentation of new variables and behavior
- Created example playbook showing mixed regular and key-only users
- Updated variable documentation table with new settings

## [1.0.0] - Initial Release
- Initial release of the ics-roles collection
- `user_management` role with group and user management functionality
- SSH key management capabilities
- Sudo rules configuration per group
- Comprehensive documentation and examples
