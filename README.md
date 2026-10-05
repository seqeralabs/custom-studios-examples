# OpenCode Studio Environment

Run [OpenCode v2](https://opencode.ai/v2/docs/) in Seqera Studios with its built-in web UI and [Seqera MCP](https://docs.seqera.io/platform-cloud/seqera-mcp/overview). Project files live on a writable Fusion data link. The SQLite session database runs locally and is backed up to the data link using SQLite's online backup API.

> Each branch of [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) contains a separate custom Studio. See `master` for the available examples.

## Launch from Git Repository

1. In Seqera Platform, select **Studios → Add Studio → Git repository**.
2. Enter `https://github.com/seqeralabs/custom-studios-examples` and select branch **`codex/opencode`** after publishing this branch.
3. Select a compatible compute environment and configure the Studio image repository and push credentials if required.
4. Under **Mount data**, select a dedicated, writable data link.
5. Set `OPENCODE_DATA_LINK` to the displayed mount path, such as `/workspace/data/agent-state`.
6. Set `OPENCODE_SERVER_PASSWORD` to a strong password through the runtime environment. Supply a model provider API key and optionally `OPENCODE_MODEL`. To authenticate Seqera MCP without forwarding an OAuth callback port, set `SEQERA_ACCESS_TOKEN` to your Seqera Platform personal access token.
7. Keep the Studio **private**, then select **Add → Start**. Open the Studio and log into OpenCode with username **`opencode`** and your server password.
8. In the web UI, choose **Projects → Add project**, select `/workspace/data/agent-state/opencode/work`, then create a session in that project.

Data links must be selected in Platform; `studio-config.yaml` cannot declare them. Startup refuses missing, unwritable or ordinary local paths unless local test mode is explicitly enabled.

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENCODE_DATA_LINK` | Required | Existing writable data-link path beneath `/workspace/data` |
| `OPENCODE_INSTANCE` | `opencode` | Separate directory for each independent Studio |
| `OPENCODE_SERVER_PASSWORD` | Required | OpenCode web/API password |
| `SEQERA_ACCESS_TOKEN` | Unset | Seqera MCP bearer token; otherwise OpenCode uses OAuth |
| `OPENCODE_MODEL` | OpenCode default | Provider/model ID; overrides the persisted model at launch |
| `OPENAI_API_KEY` | Unset | OpenAI model access |
| `ANTHROPIC_API_KEY` | Unset | Anthropic model access |
| `OPENROUTER_API_KEY` | Unset | OpenRouter model access |
| `OPENCODE_BACKUP_INTERVAL` | `60` | Seconds between database backups; minimum 5 |
| `CONNECT_TOOL_PORT` | Set by Platform | Web/API port; 3000 for local tests |

OpenCode **2.0.23**, Node.js **22.22.3** and Connect **0.14** are pinned in the Dockerfile. Use the runtime environment or OpenCode's provider connection UI for credentials. Keep secrets outside the build context and version control. The agent has access to the container environment and mounted files; only trusted users should access this Studio.

## Seqera MCP

The bundled global `opencode.json` uses the [v2 configuration shape](https://opencode.ai/v2/docs/mcp-servers/):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "seqera": {
        "type": "remote",
        "url": "https://mcp.seqera.io/mcp"
      }
    }
  }
}
```

With `SEQERA_ACCESS_TOKEN`, startup adds `oauth: false` and `Authorization: Bearer {env:SEQERA_ACCESS_TOKEN}` through `OPENCODE_CONFIG_CONTENT`. The token value is never written into the configuration file. Existing configuration and other MCP servers are preserved.

Without a token, authorize Seqera using OpenCode's MCP connection UI. OAuth's loopback callback runs on the Studio host, so remote authorization may require an SSH port forward. Verify the connection reports **connected** before asking for a read-only operation such as listing your available workspaces. MCP configuration alone does not establish authenticated access.

The persisted config is at `<data-link>/<instance>/config/opencode/opencode.json`. Edit it to add other MCP servers or change defaults. It is seeded only on first startup. Project config can override global settings according to [OpenCode's precedence rules](https://opencode.ai/v2/docs/config).

## Persistence

For the example mount above:

```text
/workspace/data/agent-state/opencode/
├── work/                        # Project files, directly on Fusion
├── config/opencode/             # Editable global config
└── state/opencode.db            # Consistent session database backup
```

The live database, WAL, cache, logs and runtime service files remain on local storage under `/var/lib/opencode-studio`. Startup restores the saved database when no local database exists. Every 60 seconds and on clean shutdown, SQLite creates a consistent local backup including committed WAL contents, checks its integrity, then replaces the saved backup. Stop with enough time for shutdown and the final backup; local Docker tests use a 60-second stop timeout.

The saved database may contain conversations, provider credentials and MCP authentication state. Restrict access to the backing data link and cloud prefix. Git undo snapshots, caches and other files outside the database are local and are not restored from this backup.

Use **one Studio per instance directory**. The writer lock prevents a second process on the same host; it is not a distributed lock. Stop the old Studio completely before reusing its instance in another Studio.

[Fusion uploads and consolidation](https://docs.seqera.io/platform-cloud/troubleshooting_and_faqs/studios_troubleshooting#data-and-storage) require a separate cloud readback check. Local SQLite backups and process restarts do not establish survival of an abruptly lost Fusion host. A killed process can lose database changes since the latest backup if its local storage is also lost; interrupted agent runs are not automatically replayed by this wrapper.

### Studio acceptance check

1. Confirm Seqera MCP is connected and can perform a read-only workspace listing.
2. Ask the agent to write `demo.txt` containing exactly `hello from OpenCode`, then read it back. Wait for the completed assistant answer.
3. Stop the **Studio** in Platform and wait for **stopped**. Check that shutdown reported `Final OpenCode database backup saved`.
4. In Data Explorer, independently download `opencode/state/opencode.db` and `opencode/work/demo.txt`. Confirm the marker and run `PRAGMA quick_check` against the downloaded database.
5. Start the same Studio with the same data link and instance. Confirm the completed conversation is present and the agent can read the marker again.

An image build or local test does not prove this live acceptance check passed.

## Build and Local Testing

```bash
python3 -m unittest discover -s .seqera/test -v
docker build --platform=linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.14 \
  -t opencode-studio .seqera
python3 .seqera/test/smoke.py opencode-studio
```

The unit tests cover WAL backup/restoration, failed-backup preservation, local database recovery, mount validation and user-config preservation. The container smoke test checks web HTML, API authentication, Seqera MCP registration, password-free logs, and session/file recovery in a fresh container. It uses a generated test password and makes no model requests. Seqera MCP authorization and live Fusion storage still require the Studio acceptance check above.

Create a private environment file **outside this repository** containing `OPENCODE_SERVER_PASSWORD` and any provider keys. Start a local preview:

```bash
docker volume create opencode-local
docker run --rm --platform=linux/amd64 \
  -p 127.0.0.1:3000:3000 --stop-timeout 60 \
  --mount source=opencode-local,target=/local-data \
  --env-file /absolute/path/to/private-opencode.env \
  -e OPENCODE_LOCAL_STORAGE=1 -e OPENCODE_DATA_LINK=/local-data \
  --entrypoint python3 opencode-studio /app/studio.py
```

Open <http://localhost:3000>. Login uses `opencode` and the password in your environment file. Reuse the volume with a fresh container to check database restoration. Keep `OPENCODE_LOCAL_STORAGE` unset in Platform. No pre-built image is published automatically.

To build with Wave, use `.seqera` as the context:

```bash
wave -f .seqera/Dockerfile --context .seqera \
  --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## References

- [OpenCode v2 web server](https://opencode.ai/v2/docs/cli/web)
- [OpenCode v2 configuration](https://opencode.ai/v2/docs/config)
- [OpenCode v2 MCP servers](https://opencode.ai/v2/docs/mcp-servers/)
- [Seqera MCP authentication](https://docs.seqera.io/platform-cloud/seqera-mcp/overview)
- [Seqera Studios: Add from Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
