# Copilot Instructions for Homelab Projects

This document defines conventions, best practices, and documentation structure for all code and documentation generated in this repository.
Follow these guidelines to ensure consistency, security, and maintainability.

---

## General Principles

- Use descriptive names for files, resources, playbooks, and roles.
- Add comments to explain non-obvious logic.
- Keep documentation concise, accurate, and up to date.
- Use version control for all code and documentation changes.
- Reference and update the `/knowledgebase` and `/architecture` directories as needed.

---

## Ansible Guidelines

- **Module Usage:** Always use Fully Qualified Collection Names (FQCNs), e.g., `ansible.builtin.file`.
- **Variable Naming:** Prefix all variables in roles with the role name (e.g., `myapp_mount_path`). In `defaults/main.yml`, use the role name as a prefix.
- **Playbook Structure:**
  - Name all plays using the `name` attribute.
  - Use variables for configuration values to maximize reusability.
  - Use handlers for service restarts and actions that should only run on change.
  - Use loops and conditionals for multiple hosts or tasks.
  - Use tags for selective execution.
  - Use Ansible Galaxy roles for common tasks to promote reuse.
- **Secrets:** Store all sensitive data in Ansible Vault or Hashicorp Vault. Never commit secrets or vault passwords to version control.
- **Quality:** Use `ansible-lint` and pre-commit hooks for code quality.
- **Documentation:** Document the purpose and usage of playbooks and roles in the knowledgebase.

---

## Terraform Guidelines

- Use a modular structure for reusable components.
- Keep provider and backend configuration clear and DRY.
- Use variables and outputs for flexibility and documentation.

---

## Jenkins Guidelines

- Prefer consuming secrets from Hashicorp Vault.
- Use declarative pipelines for clarity and maintainability.
- If Ansible is used in the pipeline, always add a lint check stage.

---

## Documentation Structure

- **Knowledgebase** (`/knowledgebase`)
  - Concise documentation of common tasks, troubleshooting, and best practices.
  - Add a `README.md` if missing, explaining the directory's purpose.
  - Keep entries short, actionable, and relevant.

- **Architecture** (`/architecture`)
  - Use LADR format for high-level design and architectural decisions.
  - Include dependencies, integrations, and patterns.
  - Use Mermaid diagrams to illustrate relationships and flows.
  - Add a `README.md` if missing, explaining the directory's purpose.

- **Diagrams**
  - Prefer Mermaid for architecture and workflow diagrams.
  - Store diagrams in the relevant documentation directory.

---

## Monitoring & Observability

- **Stack:** Graphite, Graylog, Grafana, Telegraf, Prometheus, Betterstack, Watchtower.
- Document monitoring and alerting configurations in the knowledgebase.

---

## Security & Secrets

- Store all sensitive data in Ansible Vault or Hashicorp Vault.
- Never commit secrets or vault passwords to version control.
- Document secret management practices in the knowledgebase.

---

## Contribution & Collaboration

- Follow these conventions and structure.
- Document new patterns, troubleshooting, and architectural decisions as you go.
- Keep all documentation and code modular, reusable, and secure.

---

## Future Guidance

- When introducing new tools or patterns, document them in the knowledgebase and update this file if needed.
- Use this file as the base for all future Copilot and AI interactions to ensure consistency and best practices across the homelab ecosystem.
