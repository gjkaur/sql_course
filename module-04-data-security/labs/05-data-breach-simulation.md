# Data Breach Simulation Scenario

## Scenario

A developer account `dev_user` was granted `SELECT` on the `customers` table for debugging. The account was later compromised. An attacker uses it to exfiltrate PII.

## Objectives

1. Detect the breach (audit)
2. Revoke excessive privileges
3. Implement least-privilege going forward

## Steps

### 1. Simulate Over-Privileged User

```sql
CREATE ROLE dev_user LOGIN PASSWORD 'weak';
GRANT SELECT ON customers TO dev_user;
-- Oops: also granted on orders, order_items (sensitive)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO dev_user;
```

### 2. Audit: Who Has What

```sql
-- List roles and their table privileges
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'dev_user';
```

### 3. Revoke

```sql
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM dev_user;
-- Grant only what's needed
GRANT SELECT ON customers(id, name) TO dev_user;  -- Partial? Use VIEW instead.
```

### 4. Least-Privilege: Use Views

```sql
CREATE VIEW customers_debug AS
SELECT id, name, created_at FROM customers;  -- No email, phone, address
GRANT SELECT ON customers_debug TO dev_user;
```

### 5. Enable Audit Logging (PostgreSQL)

- `log_statement = 'all'` or `'ddl'` + `'mod'`
- `pg_audit` extension for finer control
- External: pgAudit, or application-level logging

## Takeaways

- Grant minimum required privileges
- Use views to restrict columns
- Audit regularly
- Rotate credentials after incident
