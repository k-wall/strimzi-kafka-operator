#!/usr/bin/env bash

set -e

export STRIMZI_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }')
echo "Deploying licenses ${STRIMZI_VERSION}"
echo ""

mvn license:aggregate-download-licenses license:aggregate-third-party-report -DlicensesOutputDirectory=licenses 
cp target/site/aggregate-third-party-report.html licenses
tar -z -cf strimzi-licenses-${STRIMZI_VERSION}.tar.gz -C ./licenses/ .  || [[ $? -eq 1 ]]
mvn deploy:deploy-file -Durl=${AProxDeployUrl} -DrepositoryId=indy-mvn -Dfile=strimzi-licenses-${STRIMZI_VERSION}.tar.gz -Dpackaging=tar.gz -DgroupId=io.strimzi -DartifactId=strimzi-licenses -Dversion=${STRIMZI_VERSION}

