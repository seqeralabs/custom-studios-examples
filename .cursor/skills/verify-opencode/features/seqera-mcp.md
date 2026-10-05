# Seqera MCP

A user authenticates the configured remote Seqera server and asks the agent to
search public API documentation through the native MCP integration.

## Sub-features

- `mcp-register`: the location's server list contains `seqera`.
- `mcp-connect`: runtime bearer authentication reports connected.
- `mcp-search`: a real native call to `tools.seqera.search_seqera_api` returns public Studio API suggestions.

## How to get to it (user POV)

- Supply SEQERA_ACCESS_TOKEN through the Studio runtime environment before launch.
- In the project chat, send the public MCP fixture printed by `control.py prompts`.
- API automation submits that same fixture through the production prompt route.

## Driving it with control.py and browser control

Preconditions: doctor passes; launch used `--seqera-token-env TOWER_ACCESS_TOKEN`
or another already-authorized token variable; a usable model.

- **Browser path:** send the exact MCP fixture in Prompt. Save the user action and resulting tool group. It must search public documentation only, never call workspace/data APIs.
- **Observe:** run `python3 "$VERIFY_HELPER" --evidence "$VERIFY_EVIDENCE_DIR" mcp --session-id "$VERIFY_SESSION_ID"` using the observed session ID. Require connected status and a completed native documentation call with nonempty suggestions containing `platform_list_studios`.
- **API path:** omit `--session-id` to drive a separate public documentation turn through the API.
- **Proof:** save `mcp.json`, the real exported tool inputs/results, actions and `seqera-mcp.png`. The assistant's summary alone is insufficient.

## Gotchas

- The v2 config shape is `mcp.servers.seqera`; registration is asynchronous and can initially return an empty list or pending status.
- `needs_auth` proves registration only. Record the attempted `/api/mcp` route and missing token/OAuth prerequisite; do not report a tool pass.
- Runtime config uses `Bearer {env:SEQERA_ACCESS_TOKEN}`; never persist or publish the expanded token.
- Codemode may expose this call through an `execute` tool. Inspect its code and returned JSON. Earlier ReferenceError attempts can be completed tool records without a successful MCP request.
- OAuth needs an interactive callback/forwarding setup and is not established by this bearer-only recipe.
