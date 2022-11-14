# Build stage for BerkeleyDB
FROM alpine:latest as berkeleydb

RUN apk update

RUN apk add \
	autoconf \
	automake \
	build-base

ENV BERKELEYDB_VERSION=db-4.8.30.NC
RUN wget https://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz

RUN tar -xzf *.tar.gz \
    && sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i ${BERKELEYDB_VERSION}/dbinc/atomic.h \
    && mkdir -p /opt/db \
    && cd /${BERKELEYDB_VERSION}/build_unix \
    && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=/opt/db \
    && make -j7 \
    && make install \
    && rm -rf /opt/db/docs

# Build stage for Bitcoin Core
FROM alpine:latest as bitcoin-core

COPY --from=berkeleydb /opt /opt

RUN apk update

RUN apk add \
		autoconf \
		automake \
		boost-dev \
		build-base \
		chrpath file \
		gnupg \
		libevent-dev \
		libressl \
		libressl-dev \
		libtool \
		protobuf-dev \
		zeromq-dev \
		sqlite-dev

ENV BITCOIN_VERSION=23.0
RUN wget https://github.com/bitcoin/bitcoin/archive/refs/tags/v${BITCOIN_VERSION}.tar.gz

RUN tar -xzf *.tar.gz \
    && cd bitcoin-${BITCOIN_VERSION} \
    && sed -i 's/consensus.nSubsidyHalvingInterval = 150/consensus.nSubsidyHalvingInterval = 210000/g' src/chainparams.cpp \
    && ./autogen.sh \
    && ./configure LDFLAGS=-L`ls -d /opt/db`/lib/ CPPFLAGS=-I`ls -d /opt/db`/include/ \
    --prefix=/opt/bitcoin \
    --disable-man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --enable-util-cli \
    --with-daemon \
	--with-sqlite=yes\
    && make -j7 \
    && make install \
    && strip /opt/bitcoin/bin/bitcoin-cli \
    && strip /opt/bitcoin/bin/bitcoind

# Build stage for compiled artifacts
FROM alpine:latest

RUN apk update

RUN apk add --no-cache\
		boost \
		bash \
		libevent \
		libzmq \
		libressl

ENV PATH=/opt/bitcoin/bin:$PATH

COPY --from=bitcoin-core /opt /opt

ADD *.sh /
ADD bitcoin.conf /root/.bitcoin/
VOLUME ["/root/.bitcoin/regtest"]

EXPOSE 19000 19001 28332
ENTRYPOINT ["/entrypoint.sh"]

