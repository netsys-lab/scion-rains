#!/usr/bin/env bash
#
#
set -euo pipefail

function key2pub { echo "$(dirname ${1})/$(basename -s '.pem' ${1})_pub.pem"; }

OUTDIR="./test" # TODO, change to $1 or something

CERTDIR="${OUTDIR}/certificates"
mkdir -p ${CERTDIR}

CADIR="${OUTDIR}/ca"
mkdir -pv ${CADIR}
CAKEY="${CADIR}/ROOT_private.pem"
CAPUBKEY=$(key2pub ${CAKEY})
bin/keyGen Ed25519 ${CAKEY} --pubkey | tail -n 1
mv -v "${CAPUBKEY}" "${CADIR}/ROOT_public.pem"
CACERT="${CERTDIR}/ROOT_cert.pem"
bin/certGen Ed25519 ${CAKEY} ${CACERT} | tail -n 1

PARENT="scion"
PARENTDIR="${OUTDIR}/${PARENT}"
mkdir -pv ${PARENTDIR}

PARENTKEY="${CERTDIR}/${PARENT}_private.pem"
PARENTCERT="${CERTDIR}/${PARENT}_cert.pem"
bin/keyGen Ed25519 ${PARENTKEY} | tail -n 1
bin/certGenByCA Ed25519 ${PARENTKEY} ${CAKEY} ${CACERT} ${PARENTCERT} ${PARENT} | tail -n 1

CHILDREN="eleven.${PARENT} twelve.${PARENT} thirteen.${PARENT} fourteen.${PARENT} fifteen.${PARENT}"

AGGDIR="${OUTDIR}/aggregator"
mkdir -pv ${AGGDIR}
AGGKEY="${AGGDIR}/Aggregator.pem"
AGGPUB=$(key2pub ${AGGKEY})
bin/keyGen Ed25519 ${AGGKEY} --pubkey | tail -n 1

LOGGDIR="${OUTDIR}/logger"
mkdir -pv ${LOGGDIR}
LOGGKEY="${LOGGDIR}/Logger1.pem"
LOGGPUB=$(key2pub ${LOGGKEY})
DER=$(bin/keyGen RSA ${LOGGKEY} --pubkey | grep DER | grep -Eo "[^ ]*$") 
LOGSERVER="localhost:8090"

TREE_ID=$(bin/createtree --admin_server=${LOGSERVER})

CTDIR="${OUTDIR}/ct"
mkdir -pv ${CTDIR}
CTCONF="${CTDIR}/ct.conf"
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
CTSERVER="localhost:6966"

ROOTS="${OUTDIR}/roots"
DBDIR="${OUTDIR}/database"
mkdir -pv ${ROOTS} "${DBDIR}/aggregator" "${DBDIR}/logger" "${DBDIR}/zoneManager"
AGGCONF="${AGGDIR}/aggregator.json"
cat > ${AGGCONF} << EOF
{
      "PrivateKeyAlgorithm" : "Ed25519",
      "PrivateKeyPath"      : "${AGGKEY}",
      "ServerAddress"       : "localhost:50050",
      "RootCertsPath"       : "${CERTDIR}/",

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
    "RootCertsPath"       : "${CERTDIR}/",
    
    "LogsName"            : ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName"      : ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"],
    
    "CAName"              : "localhost:10000",
    "CAServerAddr"        : "localhost:10000",
    "CAPubKeyPath"        : "${CAPUBKEY}",
    
    "CTAddress"           : "${CTSERVER}",
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
    "RootCertsPath"       : "${CERTDIR}/",
    
    "LogsName"            : ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName"      : ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"]
}
EOF

CHILDDIR="${PARENTDIR}/children"
PARENTCONF="${PARENTDIR}/parent.json"
cat > ${PARENTCONF} <<EOF
{
    "PrivateKeyAlgorithm": "Ed25519",
    "PrivateKeyPath": "${PARENTKEY}",
    "ZoneName":  "${PARENT}",
    "CertificatePath": "${PARENTCERT}",
    "ServerAddress" : "localhost:10005",
    
    "LogsName" :       ["localhost:50016"],
    "LogsPubKeyPaths" :    ["${LOGGPUB}"],
    
    "AggregatorName" :  ["localhost:50050"],
    "AggPubKeyPaths"  : ["${AGGPUB}"],
    
    "CAName" : "localhost:10000",
    "CAServerAddr" : "localhost:10000",
    "CACertificatePath" : "${CACERT}",
    
    "ChildrenKeyDirectoryPath" : "${CHILDDIR}",
    "ParentDataBaseDirectory" : "${DBDIR}/zoneManager"
}
EOF



echo "Launching CT Server"
bin/ct_server -log_config=${CTCONF} -log_rpc_server=${LOGSERVER} -http_endpoint=${CTSERVER} -logtostderr &
CTPID=$!
sleep 3
echo "Creating a DT data structure"
echo bin/aggregator AddTestDT --config=${AGGCONF} --parent=${PARENT} --certPath=${PARENTCERT}
bin/aggregator AddTestDT --config=${AGGCONF} --parent=${PARENT} --certPath=${PARENTCERT}
sleep 3
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
echo "Launching parent zone Manager"
bin/zoneManager RunParentServer --config=${PARENTCONF} &
PZPID=$!
sleep 3

for CHILD in ${CHILDREN}
do
    CHILDCERTDIR="${CHILDDIR}/certs"
    mkdir -pv ${CHILDCERTDIR}
    CHILDKEY="${CHILDDIR}/${CHILD}_private.pem"
    bin/keyGen Ed25519 ${CHILDKEY} | tail -n 1

    CHILDCONF="${CHILDDIR}/${CHILD}.json"
    cat > ${CHILDCONF} <<EOF
{
    "PrivateKeyAlgorithm": "Ed25519",
    "PrivateKeyPath": "${CHILDKEY}",
    "ParentServerAddr": "localhost:10005",
    "ZoneName":  "${CHILD}",
    
    "LogsName" :       ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName" :  ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"],
    
    "CAName" : "localhost:10000",
    "CAServerAddr" : "localhost:10000",
    "CACertificatePath" : "${CACERT}"
}

EOF

    echo "Running delegation Request for ${CHILD}"
    bin/zoneManager RequestDeleg --config=${CHILDCONF} --zone=${CHILD} --output="${CERTDIR}/${CHILD}_cert.pem"
done

sleep 3&
CZPID=$!

if ! wait -n $CTPID $AGGPID $LOGGPID $CAPID $PZPID $CZPID
then
    echo "ERROR: a backpround process died"
else
    echo "SETUP COMPLETE"
fi
kill $CTPID $AGGPID $LOGGPID $CAPID $PZPID $CZPID

