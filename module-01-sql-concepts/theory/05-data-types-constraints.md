# SQL Data Types and Constraints

## PostgreSQL Data Types (Essential)

### Numeric

| Type | Use Case |
|------|----------|
| `SMALLINT` | Small integers (-32K to 32K) |
| `INTEGER` | General integers |
| `BIGINT` | Large integers (IDs, counts) |
| `NUMERIC(p,s)` | Exact decimals (money, quantities) |
| `REAL`, `DOUBLE PRECISION` | Approximate floats |

**Money**: Use `NUMERIC(10,2)` or `DECIMAL`. Avoid `REAL` for currency (floating-point errors).

### Character

| Type | Behavior |
|------|----------|
| `VARCHAR(n)` | Variable length, max n |
| `TEXT` | Unlimited length (PostgreSQL) |
| `CHAR(n)` | Fixed length, padded |

**Recommendation**: Use `TEXT` in PostgreSQL; it has no performance penalty vs VARCHAR.

### Date/Time

| Type | Use Case |
|------|----------|
| `DATE` | Date only |
| `TIME` | Time only |
| `TIMESTAMP` | Date + time (no timezone) |
| `TIMESTAMPTZ` | Date + time with timezone |

**Best practice**: Use `TIMESTAMPTZ` for user-facing timestamps (stores UTC, displays in user's zone).

### Other

| Type | Use Case |
|------|----------|
| `BOOLEAN` | true/false |
| `UUID` | Unique identifiers |
| `JSONB` | Semi-structured data (Module 6) |

## Constraints

| Constraint | Purpose |
|------------|---------|
| `NOT NULL` | Reject NULL values |
| `UNIQUE` | No duplicate values in column(s) |
| `PRIMARY KEY` | Unique + NOT NULL, identifies row |
| `FOREIGN KEY` | References another table's PK |
| `CHECK` | Enforce condition (e.g., price > 0) |
| `DEFAULT` | Value when not specified |

## NULL Handling

- NULL means "unknown" or "not applicable"
- `NULL = NULL` is NULL (not true) — use `IS NULL`
- Aggregates ignore NULL (except COUNT(*))
- Design: avoid NULL if a sensible default exists; use NOT NULL when value is required

## Interview Insight

**Q: When would you use CHECK vs application-level validation?**

A: Use CHECK for data integrity that must hold regardless of application. Examples: `price >= 0`, `status IN ('pending','shipped')`. Application validation handles UX (formatting, messages). Defense in depth: both. Never trust client-only validation.
