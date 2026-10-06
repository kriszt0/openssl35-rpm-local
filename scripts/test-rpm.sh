#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config
mkdir_secure "$ROOT/work/logs"
RPM="$(find "$ROOT/artifacts" -maxdepth 1 -type f -name "openssl35-${VERSION}-*.el7.x86_64.rpm" ! -name '*debuginfo*' | head -1)"
[[ -n "$RPM" ]] || die "binary RPM missing for OpenSSL $VERSION"
podman build --pull=never --build-arg "BASE_IMAGE=$TEST_IMAGE" -t "localhost/openssl35-test:${VERSION}" -f "$ROOT/container/Containerfile.test" "$ROOT" | tee "$ROOT/work/logs/test-container-build.log"
podman run --rm -v "$ROOT/artifacts:/rpms:ro,Z" "localhost/openssl35-test:${VERSION}" bash -euxo pipefail -c '
  RPM=/rpms/'"$(basename "$RPM")"'
  rpm -qpi "$RPM"
  rpm -qpl "$RPM" | grep -F "/opt/openssl35/bin/openssl"
  yum localinstall -y "$RPM"
  test -x /opt/openssl35/bin/openssl
  test -f /opt/openssl35/lib64/libssl.so.3
  test -f /opt/openssl35/lib64/libcrypto.so.3
  readelf -d /opt/openssl35/bin/openssl | grep -E "RPATH|RUNPATH"
  ldd /opt/openssl35/bin/openssl | grep -F "libssl.so.3 => /opt/openssl35"
  ldd /opt/openssl35/bin/openssl | grep -F "libcrypto.so.3 => /opt/openssl35"
  /opt/openssl35/bin/openssl version -a
  /opt/openssl35/bin/openssl list -providers
  printf "audit-test\n" >/tmp/plain
  /opt/openssl35/bin/openssl dgst -sha256 /tmp/plain
  /opt/openssl35/bin/openssl dgst -sha1 /tmp/plain
' 2>&1 | tee "$ROOT/work/logs/rpm-test.log"
echo "RPM_TEST=PASS" > "$ROOT/work/logs/test-result.env"
log "clean OL7 RPM test PASS"
