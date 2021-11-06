# bitcoind-custom-regtest with Bloom filtering enabled

Forked from [ulamlabs/bitcoind-custom-regtest](https://github.com/ulamlabs/bitcoind-custom-regtest).

GitHub Repository is available at [mentiflectax/bitcoind-custom-regtest](https://github.com/mentiflectax/bitcoind-custom-regtest).

---

[![](https://images.microbadger.com/badges/version/ulamlabs/bitcoind-custom-regtest.svg)](https://microbadger.com/images/ulamlabs/bitcoind-custom-regtest "Get your own version badge on microbadger.com")

Patched version of Bitcoin regtest with halving interval increased to mainnet and testnet values. Halving occurs every 210000 blocks, instead of default 150.


## Building

```
docker build -t ulamlabs/bitcoind-custom-regtest:latest .
```

## Usage

```
docker run -p 19001:19001 -p 19000:19000 -p 28332:28332 ulamlabs/bitcoind-custom-regtest:latest
```

By default RPC is available on port 19001 with username `test` and password `test`. Image includes a mining script which generates a new block every minute. Bitcoin node has wallet feature enabled and coins are available to be spent using CLI as soon as they're matured (after 100 blocks).
