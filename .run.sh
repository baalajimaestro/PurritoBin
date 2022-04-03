#! /bin/sh

./purrito -d $DOMAIN_NAME -s /data -z /db -t -m 512000 -q 13219200 -x "Content-Type" -v "text/html; charset=UTF-8" -b 167772160 $@
