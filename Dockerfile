ARG RESTY_IMAGE_BASE="debian"
ARG RESTY_IMAGE_TAG="10.4-slim"
ARG RESTY_VERSION="1.17.8.2"

FROM openresty/openresty:${RESTY_VERSION}-buster as builder

ARG RESTY_VERSION="1.17.8.2"
ARG COMMIT_HASH="4ae28b9b7f11b91e218ccab49cff3ff4db0f8152"
ARG RESTY_MYSQL_VERSION="0.23"

COPY dpkg-buildpackage-rules /opt/rules

# debian build base
RUN apt-get update \
    && apt-get install -y \
        libtemplate-perl \
        dh-systemd \
        systemtap-sdt-dev \
        perl \
        gnupg \
        curl \
        make \
        build-essential \
        dh-make \
        bzr-builddeb \
        libgeoip-dev wget unzip sudo

# openresty build
RUN curl -O https://codeload.github.com/openresty/openresty-packaging/zip/${COMMIT_HASH} \
    && unzip ${COMMIT_HASH} \
    && cd openresty-packaging-${COMMIT_HASH}/deb \
    && mv /opt/rules openresty/debian/rules \
    && make OPTS='-uc -us' openresty-build \
    && dpkg -i openresty_${RESTY_VERSION}-1~buster1_amd64.deb \
    && curl -Lo /usr/local/openresty/lualib/resty/mysql.lua \
        https://raw.githubusercontent.com/openresty/lua-resty-mysql/v${RESTY_MYSQL_VERSION}/lib/resty/mysql.lua

# cleanup
RUN rm -fr /usr/local/openresty/openssl/lib/*.a \
        /usr/local/openresty/pcre/lib/*.a \
        /usr/local/openresty/zlib/lib/*.a \
        /usr/local/openresty/openssl/include \
        /usr/local/openresty/pcre/include \
        /usr/local/openresty/zlib/include


# from slim directly!!!
FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

COPY --from=builder /usr/local/openresty /usr/local/openresty
COPY --from=builder \
       /usr/lib/x86_64-linux-gnu/libssl.so.1.1 \
       /usr/lib/x86_64-linux-gnu/libcrypto.so.1.1 \
     /usr/lib/x86_64-linux-gnu/

COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libgeoip-dev \
        ca-certificates \
    && mkdir -p /var/run/openresty \
    && mkdir -p /var/log/openresty \
    && rm -rf /var/lib/apt/lists/*
