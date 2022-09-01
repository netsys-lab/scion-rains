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

git clone https://github.com/google/certificate-transparency-go.git
pushd certificate-transparency-go/trillian/ctfe/ct_server/
go build -v .
cp ct_server ../../../../bin/
popd

pushd bin
go build -v github.com/google/trillian/cmd/createtree/
popd
