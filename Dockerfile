# syntax=docker/dockerfile:1
FROM alpine:3.24 AS python-fips

# Only source version validated under FIPS 140-3 (CMVP #4985). Must not be
# bumped automatically: any other version leaves the validated lineage.
ARG OPENSSL_FIPS_VERSION=3.1.2
ARG OPENSSL_FIPS_SHA256=a0ce69b8b97ea6a35b96875235aa453b966ba3cba8af2de23657d8b6767d6539

ENV LANG=C.UTF-8

RUN << EOT
    set -euxo pipefail

    apk add --no-cache ca-certificates openssl python3 py3-pip libffi
    rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED
EOT

# fips.so is the cryptographic module: the boundary stops at it, and the OpenSSL
# libraries calling into it stay the ones packaged by Alpine. Hence
# 'make install_fips', which installs the module and its fipsmodule.cnf only.
# The checksum enforces unmodified source, a condition of the CMVP porting rule.
#
# cryptography is built from source as well: a pre-built wheel carries its own
# OpenSSL and would sit outside the boundary.
RUN << EOT
    set -euxo pipefail

    apk add --no-cache --virtual .build-deps build-base perl linux-headers cargo pkgconfig python3-dev libffi-dev openssl-dev

    wget -O openssl.tar.gz "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_FIPS_VERSION}/openssl-${OPENSSL_FIPS_VERSION}.tar.gz"
    echo "${OPENSSL_FIPS_SHA256}  openssl.tar.gz" | sha256sum -c -
    tar -xf openssl.tar.gz
    cd "openssl-${OPENSSL_FIPS_VERSION}"
    # Install into the paths compiled into Alpine's libcrypto, so that enabling
    # FIPS needs no environment variable.
    ./Configure enable-fips --prefix=/usr --libdir=lib --openssldir=/etc/ssl
    make -j"$(nproc)"
    make install_fips
    cd ..
    rm -rf "openssl-${OPENSSL_FIPS_VERSION}" openssl.tar.gz

    pip install --no-cache-dir --no-binary cryptography cryptography

    apk del .build-deps
    # pip's isolated build environment and cargo keep their own caches, which
    # apk del does not cover.
    rm -rf /root/.cache /root/.cargo
EOT

COPY openssl.cnf /etc/ssl/openssl.cnf

# Advertised by the published tags, so a drift in the Alpine package must fail
# the build rather than produce an image whose tag lies.
ARG PYTHON_VERSION=3.12

RUN << EOT
    set -euxo pipefail

    python3 -V | grep "^Python ${PYTHON_VERSION}\." > /dev/null

    openssl list -providers
    openssl list -providers | grep 'OpenSSL FIPS Provider' > /dev/null
    openssl list -providers | grep -A2 fips | grep "version: ${OPENSSL_FIPS_VERSION}" > /dev/null
    openssl dgst -sha256 /etc/ssl/openssl.cnf > /dev/null

    if echo test | openssl dgst -md5 > /dev/null 2>&1; then
        echo 'MD5 was accepted: FIPS mode is not enforced' >&2
        exit 1
    fi

    python3 -c 'from cryptography.hazmat.backends.openssl.backend import backend; print(backend.openssl_version_text())' \
        | grep "$(openssl version | cut -d' ' -f2)" > /dev/null
EOT


FROM python-fips AS python-nodejs-fips

# Advertised by the published tags, so a drift in the Alpine package must fail
# the build rather than produce an image whose tag lies.
ARG NODEJS_VERSION=24

# Node.js reaches the FIPS provider only through the system OpenSSL it is
# dynamically linked against, which the assertions below enforce.
RUN << EOT
    set -euxo pipefail

    apk add --no-cache nodejs

    node -v | grep "^v${NODEJS_VERSION}\." > /dev/null

    test "$(node --enable-fips -p 'crypto.getFips()')" = '1'
    ldd "$(which node)" | grep 'libssl.so.3' > /dev/null
EOT
