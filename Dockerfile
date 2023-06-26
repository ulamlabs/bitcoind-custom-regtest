# Build stage for Bitcoin Core
FROM alpine:latest as bitcoin-core

# Install build tools
RUN apk update && \
    apk add \
		autoconf \
		automake \
		bash \
		build-base \
		curl \
		git \
		pkgconfig \
		libtool 

## build utilities for depends on linux see bitcoin*/depends/README.md
RUN apk add \
		make \
		automake \
		cmake \
		libtool \
		binutils \
		pkgconfig \
		python3 \
		patch \
		bison

#Build bitcoin
ARG BITCOIN_BRANCH=25.x

RUN mkdir -p /opt/build

WORKDIR /opt

RUN git config --global http.postBuffer 524288000  

RUN git clone -v --single-branch --branch ${BITCOIN_BRANCH} https://github.com/bitcoin/bitcoin.git

## see other architecture options in bitcoin*/depends/README.md
ARG CONFIG_SITE=/opt/bitcoin/depends/x86_64-pc-linux-musl/share/config.site

WORKDIR /opt/bitcoin

RUN cd depends \
    && make -j \
	   #NO_BOOST=0 \
	   #NO_LIBEVENT=0 \
	   NO_QT=1 \
	   NO_QR=1 \
	   #NO_ZMQ=0 \
	   #NO_WALLET=0 \
	   NO_BDB=1 \
	   #NO_SQLITE=0 \
	   #NO_NATPMP=0 \
	   #NO_UPNP=0 \
	   #NO_NATPMP=0 \
	   NO_USDT=1 \
	   #NO_HARDEN=0 \ 
	&& cd /opt/bitcoin \
	&& /opt/bitcoin/autogen.sh \
    && /opt/bitcoin/configure \
	  --prefix=/opt/build \
	  --with-gui=no \
	  #--with-sqlite=no \
	  --disable-bench \
	  --disable-gui-tests \
	  --disable-fuzz \
	  --disable-fuzz-binary \
	  --disable-gprof \
	  --disable-man \
	  --disable-tests \
	  --enable-util-cli \
	&& make -j 4 \
	&& make install \
    && strip /opt/build/bin/bitcoin-cli \
    && strip /opt/build/bin/bitcoind \
	&& make clean 

# Build stage for compiled artifacts
FROM alpine:latest as final-image

RUN apk update && \
    apk add --no-cache\
		bash 

ENV PATH=/opt/bitcoin/bin:$PATH

COPY --from=bitcoin-core /opt/build /opt

ADD *.sh /
ADD bitcoin.conf /root/.bitcoin/
VOLUME ["/root/.bitcoin/regtest"]

EXPOSE 19000 19001 28332
ENTRYPOINT ["/entrypoint.sh"]

