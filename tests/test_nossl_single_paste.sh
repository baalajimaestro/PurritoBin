#!/bin/sh

. ./common.sh
. ./common_functions.sh

set -e

P_RACING=1
${PURRITO} -d "${P_TMPDIR}/" -s "${P_TMPDIR}" -z "${P_TMPDBDIR}" -i 127.0.0.1 -p "${P_PORT}" &
P_ID=$!
P_RACING=

# should be enough
sleep 2

P_DATA="SOME_RANDOM_TEST_DATA"

P_PASTE=$(printf %s\\n "${P_DATA}" | purr)

# P_PASTE is not set or empty
# OR
# P_PASTE is not a file
if [ -z "${P_PASTE}" ] || [ ! -f "${P_PASTE}" ]; then
    exit 1
fi

printf %s\\n "${P_DATA}" | diff "${P_PASTE}" -

set +e
pinfo "${0}: success"
