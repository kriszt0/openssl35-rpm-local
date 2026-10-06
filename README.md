# OpenSSL 3.5 RPM factory — GitHub + REVISION

Oracle Linux 7 build flow for an isolated OpenSSL installation under `/opt/openssl35`.

## Version

Edit only `REVISION`, for example:

    3.5.9

The source URL is generated as:

    https://github.com/openssl/openssl/releases/download/openssl-<REVISION>/openssl-<REVISION>.tar.gz

There is no `download/` directory and no offline source fallback.

## Source verification

Before build, `scripts/verify-source.sh` requires both independently pinned SHA256 and SHA1 values from:

    config/checksums/<REVISION>.env

Example:

    SOURCE_SHA256="...64 hex chars..."
    SOURCE_SHA1="...40 hex chars..."

SHA256 is the primary integrity control. SHA1 is retained as an additional audit/legacy check. Never generate the approved reference hashes from the same downloaded file you are trying to verify.

## Commands

    make fetch
    make verify
    make build JOBS=4
    make test

`make build` automatically runs fetch + verify first, but does not run the RPM integration test. `make test` is separate.

Generated source is stored under `work/source/`; RPMs are written to `artifacts/`.

## Source cache

Downloaded GitHub release tarballs are cached under `work/source/`. A subsequent `make build` with the same `REVISION` skips the network download, but `verify-source.sh` still recalculates and validates both SHA256 and SHA1 before the RPM build starts. A checksum mismatch fails closed; the cached file is never silently accepted.

`make clean` preserves the source cache. Use `make clean-cache` to remove only cached source files, or `make distclean` to remove all generated state.

