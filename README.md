# Pi Durable Studio Environment

This branch runs [Pi Durable](https://earendil.com/posts/pi-durable/) as a web coding assistant in Seqera Platform. Conversation checkpoints, transcripts and generated files live on a writable Fusion data-link mount.

> This is a branch of [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples). Each branch contains a different custom Studio configuration. See `master` for the available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios → Add Studio** in Seqera Platform.
2. Select **Git repository** and enter `https://github.com/seqeralabs/custom-studios-examples`.
3. Select branch **`codex/pi-durable`**.
4. Select a compatible compute environment. Configure the Studio container repository and push credentials if your workspace does not already have them.
5. Under **Mount data**, select a dedicated, writable data link. Its compute credentials must be able to read and write the backing storage.
6. Under **General config**, set `PI_DATA_LINK` to the mount's displayed path, such as `/workspace/data/agent-state`. Set `PI_PROVIDER`, `PI_MODEL` and the matching provider key using the table below.
7. To enable Seqera MCP, also set `SEQERA_MCP_TOKEN` to a valid Platform access token in the runtime environment.
8. Keep the Studio **private**, click **Add**, then **Start**.

`PI_DATA_LINK` must point to an existing mount beneath `/workspace/data`. The app refuses absent mounts, ordinary local filesystems and unwritable paths. Data links must be selected in Platform; they cannot be declared in `studio-config.yaml`.

### Alternative: Build a Container

```bash
docker build --platform=linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.14 \
  -t pi-durable-studio .seqera
```

Push that image to a registry accessible to your compute environment, then select **Prebuilt container image** when adding the Studio. Apply the same data mount and environment settings. This branch does not publish a pre-built image automatically.

For Wave builds, use `.seqera` as the build context. It contains only app sources, package files and small tests; keep credentials and local dependencies outside that directory.

## Features

- Pi Durable, Pi AI and Chord pinned to **1.0.2** on Node.js **22.22.3**.
- Browser chat, queued follow-up messages, steering and live tool state.
- Read, write, edit and bash tools operating in the persistent working directory.
- OpenAI, Anthropic and OpenRouter providers.
- Seqera MCP tools for API discovery, workflow operations, nf-core modules and data tools.
- JSONL checkpoints and transcripts; repeated submission IDs are deduplicated.
- Connect client **0.14**, with the app listening on `CONNECT_TOOL_PORT`.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PI_DATA_LINK` | Required | Existing writable mount, e.g. `/workspace/data/agent-state` |
| `PI_INSTANCE` | `pi-durable` | Subdirectory; use a unique value for each independent agent |
| `PI_PROVIDER` | `openai` | `openai`, `anthropic` or `openrouter` |
| `PI_MODEL` | Required | Model ID supported by the pinned provider catalog |
| `OPENAI_API_KEY` | Unset | Required for OpenAI, e.g. model `gpt-6.1-sol` |
| `ANTHROPIC_API_KEY` | Unset | Required for Anthropic |
| `OPENROUTER_API_KEY` | Unset | Required for OpenRouter, e.g. model `openai/gpt-6.1-sol` |
| `SEQERA_MCP_TOKEN` | Unset | Platform access token for Seqera MCP; falls back to `TOWER_ACCESS_TOKEN` |
| `SEQERA_MCP_ENABLED` | Enabled when a token is available | Set `0` to disable the MCP connection |
| `CONNECT_TOOL_PORT` | Set by Platform | HTTP listening port |

Without a provider key, the UI opens for inspection but chat and automatic task resumption are disabled. Supply keys through the Studio runtime environment. Coding tools run with the Studio user's permissions and can access mounted files and environment variables, so grant access only to trusted users.

Changing the provider or model at launch updates subsequent requests. Unfinished requests retain their recorded model; restart with the original provider while they exist.

## Seqera MCP

The Studio connects to [Seqera MCP](https://seqera.io/mcp/) at
`https://mcp.seqera.io/mcp` using streamable HTTP. Supply a Platform access token
through `SEQERA_MCP_TOKEN` (or `TOWER_ACCESS_TOKEN`) in the Studio runtime
environment. Keep it out of the repository, Docker build context and data link.
The browser shows connection state and tool count; `/api/mcp` returns the same
status without credentials.

[Pi's MCP documentation](https://pi.dev/docs/latest/mcp) describes the coding
agent's `.pi/mcp.json` configuration. This app uses Pi Durable 1.0.2, which does
not load that extension. It uses the official MCP SDK to register discovered
server tools as durable tools named `mcp__seqera__<tool>` instead.

Try: **Use Seqera MCP to find the API for listing workflows. Do not launch or
modify anything.** The agent should call `mcp__seqera__search_seqera_api`.
`call_seqera_api` and `call_data_tool` can perform remote changes as well as
reads; ask explicitly for the action you intend and keep the Studio private.
All MCP tools use the unsafe replay policy: an interrupted call is reported to
the agent rather than automatically repeated, avoiding duplicate remote writes.

Tool discovery happens at startup. With no token, MCP remains unconfigured;
with an invalid token or connection failure, it reports an error while the
coding assistant remains available. Update the environment and restart the
Studio to reconnect. Model-provider credentials are separate from MCP auth.

A read-only live check makes an authenticated discovery call without a model:

```bash
node scripts/verify-mcp.mjs
```

Run `npm ci` in `.seqera` first and supply the token through your runtime
environment. The output contains connection status and tool names, not the
token or account/workspace results.

## Persistence and Demo

For the example mount above, the application creates:

```text
/workspace/data/agent-state/pi-durable/
├── state/   # JSONL commits, transcript and task/document sidecars
└── work/    # Coding-tool working directory
```

JSONL avoids SQLite WAL/shared-memory locking on Fusion. Every append, including the commit marker, is flushed before acknowledgement. Pi Durable can recover task checkpoints; interrupted tool calls follow the tool's replay policy. JSONL loads the stored history into memory, so size the Studio for your conversation history.

To demonstrate persistence:

1. Send: **Use the write tool to create `demo.txt` containing exactly `hello from Pi Durable`, then read it back.** Wait for the final assistant answer and the tool result.
2. Stop the **Studio** in Platform and wait for **stopped**. The UI's **Stop agent** button aborts the current run; it does not stop the Studio.
3. In Data Explorer, confirm that `pi-durable/state/` contains non-empty JSONL files and `pi-durable/work/demo.txt` contains the marker.
4. Start the same Studio with the same data link and `PI_INSTANCE`. Confirm the prior conversation is present, then ask the agent to read `demo.txt` again.

**Use one writer per instance directory.** A local `flock` prevents two app processes on the same host; it is not a distributed lock. Stop the old Studio completely before starting another Studio with the same instance directory.

[Fusion's cloud-storage boundary](https://docs.seqera.io/platform-cloud/troubleshooting_and_faqs/studios_troubleshooting#data-and-storage) matters: writes are uploaded in chunks and consolidated as complete cloud objects when the writing Studio stops. A local `fsync` or app-process restart does not prove survival of a lost Fusion host. This demo verifies clean stop/restart persistence; abrupt host-loss recovery remains unverified.

## Local Testing

```bash
cd .seqera
npm ci
npm test
```

The tests make no provider requests. They cover mount refusal, HTTP write protection, restart identity, OpenRouter configuration, coding and MCP tool turns, paginated MCP discovery, authentication failure handling, and SIGKILL checkpoint recovery with request deduplication.

For a local preview with chat disabled:

```bash
docker volume create pi-durable-local
docker run --rm --platform=linux/amd64 \
  -p 127.0.0.1:3000:3000 \
  --mount source=pi-durable-local,target=/local-data \
  -e PI_LOCAL_STORAGE=1 -e PI_DATA_LINK=/local-data \
  -e PI_MODEL=gpt-6.1-sol \
  --entrypoint /app/start.sh pi-durable-studio
```

Open <http://localhost:3000>. `PI_LOCAL_STORAGE=1` is only for local tests; keep it unset in Platform. To enable local chat, use Docker's `--env-file` with a private file outside the build context and version control. Reuse the volume when restarting the container.

### Scripted Live Checks

The optional `scripts/` checks use Studio SSH and the Seqera `tw` CLI. They save evidence locally; no deployment details or live evidence are included in this branch. Pass `--tw /path/to/tw` if another program shares that command name.

```bash
mkdir -p evidence
python3 scripts/verify-model.py submit \
  --workspace YOUR_ORG/YOUR_WORKSPACE --studio-id YOUR_STUDIO_ID \
  --ssh-key ~/.ssh/id_ed25519 --evidence evidence/model.json
python3 scripts/verify-live.py record \
  --workspace YOUR_ORG/YOUR_WORKSPACE --studio-id YOUR_STUDIO_ID \
  --ssh-key ~/.ssh/id_ed25519 --evidence evidence/live.json
```

The model check makes one real, billable submission that writes `live-model-proof.txt` and waits for the final assistant answer. The live check confirms HTTP health, app process liveness, a FUSE mount and JSONL file hashes.

After the Studio reaches **stopped**, compare independent cloud downloads:

```bash
python3 scripts/verify-cloud.py \
  --live-evidence evidence/live.json --model-evidence evidence/model.json \
  --workspace-id YOUR_WORKSPACE_ID --data-link-id YOUR_DATA_LINK_ID \
  --credentials-id YOUR_CREDENTIAL_ID --output evidence/cloud.json
```

This uses `TOWER_ACCESS_TOKEN` for Platform authentication and compares every JSONL file and both markers. Start the Studio again, then run `verify-live.py verify` and `verify-model.py verify` with their original arguments. The checks compare prior commits, marker contents and the complete parsed transcript without another provider request.

## References

- [Pi Durable introduction](https://earendil.com/posts/pi-durable/)
- [Seqera Studios: Example environments](https://docs.seqera.io/platform-cloud/studios/example-studios)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Data and storage troubleshooting](https://docs.seqera.io/platform-cloud/troubleshooting_and_faqs/studios_troubleshooting#data-and-storage)
