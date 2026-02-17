# Index Tuning

## When to Add Indexes

- Columns in WHERE, JOIN, ORDER BY
- FK columns
- Columns in GROUP BY (sometimes)

## When NOT to Index

- Small tables (Seq Scan is fine)
- Columns with low cardinality (few distinct values)
- Write-heavy tables (each index costs INSERT/UPDATE/DELETE)
- Columns rarely used in queries

## Index Types (PostgreSQL)

- **B-tree**: Default. Equality, range, ORDER BY.
- **Hash**: Equality only. Usually B-tree is preferred.
- **GIN**: JSONB, arrays, full-text.
- **GiST**: Geometric, full-text, range.
- **BRIN**: Block range. Good for large sorted tables (e.g., time-series).

## Composite Index Order

- Equality columns first, range column last
- Left-prefix: (a, b, c) supports (a), (a,b), (a,b,c)
- Most selective first for equality

## Maintenance

- `REINDEX` to rebuild corrupted indexes
- `VACUUM` and `ANALYZE` for statistics
- Monitor index bloat with `pg_stat_user_indexes`
