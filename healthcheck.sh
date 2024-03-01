#!/bin/bash

RESULT=`curl -s --fail --user "test:test" --data-binary '{"jsonrpc": "1.0", "id": "curltest", "method": "uptime", "params": []}' -H 'content-type: text/plain;' http://127.0.0.1:19001/`

if [ $? -eq 0 ]
then
  #echo "The script ran ok"
  ANSWER=`echo "$RESULT" | jq .result`
  if [ "$ANSWER" -gt "1" ]
  then
    #echo "Healthy"
    exit 0
  else
    #echo "Unhealthy"
    exit 1
  fi
else
  #echo "The script failed" >&2
  exit 1
fi

