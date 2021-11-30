#!/usr/bin/env bash

function stage() {
  echo "---------------------------------------------------------------------"
  echo "${1}"
  echo "---------------------------------------------------------------------"
}

function check_exit_code() {
  exit_code=${1}
  process_name=${2}
  if [ $exit_code != 0 ] ;  then
    echo "${process_name} exited with the code: $exit_code"
    exit $exit_code
  fi
}

###############
# Parameters
###############

TEMP_CPAAS_BUILD=${TEMP_CPAAS_BUILD:-true}
SKIP_BUILD=${SKIP_BUILD:-false}
#CPAAS_BUILD="15"
RELEASE=${RELEASE:-false}
TEST_STRATEGY=${TEST_STRATEGY:-"minimal"}
CLUSTER_CLEANUP=${CLUSTER_CLEANUP:-true}

MIRROR_FLAG=snapshot

if [[ $1 == "nightly" ]]; then
  CPAAS_PIPELINE="managed-kafka-cicd-nightly"
  MIRROR_FLAG=nightly
  TEST_STRATEGY="acceptance"
  TEMP_CPAAS_BUILD=true
  RELEASE=false
fi

docker pull quay.io/app-sre/mk-ci-tools:latest

if [ ${SKIP_BUILD} == false  ] ;  then
  stage "1. Executing managed-kafka build script..."
  docker run -v `pwd`/build_config.yaml:/opt/tools/scripts/build_config.yaml \
             -w /opt/tools/scripts \
             -e BUILD_CONFIG_FILE=/opt/tools/scripts/build_config.yaml \
             -e CPAAS_BUILD=${CPAAS_BUILD} \
             -e CPAAS_PIPELINE=${CPAAS_PIPELINE} \
             -e TEMP_CPAAS_BUILD=${TEMP_CPAAS_BUILD} \
             -e CPAAS_JENKINS_USERNAME="${CPAAS_JENKINS_USERNAME}" \
             -e CPAAS_JENKINS_APIKEY="${CPAAS_JENKINS_APIKEY}" \
             -u `id -u` \
             quay.io/app-sre/mk-ci-tools:latest python3 -u mk-build-cpaas.py
  check_exit_code $? "Build"

  stage "2. Mirroring images to quay.io..."
  # has to run outside of container due to docker calls
  curl -Lo commons.py https://gitlab.cee.redhat.com/mk-ci-cd/mk-ci-tools/-/raw/master/script/commons.py
  mirror_script_name=mk-mirror-images.py
  mirror_script=https://gitlab.cee.redhat.com/mk-ci-cd/mk-ci-tools/-/raw/master/script/${mirror_script_name}
  curl -Lo ${mirror_script_name} ${mirror_script}
  python3 -u ${mirror_script_name} --${MIRROR_FLAG} -u ${MK_CI_CD_QUAY_USER} -t ${MK_CI_CD_QUAY_TOKEN}

#  docker run --privileged -v `pwd`/build_config.yaml:/opt/tools/scripts/build_config.yaml \
#             -w /opt/tools/scripts \
#             -e WORKDIR=/opt/tools/scripts \
#             -e MK_CI_CD_QUAY_USER=${MK_CI_CD_QUAY_USER} \
#             -e MK_CI_CD_QUAY_TOKEN=${MK_CI_CD_QUAY_TOKEN} \
#             -u `id -u` \
#             quay.io/app-sre/mk-ci-tools:latest docker login & docker pull

  check_exit_code $? "Mirroring ${MIRROR_FLAG} images"
fi

stage "3. Executing tests..."
mkdir -p `pwd`/cluster
mkdir -p `pwd`/test-results
docker run -v `pwd`:/opt/strimzi-operator \
            -v `pwd`/cluster:/opt/cluster \
            -v `pwd`/test-results:/opt/test-results \
            -v `pwd`/build_config.yaml:/opt/build_config.yaml \
            -w /opt/tools/scripts \
            -e WORKDIR=/opt \
            -e HOME=/tmp \
            -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
            -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
            -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
            -e OCM_TOKEN=${OCM_TOKEN} \
            -e GOPATH=/tmp \
            -e TEST_STRATEGY=${TEST_STRATEGY} \
            -u `id -u` \
            quay.io/app-sre/mk-ci-tools:latest python3 -u mk-test-images.py
check_exit_code $? "Tests"

if [[ "${RELEASE}" == "true" ]];  then
  stage "4. Push release images..."
  # has to run outside of container due to docker calls
  curl -Lo commons.py https://gitlab.cee.redhat.com/mk-ci-cd/mk-ci-tools/-/raw/master/script/commons.py
  mirror_script_name=mk-mirror-images.py
  mirror_script=https://gitlab.cee.redhat.com/mk-ci-cd/mk-ci-tools/-/raw/master/script/${mirror_script_name}
  curl -Lo ${mirror_script_name} ${mirror_script}
  python3 -u ${mirror_script_name} --release -u ${MK_CI_CD_QUAY_USER} -t ${MK_CI_CD_QUAY_TOKEN}
  check_exit_code $? "Mirroring release images"
fi

if [[ "${CLUSTER_CLEANUP}" == "true" ]];  then
  stage "5. Cleaning..."
  ./build_cleanup.sh
  check_exit_code $? "Cleaning"
fi
