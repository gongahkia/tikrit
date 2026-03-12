#!/bin/sh

set -e

if command -v love >/dev/null 2>&1; then
    command -v love
    exit 0
fi

for app in \
    "${LOVE_APP_PATH:-/Applications/love.app}" \
    "/Applications/Love.app" \
    "$HOME/Applications/love.app" \
    "$HOME/Applications/Love.app"
do
    bin="$app/Contents/MacOS/love"
    if [ -x "$bin" ]; then
        printf '%s\n' "$bin"
        exit 0
    fi
done

exit 1
