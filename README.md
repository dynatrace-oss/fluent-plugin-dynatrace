# fluent-plugin-dynatrace, a plugin for [Fluentd](http://fluentd.org)

A generic [fluentd][1] output plugin for sending logs to an Generic Log Ingest endpoint on Active Gate.


## Build
rake build

## Configuration options

    <match *>
      @type dynatrace
      active_gate_url    http://localhost.local/api/logIngest
      api_token          api_token
    </match>

