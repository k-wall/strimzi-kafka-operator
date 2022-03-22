#!/usr/bin/env bash

set -e

export STRIMZI_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }')
echo "Deploying resources ${STRIMZI_VERSION}"
echo ""

make -C packaging/install release RELEASE_VERSION=${STRIMZI_VERSION}
tar -z -cf strimzi-resources-${STRIMZI_VERSION}.tar.gz -C ./strimzi-${STRIMZI_VERSION}/install/ .  || [[ $? -eq 1 ]]
mvn deploy:deploy-file -Durl=${AProxDeployUrl} -DrepositoryId=indy-mvn -Dfile=strimzi-resources-${STRIMZI_VERSION}.tar.gz -Dpackaging=tar.gz -DgroupId=io.strimzi -DartifactId=strimzi-resources -Dversion=${STRIMZI_VERSION}
