FROM alpine:edge as builder

RUN apk update && apk add build-base ninja meson git wget bash curl openssl3 openssl3-dev llvm clang lld

# Install usockets
RUN git clone https://github.com/uNetworking/uSockets && \
    cd uSockets && \
    git fetch --all --tags && \
    git checkout c2c1bbfa1644f1f6eb7fc9375650f41c5f9b7b06 && \
    curl https://raw.githubusercontent.com/gentoo/guru/dev/net-libs/usockets/files/usockets-0.8.1_p20211023-Makefile.patch | git apply && \
    curl https://raw.githubusercontent.com/gentoo/guru/dev/net-libs/usockets/files/usockets-0.8.1_p20211023-pkg-config.patch | git apply && \
    make CC="clang" CXX="clang++" LD="ld.lld" LDFLAGS="-flto=full -fuse-ld=lld" WITH_OPENSSL=1 && \
    make install && \
    cd ..

# Install uwebsocket source
RUN git clone https://github.com/uNetworking/uWebSockets && \
    cd uWebSockets && \
    git fetch --all --tags && \
    git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) && \
    cp -r src /usr/include/uWebSockets && \
    cd ..

# Install LMDB
RUN wget https://git.openldap.org/openldap/openldap/-/archive/LMDB_0.9.29/openldap-LMDB_0.9.29.tar.gz && \
    tar xzf openldap-LMDB_0.9.29.tar.gz && \
    cd openldap-LMDB_0.9.29/libraries/liblmdb && \
    make && \
    make CC="clang" CXX="clang++" LD="ld.lld" LDFLAGS="-flto=full -fuse-ld=lld" prefix="/usr" install

# Instal lmdb++.h
RUN wget https://raw.githubusercontent.com/hoytech/lmdbxx/1.0.0/lmdb%2B%2B.h -O /usr/include/lmdb++.h

WORKDIR /app
COPY . .
RUN mkdir /out

# Install at /out
RUN CC="clang" CXX="clang++" CC_LD="lld" CXX_LD="lld" LDFLAGS="-flto=full" meson --prefix "/out" build && \
    ninja -C build && \
    ninja -C build install && \
    strip -s /out/bin/purrito

# Our runner dockerfile
FROM alpine:edge

# Install all the dynamically linked dependencies
RUN apk add wget make gcc openssl3 openssl3-dev curl musl-dev git g++ supervisor caddy clang llvm lld && \
    wget https://git.openldap.org/openldap/openldap/-/archive/LMDB_0.9.29/openldap-LMDB_0.9.29.tar.gz && \
    tar xzf openldap-LMDB_0.9.29.tar.gz && \
    cd openldap-LMDB_0.9.29/libraries/liblmdb && \
    make CC="clang" CXX="clang++" LD="ld.lld" LDFLAGS="-flto=full -fuse-ld=lld" && \
    make prefix="/usr" install && \
    cd ../../.. && \
    rm -rf openldap-LMDB_0.9.29.tar.gz openldap-LMDB_0.9.29 && \
    git clone https://github.com/uNetworking/uSockets && \
    cd uSockets && \
    git fetch --all --tags && \
    git checkout c2c1bbfa1644f1f6eb7fc9375650f41c5f9b7b06 && \
    curl https://raw.githubusercontent.com/gentoo/guru/dev/net-libs/usockets/files/usockets-0.8.1_p20211023-Makefile.patch | git apply && \
    curl https://raw.githubusercontent.com/gentoo/guru/dev/net-libs/usockets/files/usockets-0.8.1_p20211023-pkg-config.patch | git apply && \
    make CC="clang" CXX="clang++" LD="ld.lld" LDFLAGS="-flto=full -fuse-ld=lld" WITH_OPENSSL=1 && \
    make install && \
    cd .. && \
    rm -rf uSockets && \
    apk del openssl3-dev make curl wget musl-dev git g++ clang llvm lld && \
    mkdir /var/log/supervisord /var/run/supervisord

# Purrito binary from builder container
COPY --from=builder /out/bin/purrito /
COPY --from=builder /out/share/PurritoBin /usr/share/purrito-provisioning

COPY ./.run.sh /run.sh
COPY ./.entrypoint.sh /entrypoint.sh
COPY Caddyfile /etc/caddy/Caddyfile
COPY supervisord.conf /

VOLUME ["/var/www/html"]
VOLUME ["/db"]

ENV DOMAIN_NAME="localhost/"

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
