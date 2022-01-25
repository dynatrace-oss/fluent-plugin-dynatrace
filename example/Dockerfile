FROM fluent/fluentd-kubernetes-daemonset:v1.14-debian-forward-amd64-1

USER root
WORKDIR /

RUN apt update && \
    apt install make gcc -y && \ 
    rm -rf /var/lib/apt/lists/* && \
    gem install fluent-plugin-dynatrace -v 0.1.6 && \
    gem install fluent-plugin-kubernetes_metadata_filter -v 2.7.2 && \
    gem install fluent-plugin-multi-format-parser && \
    gem install fluent-plugin-concat