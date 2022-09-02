#!/usr/bin/env bash
set -euxo pipefail

/usr/bin/env bash --version | grep -E "version [456789]" || echo "need at least bash version 4" 

OUTDIR="./test" # TODO, change to $1 or something

DATADIR="${OUTDIR}/data"
mkdir -p ${DATADIR}

CONFDIR="${OUTDIR}/configs"
mkdir -p ${CONFDIR}


function key2pub { echo "$(dirname ${1})/$(basename -s '.pem' ${1})_pub.pem"; }

function corefiles {
    DIR=$1
    ZONE=$2
    BIN=$(realpath bin/coredns-keygen)
    pushd "${DIR}"
    SIGNINGK=$(${BIN} "${ZONE}")
    cat > Coresign <<EOF
${ZONE}.:0 {
    root .
    sign zonefile ${ZONE}. {
        rcert file ${ZONE}
        key file ${SIGNINGK}
        directory .
    }
}
EOF
    cat > Corefile <<EOF
scion://${ZONE}.:53 {
    root /share/conf
    rhine db.${ZONE}.signed ${ZONE}. {
        scion on
    }
    log
}
EOF
    popd
}

function confdir {
    DIR=${CONFDIR}/${1}
    mkdir -p "${DIR}"
    echo "${DIR}"
}

function datadir {
    DIR=${DATADIR}/${1}
    mkdir -p "${DIR}"
    echo "${DIR}"
}

CADIR=$(confdir "ROOT")
CADATA=$(datadir "ROOT")
CAKEY="${CADATA}/ROOT_private.pem"
CAPUBKEY=$(key2pub ${CAKEY})
bin/keyGen Ed25519 ${CAKEY} --pubkey | tail -n 1
mv -v "${CAPUBKEY}" "${CADATA}/ROOT_public.pem"
CAPUBKEY="${CADATA}/ROOT_public.pem"
CACERT="${CADATA}/ROOT_cert.pem"
bin/certGen Ed25519 ${CAKEY} ${CACERT} | tail -n 1

PARENT="scion"
PARENTDIR=$(confdir ${PARENT})
PARENTDATA=$(datadir ${PARENT})
PARENTKEY="${PARENTDATA}/${PARENT}_private.pem"
PARENTCERT="${PARENTDATA}/${PARENT}_cert.pem"
bin/keyGen Ed25519 ${PARENTKEY} | tail -n 1
bin/certGenByCA Ed25519 ${PARENTKEY} ${CAKEY} ${CACERT} ${PARENTCERT} ${PARENT} | tail -n 1
corefiles ${PARENTDATA} ${PARENT}

CHILDREN="eleven.${PARENT} twelve.${PARENT} thirteen.${PARENT} fourteen.${PARENT} fifteen.${PARENT}"

AGGDIR=$(confdir "aggregator")
AGGKEY="${AGGDIR}/Aggregator.pem"
AGGPUB=$(key2pub ${AGGKEY})
bin/keyGen Ed25519 ${AGGKEY} --pubkey | tail -n 1

LOGGDIR=$(confdir "logger")
LOGGKEY="${LOGGDIR}/Logger1.pem"
LOGGPUB=$(key2pub ${LOGGKEY})
DER=$(bin/keyGen RSA ${LOGGKEY} --pubkey | grep DER | grep -Eo "[^ ]*$") 

LOGSERVER="localhost:8090"
TREE_ID=$(bin/createtree --admin_server=${LOGSERVER})

CTDIR=$(confdir "ct")
CTCONF="${CTDIR}/config"
cat > ${CTCONF} <<EOF
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

DBDIR=$(confdir "database")
mkdir -pv "${DBDIR}/aggregator" "${DBDIR}/logger" "${DBDIR}/zoneManager"
AGGCONF="${AGGDIR}/aggregator.json"
cat > ${AGGCONF} << EOF
{
      "PrivateKeyAlgorithm" : "Ed25519",
      "PrivateKeyPath"      : "${AGGKEY}",
      "ServerAddress"       : "localhost:50050",
      "RootCertsPath"       : "${CADATA}/",

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
    "RootCertsPath"       : "${CADATA}/",
    
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
    "RootCertsPath"       : "${CADATA}/",
    
    "LogsName"            : ["localhost:50016"],
    "LogsPubKeyPaths"     : ["${LOGGPUB}"],
    
    "AggregatorName"      : ["localhost:50050"],
    "AggPubKeyPaths"      : ["${AGGPUB}"]
}
EOF

CHILDRENDATA=$(datadir "children")
PARENTCONF="${PARENTDIR}/parent.json"
cat > ${PARENTCONF} <<EOF
{
    "PrivateKeyAlgorithm"      : "Ed25519",
    "PrivateKeyPath"           : "${PARENTKEY}",
    "ZoneName"                 : "${PARENT}",
    "CertificatePath"          : "${PARENTCERT}",
    "ServerAddress"            : "localhost:10005",
    
    "LogsName"                 : ["localhost:50016"],
    "LogsPubKeyPaths"          : ["${LOGGPUB}"],
    
    "AggregatorName"           : ["localhost:50050"],
    "AggPubKeyPaths"           : ["${AGGPUB}"],
    
    "CAName"                   : "localhost:10000",
    "CAServerAddr"             : "localhost:10000",
    "CACertificatePath"        : "${CACERT}",
    
    "ChildrenKeyDirectoryPath" : "${CHILDRENDATA}",
    "ParentDataBaseDirectory"  : "${DBDIR}/zoneManager"
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
    CHILDDIR=$(confdir ${CHILD})
    CHILDDATA=$(datadir ${CHILD})
    CHILDKEY="${CHILDDATA}/${CHILD}_private.pem"
    bin/keyGen Ed25519 ${CHILDKEY} --pubkey | tail -n 1
    mv -v "$(key2pub ${CHILDKEY})" "${CHILDRENDATA}/${CHILD}_pub.pem"
    
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
    
    bin/zoneManager RequestDeleg --config=${CHILDCONF} --zone=${CHILD} --output="${CHILDDATA}/${CHILD}_cert.pem"
    
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

