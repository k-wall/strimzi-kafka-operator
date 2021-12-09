#!/bin/bash

docker pull quay.io/app-sre/mk-ci-tools:latest
docker run -u $(id -u) -v $(pwd):/opt/strimzi-operator:z \
    quay.io/app-sre/mk-ci-tools:latest \
    "bash" "-c" "cd /opt/strimzi-operator && make 'SUBDIRS=kafka-agent mirror-maker-agent tracing-agent crd-annotations test crd-generator api mockkube certificate-manager operator-common config-model config-model-generator cluster-operator topic-operator user-operator kafka-init packaging/helm-charts/helm3 packaging/install packaging/examples' MVN_ARGS='-DskipITs -DskipTests=true -Dgroups=oauth' all"