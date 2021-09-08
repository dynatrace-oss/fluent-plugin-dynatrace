FROM fluent/fluentd-kubernetes-daemonset:v1.13-debian-forward-amd64-1

USER root
WORKDIR /

RUN gem install fluent-plugin-dynatrace -v 0.1.5
RUN gem install fluent-plugin-kubernetes_metadata_filter -v 2.7.2