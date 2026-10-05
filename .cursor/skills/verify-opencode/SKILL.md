---
name: verify-opencode
description: Verify the OpenCode Studio web UI, native agent file tools, Seqera MCP and session recovery after changes to this Studio, its image or configuration.
---

# Verify OpenCode Studio

Read [features/README.md](features/README.md) first. The primary surface is
OpenCode's web UI. The helper drives the same production HTTP routes used by
that UI; browser checks prove the rendered interaction too. This repository
wraps pinned OpenCode 2.0.23, rather than implementing its UI or API.

## Launch

From the repository root, with Docker running:

```bash
export VERIFY_EVIDENCE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/opencode-verification.XXXXXX")"
export VERIFY_HELPER="$PWD/.cursor/skills/verify-opencode/scripts/control.py"
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.14 \
  -t opencode-verification:local .seqera
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" launch \
  --image opencode-verification:local
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" doctor
```

`launch` allocates a unique named volume, labelled container, random loopback
port and generated password. It records the URL in `run.json`; credentials
are in mode-0600 `.private.json` and are removed by cleanup. Readiness requires
authenticated `/api/info`, the real OpenCode process and matching image/source
identity. Never drive the user's existing localhost or Platform Studio.

For the authenticated MCP feature, add `--seqera-token-env TOWER_ACCESS_TOKEN`
to `launch`, using an already-authorized Seqera token in that environment
variable. The value is passed through Docker's environment, never a command
argument. Do not retrieve a model key from an old chat or 1Password item.
The default model is `opencode/big-pickle`; `launch --model` can select another
available model. Only public synthetic fixtures may go to the provider.

All server features use one owned, long-lived instance, serially. `recover`
stops that writer before replacing it with a fresh container on its volume.
Two runs may coexist because their ports, credentials, volumes and labels
differ. Never share an instance directory between running containers/Studios.

Teardown, including after a failed iteration:

```bash
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" cleanup
```

## Doctor

```bash
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" doctor
```

This read-only check requires our run label, image ID, volume and loopback
port, authenticated API, pinned version, source hashes, and `/proc/<api-pid>/comm`
equal to `opencode`. Run it before the first drive, after an unexpected result,
and immediately after recovery. A healthy process does not repair a wedged
browser: reload the known run URL, or clean up and relaunch if that fails.
Never infer liveness from a log or use an existing preview without ownership.

## Drive

```bash
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" access
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" file-turn
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" mcp
python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" recover
```

These commands check HTTP login, execute an actual model Write/Read turn,
execute a public Seqera MCP documentation search, and compare complete
transcripts/file bytes after restoration. `mcp` exits with an explicit unmet
authentication prerequisite when the server reports `needs_auth`; registration
is not an authenticated-tool pass. Free model availability is external state;
provider errors are failures, not proof of a model turn.

For browser-driven turns, use `file-turn --session-id` or `mcp --session-id`
with the session ID from the observed browser URL. These modes observe the
user-submitted prompt and validate its real effects without submitting again.
Use the exact public prompts printed by `control.py prompts`.

Use the available browser-control tool for UI actions. Stable handles are
`Password`, `Connect`, `Projects`, `Add project`, `Select folder`, `New session`,
`Prompt`, `Send`, and the rendered session title. Re-observe after each action;
do not encode numeric accessibility IDs or coordinates into a reusable recipe.
Open the URL from `run.json`, enter the password from `.private.json` without
printing it, connect, select `/local-data/opencode/work`, then send a fixture.
The matching feature files specify assertions and evidence.

## Evidence

The evidence directory is outside the checkout and survives cleanup. Keep
`actions.jsonl`, `doctor.json`, feature reports, full synthetic session exports,
the independently copied SQLite snapshot and marker, and browser screenshots
plus accessibility snapshots. Record both the action and resulting state.
Capture browser artifacts through the browser-control tool into this directory;
show the relevant screenshot in the final response.

No internal setters, hand-written marker fixtures, test-only API routes or
mocked model/MCP results count as native-tool proof. Require completed tool
results, a completed assistant answer, exact file bytes, and a second read of
saved state. Inspect real tool results rather than trusting the assistant's
description. A failed codemode attempt is not a successful MCP call.

`OPENCODE_LOCAL_STORAGE=1` only bypasses the Fusion mount guard. It does not
disable network requests: OpenCode can fetch model metadata and contact MCP;
`file-turn`/`mcp` intentionally contact the provider and Seqera. Local recovery
proves the backup mechanism, not cloud consolidation or abrupt host-loss safety.
Live Fusion prerequisites and the independent-cloud readback procedure are in
[recovery.md](features/recovery.md). Never promote a missing prerequisite to a
passed feature, or reuse historical artifacts as a fresh live observation.

## Cleanup

`cleanup` stops/removes only containers bearing this run's label and removes
only this run's volume. It retains proof files and writes `cleanup.json` with
resource absence and evidence-existence checks. It removes the private password
file, not the evidence directory. Do not use `pkill`, container-name globs,
Docker prune, or delete the user's Studio/checkpoints. Close only browser tabs
created for this run after saving their proof. Clean failed launches too.

## Helpers

`scripts/control.py` is executable, Python-standard-library-only, and requires
the Docker CLI. Its `launch`, `doctor`, `access`, `file-turn`, `mcp`, `recover`,
`cleanup`, and `prompts` subcommands are invoked above; inspect
`python3 "$VERIFY_HELPER" --help` for options. Every feature command reruns
doctor. Do not invoke a feature after cleanup: launch a new isolated run.

Keep the map current with `/maintain-verification-skill`. Read each feature
from source, drive every feature, retain evidence, and edit only this skill's
directory during maintenance.
