# Agent file tools

A real model writes a public marker in the mounted project, reads it using
OpenCode's native tools, and returns a completed answer.

## Sub-features

- `file-write`: native Write creates `verification-proof.txt` with exact bytes.
- `file-read`: native Read returns the same marker.
- `answer-complete`: the assistant finishes with `Verified opencode-verification-proof`.

## How to get to it (user POV)

- Select the work project, choose New session, enter the file fixture in Prompt and choose Send.
- Automation clients create a session with `/api/session` and submit through `/api/session/{id}/prompt`.

## Driving it with control.py and browser control

Preconditions: doctor passes; a usable model; the public fixture from `control.py prompts`.

- **Browser submission:** paste the exact file fixture into Prompt and choose Send. Wait for the completed answer. Capture the prompt and expanded Used 2 Write, Read group. Read the session ID from the observed URL.
- **Observe browser effects:** run `python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" file-turn --session-id "$VERIFY_SESSION_ID"`. It must not submit another turn.
- **API entry:** on a separate session, omit `--session-id` to exercise the production API submission path. Keep both entry points' action/evidence distinct.
- **Proof:** require completed Write and Read tool results, the completed exact assistant answer, and exact bytes read from the container's work directory. Retain the exported transcript, `file-turn.json`, action trace and a browser screenshot.

## Gotchas

- A manual `docker exec` write or matching text in the user's prompt is not proof.
- Wait for the assistant `finish: stop` with `time.completed` and the final idle event before exporting a recovery baseline.
- Tool `state.status: completed` and actual side effects are authoritative; do not infer execution from the v2 `executed` flag.
- Provider availability/region restrictions are external prerequisites. Report the error and rerun doctor; never silently mark a failed model as passed.

The marker check allows one final LF from the native Write tool. Recovery compares the actual pre-stop bytes exactly.
