# 🐳 Docker FIPS for NodeJS and Python

[![Pulls](https://img.shields.io/docker/pulls/filigran/python-nodejs-fips.svg)](https://hub.docker.com/r/filigran/python-nodejs-fips/)
[![Pulls](https://img.shields.io/docker/pulls/filigran/python-fips.svg)](https://hub.docker.com/r/filigran/python-fips/)
[![CircleCI](https://img.shields.io/circleci/project/github/FiligranHQ/docker-python-nodejs-fips.svg)](https://circleci.com/gh/FiligranHQ/docker-python-nodejs-fips)

## Docker Python NodeJS FIPS

Images are available at: https://hub.docker.com/r/filigran/python-nodejs-fips.

## Docker Python FIPS

Images are available at: https://hub.docker.com/r/filigran/python-fips.

## Use the images

* For Python, bindings are automatically mapped to the OpenSSL FIPS 140-2 library, just run your Python scripts as usual.
* For NodeJS, ensure to run your NodeJS programs with `--enable-fips` or `--force-fips`.

## Proof of Concept / testing

```bash
$ docker run -it filigran/python-nodejs-fips:latest /bin/sh
$ openssl version
OpenSSL 3.1.5 30 Jan 2024 (Library: OpenSSL 3.1.5 30 Jan 2024)
$ node --enable-fips -p 'crypto.getFips()'
1
$ python3 -c "import ssl; print(ssl.OPENSSL_VERSION);"
OpenSSL 3.1.5 30 Jan 2024
```