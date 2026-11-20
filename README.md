# scalyr-dataset skill

Teaches coding agents how to query **SentinelOne DataSet (Scalyr)** through
`mcp-scalyr-dataset`: field filters, count/facets first, PowerQuery
`group → sort → limit`. Not a second MCP.

| Skill | Job |
|-------|-----|
| `scalyr-dataset` | Author DataSet queries the MCP can run |

**Core principle:** Filter on parsed fields, then aggregate. Never dump
messages through PowerQuery.

## Install

```bash
./install.sh              # symlink into ~/.cursor/skills
./install.sh --copy
./install.sh --project    # copy into ./.cursor/skills
./install.sh --claude
./install.sh --codex
./install.sh --help
```

Restart the agent / start a new chat after install. Never install into
`~/.cursor/skills-cursor/`.

Requires the **mcp-scalyr-dataset** MCP (`DATASET_READ_TOKEN`,
`DATASET_BASE_URL` in mcp.json `env`).

## Usage

```text
@scalyr-dataset
Which paths are throwing the most 500s?
```

```text
@scalyr-dataset
Hourly 5xx by host for the last 6 hours
```

## Layout

```text
scalyr-dataset-skill/
├── README.md
├── install.sh
└── scalyr-dataset/
    ├── SKILL.md
    ├── references/
    └── evals/evals.json
```

## Evals

See `scalyr-dataset/evals/evals.json` (count-then-group, timebucket-in-group,
refuse-star-dump).

## Non-goals

- Log ingest/write or Config APIs
- Splunk SPL / Elasticsearch
- Replacing `mcp-scalyr-dataset`
