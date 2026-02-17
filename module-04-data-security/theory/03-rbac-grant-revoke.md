# Role-Based Access Control

## Concepts

- **Role**: User or group; can own objects, have privileges
- **Privilege**: Permission (SELECT, INSERT, UPDATE, DELETE, etc.)
- **Grant**: Give privilege to role
- **Revoke**: Remove privilege

## GRANT Syntax

```sql
GRANT SELECT ON table_name TO role_name;
GRANT SELECT, INSERT ON schema_name.table_name TO role_name;
GRANT ALL ON ALL TABLES IN SCHEMA public TO role_name;
```

## Common Patterns

- **Read-only app**: `GRANT SELECT ON ... TO app_readonly;`
- **Read-write app**: `GRANT SELECT, INSERT, UPDATE, DELETE ON ... TO app_readwrite;`
- **Schema-level**: `GRANT USAGE ON SCHEMA public TO role;` then table grants

## REVOKE

```sql
REVOKE INSERT ON table_name FROM role_name;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM role_name;
```

## Default Privileges

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;
```
Applies to future objects.

## Interview Insight

**Q: How do you restrict a user to read-only access?**
A: Create a role, GRANT SELECT on required tables/schemas. REVOKE other privileges. Connect application as that role.
