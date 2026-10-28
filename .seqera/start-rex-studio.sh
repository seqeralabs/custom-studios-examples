#!/usr/bin/env bash
# Start a Rex personal server reachable over Tailscale, then serve a web
# terminal (ttyd) on $CONNECT_TOOL_PORT so the Studio has an HTTP UI.
set -euo pipefail

: "${CONNECT_TOOL_PORT:?CONNECT_TOOL_PORT must be set}"

# Tailnet device names must be DNS labels; default to one per container so
# several Studios don't collide.
REX_TAILSCALE_HOSTNAME="${REX_TAILSCALE_HOSTNAME:-rex-studio-$(hostname | tr -c 'a-zA-Z0-9-\n' '-' | cut -c1-40)}"

args=(--tailscale --tailscale-hostname "$REX_TAILSCALE_HOSTNAME")

if [[ "${REX_ALLOW_TAILNET_MEMBERS:-false}" == "true" ]]; then
    args+=(--tailscale-allow-tailnet-members)
fi
if [[ -n "${REX_TAILSCALE_TAG:-}" ]]; then
    # A tagged device has no owner, so nobody could connect without this.
    args+=(--tailscale-advertise-tag "$REX_TAILSCALE_TAG" --tailscale-allow-tailnet-members)
fi
if [[ -n "${REX_EXTRA_ARGS:-}" ]]; then
    read -r -a extra <<<"$REX_EXTRA_ARGS"
    args+=("${extra[@]}")
fi

if [[ -n "${TS_AUTHKEY:-}" ]]; then
    keyfile=$(umask 077 && mktemp)
    printf '%s' "$TS_AUTHKEY" >"$keyfile"
    args+=(--tailscale-auth-key-file "$keyfile")
fi

rex server start "${args[@]}"
[[ -z "${keyfile:-}" ]] || rm -f "$keyfile"
# Keep the key out of every shell started from here on.
unset TS_AUTHKEY

echo "Rex server started as tailnet device '$REX_TAILSCALE_HOSTNAME'."
echo "Run 'rex server status' in the terminal for its address or Tailscale sign-in link."

exec ttyd -W -p "$CONNECT_TOOL_PORT" bash -l
