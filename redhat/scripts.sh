####################
# Build ZIPs with container image scripts and deploy them
####################

export STRIMZI_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:3.1.1:evaluate -Dexpression=project.version | sed -n -e '/^\[.*\]/ !{ /^[0-9]/ { p; q } }')
echo "Deploying container scripts ${STRIMZI_VERSION}"
echo ""

# Operator scripts
mkdir operator-scripts/
cp -rv docker-images/operator/scripts/* operator-scripts/

pushd operator-scripts
zip -r ../strimzi-operator-scripts-${STRIMZI_VERSION}.zip *
popd

mvn deploy:deploy-file -Durl=${AProxDeployUrl} -DrepositoryId=indy-mvn -Dfile=strimzi-operator-scripts-${STRIMZI_VERSION}.zip -Dpackaging=zip -DgroupId=io.strimzi -DartifactId=strimzi-operator-scripts -Dversion=${STRIMZI_VERSION}

# Kafka scripts
mkdir kafka-scripts/

# Kafka Broker
mkdir kafka-scripts/kafka/
cp -rv docker-images/kafka/scripts/* kafka-scripts/kafka/

# Kafka S2I
mkdir kafka-scripts/kafka/s2i/
cp -rv docker-images/kafka/s2i-scripts/* kafka-scripts/kafka/s2i/

# Stunnel
mkdir kafka-scripts/stunnel/
cp -rv docker-images/kafka/stunnel-scripts/* kafka-scripts/stunnel/

# Kafka Exporter
mkdir kafka-scripts/kafka-exporter/
cp -rv docker-images/kafka/exporter-scripts/* kafka-scripts/kafka-exporter/

# Cruise Control
mkdir kafka-scripts/cruise-control/
cp -rv docker-images/kafka/cruise-control-scripts/* kafka-scripts/cruise-control/

pushd kafka-scripts
zip -r ../strimzi-kafka-scripts-${STRIMZI_VERSION}.zip *
popd

mvn deploy:deploy-file -Durl=${AProxDeployUrl} -DrepositoryId=indy-mvn -Dfile=strimzi-kafka-scripts-${STRIMZI_VERSION}.zip -Dpackaging=zip -DgroupId=io.strimzi -DartifactId=strimzi-kafka-scripts -Dversion=${STRIMZI_VERSION}
