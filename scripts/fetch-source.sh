#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

mkdir_secure "$ROOT/work/source"

TARBALL="openssl-${REVISION}.tar.gz"
OUT="$ROOT/work/source/$TARBALL"
PART="$OUT.part"
URL="https://github.com/openssl/openssl/releases/download/openssl-${REVISION}/${TARBALL}"

# Never reuse an incomplete download.
rm -f "$PART"

if [[ -s "$OUT" ]]; then
    log "source cache HIT: $OUT"
    log "skipping GitHub download; cached source will still be verified"
    FETCH_MODE="cache"
else
    log "source cache MISS: OpenSSL ${REVISION}"
    log "downloading from GitHub release: $URL"

    curl --fail --location --retry 3 \
      --connect-timeout 15 --max-time 600 \
      --proto '=https' --tlsv1.2 \
      "$URL" -o "$PART"

    # Basic transport/file sanity check before accepting it into the cache.
    tar -tzf "$PART" >/dev/null || {
        rm -f "$PART"
        die "downloaded source is not a valid gzip tar archive"
    }

    mv "$PART" "$OUT"
    FETCH_MODE="download"
    log "source cached: $OUT"
fi

# Basic archive validation is performed even for a cache hit.
# Cryptographic verification is mandatory in verify-source.sh and runs
# immediately after fetch through the Makefile dependency chain.
tar -tzf "$OUT" >/dev/null || die "cached source archive is invalid: $OUT"

{
  echo "SOURCE_URL=$URL"
  echo "SOURCE_FILE=$TARBALL"
  echo "FETCH_MODE=$FETCH_MODE"
  echo "SOURCE_SHA256_OBSERVED=$(sha256_file "$OUT")"
  echo "SOURCE_SHA1_OBSERVED=$(sha1_file "$OUT")"
} > "$ROOT/work/source/fetch.env"

log "source ready for mandatory SHA256 + SHA1 verification"
