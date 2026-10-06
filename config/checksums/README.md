Create one approved file per REVISION, for example `3.5.9.env`:

SOURCE_SHA256="<64 hex chars from independently trusted upstream checksum>"
SOURCE_SHA1="<40 hex chars from independently trusted upstream checksum>"

The build intentionally fails closed when this approved file is absent or invalid.
