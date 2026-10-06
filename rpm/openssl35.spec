Name:           openssl35
Version:        %{openssl_version}
Release:        1%{?dist}
Summary:        Isolated OpenSSL %{version} for Oracle Linux 7
License:        Apache-2.0
URL:            https://www.openssl.org/
Source0:        openssl-%{version}.tar.gz
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  perl
BuildRequires:  perl-core
BuildRequires:  zlib-devel
BuildRequires:  binutils

%global install_root /opt/openssl35
%{!?build_jobs:%global build_jobs 1}

%description
Side-by-side OpenSSL %{version} for Oracle Linux 7, installed only under
/opt/openssl35. It does not replace the operating system OpenSSL package.

%prep
%setup -q -n openssl-%{version}

%build
./Configure linux-x86_64 \
    --prefix=%{install_root} \
    --openssldir=%{install_root}/ssl \
    --libdir=lib64 \
    shared zlib \
    '-Wl,-rpath,\$$ORIGIN/../lib64'
make -j%{build_jobs}

# Fail early if the runtime path was not preserved.
readelf -d apps/openssl | grep -E 'RPATH|RUNPATH' || {
    echo 'ERROR: RPATH/RUNPATH missing after build'
    exit 1
}

%install
rm -rf %{buildroot}
make install_sw install_ssldirs DESTDIR=%{buildroot}
rm -f %{buildroot}%{install_root}/ssl/misc/tsget
rm -f %{buildroot}%{install_root}/ssl/misc/tsget.pl

OPENSSL_BIN="%{buildroot}%{install_root}/bin/openssl"
LIBSSL="%{buildroot}%{install_root}/lib64/libssl.so.3"
LIBCRYPTO="%{buildroot}%{install_root}/lib64/libcrypto.so.3"

[ -x "$OPENSSL_BIN" ] || { echo 'ERROR: openssl binary missing'; exit 1; }
[ -f "$LIBSSL" ] || { echo 'ERROR: libssl.so.3 missing'; exit 1; }
[ -f "$LIBCRYPTO" ] || { echo 'ERROR: libcrypto.so.3 missing'; exit 1; }

RUNPATH="$(readelf -d "$OPENSSL_BIN" | grep -E '\((RPATH|RUNPATH)\)' || true)"
echo "Detected RPATH/RUNPATH: ${RUNPATH:-<none>}"
[ -n "$RUNPATH" ] || { echo 'ERROR: no RPATH/RUNPATH'; exit 1; }
printf '%s\n' "$RUNPATH" | grep -Fq '$ORIGIN/../lib64' || {
    echo 'ERROR: required $ORIGIN/../lib64 runtime path missing'
    exit 1
}

NEEDED="$(readelf -d "$OPENSSL_BIN" | grep NEEDED || true)"
printf '%s\n' "$NEEDED" | grep -Fq 'Shared library: [libssl.so.3]' || { echo 'ERROR: libssl.so.3 NEEDED missing'; exit 1; }
printf '%s\n' "$NEEDED" | grep -Fq 'Shared library: [libcrypto.so.3]' || { echo 'ERROR: libcrypto.so.3 NEEDED missing'; exit 1; }

echo 'OpenSSL RPM buildroot validation PASS'

%files
%license LICENSE.txt
%doc README.md
/opt/openssl35

%changelog
* Tue Oct 06 2026 Company Build Engineering <build@example.company> - 3.5.9-1
- Install exclusively under /opt/openssl35
- Package private OpenSSL 3 shared libraries
- Add and validate relative $ORIGIN/../lib64 runtime path
- Keep upstream tests separate from RPM build
- Remove tsget WWW::Curl::Easy dependency
