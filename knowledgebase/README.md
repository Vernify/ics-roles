# Knowledge Base

Concise docs for operating the ICS Ansible Collection roles used here. Keep content brief, actionable, and version-aware.

## Contents

- Monitoring
	- [Monitoring Stack overview](monitoring_stack.md)
	- [Graylog + OpenSearch troubleshooting](graylog-opensearch-troubleshooting.md)

## Deployment notes

- Collections: this project uses the shared `ics-roles` collection and common community collections (`community.docker`, `community.general`, `ansible.posix`).
- Playbooks consume roles via FQCNs (e.g., `ics.common.graylog`).

## Authoring guidelines

- Be concise: focus on steps, commands, and variables.
- Keep versions current; note when a tip applies to a specific release.
- Prefer role defaults over hardcoded org values; use `ansible_domain` when deriving FQDNs.
