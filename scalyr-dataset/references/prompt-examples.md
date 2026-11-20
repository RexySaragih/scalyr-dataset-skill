# Scalyr DataSet — Prompt Examples

## Minimal

```text
@scalyr-dataset
How many 5xx from api hosts in the last 15 minutes?
```

Expect: `count_logs` with `status >= 500 serverHost contains "api"` (or
equivalent field clause), default window, then optionally `power_query`
grouped by `serverHost` or `uriPath`.

## Incident sample

```text
@scalyr-dataset
Show recent error lines on checkout hosts
```

Expect: `count_logs` or facets first if volume unknown, then `search_logs`
(`severity >= 5 serverHost contains "checkout"`), one page, no auto-pagination.
Not `power_query | columns message`.

## Top-N PowerQuery

```text
@scalyr-dataset
Which paths are throwing the most 500s?
```

Expect:

```text
status=500
| group errors=count() by uriPath
| sort -errors
| limit 30
```

via `power_query`.

## Time series

```text
@scalyr-dataset
Hourly 5xx by host for the last 6 hours
```

Expect: `start_time=6h`, query using
`timestamp=timebucket('1h')` **inside** `group by`, not `| timebucket 1h`.

## Must-not

```text
@scalyr-dataset
Dump every log message matching *
```

Expect: refuse lone `*`; ask for a field clause; use `search_logs` with a
tight filter and a 25–50 event page — never `| columns message`.
