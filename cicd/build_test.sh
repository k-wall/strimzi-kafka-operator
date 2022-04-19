#!/usr/bin/env bash

export ST_KAFKA_VERSION=3.0.0
export COMPONENTS_IMAGE_PULL_POLICY=Always
export TEST_CLIENT_IMAGE=quay.io/strimzi/test-client:0.26.1-kafka-3.0.0
export TEST_PRODUCER_IMAGE=quay.io/mk-ci-cd/java-kafka-producer:latest
export TEST_CONSUMER_IMAGE=quay.io/mk-ci-cd/java-kafka-consumer:latest
export TEST_STREAMS_IMAGE=quay.io/mk-ci-cd/java-kafka-streams:latest

# require WORKDIR (defaults to strimzi-operator dir)
WORKDIR=${WORKDIR:-$(pwd)}


if [[ $1 == "minimal" ]]; then
  STRATEGY=$1
fi
if [[ $1 == "acceptance" ]]; then
  STRATEGY=$1
fi
if [[ $1 == "regression" ]]; then
  STRATEGY=$1
fi

STRATEGY=${STRATEGY:-"minimal"}

echo "####  Executing ${STRATEGY} tests  ####"


if [ ${STRATEGY} == "minimal"  ] ;  then
  # Minimal test (CVE, minimal PR)
  export TEST_LOG_DIR="${WORKDIR}/test-results/strimzi-operator/minimal/":
  mkdir -p "${TEST_LOG_DIR}"
  mvn clean verify -am -Pall -pl systemtest -DfailIfNoTests=false -Dfailsafe.rerunFailingTestsCount=2 \
                   -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
                   -Dgroups=regression \
                   -Dit.test=ListenersST#testCustomCertRouteAndTlsRollingUpdate
  exit $?
fi


if [ ${STRATEGY} == "acceptance"  ] ;  then
  # Acceptance tests
  export TEST_LOG_DIR="${WORKDIR}/test-results/strimzi-operator/acceptance/":
  mkdir -p "${TEST_LOG_DIR}"
  mvn clean verify -am -Pall -pl systemtest -Dfailsafe.rerunFailingTestsCount=2 -DfailIfNoTests=false \
                   -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
                   -Dgroups=acceptance \
                   -DexcludedGroups=loadbalancer,nodeport,bridge,connectcomponents,mirrormaker,upgrade
  exit $?
fi

if [ ${STRATEGY} == "regression"  ] ;  then
  # Regression tests
  export TEST_LOG_DIR="${WORKDIR}/test-results/strimzi-operator/regression/":
  mkdir -p "${TEST_LOG_DIR}"
  mvn clean verify -am -Pall -pl systemtest -Dfailsafe.rerunFailingTestsCount=2 -DfailIfNoTests=false \
                   -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
                   -Dgroups=regression \
                   -DexcludedGroups=loadbalancer,nodeport,bridge,connectcomponents,mirrormaker,upgrade,helm
  exit $?
fi


# Upgrade tests
#################
#export TEST_LOG_DIR="${WORKDIR}/test-results/strimzi-operator/upgrade/":
#mkdir -p "${TEST_LOG_DIR}"
#mvn clean verify -am -Pall -pl systemtest -Dfailsafe.rerunFailingTestsCount=2 -DfailIfNoTests=false \
#                 -B -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
#                 -Dgroups=upgrade \
#                 -Dit.test=KafkaUpgradeDowngradeST
