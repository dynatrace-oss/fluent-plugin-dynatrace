FROM fluent/fluentd-kubernetes-daemonset:v1.20-debian-forward-amd64-1@sha256:86dfc99d17419064610310fcc24b5843b98f4ba24e5ff208240554a7a99ada51

USER root
WORKDIR /

RUN apt update && \
    apt install make gcc -y && \ 
    rm -rf /var/lib/apt/lists/* && \
    gem install fluent-plugin-dynatrace -v 0.1.6 && \
    gem install fluent-plugin-kubernetes_metadata_filter -v 2.7.2 && \
    gem install fluent-plugin-multi-format-parser && \
    gem install fluent-plugin-concat
