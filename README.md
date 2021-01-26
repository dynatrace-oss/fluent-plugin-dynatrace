# fluent-plugin-dynatrace, a plugin for [fluentd](http://fluentd.org)

> This project is developed and maintained by Dynatrace R&D.
Currently, this is a prototype and not intended for production use.
It is not covered by Dynatrace support.

A fluentd output plugin for sending logs to the Dynatrace Generic log ingest API v2.

## Build

```sh
rake build
```

## Configuration options

```text
    <match *>
      @type dynatrace
      active_gate_url    https://{your-domain}/e/{your-environment-id}/api/v2/logs/ingest
      api_token          api_token
      ssl_verify_none    false
    </match>
```
