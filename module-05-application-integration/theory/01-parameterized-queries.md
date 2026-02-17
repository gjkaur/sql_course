# Parameterized Queries

## Why Parameterize?

1. **SQL Injection prevention**: User input is never interpreted as SQL
2. **Performance**: Query plan can be cached for repeated executions
3. **Type safety**: Database validates types

## Bad (Vulnerable)

```python
# NEVER do this
query = f"SELECT * FROM customers WHERE email = '{email}'"
# Attacker: email = "x' OR '1'='1" → returns all rows
```

## Good (Parameterized)

```python
# psycopg2
cur.execute("SELECT * FROM customers WHERE email = %s", (email,))

# SQLAlchemy
session.execute(text("SELECT * FROM customers WHERE email = :email"), {"email": email})
```

## Placeholder Syntax

| Driver | Placeholder |
|--------|-------------|
| psycopg2 | %s |
| psycopg3 | %s |
| SQLAlchemy | :name or %s |
| Node pg | $1, $2 |

## Interview Insight

**Q: How do you prevent SQL injection?**
A: Always use parameterized queries. Never concatenate user input into SQL. Use ORM or prepared statements. Validate/sanitize input at application layer as defense in depth.
