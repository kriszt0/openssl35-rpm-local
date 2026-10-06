#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config
TARBALL="$ROOT/work/source/openssl-${REVISION}.tar.gz"
[[ -s "$TARBALL" ]] || die "source missing; run make source"
echo "Observed only - compare these against an independently trusted OpenSSL checksum source:"
echo "SOURCE_SHA256=$(sha256_file "$TARBALL")"
echo "SOURCE_SHA1=$(sha1_file "$TARBALL")"
