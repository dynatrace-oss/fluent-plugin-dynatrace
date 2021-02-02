# fluent-plugin-dynatrace, a plugin for [Fluentd](http://fluentd.org)

A fluentd output plugin for sending logs to Dynatrace using the log import API v2.

## Requirements

- An instance of fluentd from which logs should be exported
- The log ingest v2 API must be enabled on your active gate
- An API token with the `Log import` permission

## Configuration options

Below is an example configuration which sends all logs with tags starting with `dt.` to Dynatrace.

```
<match dt.*>
  @type              dynatrace
  active_gate_url    https://abc12345.live.dynatrace.com/api/v2/logs/ingest
  api_token          api_token
  ssl_verify_none    false
</match>
```

### match directive

- `required`

The `match` directive is required to use an output plugin and tells fluentd which tags should be sent to the output plugin. In the above example, any tag that starts with `dt.` will be sent to Dynatrace. For more information see [how do match patterns work?](https://docs.fluentd.org/configuration/config-file#how-do-the-match-patterns-work). 

### @type

- `required`

The `@type` directive tells fluentd which plugin should be used for the corresponding match block. This should always be `dynatrace` when you want to use the Dynatrace output plugin.

### `active_gate_url`

- `required`

This is the full URL of the logs ingest 2.0 API endpoint on your active gate.

### `api_token`

- `required`

This is the API token which will be used to authenticate log ingest requests. It should be assigned only the `Log import` permission.

### `ssl_verify_none`

- `optional`
- `default: false`

It is recommended to leave this optional configuration set to `false` unless absolutely required. Setting `ssl_verify_none` to `true` causes the output plugin to skip certificate verification when sending log ingest requests to SSL and TLS protected HTTPS endpoints. This option may be required if you are using a self-signed certificate, an expired certificate, or a certificate which was generated for a different domain than the one in use.
