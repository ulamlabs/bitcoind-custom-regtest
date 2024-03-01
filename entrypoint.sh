#!/bin/bash
#The depreceated rpc options is necessary in v26 until you can make a wallet
#with the createwallet RPC call with sqlite
exec bitcoind -deprecatedrpc=create_bdb
