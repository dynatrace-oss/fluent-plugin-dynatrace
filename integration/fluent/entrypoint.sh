#!/usr/bin/env sh

exec fluentd -c /fluentd/etc/fluent.conf -p /fluentd/plugins
