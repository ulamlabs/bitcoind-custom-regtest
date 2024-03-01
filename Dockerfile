# Build stage for Bitcoin Core
FROM alpine:latest as bitcoin-core

######### Optional things to adjust ########
# Maxing out processors was killing my docker instance, so here's a place to 
# manually set how many you want to use.
ARG NUM_PROCESSES=6 

# Build a specific bitcoin branch
ARG BITCOIN_BRANCH=26.x
###########################################

# Install build tools
# and build utilities for depends on linux see bitcoin*/depends/README.md
RUN apk update && \
    apk add --no-cache \
		autoconf \
		automake \
		bash \
		binutils \
		bison \
		build-base \
		cmake \
		curl \
		git \
		libtool \
		make \
		patch \
		pkgconfig \
		python3 

RUN mkdir -p /opt/build

WORKDIR /opt

RUN git config --global http.postBuffer 524288000  

RUN git clone -v -j${NUM_PROCESSES} --single-branch --branch ${BITCOIN_BRANCH} https://github.com/bitcoin/bitcoin.git

## see other architecture options in bitcoin/depends/README.md
ARG CONFIG_SITE=/opt/bitcoin/depends/x86_64-pc-linux-musl/share/config.site

WORKDIR /opt/bitcoin

# This is going to install libevent, boost, sqlite and bdb
# Getting compatible versions of those from the package manager was harder than
# just compiling them with the depends make scripts
#
# bdb is needed in v26 for the createwallet RPC call to work. 
# SQLite is supposed to work for createwallets but it's not working in v26 yet.
RUN cd depends && \
	make -j ${NUM_PROCESSES} install \
	   NO_QR=1 \
	   NO_QT=1 \
	   NO_USDT=1  
#	   NO_BDB=0 \
#	   NO_BOOST=0 \
#	   NO_HARDEN=0  
#	   NO_LIBEVENT=0 \
#	   NO_NATPMP=0 \
#	   NO_SQLITE=0 \
#	   NO_UPNP=0 \
#	   NO_WALLET=0 \
#	   NO_ZMQ=0 \

RUN cd /opt/bitcoin && \
	/opt/bitcoin/autogen.sh && \
	/opt/bitcoin/configure \
	  --prefix=/opt/build \
	  --with-sqlite \
	  --with-bdb \
	  --with-utils \
	  --with-libs \
	  --with-gui=no \
	  --without-qrencode \
      --enable-wallet \
	  --disable-bench \
	  --disable-gui-tests \
	  --disable-fuzz \
	  --disable-fuzz-binary \
	  --disable-gprof \
	  --disable-man \
	  --disable-usdt \
	  --disable-tests \
	  --enable-util-cli && \
	make -j ${NUM_PROCESSES} install && \
	strip /opt/build/bin/*

### Build stage for compiled artifacts
FROM alpine:latest as final-image

#jq and curl needed for the healthcheck script
RUN apk update && \
    apk add --no-cache \
		libstdc++ \
		bash \
		binutils \
		curl \
		jq 

ENV PATH=/opt/bin:$PATH

COPY --from=bitcoin-core /opt/build /opt

ADD *.sh /
ADD bitcoin.conf /root/.bitcoin/
VOLUME ["/root/.bitcoin/regtest"]

EXPOSE 19000 19001 28332
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY healthcheck.sh /healthcheck.sh
HEALTHCHECK --interval=1s --timeout=12s --start-period=60s \  
    CMD /healthcheck.sh 

