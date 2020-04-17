#!/bin/bash
# wait a while for the bitcoin node to bootstrap
sleep 10

# `generate` is deprecated in 0.18.0, we need to generate an address and
# use generatetoaddress
BTC_ADDRESS=`bitcoin-cli -regtest getnewaddress`
while true
do
    bitcoin-cli -regtest generatetoaddress 1 $BTC_ADDRESS || true
    sleep 60
done
