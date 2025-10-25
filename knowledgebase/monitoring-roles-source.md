# Monitoring roles source (deprecated)

The monitoring stack roles are now sourced from the shared ICS collection:

- ics.common.monitoring_common
- ics.common.monitoring_proxy (renamed from local nginx role)
- ics.common.graphite
- ics.common.grafana
- ics.common.graylog

Update ansible/requirements.yml to use tag 2.0.0 and run:

```
ansible-galaxy collection install -r ansible/requirements.yml
```

Playbooks have been updated to reference the collection using FQCNs.
