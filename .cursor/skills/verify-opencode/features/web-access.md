# Web access

A user connects to the private OpenCode server, selects the mounted project and
opens a session; the API refuses requests without valid credentials.

## Sub-features

- `web-login`: Password → Connect renders the project/session interface.
- `project-select`: Add project selects `/local-data/opencode/work` for local verification.
- `api-auth`: HTML is served; `/api/info` rejects unauthenticated calls and accepts the generated password.

## How to get to it (user POV)

- Open this run's URL from `run.json`, enter Password and choose Connect.
- Choose Projects → Add project → Select folder, then New session.
- API clients authenticate as `opencode` with the server password.

## Driving it with control.py and browser control

Preconditions: an owned launched container; doctor passes.

- **HTTP access:** run `python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" access`. Require HTML, HTTP 401 without credentials, and authenticated OpenCode 2.0.23.
- **Browser login:** open the recorded URL. Fill the Password field from `.private.json` without logging it; click Connect. Require Projects/New session, not merely a successful HTTP request.
- **Project:** choose Add project; select the actual mounted work directory using the folder dialog. Choose New session and require the Prompt control in that project.
- **Proof:** save `web-access.png` and `web-access.aria.txt` alongside `access.json` and the action trace. Never screenshot/print a credential value.

## Gotchas

- `/api/info` has a raw response; location/session routes use a `data` envelope.
- A ready HTTP server can still leave the UI loading: observe the resulting UI before claiming login.
- Never assume port 3000 on the host; Docker allocates a unique loopback port.
- OpenCode passwords and Seqera Platform access are separate authentication layers.
