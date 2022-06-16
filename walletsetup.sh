#!/bin/bash
# wait a while for the bitcoin node to bootstrap
sleep 10

bitcoin-cli -named createwallet wallet_name="blockpliance" descriptors=false load_on_startup=true

