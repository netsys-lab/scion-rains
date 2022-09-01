#!/usr/bin/env bash
#
#

set -euo pipefail

function key2pub { echo "$(dirname ${1})/$(basename -s '.pem' ${1})_pub.pem"; }

mkdir -p test/ca
CAKEY="./test/ca/CAKey.pem"
CAPUBKEY=$(key2pub ${CAKEY})
bin/keyGen Ed25519 ${CAKEY} --pubkey
CACERT="./test/ca/CACert.pem"
bin/certGen Ed25519 ${CAKEY} ${CACERT}

mkdir -p test/aggregator
AGG1="./test/aggregator/Aggregator1.pem"
AGG1PUB=$(key2pub ${AGG1})
bin/keyGen Ed25519 ${AGG1} --pubkey

mkdir -p test/logger
LOGG="./test/logger/Logger1.pem"
LOGGPUB=$(key2pub ${LOGG})
DER=$(bin/keyGen RSA ${LOGG} --pubkey | grep DER | grep -Eo "[^ ]*$")

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
mkdir -p ${ROOTS} ${DBDIR}
AGGCONF="./test/Aggregator1.conf"
cat > ${AGGCONF} << EOF
{
      "PrivateKeyAlgorithm" : "Ed25519",
      "PrivateKeyPath"      : "${AGG1}",
      "ServerAddress"       : "localhost:50050",
      "RootCertsPath"       : "${ROOTS}",

      "LogsName"            : ["localhost:50016"],
      "LogsPubKeyPaths"     : ["${LOGGPUB}"],

      "AggregatorName"      : ["localhost:50050"],
      "AggPubKeyPaths"      : ["${AGGPUB}"],

      "CAName"              : "localhost:10000",
      "CAServerAddr"        : "localhost:10000",
      "CAPubKeyPath"        : "${CAPUBKEY}",

      "KeyValueDBDirectory" : "${DBDIR}"
}
EOF
