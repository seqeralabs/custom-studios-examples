#!/usr/bin/env bash
set -euo pipefail
umask 077
cd /app
# Lock locally, never on Fusion: only one writer on this host may open a store.
# Separate Studios must use separate PI_INSTANCE values (no distributed lock).
storage_dir=$(node --input-type=module -e 'import { storagePaths } from "./storage.mjs"; console.log((await storagePaths()).directory)')
lock_id=$(printf '%s' "$storage_dir" | sha256sum | cut -d ' ' -f 1)
exec flock --nonblock --no-fork --conflict-exit-code 73 "/tmp/pi-durable-${lock_id}.lock" node /app/server.mjs
