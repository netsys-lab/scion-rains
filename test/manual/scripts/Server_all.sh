#!/usr/bin/env bash
set -eumo pipefail

function usage() {
    echo
    cat <<EOF 
usage: ${0} scion|tcp SERVER_ADDRESS
       generates a collection of zone files and configurations to 
       test the RAINS components over SCION or TCP. The components are
       then executed in the background and their output logged.

       SERVER_ADDRESS should be a valid TCP or SCION address of the 
       current machine, where the RAINS components should listen on 
       their respective ports (5022-5025).

       Example for a valid SERVER_ADDRESS: 17-ffaa:0:1107,[127.0.0.1]

       The server can then be tested by executing
       
        rdig -p 5025 @SERVER_ADDRESS DOMAIN.

       For example:

        rdig -p 5025 @17-ffaa:0:1107,[127.0.0.1] www.ethz.ch.

EOF
}

if test -z ${1:-}
then
    usage
    echo "Error: need to specify either \"scion\" or \"tcp\" as protocol"
    exit 1
fi

if echo ${1} | grep -i "scion" > /dev/null
then
    PROTO="scion"
elif echo ${1} | grep -i "tcp" > /dev/null
then
    PROTO="tcp"
else
    usage
    echo "Error: need to either specify \"tcp\" or \"scion\""
    exit 1
fi
    

if test -z ${2:-}
then
    usage
    echo "Error: need to specify a SERVER_ADDRESS"
    exit 1
fi
SERVADDR="${2}"


function gen_server_addr() {
    if test ${PROTO} = "tcp"
    then
        cat <<EOF
{
        "Type":     "TCP",
        "TCPAddr":  {
                    "IP":   "${SERVADDR}",
                    "Port": ${1}
                    }
}
EOF
    else
        cat <<EOF
{
        "Type":     "SCION",
        "SCIONAddr": "${SERVADDR}:${1}"
}
EOF
    fi
}



BINDIR="../../build"
WAIT=5

LOGS=()
PIDS=()

mkdir -p config

trap cleanup SIGINT EXIT

function cleanup() {
    echo "================================================================"
    kill ${PIDS[*]}
    rm -v ${LOGS[*]}
    echo "CLEANUP DONE"
    echo "================================================================"
}

function run_bg() {
    echo "================================================================"
    LOG=$(mktemp $(basename ${1})-XXXX.log)
    # start process in background, ignore SIGHUP from stdin, log to $LOG
    nohup $@ < /dev/null >> $LOG 2>&1 &
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
        PIDS+=($PID)
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
    "PublisherAddress":             $(gen_server_addr ${2}),
EOF`
    fi
    
    cat > config/${PROTO}_ns_${1}.conf <<EOF
{
    "RootZonePublicKeyPath":        "./config/selfSignedRootDelegationAssertion.gob",
    "AssertionCheckPointInterval": ${INTERVAL},
	"NegAssertionCheckPointInterval":${INTERVAL},
	"ZoneKeyCheckPointInterval":${INTERVAL},
	"CheckPointPath": "./checkpoint/${1}/",
	"PreLoadCaches": false,
    "ServerAddress": $(gen_server_addr ${2}),
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
    cat > config/${PROTO}_pub_$1.conf <<EOF
{
    "ZonefilePath": "${3}",
	"AuthServers": [$(gen_server_addr ${2})],
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
    echo "./config/${PROTO}_${1}_zone.txt"
}

function gen_configs() {
    if test ${PROTO} = "tcp"
    then
        redir="_tcp"
        proto=":ip4:"
    else
        redir="_udpscion"
        proto=":scion:"
    fi

    
    ZONE="root"
    ZONEFILE=$(zonefile ${ZONE})
    gen_ns_config $ZONE 5022 "."
    gen_pub_config $ZONE 5022 $ZONEFILE "true"
    cat > ${ZONEFILE} <<EOF
:Z: . . [
    :A: ch [ :redir:   _rains.${redir}.ns.ch. ]
    :A: ch [ :deleg:   :ed25519: 1 06c6d21fa1f2047581e8dcf2b014a9a001cd00c58de592c57cc86b2be641a220 ]
    :A: _rains.${redir}.ns.ch [ :srv:     ns1.ch. 5023 0 ]
    :A: ns1.ch [ ${proto}     ${SERVADDR} ]
]
EOF

    ZONE="ch"
    ZONEFILE=$(zonefile ${ZONE})
    gen_ns_config $ZONE 5023 "ch."
    gen_pub_config $ZONE 5023 $ZONEFILE "true"

    cat > ${ZONEFILE} <<EOF
:Z: ch. . [
    :A: ethz [ :redir:   _rains.${redir}.ns.ethz.ch. ]
    :A: ethz [ :deleg:   :ed25519: 1 e399545d248fb3ece0cd822ee3b6222df06fd278308923d9bebef997c9a1afa9 ]
    :A: _rains.${redir}.ns.ethz [ :srv:     ns1.ethz.ch. 5024 0 ]
    :A: ns1.ethz [ ${proto}     ${SERVADDR} ]
]
EOF

    ZONE="ethz.ch"
    ZONEFILE=$(zonefile ${ZONE})
    gen_ns_config $ZONE 5024 "ethz.ch."
    gen_pub_config $ZONE 5024 $ZONEFILE "false"
    cat > ${ZONEFILE} <<EOF
:Z: ethz.ch. . [
    :A: www  [ :name: a [ :ip6: :ip4: :scion: ] ]
    :A: www  [ :ip6:      2001:0db8:85a3:0000:0000:8a2e:0370:7334 ]
    :A: www  [ :ip4:      198.175.162.241 ]
    :A: www  [ :scion: 2-ff00:0:222,[198.175.162.241] ]
    :A: www  [ :cert: :tls: :endEntity: :sha256: e28b1bd3a73882b198dfe4f0fa954c ]
    :A: _ftp.${redir}  [ :srv: ftp.ethz.ch. 20 0 ]
]
EOF

    ZONE="resolver"
    gen_ns_config $ZONE 5025
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
run_bg ${BINDIR}/rainsd ./config/${PROTO}_ns_root.conf --id "${PROTO}nameServerRoot"
echo "starting CH Zone server..."
run_bg ${BINDIR}/rainsd ./config/${PROTO}_ns_ch.conf --rootServerAddress ${SERVADDR}:5022 --id "${PROTO}NnameServerch"
echo "starting ETHZ Zone server..."
run_bg ${BINDIR}/rainsd ./config/${PROTO}_ns_ethz.ch.conf --rootServerAddress ${SERVADDR}:5022 --id "${PROTO}NnameServerethzch"
echo "Launching publishers"
${BINDIR}/publisher ./config/${PROTO}_pub_root.conf
${BINDIR}/publisher ./config/${PROTO}_pub_ch.conf
${BINDIR}/publisher ./config/${PROTO}_pub_ethz.ch.conf
echo "some timeout warnings may be safely ignored"
echo "================================================================"
echo "Launching Resolver"
run_bg ${BINDIR}/rainsd ./config/${PROTO}_ns_resolver.conf --rootServerAddress ${SERVADDR}:5022 --id "${PROTO}resolver"
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
