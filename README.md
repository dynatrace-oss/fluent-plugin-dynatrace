# fluent-plugin-dynatrace, a plugin for [fluentd](https://www.fluentd.org/)

> This project is developed and maintained by Dynatrace R&D.

A fluentd output plugin for sending logs to the Dynatrace [Generic log ingest API v2](https://www.dynatrace.com/support/help/how-to-use-dynatrace/log-monitoring/log-monitoring-v2/post-log-ingest/).

## Requirements

- An instance of fluentd >= v1.0 from which logs should be exported
- Ruby version >= 2.4.0
- An ActiveGate with the Generic log ingest API v2 enabled as described in the [Dynatrace documentation](https://www.dynatrace.com/support/help/how-to-use-dynatrace/log-monitoring/log-monitoring-v2/log-data-ingestion/)
- A [Dynatrace API token](https://www.dynatrace.com/support/help/dynatrace-api/basics/dynatrace-api-authentication/) with the `logs.ingest` (Ingest Logs) scope

## Installation

The plugin is published on Rubygems at <https://rubygems.org/gems/fluent-plugin-dynatrace/>.

To install it, run the following command:

```sh
fluent-gem install fluent-plugin-dynatrace
```

If you are using `td-agent`, run:

```sh
td-agent-gem install fluent-plugin-dynatrace
```

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

If configured with custom `<buffer>` settings, it is recommended to set `flush_thread_count` to `1`.
The output plugin is limited to a single outgoing connection to Dynatrace and multiple export threads will have limited impact on export latency.

### match directive

- `required`

The `match` directive is required to use an output plugin and tells fluentd which tags should be sent to the output plugin. In the above example, any tag that starts with `dt.` will be sent to Dynatrace. For more information see [how do match patterns work?](https://docs.fluentd.org/configuration/config-file#how-do-the-match-patterns-work). 

### @type

- `required`

The `@type` directive tells fluentd which plugin should be used for the corresponding match block. This should always be `dynatrace` when you want to use the Dynatrace output plugin.

### `active_gate_url`

- `required`

This is the full URL of the [Generic log ingest API v2](https://www.dynatrace.com/support/help/how-to-use-dynatrace/log-monitoring/log-monitoring-v2/post-log-ingest/) endpoint on your ActiveGate.

### `api_token`

- `required`

This is the [Dynatrace API token](https://www.dynatrace.com/support/help/dynatrace-api/basics/dynatrace-api-authentication/) which will be used to authenticate log ingest requests. It should be assigned only the `logs.ingest` (Ingest Logs) scope.

### `ssl_verify_none`

- `optional`
- `default: false`

It is recommended to leave this optional configuration set to `false` unless absolutely required. Setting `ssl_verify_none` to `true` causes the output plugin to skip certificate verification when sending log ingest requests to SSL and TLS protected HTTPS endpoints. This option may be required if you are using a self-signed certificate, an expired certificate, or a certificate which was generated for a different domain than the one in use.

## Development

`fluent-plugin-dynatrace` supports Ruby versions `>= 2.4.0` but it is recommended that at least `2.7.2` is used for development. Ruby versions can be managed with tools like [chruby](https://github.com/postmodern/chruby) or [rbenv](https://github.com/rbenv/rbenv).

### Install Dependencies

```sh
bundle install
```

### Run All Tests

```sh
rake test
```

### Run Specific Tests

```sh
# Run one test file
rake test TEST=test/plugin/out_dynatrace_test.rb
```

### Code Style Checks

```sh
# Check for code style violations
rake rubocop

# Fix auto-fixable style violations
rake rubocop:auto_correct
```

### Run all checks and build

```sh
# Runs rubocop, tests, and builds the gem
rake check
```
