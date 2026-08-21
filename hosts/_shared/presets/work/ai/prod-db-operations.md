---
name: prod-db-operations
description: Inspect the production read replica with prod-db-mcp and retrieve Kubernetes logs when database data is insufficient.
---

# Production Database Operations

Use the `prod-db` MCP server (it might be behind the gateway MCP server) for production database investigation. It connects
to a read-only MariaDB replica, so use it to inspect data and schema only.

1. Start with `prod-db_list_tables` to identify relevant tables and columns.
2. Use `prod-db_execute_sql` for targeted `SELECT` queries. Limit result sets
   and filter by indexed identifiers or time ranges where possible.
3. Use `prod-db_get_query_plan` before running a query that may scan a large
   table. Do not run write statements or schema changes.
4. If database results do not explain an application failure, retrieve the
   relevant workload logs with `kubectl`: locate pods with `kubectl get pods
   -A`, then use `kubectl logs -n <namespace> <pod> -c <container> --since=1h`.
   Include `--previous` for a restarted container and narrow the time window
   before expanding it.

Do not expose credentials, connection details, or sensitive production data in
responses. Summarize only the rows and log lines needed to answer the request.
