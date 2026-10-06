#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

CHECKSUM_FILE="$ROOT/config/checksums/${REVISION}.env"
TARBALL="$ROOT/work/source/openssl-${REVISION}.tar.gz"
[[ -s "$TARBALL" ]] || die "source missing: $TARBALL; run make source"
[[ -s "$CHECKSUM_FILE" ]] || die "approved checksum file missing: $CHECKSUM_FILE (create it from an independently trusted OpenSSL checksum source; do not approve the locally observed digest blindly)"
# shellcheck disable=SC1090
source "$CHECKSUM_FILE"
[[ "${SOURCE_SHA256:-}" =~ ^[A-Fa-f0-9]{64}$ ]] || die "SOURCE_SHA256 missing/invalid in $CHECKSUM_FILE"
[[ "${SOURCE_SHA1:-}" =~ ^[A-Fa-f0-9]{40}$ ]] || die "SOURCE_SHA1 missing/invalid in $CHECKSUM_FILE"
ACTUAL256="$(sha256_file "$TARBALL")"
ACTUAL1="$(sha1_file "$TARBALL")"
[[ "${ACTUAL256,,}" == "${SOURCE_SHA256,,}" ]] || die "SHA256 mismatch: expected=$SOURCE_SHA256 actual=$ACTUAL256"
[[ "${ACTUAL1,,}" == "${SOURCE_SHA1,,}" ]] || die "SHA1 mismatch: expected=$SOURCE_SHA1 actual=$ACTUAL1"
tar -tzf "$TARBALL" >/dev/null || die "source archive validation failed"
{
  echo "REVISION=$REVISION"
  echo "VERIFIED_SOURCE_SHA256=$ACTUAL256"
  echo "VERIFIED_SOURCE_SHA1=$ACTUAL1"
  echo "SOURCE_VERIFICATION=PASS"
} > "$ROOT/work/source/verification.env"
log "source verification PASS (SHA256 security check + SHA1 audit check)"
