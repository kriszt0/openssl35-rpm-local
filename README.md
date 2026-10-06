# openssl35 GitHub revision RPM factory

Builds an isolated OpenSSL 3.5.x RPM for Oracle Linux 7. The installed payload is always under `/opt/openssl35`; system OpenSSL is not replaced.

## Version

Set only the desired 3.5.x release in `REVISION`, for example:

    3.5.9

## Proxy (optional)

Copy `config/proxy.env.example` to `config/proxy.env` and edit it. The file is gitignored. `fetch-source.sh` exports both upper- and lower-case proxy variables for curl.

## Source/cache workflow

`make source` downloads the GitHub release tarball selected by `REVISION`. If `work/source/openssl-<REVISION>.tar.gz` already exists, it is reused as a cache hit. The archive is sanity-checked on every source invocation.

`make source` intentionally does not require an approved checksum file. This allows the source to be acquired first.

## Cryptographic verification

Before a build, create `config/checksums/<REVISION>.env` containing independently approved values:

    SOURCE_SHA256="...64 hex characters..."
    SOURCE_SHA1="...40 hex characters..."

Do not populate these values merely by trusting the just-downloaded tarball. `make checksums` prints locally observed values only to help comparison with an independently trusted OpenSSL checksum source.

Run:

    make verify

SHA256 is the security integrity check. SHA1 is retained as an additional audit/legacy check. Both are required by this repository before build.

## Build

    make build JOBS=4

The dependency chain is:

    preflight -> source/cache -> verify -> build

Therefore `make build` cannot bypass verification. `make build` does not run the separate RPM integration test.

## Test

    make test

The test installs the RPM in a clean Oracle Linux 7 container and verifies `/opt/openssl35`, private `libssl.so.3`/`libcrypto.so.3`, ELF RPATH/RUNPATH, library resolution and OpenSSL smoke tests.

## Cleaning

`make clean` removes build outputs but preserves the source cache.

`make clean-cache` removes downloaded source files.

`make distclean` removes all generated work, artifacts and release output.
