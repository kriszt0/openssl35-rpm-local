SHELL := /bin/bash
JOBS ?= 1

.PHONY: preflight fetch source verify checksums build test evidence sign verify-rpm repo release dev-release clean clean-cache distclean

preflight:
	./scripts/preflight.sh

fetch: preflight
	./scripts/fetch-source.sh

# source means: ensure the REVISION-selected GitHub tarball exists in cache.
# It deliberately does not require approved checksums yet.
source: fetch

# verify always re-hashes the cached/downloaded source.
verify: source
	./scripts/verify-source.sh

checksums: source
	./scripts/show-observed-checksums.sh

# Build is impossible without successful verification.
build: verify
	JOBS=$(JOBS) ./scripts/build-rpm.sh

test:
	./scripts/test-rpm.sh

evidence:
	./scripts/generate-evidence.sh

sign:
	./scripts/sign-rpm.sh

verify-rpm:
	./scripts/verify-rpm.sh

repo:
	./scripts/create-yum-repo.sh

release: clean build test sign verify-rpm evidence repo
	./scripts/assemble-release.sh

dev-release: clean build test evidence
	ALLOW_UNSIGNED=1 ./scripts/assemble-release.sh

clean:
	@echo "Cleaning build outputs; preserving source cache..."
	rm -rf artifacts release work/logs work/rpmbuild
	rm -f work/source/verification.env work/source/fetch.env

clean-cache:
	@echo "Removing source cache..."
	rm -rf work/source

distclean:
	rm -rf work artifacts release
