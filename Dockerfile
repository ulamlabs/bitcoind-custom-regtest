# Build stage for Bitcoin Core
FROM alpine:latest as bitcoin-core

ENV BITCOIN_VERSION=25.0

RUN apk update && \
    apk add \
		autoconf \
		automake \
		bash \
		boost-dev \
		build-base \
		chrpath file \
		curl \
		gnupg \
		libevent-dev \
		libressl \
		libressl-dev \
		libtool \
		protobuf-dev \
		zeromq-dev \
		sqlite-dev

RUN wget https://github.com/bitcoin/bitcoin/archive/refs/tags/v${BITCOIN_VERSION}.tar.gz

RUN tar -xzf *.tar.gz \
    && cd bitcoin-${BITCOIN_VERSION} \
    && make -C depends/ NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_ZMQ=1 NO_UPNP=1 NO_USDT=1 \
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

RUN apk update && \
    apk add --no-cache\
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

