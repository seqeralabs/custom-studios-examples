---
name: renovate
description: >
  Run Renovate CLI for dependency updates. Use when checking for outdated dependencies,
  testing Renovate config, or manually triggering dependency update PRs in a repository.
---

# Renovate CLI Skill

Renovate is a dependency update tool that can automatically create PRs for outdated dependencies. This skill covers running Renovate locally via CLI for testing, debugging, and manual updates.

## When to Use Renovate CLI

**Use Renovate CLI when:**
- Testing a `renovate.json` configuration before deploying
- Debugging why Renovate isn't detecting certain dependencies
- Manually triggering dependency checks outside of scheduled runs
- Checking what updates are available without creating PRs (dry-run)
- Validating custom managers or package rules

## Quick Reference

| Task | Command |
|------|---------|
| Dry-run (local, no PRs) | `npx renovate --platform=local --dry-run` |
| Check specific repo | `npx renovate --dry-run owner/repo` |
| Debug dependency detection | `npx renovate --log-level=debug --dry-run` |
| Validate config | `npx renovate-config-validator` |
| See detected dependencies | `LOG_LEVEL=debug npx renovate --dry-run 2>&1 \| grep -E "packageFile\|deps"` |

## Installation

```bash
# Via npx (recommended for one-off runs)
npx renovate --help

# Global install
npm install -g renovate

# Via nix
nix shell nixpkgs#renovate
```

## Common Workflows

### 1. Test Configuration Locally

```bash
# Validate JSON syntax and schema
npx renovate-config-validator renovate.json

# Dry-run to see what Renovate would do
npx renovate --platform=local --dry-run
```

### 2. Debug Dependency Detection

```bash
# Run with debug logging
LOG_LEVEL=debug npx renovate --platform=local --dry-run 2>&1 | tee renovate-debug.log

# Search for specific package
grep -i "packageName" renovate-debug.log

# Check which managers are running
grep "manager" renovate-debug.log
```

### 3. Check for Available Updates

```bash
# Local dry-run shows all detected updates
npx renovate --platform=local --dry-run

# For a GitHub repo (requires token)
RENOVATE_TOKEN=ghp_xxx npx renovate --dry-run owner/repo
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `RENOVATE_TOKEN` | GitHub/GitLab token for API access |
| `LOG_LEVEL` | `debug`, `info`, `warn`, `error` |
| `RENOVATE_CONFIG_FILE` | Path to config file (default: `renovate.json`) |

### Custom Manager Pattern

For tracking versions in non-standard locations (like `ARG` in Dockerfiles):

```json
{
  "customManagers": [
    {
      "customType": "regex",
      "description": "Update VERSION ARG in Dockerfiles",
      "fileMatch": ["(^|/)Dockerfile$"],
      "matchStrings": [
        "#\\s*renovate:\\s*datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\nARG \\w+=(?<currentValue>.*)"
      ],
      "versioningTemplate": "semver"
    }
  ]
}
```

Then annotate your Dockerfile:

```dockerfile
# renovate: datasource=docker depName=myregistry.io/myimage
ARG VERSION=1.2.3
```

## Datasources

| Datasource | Use Case | Example depName |
|------------|----------|-----------------|
| `docker` | Container images | `python`, `nginx` |
| `pypi` | Python packages | `requests`, `pandas` |
| `npm` | Node packages | `lodash`, `express` |
| `github-releases` | GitHub releases | `owner/repo` |
| `github-tags` | GitHub tags | `owner/repo` |

## Error Handling

### "No token provided"

```bash
# Set token via environment
export RENOVATE_TOKEN=ghp_your_token_here
npx renovate owner/repo

# Or use --platform=local for local-only testing
npx renovate --platform=local --dry-run
```

### "Config validation failed"

```bash
# Validate config
npx renovate-config-validator renovate.json

# Check JSON syntax
python3 -c "import json; json.load(open('renovate.json'))"
```

### "No dependencies found"

```bash
# Debug to see what files are being scanned
LOG_LEVEL=debug npx renovate --platform=local --dry-run 2>&1 | grep -E "fileMatch|packageFile"
```

## Integration with GitHub Actions

```yaml
# .github/workflows/renovate.yml
name: Renovate
on:
  schedule:
    - cron: '0 5 * * 1'  # Weekly Monday 5am
  workflow_dispatch:

jobs:
  renovate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: renovatebot/github-action@v41
        with:
          configurationFile: renovate.json
          token: ${{ secrets.RENOVATE_TOKEN }}
```

**Required PAT permissions:**
- `contents: write` - create branches/commits
- `pull-requests: write` - create PRs
- `workflows: write` - update workflow files

## References

- [Renovate Docs](https://docs.renovatebot.com/)
- [Configuration Options](https://docs.renovatebot.com/configuration-options/)
- [Custom Managers](https://docs.renovatebot.com/modules/manager/regex/)
- [Datasources](https://docs.renovatebot.com/modules/datasource/)
- [GitHub Action](https://github.com/renovatebot/github-action)
