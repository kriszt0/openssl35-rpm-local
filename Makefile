SHELL := /bin/bash
JOBS ?= 1

.PHONY: preflight fetch verify source build test evidence sign verify-rpm repo release dev-release clean clean-cache distclean

preflight:
	./scripts/preflight.sh

fetch: preflight
	./scripts/fetch-source.sh

verify: fetch
	./scripts/verify-source.sh

source: verify

build: source
	JOBS=$(JOBS) ./scripts/build-rpm.sh

# Test is intentionally separate from build.
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

release: clean preflight source build test sign verify-rpm evidence repo
	./scripts/assemble-release.sh

dev-release: clean preflight source build test evidence
	ALLOW_UNSIGNED=1 ./scripts/assemble-release.sh

clean:
	@echo "Cleaning build outputs; preserving work/source cache..."
	rm -rf artifacts release work/logs work/rpmbuild
	rm -f work/source/verification.env work/source/fetch.env

clean-cache:
	@echo "Removing downloaded source cache..."
	rm -rf work/source

distclean:
	rm -rf work artifacts release
