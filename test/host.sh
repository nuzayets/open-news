#!/bin/sh
# Checks the native host's message framing and input validation without opening News.
set -eu
HOST=${1:?usage: test/host.sh <host-binary>}
failures=0

send() { # $1 = JSON body, $2 = extra bytes claimed in the length header
  python3 -c 'import sys, struct; b = sys.argv[1].encode(); sys.stdout.buffer.write(struct.pack("=I", len(b) + int(sys.argv[2])) + b)' "$1" "$2" \
    | "$HOST" | python3 -c 'import sys, struct; d = sys.stdin.buffer.read(); n = struct.unpack("=I", d[:4])[0]; assert n == len(d) - 4, "bad reply length"; print(d[4:].decode())'
}

expect() { # $1 = name, $2 = expected error, $3 = JSON body, $4 = extra length
  reply=$(send "$3" "$4" || true)
  case $reply in
    *"\"error\":\"$2\""*) echo "ok   $1" ;;
    *) echo "FAIL $1: $reply"; failures=$((failures + 1)) ;;
  esac
}

expect "rejects non-web URL" "not a web URL" '{"url":"file:///etc/hosts"}' 0
expect "rejects malformed JSON" "invalid message" '{"url":' 0
expect "rejects truncated frame" "invalid message" '{"url":"https://example.com/"}' 1
expect "rejects missing url" "invalid message" '{}' 0

[ "$failures" -eq 0 ]
