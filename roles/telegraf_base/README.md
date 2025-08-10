telegraf.saicom_io.svs-za-jhb-se-dev-db-01_saicom_io.mosaic.metrics.mongodb.mongodb_mongod_connections_current

# Telegraf Base Role

Manages Telegraf installation and configuration, including plugin monitoring and Graphite output.

## MongoDB Monitoring

  `/opt/graphite/storage/whisper/telegraf/saicom_io/<fqdn>/mosaic/metrics/mongodb/*`

- To enable MongoDB monitoring, ensure the `telegraf-mongodb.conf` template is deployed to `/etc/telegraf/telegraf.d/` on MongoDB servers.
- This can be done by including the appropriate deploy task in your playbook or role for MongoDB hosts.
- Metrics are sent to Graphite under:

**Example metric path:**
```
telegraf.saicom_io.<fqdn>.mosaic.metrics.mongodb.mongodb_mongod_connections_current
```

## Adding New Plugins

- Add a Telegraf input template in `templates/` and a deploy task in `tasks/configure.yml`.
- Follow the metric path convention above.

## Graphite Output

- The authoritative Graphite output config is in `graphite.conf.j2`.
- All metrics use the path:
  `/opt/graphite/storage/whisper/telegraf/saicom_io/<fqdn>/mosaic/metrics/<plugin>/*`
