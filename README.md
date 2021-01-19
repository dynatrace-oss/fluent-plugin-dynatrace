# fluent-plugin-dynatrace, a plugin for [Fluentd](http://fluentd.org)

A generic fluentd output plugin for sending logs to an Generic Log Ingest endpoint on Active Gate.


## Build
rake build

## Configuration options

    <match *>
      @type dynatrace
      active_gate_url    http://localhost.local/api/logs/ingest
      api_token          api_token
      ssl_verify_none    false
    </match>

