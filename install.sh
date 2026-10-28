#!/bin/sh
# Installs rex-studio to ~/.local/bin.
#
#   curl -fsSL https://raw.githubusercontent.com/seqeralabs/custom-studios-examples/rex/install.sh | sh
#
# REX_STUDIO_URL overrides where the script is downloaded from.
set -eu

url=${REX_STUDIO_URL:-https://raw.githubusercontent.com/seqeralabs/custom-studios-examples/rex/bin/rex-studio}
dir=$HOME/.local/bin
missing=0

need() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "ok       $1"
  else
    echo "missing  $1: $2"
    missing=1
  fi
}

case $(uname -s) in
  Darwin)
    need jq "brew install jq"
    need curl "brew install curl"
    need ssh "comes with macOS; check that /usr/bin is on PATH"
    need rex "install Rex for Mac from https://www.superlogical.com/rex/docs and put its rex CLI on PATH"
    ;;
  *)
    need jq "install jq with your package manager, e.g. apt install jq"
    need curl "install curl with your package manager, e.g. apt install curl"
    need ssh "install the OpenSSH client, e.g. apt install openssh-client"
    need rex "install the rex CLI, see https://www.superlogical.com/rex/docs/linux/server-modes"
    ;;
esac

command -v curl >/dev/null 2>&1 || {
  echo "curl is needed to download rex-studio" >&2
  exit 1
}

mkdir -p "$dir"
tmp=$(mktemp "$dir/.rex-studio.XXXXXX")
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$url" -o "$tmp"
chmod 755 "$tmp"
mv "$tmp" "$dir/rex-studio"
trap - EXIT
echo "installed $dir/rex-studio"

case ":$PATH:" in
  *":$dir:"*) ;;
  *) echo "warning: $dir is not on PATH; add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

if [ "$missing" -ne 0 ]; then
  echo "install the missing tools above, then run: rex-studio doctor"
fi
