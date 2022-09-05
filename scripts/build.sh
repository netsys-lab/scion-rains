#!/usr/bin/env bash

set -euo pipefail

pushd cmd/keyManager
go build -v keyGen.go
go build -v certGen.go
go build -v certGenByCA.go
mkdir -p ../../bin
cp certGen certGenByCA keyGen ../../bin/
popd

pushd cmd/aggregator
go build -v .
cp aggregator ../../bin
popd

pushd cmd/log
go build -v .
cp log ../../bin
popd

pushd cmd/zoneManager
go build -v .
cp zoneManager ../../bin
popd

pushd cmd/ca
go build -v .
cp ca ../../bin
popd

CTDIR="certificate-transparency-go/trillian/ctfe/ct_server/"
if [ ! -d ${CTDIR} ]
then
    git clone https://github.com/google/certificate-transparency-go.git
else
    pushd certificate-transparency-go
    git pull
    popd
fi
pushd certificate-transparency-go/trillian/ctfe/ct_server/
go build -v .
cp ct_server ../../../../bin/
popd

pushd bin
go build -v github.com/google/trillian/cmd/createtree/
popd
