# SELECT Deep Dive

## Execution Order

```
FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT/OFFSET
```

**Implication**: You cannot use column aliases from SELECT in WHERE (SELECT runs after WHERE). Use subquery or repeat expression.

## Clauses

### FROM

- Tables, JOINs, subqueries (derived tables)
- `FROM (SELECT ...) AS sub` — must have alias

### WHERE

- Filters rows before aggregation
- Cannot use aggregate functions (use HAVING)
- Short-circuit: put most selective conditions first (optimizer may reorder)

### GROUP BY

- Groups rows; one result row per group
- All non-aggregated columns in SELECT must be in GROUP BY
- PostgreSQL allows grouping by expression or column position (1, 2)

### HAVING

- Filters groups after aggregation
- Can use aggregate functions: `HAVING COUNT(*) > 5`

### SELECT

- Projection: which columns
- `*` — all columns (avoid in production; be explicit)
- Expressions, aggregates, subqueries (scalar)

### DISTINCT

- Removes duplicates
- `DISTINCT ON (col)` — PostgreSQL extension; one row per col value

### ORDER BY

- Sort result
- `NULLS FIRST` / `NULLS LAST` — control NULL ordering
- Can use column position: `ORDER BY 2`

### LIMIT / OFFSET

- `LIMIT n` — first n rows
- `OFFSET m` — skip m rows
- **Pagination warning**: OFFSET is O(n); for large offsets use keyset pagination
