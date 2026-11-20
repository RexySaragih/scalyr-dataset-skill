# PowerQuery cookbook

Source of truth: [Help: PowerQueries](https://app.scalyr.com/help/power-queries),
[API powerQuery](https://app.scalyr.com/help/api),
[Best practices](https://support.dataset.com/hc/en-us/articles/360058669834-PowerQueries-Best-Practices).

## Canonical shape

```text
<field-filter>                 // everything before first | is the initial search
| group aggs by keys [, timestamp=timebucket('5m')]
| filter <computed column>
| sort -metric
| limit 30
```

Put as much as possible on line 1. `| filter` after `group` is for
**computed** rows (`ct > 100`), not a second copy of the same search.

After `group` or `columns`, only fields those commands created still exist.

## Commands (official)

| Command | Use |
|---------|-----|
| (initial filter) | Search language; no `filter` keyword needed |
| `\| filter` | Later: keep rows of a table |
| `\| let` | Add derived columns (`isError = status>=500 && status<=599`) |
| `\| group` | Aggregates; without `by` → one row |
| `\| sort` / `\| limit` | Top-N; sort **before** limit; sort **last** otherwise |
| `\| join` | Must start with `\| join` and set `on` |
| `\| parse` | Last resort — ingest parsers are faster |
| `\| columns` | Rename/select **after** group; never as the only stage (MCP dump guard) |
| `\| union` / `\| lookup` / `\| transpose` | Official; MCP v1 may reject unless another allowlisted stage is present |

MCP v1 allowlist: `group`, `sort`, `count(`, `filter`, `let`, `join`, `timebucket`.

## `timebucket` is a function

Not a pipe command. Name the field `timestamp` for human-readable times:

```text
status >= 500
| group count() by serverHost, timestamp=timebucket('1h')
```

Forms: `timebucket()`, `timebucket('5m')`, `timebucket(timestamp, '5m')`,
or `timebucket(8)` to split the window into 1–500 buckets. **>500 buckets
fails** — coarsen (`1h`/`1d`) on long ranges.

## Aggregations that beat raw `count()`

```text
| group errors=count(status>=500), rate=count(status>=500)/count(), p95=p95(latency) by uriPath
| group uniques=estimate_distinct(ip) by serverHost
| group latest=newest(status) by serverHost
```

`newest`/`oldest` cannot follow `group`/`sort`/`limit`. `estimate_distinct` is
HyperLogLog (~1.3% error) — use it instead of `group by ip`.

`count(expr)` does not need `where`. Other aggs use `where`:
`any(serverHost where status=500)`.

## Official performance tips

1. Filter **before** parse/group/sort
2. Field filters (`status=404`) beat `"404"`
3. Few, low-cardinality `by` keys (path, not URL+query)
4. Defer `lookup` until after `group`
5. Joins left-to-right; **smallest unique-key subquery first**; filters
   **inside** subqueries
6. Refine on a short window, then widen
7. Stay `priority=low`

KB rewrite: fold `|filter (status==500)` into line 1; drop `$` prefixes and
implied `&&`.

## Completeness limits (do not ignore)

| Limit | Effect |
|-------|--------|
| 100,000 rows | Final **and** every intermediate `group` table |
| No `group` / no `limit` | DataSet returns first **1,000** rows |
| `omittedEvents` | Memory drop; stats can **undercount** |
| Later `join` subqueries | Can omit **without** reporting |
| CPU `cpuUsage` | Milliseconds; 429 + `cpuUsageSecondsToWait` |
| API query length | 5,000 chars (MCP caps 2,000) |

If results look thin: tighter initial filter, fewer `by` keys, coarser
`timebucket`, then `| sort -x | limit 30`.

## Join

```text
| join
  start = (message contains "start_transaction" | columns timestamp, transaction_id),
  end   = (message contains "end_transaction"   | columns timestamp, transaction_id, elapsed_time)
  on transaction_id
```

Without `|`, DataSet searches the word “join”. Unset `on` glues row 1 to row 1.
Default `inner` is **first match**, not SQL inner.

## Copy-paste recipes

Top-N errors:

```text
logfile contains "access_log" status >= 500
| group errors=count(), p95=p95(latency) by uriPath
| sort -errors
| limit 30
```

Time series:

```text
status >= 500
| group count(), p90(latency) by timestamp=timebucket('5m')
```

Post-agg (search language cannot do this):

```text
outcome_result="SUCCESS" country=*
| group countries=estimate_distinct(geographicalContext_country) by actorAlternateId
| filter countries > 1
```

Rate over the window:

```text
severity >= 5
| group eventsPerMinute=count()/queryspan("minutes") by serverHost
| sort -eventsPerMinute
```
