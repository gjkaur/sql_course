# BOOK 5 – Chapter 3: Parameterized Queries

---

## 1. Core Concept Explanation (Deep Technical Version)

### The SQL Injection Problem

**SQL injection** occurs when user input is concatenated into SQL and interpreted as part of the query. An attacker crafts input that changes the query's meaning.

Example: `"SELECT * FROM users WHERE email = '" + email + "'"`  
Attacker input: `email = "x' OR '1'='1"`  
Result: `SELECT * FROM users WHERE email = 'x' OR '1'='1'` — returns all rows (or worse: `'; DROP TABLE users; --`).

**Parameterized queries** (prepared statements with bound parameters) send SQL and data **separately**. The database treats parameters as data, never as SQL. Injection is impossible.

### How Parameterization Works

1. Application sends SQL template: `SELECT * FROM users WHERE email = $1`
2. Application sends parameter values: `['user@example.com']`
3. Database binds values to placeholders. No parsing of parameter as SQL.

The placeholder (`$1`, `%s`, `?`) is a slot. The value is always a literal. Even if value is `"'; DROP TABLE users; --"`, it becomes a string comparison, not executable SQL.

### Benefits Beyond Security

- **Plan caching**: Database can cache the plan for the parameterized query. Repeated executions with different parameters reuse the plan. Faster.
- **Type safety**: Database validates parameter types. Wrong type → error. Prevents logic bugs.
- **Readability**: Clear separation of structure and data. Easier to audit.

### Placeholder Syntax by Driver

| Driver | Placeholder | Example |
|--------|-------------|---------|
| psycopg2, psycopg3 | %s | `cur.execute("... WHERE id = %s", (1,))` |
| JDBC | ? | `stmt.setInt(1, 1)` |
| Node pg | $1, $2 | `query('... WHERE id = $1', [1])` |
| SQLAlchemy | :name or %s | `text("... WHERE id = :id").bindparams(id=1)` |

### What Cannot Be Parameterized

**Identifiers** (table names, column names) cannot be parameterized in standard SQL. `SELECT * FROM $1` — invalid. Table name must be in the query text. If table name comes from user, **whitelist**: validate against known tables. Never concatenate.

**Dynamic ORDER BY**: `ORDER BY column_name` — column name can't be parameterized. Whitelist allowed columns.

---

## 2. Why This Matters in Production

### Real-World System Example

Login: `SELECT * FROM users WHERE email = ? AND password_hash = ?`. Parameters from form. Attacker cannot inject. Compare to concatenation: one crafted email = full breach.

### Scalability Impact

- **Plan reuse**: High-throughput app with same query shape. Parameterized = one plan, many executions. Concatenation = new plan per unique string (plan cache bloat).

### Performance Impact

- **Parse/plan overhead**: Parameterized avoids re-parse when plan is cached. Marginal for simple queries; significant for complex ones.

### Data Integrity Implications

- **Injection**: Can delete data, bypass auth, exfiltrate. Critical vulnerability. Parameterization is primary defense.

### Production Failure Scenario

**Case: SQL injection in search.** Search box: `"SELECT * FROM products WHERE name LIKE '%" + query + "%'"`. Attacker: `"%' UNION SELECT id, password_hash, 3, 4 FROM users --"`. Exposed password hashes. Fix: Parameterized. `WHERE name LIKE %s` with `('%' + query + '%',)`.

---

## 3. PostgreSQL Implementation

### Python (psycopg2)

```python
# Correct
cur.execute("SELECT * FROM customers WHERE email = %s", (email,))
cur.execute("INSERT INTO orders (customer_id, total) VALUES (%s, %s)", (cid, total))

# Multiple parameters
cur.execute("SELECT * FROM t WHERE a = %s AND b = %s", (a_val, b_val))
```

### Python (SQLAlchemy)

```python
from sqlalchemy import text
result = session.execute(text("SELECT * FROM customers WHERE email = :email"), {"email": email})
```

### Node (pg)

```javascript
await pool.query('SELECT * FROM customers WHERE id = $1', [id]);
await pool.query('INSERT INTO t (a, b) VALUES ($1, $2)', [a, b]);
```

### Identifier Whitelist (When Dynamic)

```python
ALLOWED_COLUMNS = {'name', 'created_at', 'status'}
order_by = request.args.get('sort', 'name')
if order_by not in ALLOWED_COLUMNS:
    order_by = 'name'
query = f"SELECT * FROM t ORDER BY {order_by}"  # Safe: whitelisted
```

---

## 4. Common Developer Mistakes

### Mistake 1: Concatenating User Input

`f"SELECT * FROM t WHERE id = {user_id}"` — even if user_id is "validated" as int, use parameter. Defense in depth.

### Mistake 2: Partial Parameterization

`"SELECT * FROM t WHERE id = %s AND name = '" + name + "'"` — name is still injectable. Parameterize all user input.

### Mistake 3: ORM Assumption

ORM can have injection if used wrong (e.g., raw string in filter). Use ORM's parameter binding. Don't pass raw SQL with concatenation.

### Mistake 4: Trusting "Sanitization"

Escaping quotes is fragile. One missed edge case = injection. Parameterization is the correct fix.

### Mistake 5: Parameterizing Identifiers

`"SELECT * FROM %s"` — invalid. Identifiers can't be parameterized. Whitelist.

---

## 5. Interview Deep-Dive Section

**Q: How do you prevent SQL injection?**  
A: Always use parameterized queries. Never concatenate user input into SQL. Use ORM or prepared statements. Validate input at application layer as defense in depth.

**Q: What are the benefits of parameterized queries beyond security?**  
A: Query plan caching, type validation by the database. Cleaner code.

**Q: Can you parameterize table or column names?**  
A: No. Identifiers must be in query text. Use whitelist: validate against known tables/columns. Never use user input directly.

---

## 6. Advanced Engineering Notes

### Prepared Statements (Explicit)

```python
cur.execute("PREPARE plan AS SELECT * FROM t WHERE id = $1")
cur.execute("EXECUTE plan (1)")
cur.execute("EXECUTE plan (2)")
```

Most drivers do this internally when you use parameterized execute. Explicit when you need to control lifecycle.

### ORM and Raw SQL

ORM's `where(field == value)` generates parameterized SQL. Raw SQL: use `text()` + bindparams. Never: `f"SELECT * FROM t WHERE id = {id}"`.

---

## 7. Mini Practical Exercise

1. Write vulnerable query: concatenate email into SELECT. Try injection: `' OR '1'='1`.
2. Rewrite with parameterization. Verify injection no longer works.
3. Implement dynamic ORDER BY with whitelist. Test with invalid column name.

---

## 8. Summary in 10 Bullet Points

1. **SQL injection**: User input concatenated into SQL. Attacker alters query.
2. **Parameterized queries**: SQL and data sent separately. Parameters never parsed as SQL.
3. **Placeholders**: %s (Python), ? (JDBC), $1 (Node). Driver-specific.
4. **Plan caching**: Parameterized enables reuse. Better performance.
5. **Type safety**: Database validates parameter types.
6. **Identifiers**: Table/column names cannot be parameterized. Whitelist.
7. **Never concatenate**: Even "validated" input. Parameterize.
8. **ORM**: Use parameter binding. Raw SQL with params, not concatenation.
9. **Defense in depth**: Parameterize + validate. Both.
10. **Whitelist for dynamic**: ORDER BY, table name. Validate against allowed set.
