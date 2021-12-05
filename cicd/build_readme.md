## Overview

Build job is triggered when MR to `mk-release` branch is merged. The job executes `./build_deploy.sh` which has the following steps:

1. CPaaS build
    - triggers new CPaaS build: 
    - when CPaaS build is successful `./build_config.yaml` file is updated:
        - `brew` keys are updated with references to the built images
2. Mirror images to Quay.io
    - if CPaaS build is successful, the built images (brew key) are used to create snapshot images in Quay.io
    - names of the snapshot images are defined in `./build_config.yaml` under `snapshot` key 
3. Run tests
    - uses `mk-ci-tools/script/mk-osd-provision.sh` to provision an OSD cluster for testing
        - cluster info of provisioned cluster can be found in `./cluster` folder
    - updates `./packaging/install/cluster-operator/060...yaml` file with `snapshot` image details
    - executes tests specified in `./build_test.sh`
4. Re-tag release images
    - if tests are successful, the snapshot images are then in Quay.io re-tagged with release tag
    - names of the release images (incl. tag) are defined in `./build_config.yaml` under `release` key 
    - `XXX` in prepared `release` image names are updated with generated tag suffixes `-yymmddHHMMSS`   
5. Clean-up
    - uses value of `./cluster/cluster-name` to delete an OSD cluster


## Parameters

#### Pipeline parameters:
- TEMP_CPAAS_BUILD (default: true)
    - if true, CPaaS will create only temporary images, i.e. not override existing builds in PNC
- SKIP_BUILD (default: false)
    - if true, skip steps 1 and 2 (CPaaS build and mirroring to Quay) and uses `snapshot` images defined in `build_config.yaml` for testing/releasing
- CPAAS_BUILD 
    - value: CPaaS build number
    - if set, skip step 1 and uses the existing CPaaS build to create `snapshot` images and continue with following steps
    - used to avoid triggering new CPaaS build
- RELEASE (default: false)
    - if false, skip step 4 (re-tagging release images)
- CLUSTER_CLEANUP (default: true)
    - if false, skip step 5 (cluster cleanup)

#### Parameters provided by App-SRE Jenkins secrets ([stored in Vault](https://vault.devshift.net/ui/vault/secrets/managed-services-ci/list)):
- CPAAS_JENKINS_USERNAME
- CPAAS_JENKINS_APIKEY
- MK_CI_CD_QUAY_USER
- MK_CI_CD_QUAY_TOKEN
- AWS_ACCOUNT_ID
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- OCM_TOKEN

## Troubleshooting (e.i. if pipeline fails)

- If CPaaS build fails (step 1), it could require more investigation/fixing CPaaS configs - once fixed, simply rerun the App-SRE pipeline
- In case mirroring snapshot images fails (step 2), rerun the pipeline with specified CPAAS_BUILD=<build_number> - pointing to successful CPaaS build
- An error while testing images (e.g. provisioning error) (step 3) you can try to rerun the pipeline with SKIP_BUILD=true - it will take snapshot images from quay and continue with the process
- Manual local testing with existing cluster:
    - `git clone <strimzi-operator_repo>` and checkout `mk-release` branch
    - `oc login...` to an existing cluster
    - Update [060 deployment file](https://gitlab.cee.redhat.com/mk-ci-cd/strimzi-operator/-/blob/mk-release/packaging/install/cluster-operator/060-Deployment-strimzi-cluster-operator.yaml) with snapshot images
    - Execute [test script](https://gitlab.cee.redhat.com/mk-ci-cd/strimzi-operator/-/blob/mk-release/build_test.sh)
- Automatic local testing - [command](https://gitlab.cee.redhat.com/mk-ci-cd/strimzi-operator/-/blob/mk-release/build_deploy.sh#L69-84) 
- Retagging with release tags locally - [command](https://gitlab.cee.redhat.com/mk-ci-cd/strimzi-operator/-/blob/mk-release/build_deploy.sh#L91-95)
- Command to provision an OSD cluster for testing:
    ```
    mkdir `pwd`/cluster
    docker run -v `pwd`/cluster:/opt/cluster \
                -w /opt/tools/scripts \
                -e WORKDIR=/opt \
                -e CLUSTER_NAME=${CLUSTER_NAME} \
                -e AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID} \
                -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
                -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
                -e OCM_TOKEN=${OCM_TOKEN} \
                -u `id -u` \
                quay.io/app-sre/mk-ci-tools:latest ./mk-osd-provision.sh
    ```
