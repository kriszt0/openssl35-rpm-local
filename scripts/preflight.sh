#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

for cmd in podman curl sha256sum sha1sum rpm make awk sed grep tar; do
  command -v "$cmd" >/dev/null 2>&1 || die "missing host command: $cmd"
done

if [[ "${REQUIRE_PINNED_CONTAINER_DIGEST:-0}" == "1" ]]; then
  [[ "$BUILD_IMAGE" == *@sha256:* ]] || die "BUILD_IMAGE is not digest-pinned"
  [[ "$TEST_IMAGE" == *@sha256:* ]] || die "TEST_IMAGE is not digest-pinned"
fi

log "preflight PASS for OpenSSL $REVISION"
