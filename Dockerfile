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
		boost \
		boost-dev \
		build-base \
		cmake \
		curl \
		git \
		libevent \
		libevent-dev \
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

RUN cd depends \
    && make -j ${NUM_PROCESSES} \
	   #NO_BOOST=0 \
	   #NO_LIBEVENT=0 \
	   NO_QT=1 \
	   NO_QR=1 \
	   #NO_ZMQ=0 \
	   #NO_WALLET=0 \
	   #NO_BDB=0 \  #Needs bdb for legacy wallets to be enabled see line 407 of src/wallet/rpc/wallet.cpp \
	   NO_SQLITE=1 \
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
	  --with-sqlite=no \
	  --disable-bench \
	  --disable-gui-tests \
	  --disable-fuzz \
	  --disable-fuzz-binary \
	  --disable-gprof \
	  --disable-man \
	  --disable-tests \
	  --enable-util-cli \
	&& make -j ${NUM_PROCESSES} \
	&& make install \
	&& make clean \
    && strip /opt/build/bin/*

# Build stage for compiled artifacts
FROM alpine:latest as final-image

RUN apk update && \
    apk add --no-cache \
		libstdc++ \
		bash \
		jq \
		curl

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

