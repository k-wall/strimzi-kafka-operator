#!/usr/bin/env bash

docker pull quay.io/app-sre/mk-ci-tools:latest

docker run -v `pwd`/cluster:/opt/cluster \
            -w /opt/tools/scripts \
            -e WORKDIR=/opt \
            -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
            -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
            -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
            -e OCM_TOKEN=${OCM_TOKEN} \
            -u `id -u` \
            quay.io/app-sre/mk-ci-tools:latest ./mk-osd-provision.sh delete_cluster_if_exists "/opt/cluster/cluster-name"
