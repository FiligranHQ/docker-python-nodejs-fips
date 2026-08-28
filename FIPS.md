# FIPS 140-3 posture of these images

## OpenSSL FIPS provider 3.1.2, validated under CMVP #4985

All cryptography in these images goes through that module, at the validated
version, under a certificate valid until 10 March 2030.

FIPS mode is active by default. No flag, environment variable or configuration
step is required.

## Built from the validated sources, by the documented procedure

The Security Policy addresses integrators who build the module into their
product, and gives them this procedure:

```
$ ./Configure enable-fips
$ make
$ make install_fips
```

That is what the `Dockerfile` runs, on the source tarball from openssl.org whose
SHA-256 is pinned and verified. `make install_fips` computes the module's
HMAC-SHA2-256 integrity value against the file actually shipped and writes it to
`fipsmodule.cnf`. Nothing is patched, and the run-time security checks the policy
requires to remain enabled are left enabled.

The policy places no restriction on the environment the module runs on, refers to
the upstream `INSTALL.md` and `README-FIPS.md` for building on other platforms,
and contemplates porting the module beyond the configurations it was tested on.

Only 3.1.2 carries a FIPS 140-3 validation, hence the pinned version, left out of
Renovate's reach. The other validated sources — 3.0.0, 3.0.8 and 3.0.9 under
certificate #4282 — are FIPS 140-2, and #4282 moves to the CMVP *Historical* list
on 21 September 2026.

## Non-approved algorithms are refused, not substituted

Only the `fips` and `base` providers are activated, with
`default_properties = fips=yes`. The `default` provider is not declared at all,
so a non-approved algorithm is refused rather than quietly served from outside
the module. Were `fips.so` to become unreachable, operations would fail outright
instead of falling back.

The build asserts all of this, and fails rather than produce an image whose FIPS
mode is not effective.

## Claims these images support

* They perform cryptography through the OpenSSL FIPS provider 3.1.2, validated
  under CMVP certificate #4985.
* The module is built from the validated source distribution, unmodified, by the
  procedure documented in its Security Policy, with integrity verification and
  self-tests enabled.
* FIPS mode is enforced: non-approved algorithms are refused, not substituted.

## What falls outside the module

**Python `hashlib` is not fully inside the module.** `hashlib.sha256()` resolves
to `_hashlib.HASH` and goes through it, but `hashlib.md5()` resolves to
`_md5.md5`, CPython's built-in implementation, which bypasses OpenSSL and is not
blocked by FIPS mode. This is upstream CPython behaviour. Python code that must
stay inside the module belongs on `ssl` or `cryptography`.

**Statically linked crypto bypasses the module.** Any Python wheel, Go or Rust
binary carrying its own OpenSSL or BoringSSL does not use it. The images install
`cryptography` with `pip install --no-binary cryptography`, which links the
system OpenSSL; a plain `pip install cryptography` takes a `musllinux` wheel with
a bundled one.

## Checking an image

```bash
docker run --rm filigran/alpine-python-nodejs-fips:latest sh -c '
  openssl list -providers
  node --enable-fips -p "crypto.getFips()"
  python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
  echo test | openssl dgst -md5 || echo "MD5 refused, as expected"
'
```

The provider reports **3.1.2** while the library reports the Alpine version. That
difference is the point: the validated module is the provider, and it is
supported across OpenSSL library releases.

## References

- [OpenSSL FIPS 140-3 validation announcement (3.1.2, cert #4985)](https://openssl-library.org/post/2025-03-11-fips-140-3/)
- [Security Policy for certificate #4985](https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4985.pdf)
- [OpenSSL: which versions are FIPS validated](https://openssl-library.org/source/)
- [CMVP certificate #4282 (FIPS 140-2, historical 21 Sept 2026)](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4282)
- [OpenSSL `README-FIPS.md` — provider/library version compatibility](https://github.com/openssl/openssl/blob/master/README-FIPS.md)
