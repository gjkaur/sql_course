# Error Handling and SQLSTATE

## SQLSTATE

5-character code: `class` + `subclass`. Example: `23505` = unique violation.

## Common Classes

| Class | Meaning |
|-------|---------|
| 00 | Success |
| 01 | Warning |
| 02 | No data |
| 22 | Data exception (invalid format) |
| 23 | Integrity violation |
| 40 | Transaction rollback |
| 42 | Syntax error |
| 53 | Insufficient resources |
| 54 | Program limit exceeded |
| 55 | Object not in prerequisite state |
| P0 | PL/pgSQL |
| XX | Internal error |

## Common Codes

- `23505`: Unique violation
- `23503`: Foreign key violation
- `23502`: Not null violation
- `23514`: Check violation
- `40P01`: Deadlock detected

## Handling in PL/pgSQL

```sql
BEGIN
  -- statements
EXCEPTION
  WHEN unique_violation THEN
    -- handle
  WHEN OTHERS THEN
    RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
END;
```

## WHENEVER (Embedded SQL)

In embedded SQL (C, etc.): `EXEC SQL WHENEVER SQLERROR GOTO handle_error;`

## Interview Insight

**Q: How do you handle a duplicate key error in a stored procedure?**
A: Use EXCEPTION block with `WHEN unique_violation THEN` to catch 23505. Either update instead of insert (upsert) or return a friendly message.
