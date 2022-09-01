#!/usr/bin/env bash
#
#

set -euo pipefail

function key2pub { echo "$(dirname ${1})/$(basename -s '.pem' ${1})_pub.pem"; }

CADIR="./test/ca"
mkdir -pv ${CADIR}
CAKEY="${CADIR}/CAKey.pem"
CAPUBKEY=$(key2pub ${CAKEY})
bin/keyGen Ed25519 ${CAKEY} --pubkey | tail -n 1
CACERT="${CADIR}/CACert.pem"
bin/certGen Ed25519 ${CAKEY} ${CACERT} | tail -n 1

PARENT="parent"
PARENTDIR="./test/${PARENT}"
PARENTCERTDIR="${PARENTDIR}/certs"
mkdir -pv ${PARENTCERTDIR}
PARENTKEY="${PARENTDIR}/${PARENT}key.pem"
PARENTPUB=$(key2pub ${PARENTKEY})
PARENTCERT="${PARENTCERTDIR}/${PARENT}cert.pem"
bin/keyGen Ed25519 ${PARENTKEY} --pubkey | tail -n 1
bin/certGenByCA Ed25519 ${PARENTKEY} ${CAKEY} ${CACERT} ${PARENTCERT} ${PARENT} | tail -n 1

AGGDIR="./test/aggregator"
mkdir -pv ${AGGDIR}
AGGKEY="${AGGDIR}/Aggregator.pem"
AGGPUB=$(key2pub ${AGGKEY})
bin/keyGen Ed25519 ${AGGKEY} --pubkey | tail -n 1

LOGGDIR="./test/logger"
mkdir -pv ${LOGGDIR}
LOGGKEY="${LOGGDIR}/Logger1.pem"
LOGGPUB=$(key2pub ${LOGGKEY})
DER=$(bin/keyGen RSA ${LOGGKEY} --pubkey | grep DER | grep -Eo "[^ ]*$") 

TREE_ID=$(bin/createtree --admin_server=localhost:8090)

CTCONF="./test/CTConfig.conf"
cat > ${CTCONF} << EOF
config {
      log_id: ${TREE_ID}
      prefix: "RHINE"
      roots_pem_file: "${CACERT}"
      private_key: {
          [type.googleapis.com/keyspb.PrivateKey] {
              der: "${DER}"
          }
      }
      max_merge_delay_sec: 86400
      expected_merge_delay_sec: 120
}
EOF

ROOTS="./test/roots"
DBDIR="./test/database"
mkdir -pv ${ROOTS} "${DBDIR}/aggregator" "${DBDIR}/logger"
AGGCONF="${AGGDIR}/aggregator.json"
cat > ${AGGCONF} << EOF
{
      "PrivateKeyAlgorithm" : "Ed25519",
      "PrivateKeyPath"      : "${AGGKEY}",
      "ServerAddress"       : "localhost:50050",
      "RootCertsPath"       : "${PARENTCERTDIR}",

      "LogsName"            : ["localhost:50016"],
      "LogsPubKeyPaths"     : ["${LOGGPUB}"],

      "AggregatorName"      : ["localhost:50050"],
      "AggPubKeyPaths"      : ["${AGGPUB}"],

      "CAName"              : "localhost:10000",
      "CAServerAddr"        : "localhost:10000",
      "CAPubKeyPath"        : "${CAPUBKEY}",

      "KeyValueDBDirectory" : "${DBDIR}/aggregator"
}
EOF


LOGGCONF="${LOGGDIR}/logger.json"
cat > ${LOGGCONF} <<EOF
{
    "PrivateKeyAlgorithm" : "RSA",
    "PrivateKeyPath"      : "${LOGGKEY}",
    "ServerAddress"       : "localhost:50016",
    "RootCertsPath"       : "${PARENTCERTDIR}",
    
    "LogsName"            : ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName"      : ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"],
    
    "CAName"              : "localhost:10000",
    "CAServerAddr"        : "localhost:10000",
    "CAPubKeyPath"        : "${CAPUBKEY}",
    
    "CTAddress"           : "localhost:6966",
    "CTPrefix"            : "RHINE",
    
    "KeyValueDBDirectory" : "${DBDIR}/logger"
}
EOF

CACONF="${CADIR}/ca.json"
cat > ${CACONF} <<EOF
{
    "PrivateKeyAlgorithm" : "Ed25519",
    "PrivateKeyPath"      : "${CAKEY}",
    "CertificatePath"     : "${CACERT}",
    "ServerAddress"       : "localhost:10000",
    "RootCertsPath"       : "${PARENTCERTDIR}",
    
    "LogsName"            : ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName"      : ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"]
}
EOF

echo "Creating a DT data structure"
bin/aggregator AddTestDT --config=${AGGCONF} --parent=${PARENT} --certPath=${PARENTCERT}
echo "Launching Aggregator"
bin/aggregator --config=${AGGCONF} &
AGGPID=$!
sleep 3
echo "Launching Logger"
bin/log --config=${LOGGCONF} &
LOGGPID=$!
sleep 3
echo "Launching CA"
bin/ca --config=${CACONF} &
CAPID=$!
sleep 3
for PID in $AGGPID $LOGGPID $CAPID
do
    ps --no-headers -p ${PID} > /dev/null
done

cat <<EOF
SETUP COMPLETE
EOF


wait -n $AGGPID $LOGGPID $CAPID
kill $AGGPID $LOGGPID $CAPID

