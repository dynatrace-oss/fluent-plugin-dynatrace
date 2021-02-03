FROM fluent/fluentd:edge

LABEL maintainer="Daniel Dyla <Daniel.Dyla@dynatrace.com>"
USER root

# the build context is the root of the repo to allow access to the plugin rb
COPY integration/fluent/entrypoint.sh /fluentd/entrypoint.sh
RUN chmod +x /fluentd/entrypoint.sh

COPY integration/fluent/fluent.conf /fluentd/etc/fluent.conf
COPY lib/fluent/plugin/out_dynatrace.rb /fluentd/plugins/

ENTRYPOINT ["tini", "--", "/fluentd/entrypoint.sh"]

USER fluent
