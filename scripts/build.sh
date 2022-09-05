#!/usr/bin/env bash

set -euo pipefail

# find repo root
ROOT="$(git rev-parse --show-toplevel)"
BUILDDIR="${ROOT}/build"
mkdir -p "${BUILDDIR}"

WORKDIR="${ROOT}/offlineauth/cmd"

# change to workdir
pushd "${WORKDIR}"

pushd keyManager
go build -v keyGen.go
go build -v certGen.go
go build -v certGenByCA.go
cp certGen certGenByCA keyGen "${BUILDDIR}"
popd

pushd aggregator
go build -v .
cp aggregator "${BUILDDIR}"
popd

pushd log
go build -v .
cp log "${BUILDDIR}"
popd

pushd zoneManager
go build -v .
cp zoneManager "${BUILDDIR}"
popd

pushd ca
go build -v .
cp ca "${BUILDDIR}"
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
cp ct_server "${BUILDDIR}"
popd

pushd "${BUILDDIR}"
go build -v github.com/google/trillian/cmd/createtree/
popd

popd
