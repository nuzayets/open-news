#!/bin/sh
# Builds the native host and registers it with every installed Chrome/Brave channel.
set -eu
cd "$(dirname "$0")"

HOST_NAME=com.open_in_news.host
SUPPORT="$HOME/Library/Application Support"
HOST_BIN="$SUPPORT/OpenInNews/open-in-news-host"
# Chromium derives an extension's ID from its public key: SHA-256, first 32 hex digits, mapped 0-f to a-p.
EXTENSION_ID=$(plutil -extract key raw extension/manifest.json | base64 -d | shasum -a 256 | cut -c1-32 | tr 0-9a-f a-p)

mkdir -p "$(dirname "$HOST_BIN")"
swiftc -O host/OpenInNewsHost.swift -o "$HOST_BIN"

for browser in "Google/Chrome" "Google/Chrome Beta" "Google/Chrome Dev" "Google/Chrome Canary" \
    "BraveSoftware/Brave-Browser" "BraveSoftware/Brave-Browser-Beta" "BraveSoftware/Brave-Browser-Nightly"; do
  [ -d "$SUPPORT/$browser" ] || continue
  dir="$SUPPORT/$browser/NativeMessagingHosts"
  mkdir -p "$dir"
  cat > "$dir/$HOST_NAME.json" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Open in News",
  "path": "$HOST_BIN",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXTENSION_ID/"]
}
EOF
  echo "Registered host for $browser"
done
echo "Extension ID: $EXTENSION_ID"
