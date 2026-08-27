# 🐳 Docker FIPS for Node.js and Python

[![Pulls](https://img.shields.io/docker/pulls/filigran/alpine-python-nodejs-fips.svg)](https://hub.docker.com/r/filigran/alpine-python-nodejs-fips/)
[![Pulls](https://img.shields.io/docker/pulls/filigran/alpine-python-fips.svg)](https://hub.docker.com/r/filigran/alpine-python-fips/)
[![Build](https://github.com/FiligranHQ/docker-python-nodejs-fips/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/FiligranHQ/docker-python-nodejs-fips/actions/workflows/docker-build-push.yml)

Alpine-based images running Python and Node.js against the OpenSSL FIPS provider
built from **FIPS 140-3 validated sources** (CMVP certificate #4985).

OpenSSL, Python and Node.js come from Alpine packages; only the FIPS provider is
compiled. See [`FIPS.md`](FIPS.md) for the exact compliance posture before making
any claim.

## Docker Python Node.js FIPS

Images are available at: https://hub.docker.com/r/filigran/alpine-python-nodejs-fips.

## Docker Python FIPS

Images are available at: https://hub.docker.com/r/filigran/alpine-python-fips.

## Migrating from `filigran/python-fips` and `filigran/python-nodejs-fips`

Those two images are no longer published. They remain available at their last
build, but receive no further Alpine security updates, so pin one of the images
above instead. What changes:

* `npm` and `yarn` are gone, and so is the build toolchain (`rust`, `cargo`,
  `gcc`) — an image that compiles native wheels has to install its own.
* The FIPS provider now comes from the OpenSSL 3.1.2 validated sources instead of
  the same version as the libraries, so the set of accepted algorithms differs.
* Node.js is 24, which the tag now states.

## Use the images

* For Python, bindings are automatically mapped to the OpenSSL FIPS provider,
  just run your Python scripts as usual.
* For Node.js, ensure to run your Node.js programs with `--enable-fips` or
  `--force-fips`.
* When installing `cryptography`, use `pip install --no-binary cryptography` so
  that it links the system OpenSSL instead of a bundled one.

## Proof of Concept / testing

```bash
$ docker run -it filigran/alpine-python-nodejs-fips:latest /bin/sh
$ openssl list -providers
Providers:
  base
    name: OpenSSL Base Provider
    version: 3.5.7
    status: active
  fips
    name: OpenSSL FIPS Provider
    version: 3.1.2
    status: active
$ node --enable-fips -p 'crypto.getFips()'
1
$ python3 -c "import ssl; print(ssl.OPENSSL_VERSION);"
OpenSSL 3.5.7 9 Jun 2026
$ echo test | openssl dgst -md5
Error setting digest
```

The FIPS provider reports `3.1.2` while the library reports the Alpine version.
That difference is expected: the validated module is the provider, and it is
supported across OpenSSL library releases.
