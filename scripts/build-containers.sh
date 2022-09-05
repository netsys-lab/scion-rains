#!/usr/bin/env bash

set -euo pipefail

# find repo root
ROOT="$(git rev-parse --show-toplevel)"
BUILDDIR="${ROOT}/docker"
pushd "${BUILDDIR}"

set -e
echo "Building local containers for docker-compose setup"

echo "Building netsys-lab/scion-base..."
pushd scion-base
docker build --no-cache -t netsys-lab/scion-base .
echo "Built netsys-lab/scion-base."
popd

echo "Building netsys-lab/scion-control..."
pushd control
docker build -t netsys-lab/scion-control .
echo "Built netsys-lab/scion-control."
popd

echo "Building netsys-lab/scion-daemon..."
pushd daemon
docker build -t netsys-lab/scion-daemon .
echo "Built netsys-lab/scion-daemon."
popd

echo "Building netsys-lab/scion-router..."
pushd router
docker build -t netsys-lab/scion-router .
echo "Built netsys-lab/scion-router."
popd

echo "Building netsys-lab/scion-coredns..."
pushd scion-coredns
docker build -t netsys-lab/scion-coredns .
echo "Built netsys-lab/scion-coredns."
popd

echo "Building netsys-lab/scion-sdns..."
pushd scion-sdns
docker build -t netsys-lab/scion-sdns .
echo "Built netsys-lab/scion-sdns."
popd

echo "Building netsys-lab/topogen..."
pushd topogen
docker build -t netsys-lab/topogen .
echo "Built netsys-lab/topogen."
popd
popd
