# BOOK 4 – Chapter 4: Error Handling

---

## 1. Core Concept Explanation (Deep Technical Version)

### SQLSTATE: The Standard Error Code

**SQLSTATE** is a 5-character code defined by the SQL standard. Format: 2 characters (class) + 3 characters (subclass). Example: `23505` = unique violation. Class `23` = integrity constraint violation; subclass `505` = unique violation.

SQLSTATE is **portable**—same code across DBMSs. Application can catch by code and handle consistently. PostgreSQL also provides SQLERRM (message) and SQLSTATE in exception handlers.

### Common SQLSTATE Classes

| Class | Meaning |
|-------|---------|
| 00 | Success |
| 01 | Warning |
| 02 | No data (e.g., no rows from FETCH) |
| 22 | Data exception (invalid format, type) |
| 23 | Integrity constraint violation |
| 40 | Transaction rollback |
| 42 | Syntax error |
| 53 | Insufficient resources |
| 54 | Program limit exceeded |
| 55 | Object not in prerequisite state |
| P0 | PL/pgSQL |
| XX | Internal error |

### Common PostgreSQL SQLSTATE Codes

| Code | Meaning |
|------|---------|
| 23502 | Not null violation |
| 23503 | Foreign key violation |
| 23505 | Unique violation (duplicate key) |
| 23514 | Check violation |
| 40P01 | Deadlock detected |
| 42P01 | Undefined table |
| 42703 | Undefined column |

### Handling Errors in Application

**Parameterized queries** prevent SQL injection. **Try/catch** blocks catch database errors. Map SQLSTATE to application behavior:

- `23505` (unique violation): Upsert or return "already exists" to user.
- `23503` (FK violation): Return "referenced record doesn't exist" or cascade.
- `40P01` (deadlock): Retry transaction.
- `53xxx` (resource): Retry with backoff or return "system busy."

### Handling in PL/pgSQL

```sql
BEGIN
  INSERT INTO users (email) VALUES (v_email);
EXCEPTION
  WHEN unique_violation THEN
    -- Handle duplicate
    UPDATE users SET last_login = NOW() WHERE email = v_email;
  WHEN foreign_key_violation THEN
    RAISE EXCEPTION 'Invalid reference';
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
    RAISE;
END;
```

**WHEN** catches by condition name (e.g., unique_violation) or by SQLSTATE. **RAISE** rethrows. **RAISE EXCEPTION** aborts with custom message.

### WHENEVER (Embedded SQL)

In embedded SQL (C, etc.): `EXEC SQL WHENEVER SQLERROR GOTO handle_error;` — redirect on any error. Less granular than application-level handling.

---

## 2. Why This Matters in Production

### Real-World System Example

User registration: INSERT into users. If email exists (23505), handle: "Already registered" or "Login instead." If FK violation (23503) on country_id, "Invalid country." Application maps SQLSTATE to user-friendly message and HTTP status.

### Scalability Impact

- **Unhandled errors**: Crash or 500. User sees generic error. Retry storms if client retries on transient error.
- **Proper handling**: Return 409 Conflict for duplicate. Return 429 for deadlock (retry). Client retries appropriately.

### Performance Impact

- **Exception overhead**: Catching exceptions has cost. Prefer validation before INSERT when possible (e.g., check existence first). But for race conditions, catch 23505—two concurrent inserts can both succeed pre-check.
- **Retry on deadlock**: Transient. Retry with exponential backoff. Don't retry indefinitely.

### Data Integrity Implications

- **Swallowing errors**: Catch and ignore. Bad data persists. At minimum, log and alert.
- **Partial rollback**: Savepoints allow partial rollback. BEGIN; ... SAVEPOINT s1; ... ROLLBACK TO s1; — undo part of transaction.

### Production Failure Scenario

**Case: Unhandled deadlock.** Application got 40P01, logged it, returned 500. User retried. Same deadlock. Loop. Fix: Catch 40P01, retry transaction (up to 3 times). Return success or 503 after retries exhausted.

---

## 3. PostgreSQL Implementation

### PL/pgSQL Exception Block

```sql
CREATE OR REPLACE FUNCTION upsert_user(p_email TEXT, p_name TEXT)
RETURNS void AS $$
BEGIN
  INSERT INTO users (email, name) VALUES (p_email, p_name);
EXCEPTION
  WHEN unique_violation THEN
    UPDATE users SET name = p_name WHERE email = p_email;
END;
$$ LANGUAGE plpgsql;
```

### Catching by SQLSTATE

```sql
EXCEPTION
  WHEN SQLSTATE '23505' THEN
    -- Unique violation
  WHEN SQLSTATE '40P01' THEN
    -- Deadlock
  WHEN OTHERS THEN
    RAISE NOTICE 'SQLSTATE: %', SQLSTATE;
    RAISE;
```

### Savepoints (Partial Rollback)

```sql
BEGIN;
  INSERT INTO orders ...;
  SAVEPOINT sp1;
  INSERT INTO order_items ...;
  -- If error here:
  ROLLBACK TO sp1;  -- Undo order_items, keep orders
  -- Or: RELEASE sp1 to keep both
COMMIT;
```

### Application (Python/psycopg2)

```python
try:
    cur.execute("INSERT INTO users (email) VALUES (%s)", (email,))
    conn.commit()
except psycopg2.IntegrityError as e:
    if e.pgcode == '23505':  # Unique violation
        return {"error": "Email already registered"}, 409
    elif e.pgcode == '23503':  # FK violation
        return {"error": "Invalid reference"}, 400
except psycopg2.OperationalError as e:
    if e.pgcode == '40P01':  # Deadlock
        # Retry
        time.sleep(0.1)
        return retry_insert(...)
```

---

## 4. Common Developer Mistakes

### Mistake 1: Catching and Ignoring

EXCEPTION WHEN OTHERS THEN NULL; — swallows all errors. Data may be corrupt. At minimum, log and re-raise.

### Mistake 2: Not Retrying on Deadlock

40P01 is transient. Retry. Don't show "deadlock" to user—retry transparently.

### Mistake 3: Relying on Error Message for Logic

SQLERRM varies by locale and version. Use SQLSTATE for programmatic handling.

### Mistake 4: No Handling for Unique Violation in Upsert

INSERT ... ON CONFLICT is cleaner than catch-and-update. But if using catch, ensure you handle 23505.

### Mistake 5: RAISE Without Re-throwing

In exception handler, RAISE; rethrows. RAISE EXCEPTION 'msg'; throws new. Use RAISE; to preserve original error for caller.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is SQLSTATE 23505?**  
A: Unique violation (duplicate key). Insert or update violated UNIQUE constraint.

**Q: What is SQLSTATE 40P01?**  
A: Deadlock detected. Transaction was aborted. Retry.

**Q: How do you handle duplicate key in stored procedure?**  
A: EXCEPTION WHEN unique_violation THEN — either UPDATE instead (upsert) or return friendly message. Or use INSERT ... ON CONFLICT.

### Scenario-Based Questions

**Q: When would you use a savepoint?**  
A: Multi-step transaction where one step can fail. SAVEPOINT before risky step; ROLLBACK TO on error. Keeps earlier work.

**Q: How do you implement retry on deadlock?**  
A: Catch 40P01. In loop: retry transaction (up to N times). Return success or 503 after retries. Use exponential backoff between retries.

---

## 6. Advanced Engineering Notes

### GET DIAGNOSTICS

```sql
GET DIAGNOSTICS v_count = ROW_COUNT;
GET DIAGNOSTICS v_state = RETURNED_SQLSTATE;
```

After exception or statement. ROW_COUNT = rows affected. RETURNED_SQLSTATE = last error.

### RAISE Levels

- NOTICE, WARNING: Log, don't abort.
- EXCEPTION: Abort transaction, raise error.

### Custom Exceptions

```sql
RAISE EXCEPTION 'Invalid amount: %', p_amount USING ERRCODE = '22P02';
```

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Write INSERT that violates UNIQUE. Catch in PL/pgSQL, log SQLSTATE, return.
2. Use SAVEPOINT. Insert one row, SAVEPOINT, insert second (force error). ROLLBACK TO SAVEPOINT. Verify first row committed after COMMIT.
3. In application (if available): Catch 23505, return 409. Catch 40P01, retry.

---

## 8. Summary in 10 Bullet Points

1. **SQLSTATE**: 5-char code. Portable. Use for programmatic handling.
2. **23505**: Unique violation. Duplicate key.
3. **23503**: Foreign key violation.
4. **40P01**: Deadlock. Retry transaction.
5. **EXCEPTION block**: WHEN condition THEN handler. In PL/pgSQL.
6. **unique_violation**: Condition name for 23505.
7. **Savepoints**: SAVEPOINT name; ROLLBACK TO name. Partial rollback.
8. **Retry on deadlock**: Catch 40P01, retry. Transient.
9. **Don't swallow**: Log and re-raise or handle explicitly.
10. **SQLSTATE over message**: Use code, not SQLERRM text, for logic.
