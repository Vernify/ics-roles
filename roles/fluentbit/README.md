# fluentbit role

Scaffold for a generic Fluent Bit role. Installs Fluent Bit and renders a basic config suitable for forwarding to a configurable collector endpoint.

Note: Fluent Bit is disabled by default in this collection (see `defaults/main.yml`). The collection no longer includes an automated auditd -> Fluent Bit forwarding integration; audit forwarding uses rsyslog by default. If you explicitly enable Fluent Bit and want audit forwarding, re-enable or restore the `auditd/templates/disabled_fluentbit_audit.conf.j2` template and wire it up intentionally.
