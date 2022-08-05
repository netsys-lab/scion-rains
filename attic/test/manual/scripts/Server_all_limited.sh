#!/usr/bin/env bash
set -x

Address= $(scion address)
systemd-run --scope -p CPUQuota=10% ./scripts/Server_all.sh scion $(Address)

