# MCP tools — mcp-scalyr-dataset

Read-only stdio MCP. Secrets: `DATASET_READ_TOKEN` + `DATASET_BASE_URL` in
mcp.json `env`. Never a project `.env`.

## Which tool

| Intent | Tool | Endpoint |
|--------|------|----------|
| How many matches? | `count_logs` | `POST /api/numericQuery` |
| Top values of one field | `list_log_facets` | `POST /api/facetQuery` |
| A page of events | `search_logs` | `POST /api/query` |
| Aggregate table | `power_query` | `POST /api/powerQuery` |

Recommended order: facets or count → tight `search_logs` **or** `power_query`.

## Caps (server v1)

| Cap | Value |
|-----|-------|
| Default window | `15m` → `0h` (API PowerQuery default is 24h — do not assume 24h) |
| `search_logs` page | default 25, hard max 50 |
| Filter length | 1000 chars |
| PowerQuery query | 2000 chars (API allows 5000) |
| PowerQuery display rows | first 30 |
| Facet values | default 20, max 50 |
| Priority | `low` default (more CPU budget than `high`) |

`search_logs` snapshots relative windows to epoch-ms. Page 2 must reuse those
absolute times plus `continuation_token`. `more: yes` only when the page is
full. Never auto-follow.

## Filter language (Search + PowerQuery line 1)

From [Query Language](https://app.scalyr.com/help/query-language):

- Bare `error` searches `message contains 'error'` — slower, noisier
- Prefer `status=404`, `severity >= 5`, `logfile contains 'access_log'`
- Adjacent terms are AND; quote punctuation
- `contains` / `matches` need a field after the first PowerQuery pipe
- `* contains` / `* matches` only on the **initial** PowerQuery filter, and
  they are not optimized — avoid

Good: `logfile contains 'api' status >= 500 serverHost contains "prod"`
Bad: `*`
Bad: `"500"` as the whole filter

## `power_query` MCP allowlist

Query must contain at least one of:

`| group` `| sort` `| count(` `| filter` `| let` `| join` `| timebucket`

Rejected before HTTP: empty query, `| columns …` with no allowed stage.

JSON body cannot use single quotes; the MCP client sends the string — write
double quotes in the query (`serverHost contains "frontend"`).

## Empty / errors

| Signal | Meaning |
|--------|---------|
| `No matching events.` | Filter/window miss — tighten or widen deliberately |
| `INVALID` | Schema, empty filter, or illegal PowerQuery pipe |
| `UPSTREAM_AUTH` | Token/base URL |
| `RATE_LIMIT` | CPU leaky bucket — wait / narrower filter / stay on `low` |
