# OpenCode Studio verification map

This is the maintained verification source for the Studio on `codex/opencode`.
Read it before driving the app. Product source is `.seqera/studio.py`,
`.seqera/opencode.json`, `.seqera/Dockerfile` and the root README; the production
UI/API belongs to the pinned OpenCode binary and can be inspected through its
served `/openapi.json`. `.seqera/test/smoke.py` is a useful startup baseline,
but its manually written file does not prove a model tool turn.

## Baseline preconditions

- Follow the skill's Launch section; use one unique owned volume/loopback port.
- Run doctor before every feature and after any surprise.
- Use public fixture prompts printed by `control.py prompts`, not private data.
- The model must be available. Authenticated MCP needs an authorized token.
- Browser actions use the available browser-control tool and fresh semantic handles.
- Evidence lives in `VERIFY_EVIDENCE_DIR`, outside the repository, and survives cleanup.

## Features

- [Web access](web-access.md): login, project selection, authenticated API and rendered UI.
- [Agent file tools](agent-file-tools.md): real Write/Read calls, completed answer and exact file bytes.
- [Seqera MCP](seqera-mcp.md): runtime bearer connection and real public documentation search.
- [Recovery](recovery.md): stop, independent snapshot readback and fresh-runtime restoration; live Fusion has additional prerequisites.

## Proof and coverage

Capture each user action, visible result and side effect. API assertions and
browser screenshots complement one another; an API pass alone is not UI proof.
Record the entry point used. API and browser submissions use the same production
prompt route, but observing an API-created conversation does not prove browser
submission worked. Maintenance must exercise each feature; call out any separate
entry point or external prerequisite not exercised. OAuth callback forwarding,
arbitrary provider onboarding and abrupt host loss are outside this map's
automated coverage, not implicitly verified by bearer/free-model tests.
