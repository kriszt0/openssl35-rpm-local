#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

# Optional proxy config. Keep credentials out of Git.
if [[ -f "$ROOT/config/proxy.env" ]]; then
  # shellcheck disable=SC1090
  source "$ROOT/config/proxy.env"
  export HTTP_PROXY="${HTTP_PROXY:-}" HTTPS_PROXY="${HTTPS_PROXY:-}" NO_PROXY="${NO_PROXY:-}"
  export http_proxy="${HTTP_PROXY:-}" https_proxy="${HTTPS_PROXY:-}" no_proxy="${NO_PROXY:-}"
  [[ -n "${HTTPS_PROXY:-}" ]] && log "HTTPS proxy enabled from config/proxy.env"
fi

mkdir_secure "$ROOT/work/source"
TARBALL="openssl-${REVISION}.tar.gz"
OUT="$ROOT/work/source/$TARBALL"
PART="$OUT.part"
URL="https://github.com/openssl/openssl/releases/download/openssl-${REVISION}/${TARBALL}"
rm -f "$PART"

if [[ -s "$OUT" ]]; then
  log "source cache HIT: $OUT"
  FETCH_MODE="cache"
else
  log "source cache MISS: downloading OpenSSL ${REVISION} from GitHub"
  curl --fail --location --retry 3 --connect-timeout 15 --max-time 900 \
    --proto '=https' --tlsv1.2 "$URL" -o "$PART"
  tar -tzf "$PART" >/dev/null || { rm -f "$PART"; die "downloaded source is not a valid gzip tar archive"; }
  mv "$PART" "$OUT"
  FETCH_MODE="download"
  log "source cached: $OUT"
fi

tar -tzf "$OUT" >/dev/null || die "cached source archive is invalid: $OUT"
{
  echo "SOURCE_URL=$URL"
  echo "SOURCE_FILE=$TARBALL"
  echo "FETCH_MODE=$FETCH_MODE"
  echo "SOURCE_SHA256_OBSERVED=$(sha256_file "$OUT")"
  echo "SOURCE_SHA1_OBSERVED=$(sha1_file "$OUT")"
} > "$ROOT/work/source/fetch.env"
log "source ready; cryptographic verification is still required before build"
