#!/bin/sh

. ./common.sh
. ./common_functions.sh

set -e

P_RACING=1
../purrito -d "${P_TMPDIR}/" -s "${P_TMPDIR}" -i 127.0.0.1 -p "${P_PORT}" -m $((${P_MAXSIZE} * 1024 * 1024)) &
P_ID=$!
P_RACING=

# should be enough
sleep 2

P_DATA_FILE="$(mktemp -p ${P_TMPDIR} )"
dd if=/dev/random of="${P_DATA_FILE}" bs=1M count=$((${P_MAXSIZE} + 1)) iflag=fullblock

set +e
P_PASTE=$(purr "${P_DATA_FILE}")
set -e

if [ ! -z "${P_PASTE}" ]; then
    exit 1
fi

set +e
pinfo "${0}: success"
