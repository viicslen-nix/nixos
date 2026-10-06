---
name: prod-db-operations
description: Investigate production read-only — query the database replica, read Loki and Kubernetes logs, run tinker/artisan probes, check the deployed version.
---

# Production Operations

Everything here is read-only: `SELECT` and `kubectl get`/`logs`. Keep credentials and connection details out of responses; summarize only the rows and log lines the answer needs.

## Database

The MariaDB replica sits behind the hm-gateway MCP. Call it directly; no tool discovery needed:

- `gateway_invoke(server: "prod-db", tool: "execute_sql", arguments: {sql: "..."})`
- `gateway_invoke(server: "prod-db", tool: "get_query_plan", arguments: {sql_statement: "..."})`

Schemas are `mylisterhub_central` and `mylisterhub_tenant<ID>`; qualify every table (`mylisterhub_tenant446.listings`). Read column shapes locally (Boost `database-schema`, `database/schema/tenant-schema.sql`).

Write SQL the gateway accepts and the replica finishes:

- Plain identifiers. The firewall rejects backticks as shell injection, so alias tables and qualify reserved-word columns: `s.group`, `s.from`.
- Named columns and a `LIMIT` on every query. Wide/log tables (`system_logs`) overflow the token limit otherwise.
- Large tenants — 446 (~500k listings), 447, 496, 176: run `get_query_plan` first and proceed only with an indexed filter plus `LIMIT`. Correlated `EXISTS`, whole-table `GROUP BY`, and fleet-wide `information_schema` scans time out there.

Which tenants have rows in table X — cheap because `table_name` is pinned; `table_rows` is an estimate, so confirm with `COUNT(*)` in the schemas that matter:

```sql
SELECT t.table_schema, t.table_rows FROM information_schema.tables t
WHERE t.table_name = 'X' AND t.table_schema LIKE 'mylisterhub_tenant%' AND t.table_rows > 0
ORDER BY t.table_rows DESC LIMIT 50
```

## Logs

1. Loki first. The `app` label is the deployment name:
   `gateway_invoke(server: "grafana", tool: "query_loki_logs", arguments: {datasourceUid: "b0419c63-db98-49e7-9940-ac16fc84b492", logql: "{namespace=\"default\", app=\"mylisterhub-worker-default\"} |= \"needle\"", startRfc3339: "now-1h", limit: 50})`
2. Then `kubectl logs -n default <pod> --since=1h` (`--previous` for a restarted container). Narrow the window before widening it.

The `listing` log channel goes to Discord, not stdout, so it is in neither.

## Probes

Run tinker/artisan probes in the debugger only — it has no memory limit:
`kubectl exec -n default deploy/mylisterhub-debugger -- php artisan tinker --execute '...'`

Worker pods (`mylisterhub-worker-*`) run on tight memory limits, and a read-only probe has OOM-killed one in production; leave them alone. The debugger runs `mylisterhub-cli:latest`, so its code can differ from the deployed release.

## Deployed version

Before calling a fix live, compare the running tag with the release containing the fix (`git tag --contains <sha>`):

```sh
kubectl get deploy -n default mylisterhub-web mylisterhub-worker-default \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[*].image}{"\n"}{end}'
```

Tags track releases: `mylisterhub-web:frankenphp-5.192.0`, `mylisterhub-cli:5.192.0` ↔ `v5.192.0`.
