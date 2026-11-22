#!/bin/sh
# Builds dist/OpenInNews-<version>.pkg and dist/open-in-news-extension-<version>.zip.
# Signs when APP_IDENTITY (Developer ID Application) and INSTALLER_IDENTITY (Developer ID Installer) are set.
set -eu
cd "$(dirname "$0")/.."

VERSION=${1:?usage: scripts/package.sh <version>}
# Chrome extension versions are one to four dot-separated integers.
echo "$VERSION" | grep -Eq '^[0-9]+(\.[0-9]+){0,3}$' || { echo "invalid version: $VERSION" >&2; exit 1; }
HOST_NAME=com.open_in_news.host
HOST_PATH="/Library/Application Support/OpenInNews/open-in-news-host"
EXTENSION_ID=$(plutil -extract key raw extension/manifest.json | base64 -d | shasum -a 256 | cut -c1-32 | tr 0-9a-f a-p)
DIST=dist
ROOT=$DIST/root

rm -rf "$DIST"
mkdir -p "$ROOT$(dirname "$HOST_PATH")" "$DIST/build"

for arch in arm64 x86_64; do
  swiftc -O -target "$arch-apple-macos12" host/OpenInNewsHost.swift -o "$DIST/build/host-$arch"
done
lipo -create "$DIST/build/host-arm64" "$DIST/build/host-x86_64" -output "$ROOT$HOST_PATH"
if [ -n "${APP_IDENTITY:-}" ]; then
  codesign --force --options runtime --timestamp --sign "$APP_IDENTITY" "$ROOT$HOST_PATH"
fi

# Google Chrome reads the first directory; Brave and Chromium read the second.
for dir in "/Library/Google/Chrome/NativeMessagingHosts" "/Library/Application Support/Chromium/NativeMessagingHosts"; do
  mkdir -p "$ROOT$dir"
  cat > "$ROOT$dir/$HOST_NAME.json" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Open in News",
  "path": "$HOST_PATH",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXTENSION_ID/"]
}
EOF
done

xattr -cr "$ROOT" # otherwise extended attributes become ._ files in the payload
pkgbuild --root "$ROOT" --identifier "$HOST_NAME" --version "$VERSION" --install-location / \
  ${INSTALLER_IDENTITY:+--sign "$INSTALLER_IDENTITY" --timestamp} "$DIST/OpenInNews-$VERSION.pkg"

# The Chrome Web Store rejects manifests containing "key"; the first upload carries key.pem instead.
cp -R extension "$DIST/extension"
plutil -remove key "$DIST/extension/manifest.json"
plutil -replace version -string "$VERSION" "$DIST/extension/manifest.json"
(cd "$DIST/extension" && zip -qr "../open-in-news-extension-$VERSION.zip" .)

rm -rf "$DIST/build" "$DIST/extension"
