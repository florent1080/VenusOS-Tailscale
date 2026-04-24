#!/bin/sh
# tailscale_connect.sh
# Run once after tailscaled service is started to authenticate with Tailscale.
# Called automatically by the runit finish script, or manually:
#   /data/VenusOS-Tailscale/tailscale_connect.sh

CONF=/data/tailscale/tailscale.conf
BIN=/data/tailscale/bin/tailscale

if [ ! -x "$BIN" ]; then
    echo "ERROR: $BIN not found — run setup install first"
    exit 1
fi

# Read config
AUTHKEY=$(grep '^AUTHKEY=' "$CONF" 2>/dev/null | cut -d= -f2- | tr -d ' \r\n')
HOSTNAME=$(grep '^HOSTNAME=' "$CONF" 2>/dev/null | cut -d= -f2- | tr -d ' \r\n')
HOSTNAME="${HOSTNAME:-venus-van}"

# Wait for tailscaled socket to be ready
for i in $(seq 1 15); do
    if "$BIN" status >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if [ -n "$AUTHKEY" ]; then
    echo "Authenticating with Tailscale (hostname=$HOSTNAME)..."
    "$BIN" up --authkey="$AUTHKEY" --hostname="$HOSTNAME" --accept-routes
else
    echo "No AUTHKEY set in $CONF"
    echo "Edit the file and re-run this script, or run: tailscale up"
fi

echo "Tailscale status:"
"$BIN" status 2>/dev/null || echo "(tailscaled may still be starting)"
