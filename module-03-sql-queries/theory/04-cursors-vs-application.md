# Cursors vs Application-Level Iteration

## Cursors (SQL)

- Declare, open, fetch rows one-by-one, close
- Server-side state; useful in stored procedures
- **Downside**: Round-trips per row; slow for large result sets

## Application Iteration

- Fetch full result set (or batch) into application
- Process in Python, Java, etc.
- **Advantage**: Single round-trip; leverage application logic

## When to Use Cursors

- Streaming large result sets (don't load all into memory)
- Stored procedure that processes row-by-row
- Legacy systems

## When to Use Application

- Most cases: fetch batch, process, repeat
- Pagination: LIMIT/OFFSET or keyset
- Aggregation: do in SQL, not in app

## Pagination Comparison

| Method | Pros | Cons |
|--------|------|------|
| OFFSET/LIMIT | Simple | O(n) for large offset; skips rows |
| Keyset (WHERE id > last_id) | O(1); stable | No random page access |
| Cursor | Server-side | Extra round-trips |

**Recommendation**: Keyset for infinite scroll; OFFSET for small pages (e.g., page 1-10).
