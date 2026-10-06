#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
load_config

JOBS="${JOBS:-1}"
[[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || die "invalid JOBS value: $JOBS"
mkdir -p "$ROOT/artifacts"
mkdir_secure "$ROOT/work/logs"

SOURCE="$ROOT/work/source/openssl-${VERSION}.tar.gz"
SPEC="$ROOT/rpm/openssl35.spec"
[[ -s "$ROOT/work/source/verification.env" ]] || die "verified source evidence missing; run make verify"
[[ -f "$SOURCE" ]] || die "source tarball missing: $SOURCE"
[[ -f "$SPEC" ]] || die "RPM spec missing: $SPEC"

podman build --pull=never \
  --build-arg "BASE_IMAGE=$BUILD_IMAGE" \
  -t "localhost/openssl35-builder:${VERSION}" \
  -f "$ROOT/container/Containerfile.build" "$ROOT" \
  2>&1 | tee "$ROOT/work/logs/container-build.log"

podman run --rm \
  -e "JOBS=$JOBS" \
  -v "$SOURCE:/input/openssl-${VERSION}.tar.gz:ro,Z" \
  -v "$SPEC:/input/openssl35.spec:ro,Z" \
  -v "$ROOT/artifacts:/output:Z" \
  "localhost/openssl35-builder:${VERSION}" \
  bash -euxo pipefail -c '
    RPMBUILD=/tmp/rpmbuild
    mkdir -p "${RPMBUILD}"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
    cp /input/openssl-'"$VERSION"'.tar.gz "${RPMBUILD}/SOURCES/"
    cp /input/openssl35.spec "${RPMBUILD}/SPECS/"
    rpmbuild -ba "${RPMBUILD}/SPECS/openssl35.spec" \
      --define "_topdir ${RPMBUILD}" \
      --define "openssl_version '"$VERSION"'" \
      --define "build_jobs ${JOBS}"
    find "${RPMBUILD}/RPMS" -type f -name "*.rpm" -exec cp -f {} /output/ \;
    find "${RPMBUILD}/SRPMS" -type f -name "*.rpm" -exec cp -f {} /output/ \;
  ' 2>&1 | tee "$ROOT/work/logs/rpmbuild.log"

RPM="$(find "$ROOT/artifacts" -maxdepth 1 -type f -name "openssl35-${VERSION}-*.el7.x86_64.rpm" ! -name '*debuginfo*' | head -1)"
[[ -n "$RPM" ]] || die "no openssl35 ${VERSION} binary RPM produced"
log "RPM build PASS: $(basename "$RPM")"
