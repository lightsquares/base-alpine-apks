#!/bin/sh
ALPINE='docker.io/amd64/alpine:3.22.2@sha256:85f2b723e106c34644cd5851d7e81ee87da98ac54672b29947c052a45d31dc2f'

PACKAGES='openrc alpine-conf iproute2 ifupdown-ng busybox-openrc busybox-mdev-openrc cryptsetup device-mapper lddtree podman iptables git e2fsprogs'

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR"
mkdir -p "$OUT/x86_64" "$OUT/noarch"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "==> Fetching APK closure from $ALPINE"
podman run --rm -v "$TMP:/out:Z" "$ALPINE" sh -c "
  set -e
  apk update
  apk fetch --recursive --output /out $PACKAGES
  echo \"Fetched \$(ls /out/*.apk | wc -l) packages\"
"

echo "==> Organizing into x86_64/ and noarch/, building APKINDEXes"
podman run --rm \
  -v "$TMP:/flat:Z" \
  -v "$OUT:/apks:Z" \
  "$ALPINE" sh -c '
  set -e
  rm -f /apks/x86_64/*.apk /apks/noarch/*.apk
  for f in /flat/*.apk; do
    arch=$(tar -Oxf "$f" .PKGINFO 2>/dev/null | awk -F= "/^arch/{print \$2}" | tr -d " \n")
    cp -p "$f" /apks/x86_64/
    [ "$arch" = "noarch" ] && cp -p "$f" /apks/noarch/
  done
  cd /apks/x86_64 && apk index -o APKINDEX.tar.gz *.apk
  cd /apks/noarch  && apk index -o APKINDEX.tar.gz *.apk
  echo "x86_64: $(ls /apks/x86_64/*.apk | wc -l) packages"
  echo "noarch:  $(ls /apks/noarch/*.apk | wc -l) packages"
'

echo "==> Pinned packages present in x86_64/:"
ls "$OUT/x86_64/" | grep -E "^(openrc|alpine-conf|iproute2|ifupdown-ng|busybox-openrc|busybox-mdev-openrc|cryptsetup|device-mapper|lddtree|podman|iptables|git|e2fsprogs)-"
echo "==> Done. Commit the changes and update the consuming repository’s submodule pointer."
