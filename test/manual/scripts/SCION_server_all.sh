#!/usr/bin/env bash
set -eumo pipefail

if test -z ${1:-}
then
    echo
    cat <<EOF 
usage: ${0} SERVER_ADDRESS
       generates a collection of zone files and configurations to 
       test the RAINS components over SCION. The components are then 
       executed in the background and their output logged.

       SERVER_ADDRESS should be a valid SCION address of the current
       machine, where the RAINS components should listen on their
       respective ports (5022-5025).

       Example for a valid SERVER_ADDRESS: 17-ffaa:0:1107,[127.0.0.1]

       The server can then be tested by executing
       
        rdig -p 5025 @SERVER_ADDRESS DOMAIN.

       For example:

        rdig -p 5025 @17-ffaa:0:1107,[127.0.0.1] www.ethz.ch.

EOF
    exit 1
fi

SERVADDR="${1}"

BINDIR="../../build"
WAIT=5

LOGS=()

mkdir -p config

trap cleanup SIGINT EXIT

function cleanup() {
    echo "================================================================"
    rm -v ${LOGS[*]}
    echo "CLEANUP DONE"
    echo "================================================================"
}

function run_bg() {
    echo "================================================================"
    LOG=$(mktemp $(basename ${1})-XXXX.log)
    $@ >> $LOG &
    PID=$!
    sleep 1
    echo "Sleeping for ${WAIT} seconds before checking if command is still alive"
    sleep ${WAIT}
    if ! ps -p $PID > /dev/null
    then
        echo "================================================================"
        echo "ERROR: Executing \"$@\" failed! PID $PID no longer running! Log:"
        echo "================================================================"
        cat $LOG
        echo "================================================================"
        echo "ABORTING"
        rm -v $LOG
        exit 1
    else
        LOGS+=($LOG)
        echo "================================================================"
    fi
}




function gen_ns_config() {
    if test -z ${3:-}
    then
        INTERVAL=1
        AUTHORITIES=""
        PUBLISHER=""
    else
        INTERVAL=3600
        AUTHORITIES=`cat <<EOF

                                        {
                                            "Zone": "${3}",
                                            "Context": "."
                                        }

EOF`
        PUBLISHER=`cat <<EOF
    "PublisherAddress":             {
                                        "Type":     "SCION",
                                        "SCIONAddr": "${2}"
                                    },
EOF`
    fi
    
    cat > config/SCION_ns_${1}.conf <<EOF
{
    "RootZonePublicKeyPath":        "./config/selfSignedRootDelegationAssertion.gob",
    "AssertionCheckPointInterval": ${INTERVAL},
	"NegAssertionCheckPointInterval":${INTERVAL},
	"ZoneKeyCheckPointInterval":${INTERVAL},
	"CheckPointPath": "./checkpoint/${1}/",
	"PreLoadCaches": false,
    "ServerAddress":                {
                                        "Type":     "SCION",
                                        "SCIONAddr": "${2}"
                                    },
${PUBLISHER}
    "MaxConnections":               1000,
    "KeepAlivePeriod":              60,
    "TCPTimeout":                   300,
    "TLSCertificateFile":           "./tls_cert/server.crt",
    "TLSPrivateKeyFile":            "./tls_cert/server.key",

    "PrioBufferSize":               20,
    "NormalBufferSize":             100,
    "NotificationBufferSize":       10,
    "PrioWorkerCount":              2,
    "NormalWorkerCount":            10,
    "NotificationWorkerCount":      2,
    "CapabilitiesCacheSize":        50,
    "Capabilities":                 ["urn:x-rains:tlssrv"],

    "ZoneKeyCacheSize":             1000,
    "ZoneKeyCacheWarnSize":         750,
    "MaxPublicKeysPerZone":         5,
    "PendingKeyCacheSize":          1000,
    "DelegationQueryValidity":      5,
    "ReapZoneKeyCacheInterval":      1800,
    "ReapPendingKeyCacheInterval":   1800,

    "AssertionCacheSize":           10000,
    "NegativeAssertionCacheSize":   1000,
    "PendingQueryCacheSize":        100,
    "QueryValidity":                5,
    "Authorities":                  [${AUTHORITIES}],
    "MaxCacheValidity":             {
                                        "AssertionValidity": 720,
                                        "ShardValidity": 720,
                                        "PshardValidity": 720,
                                        "ZoneValidity": 720
                                    },
    "ReapAssertionCacheInterval":    1800,
    "ReapNegAssertionCacheInterval": 1800,
    "ReapPendingQCacheInterval":     1800
}
EOF
}

function gen_pub_config() {
    cat > config/SCION_pub_$1.conf <<EOF
{
    "ZonefilePath": "${3}",
	"AuthServers": [{
						"Type":     "SCION",
						"SCIONAddr": "${2}"
					}],
	"PrivateKeyPath": "./keys/${1}",
	"ShardingConf" : {
		"KeepShards": false,
		"DoSharding": ${4},
		"MaxShardSize": 1000,
		"NofAssertionsPerShard": -1
	},
	"PShardingConf" : {
		"KeepPshards": false,
		"DoPsharding" : ${4},
		"NofAssertionsPerPshard" : 2,
		"BloomFilterConf" : {
			"BFAlgo" : "BloomKM12",
			"BFHash" : "Shake256",
			"BloomFilterSize" : 80
		}
	},
	"MetaDataConf" : {
		"AddSignatureMetaData": true,
		"AddSigMetaDataToAssertions": true,
		"AddSigMetaDataToShards": true,
		"AddSigMetaDataToPshards": true,
		"SignatureAlgorithm": "Ed25519",
		"KeyPhase": 1,
		"SigValidSince": 1543840931,
		"SigValidUntil": 2301221742,
		"SigSigningInterval": 60
	},
	"ConsistencyConf" : {
		"DoConsistencyCheck": false,
		"SortShards": true,
		"SortZone": true,
		"SigNotExpired": false,
		"CheckStringFields": false
	},
	"DoSigning": true,
	"MaxZoneSize": 50000,
	"OutputPath": "",
	"DoPublish": true
}
EOF
}

function zonefile() {
    echo "./config/SCION_${1}_zone.txt"
}

function gen_configs() {
    ZONE="root"
    ZONEFILE=$(zonefile ${ZONE})
    ADDR="${SERVADDR}:5022"
    gen_ns_config $ZONE $ADDR "."
    gen_pub_config $ZONE $ADDR $ZONEFILE "true"
    cat > ${ZONEFILE} <<EOF
:Z: . . [
    :A: ch [ :redir:   _rains._udpscion.ns.ch. ]
    :A: ch [ :deleg:   :ed25519: 1 06c6d21fa1f2047581e8dcf2b014a9a001cd00c58de592c57cc86b2be641a220 ]
    :A: _rains._udpscion.ns.ch [ :srv:     ns1.ch. 5023 0 ]
    :A: ns1.ch [ :scion:     ${SERVADDR} ]
]
EOF

    ZONE="ch"
    ZONEFILE=$(zonefile ${ZONE})
    ADDR="${SERVADDR}:5023"
    gen_ns_config $ZONE $ADDR "ch."
    gen_pub_config $ZONE $ADDR $ZONEFILE "true"

    cat > ${ZONEFILE} <<EOF
:Z: ch. . [
    :A: ethz [ :redir:   _rains._udpscion.ns.ethz.ch. ]
    :A: ethz [ :deleg:   :ed25519: 1 e399545d248fb3ece0cd822ee3b6222df06fd278308923d9bebef997c9a1afa9 ]
    :A: _rains._udpscion.ns.ethz [ :srv:     ns1.ethz.ch. 5024 0 ]
    :A: ns1.ethz [ :scion:     ${SERVADDR} ]
]
EOF

    ZONE="ethz.ch"
    ZONEFILE=$(zonefile ${ZONE})
    ADDR="${SERVADDR}:5024"
    gen_ns_config $ZONE $ADDR "ethz.ch."
    gen_pub_config $ZONE $ADDR $ZONEFILE "false"
    cat > ${ZONEFILE} <<EOF
:Z: ethz.ch. . [
    :A: www  [ :name: a [ :scion: ] ]
    :A: www  [ :scion: 2-ff00:0:222,[198.175.162.241] ]
    :A: www  [ :cert: :tls: :endEntity: :sha256: e28b1bd3a73882b198dfe4f0fa954c ]
    :A: _ftp._udpscion  [ :srv: ftp.ethz.ch. 20 0 ]
]
EOF

    ZONE="resolver"
    ADDR="${SERVADDR}:5025"
    gen_ns_config $ZONE $ADDR
}

echo "================================================================"
echo "==================== STARTUP IN PROGRESS ======================="
echo "================================================================"
echo "Generating configs"
gen_configs
echo "================================================================"
echo "Generating self-signed Root Delegation Assertion"
${BINDIR}/keymanager selfsign ./keys/root/root -s ./config/selfSignedRootDelegationAssertion.gob
echo "================================================================"
echo "starting root Zone server..."
#run_bg ${BINDIR}/rainsd ./conf/SCIONnamingServerRoot.conf --id SCIONnameServerRoot
run_bg ${BINDIR}/rainsd ./config/SCION_ns_root.conf --id SCIONnameServerRoot
echo "starting CH Zone server..."
run_bg ${BINDIR}/rainsd ./config/SCION_ns_ch.conf --rootServerAddress ${SERVADDR}:5022 --id SCIONnameServerch
echo "starting ETHZ Zone server..."
run_bg ${BINDIR}/rainsd ./config/SCION_ns_ethz.ch.conf --rootServerAddress ${SERVADDR}:5022 --id SCIONnameServerethz.ch
echo "Launching publishers"
${BINDIR}/publisher ./config/SCION_pub_root.conf
${BINDIR}/publisher ./config/SCION_pub_ch.conf
${BINDIR}/publisher ./config/SCION_pub_ethz.ch.conf
echo "(some timeout warnings may be safely ignored)"
echo "================================================================"
echo "Launching Resolver"
run_bg ${BINDIR}/rainsd ./config/SCION_ns_resolver.conf --rootServerAddress ${SERVADDR}:5022 --id SCIONresolver
echo "Log messages so far"
tail ${LOGS[*]}
cat <<EOF
================================================================
====================== STARTUP COMPLETE ========================
================================================================
Everything should now be up and running, terminate with Ctrl+C
Try executing:

  ${BINDIR}/rdig -p 5025 @${SERVADDR} www.ethz.ch.

Server log messages will appear below:
================================================================
EOF
tail -n0 -f ${LOGS[*]}
