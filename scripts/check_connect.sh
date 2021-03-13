#!/bin/bash
# Check internet connectivity.
# To be used in systemd scripts.

. /home/boret/sbin/script-funcs.sh

i=0; RC=1
while [[ $RC -ne 0 && $i -lt 100 ]]; do
        sleep 0.5
	(( i++ ))
        check_connect
        RC=$?
done
exit $RC
