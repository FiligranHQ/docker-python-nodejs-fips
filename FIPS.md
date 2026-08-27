# FIPS 140-3 posture of these images

What these images claim and what they do not, so that downstream users can
assess it against their own compliance requirements.

## What the cryptographic module is

The cryptographic module is the **OpenSSL FIPS provider** (`fips.so`), and
nothing else. `libcrypto`, `libssl`, Python and Node.js sit outside the boundary
and delegate to it — which is why the images use the OpenSSL packaged by Alpine
and compile only the provider.

## Which version, and why that one

The provider is built from the source distribution of **OpenSSL 3.1.2**, the
module validated under **CMVP certificate #4985** (FIPS 140-3, valid until
10 March 2030). It is the only source version with a FIPS 140-3 validation: the
other validated sources — 3.0.0, 3.0.8 and 3.0.9 under certificate #4282 — are
FIPS 140-**2**, and #4282 moves to the CMVP *Historical* list on
**21 September 2026**.

The source distribution is checksum-verified at build time: leaving it
unmodified is the central condition of the porting rule below.

## What is claimed — and what is not

> FIPS mode enforced by a module built from FIPS 140-3 validated sources under
> certificate #4985, ported to Alpine/musl by vendor affirmation.

This is **not** a claim that the image is "FIPS 140-3 validated". The operational
environments (OE) tested for #4985 do not include Alpine or musl. Recompiling a
software module for an untested OE falls under the CMVP porting rules
(FIPS 140-3 IG 2.3.B): the certificate is not extended, NIST does not list the
new OE, and the posture is **vendor affirmation** — an allowance addressed to
the module vendor.

## What is enforced at runtime

FIPS mode is active out of the box, with no environment variable or flag to set:
the configuration activates only the `fips` and `base` providers and sets
`default_properties = fips=yes`. The `default` provider is not declared at all,
so non-approved algorithms are refused rather than silently substituted, and an
unreachable `fips.so` fails operations outright
(`inner_evp_generic_fetch:unsupported`) instead of falling back to non-validated
implementations.

The module's integrity check (`module-mac` in `fipsmodule.cnf`) is generated at
build time by `make install_fips`, against the module actually shipped.
`conditional-errors` and `security-checks` remain enabled.

The build asserts all of this and fails rather than produce an image whose FIPS
mode is not effective.

## Known gaps in coverage

**Python `hashlib` is not fully inside the boundary.** `hashlib.sha256()`
resolves to `_hashlib.HASH` and goes through the module, but `hashlib.md5()`
resolves to `_md5.md5`, CPython's built-in implementation, which bypasses OpenSSL
and is not blocked by FIPS mode. This is upstream CPython behaviour; only Red
Hat's patched CPython enforces it. Python code that must stay inside the boundary
should use `ssl` or `cryptography`.

**Statically linked crypto escapes the boundary silently.** Any Python wheel, Go
or Rust binary bundling its own OpenSSL or BoringSSL does not use the module.
`pip install cryptography` takes a `musllinux` wheel with its own bundled
OpenSSL by default — use `pip install --no-binary cryptography` so that it links
the system one.

## Verifying an image yourself

```bash
docker run --rm filigran/alpine-python-nodejs-fips:latest sh -c '
  openssl list -providers
  node --enable-fips -p "crypto.getFips()"
  python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
  echo test | openssl dgst -md5 || echo "MD5 refused, as expected"
'
```

The provider must report version **3.1.2** while the library reports the Alpine
version.

## References

- [OpenSSL FIPS 140-3 validation announcement (3.1.2, cert #4985)](https://openssl-library.org/post/2025-03-11-fips-140-3/)
- [OpenSSL: which versions are FIPS validated](https://openssl-library.org/source/)
- [CMVP certificate #4282 (FIPS 140-2, historical 21 Sept 2026)](https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4282)
- [OpenSSL `README-FIPS.md` — provider/library version compatibility](https://github.com/openssl/openssl/blob/master/README-FIPS.md)
