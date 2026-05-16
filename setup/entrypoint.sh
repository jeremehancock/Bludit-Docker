#!/bin/bash
set -e

WEB_ROOT=/var/www/html/bludit
MARKER="$WEB_ROOT/.bludit-installed"

# Align the in-container www-data user with the host user's UID/GID so files
# created via the bind mount end up owned by the host user, not root.
PUID="${PUID:-33}"
PGID="${PGID:-33}"

CURRENT_UID=$(id -u www-data)
CURRENT_GID=$(getent group www-data | cut -d: -f3)

if [ "$PGID" != "$CURRENT_GID" ]; then
    echo "Setting www-data GID to $PGID"
    groupmod -o -g "$PGID" www-data
fi
if [ "$PUID" != "$CURRENT_UID" ]; then
    echo "Setting www-data UID to $PUID"
    usermod -o -u "$PUID" www-data
fi

echo -e "\e[96m******************************* Install Latest Bludit *******************************\e[0m"

if [ -f "$MARKER" ]; then
    echo "Bludit is already installed at $WEB_ROOT. Skipping download to preserve your site."
    echo "To force a fresh install, remove $MARKER (and back up your site first)."
else
    TMP_DIR=$(mktemp -d)
    BLUDIT_ZIP_URL=$(curl -fsSL https://api.github.com/repos/bludit/bludit/releases/latest \
        | grep -Eo '"zipball_url"\s*:\s*"[^"]+"' \
        | head -n1 \
        | sed -E 's/.*"zipball_url"\s*:\s*"([^"]+)".*/\1/')

    if [ -z "$BLUDIT_ZIP_URL" ]; then
        echo "Failed to determine latest Bludit release URL" >&2
        exit 1
    fi

    echo "Latest Bludit release: $BLUDIT_ZIP_URL"
    wget -nv -L "$BLUDIT_ZIP_URL" -O "$TMP_DIR/bludit.zip"
    unzip -q -o "$TMP_DIR/bludit.zip" -d "$TMP_DIR/extracted"
    mkdir -p "$WEB_ROOT"

    # The Bludit zip may extract either directly or inside a single wrapper
    # directory (e.g. bludit-3.x.x/). Handle both layouts.
    EXTRACTED_ENTRIES=("$TMP_DIR"/extracted/*)
    if [ ${#EXTRACTED_ENTRIES[@]} -eq 1 ] && [ -d "${EXTRACTED_ENTRIES[0]}" ]; then
        SRC_DIR="${EXTRACTED_ENTRIES[0]}"
    else
        SRC_DIR="$TMP_DIR/extracted"
    fi

    rsync -a "$SRC_DIR/" "$WEB_ROOT/"
    rm -rf "$TMP_DIR"
    touch "$MARKER"
fi

chown -R www-data:www-data /var/www/html

echo -e "\e[96m******************************* Starting Apache *******************************\e[0m"
exec "$@"
