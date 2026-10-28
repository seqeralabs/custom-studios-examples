#!/usr/bin/env bash
# Start a Rex personal server, then serve a web terminal (ttyd) on
# $CONNECT_TOOL_PORT so the Studio has an HTTP UI.
#
# Remote access, pick one or both:
#   - Loopback HTTP on 127.0.0.1:$REX_LOCAL_PORT (default). Reach it through a
#     Studio SSH tunnel, which Seqera authenticates with your Platform SSH key.
#   - Built-in Tailscale, when REX_TAILSCALE=true.
set -euo pipefail

: "${CONNECT_TOOL_PORT:?CONNECT_TOOL_PORT must be set}"

args=()

REX_LOCAL_PORT="${REX_LOCAL_PORT:-7297}"
if [[ "$REX_LOCAL_PORT" != "off" ]]; then
    # Anonymous is safe only because the listener is bound to loopback: the
    # Studio's SSH proxy is the only way in from outside the container.
    args+=(--extra-listen "127.0.0.1:$REX_LOCAL_PORT" --allow-anonymous)
fi

if [[ "${REX_TAILSCALE:-false}" == "true" ]]; then
    # Tailnet device names must be DNS labels; default to one per container so
    # several Studios don't collide.
    REX_TAILSCALE_HOSTNAME="${REX_TAILSCALE_HOSTNAME:-rex-studio-$(hostname | tr -c 'a-zA-Z0-9-\n' '-' | cut -c1-40)}"
    args+=(--tailscale --tailscale-hostname "$REX_TAILSCALE_HOSTNAME")

    if [[ "${REX_ALLOW_TAILNET_MEMBERS:-false}" == "true" ]]; then
        args+=(--tailscale-allow-tailnet-members)
    fi
    if [[ -n "${REX_TAILSCALE_TAG:-}" ]]; then
        # A tagged device has no owner, so nobody could connect without this.
        args+=(--tailscale-advertise-tag "$REX_TAILSCALE_TAG" --tailscale-allow-tailnet-members)
    fi
    if [[ -n "${TS_AUTHKEY:-}" ]]; then
        keyfile=$(umask 077 && mktemp)
        printf '%s' "$TS_AUTHKEY" >"$keyfile"
        args+=(--tailscale-auth-key-file "$keyfile")
    fi
fi

if [[ -n "${REX_EXTRA_ARGS:-}" ]]; then
    read -r -a extra <<<"$REX_EXTRA_ARGS"
    args+=("${extra[@]}")
fi

rex server start "${args[@]}"
[[ -z "${keyfile:-}" ]] || rm -f "$keyfile"
# Keep the key out of every shell started from here on.
unset TS_AUTHKEY

echo "Rex server started. Run 'rex server status' in the terminal for details."

exec ttyd -W -p "$CONNECT_TOOL_PORT" bash -l
