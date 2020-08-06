#!/bin/bash

USER="admin@kayako.com"
PASS="setup"

if [ $# -lt 1 -o $# -gt 2 ]; then
		echo "Usage: `basename $0` {USER_ID | FROM_ID TO_ID}"
		exit 1
fi

if [ $# -eq 1 ]; then
		curl -u $USER:$PASS \
				-X DELETE \
				-k "https://brewfictus.kayako.com/api/v1/users/$1.json"
else
		curl -u $USER:$PASS \
				-X DELETE \
				-k "https://brewfictus.kayako.com/api/v1/users.json?ids=`seq $1 $2|tr "\n" ","|sed 's/,$//'`"
fi
