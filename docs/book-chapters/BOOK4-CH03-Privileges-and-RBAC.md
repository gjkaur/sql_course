# BOOK 4 – Chapter 3: Privileges and RBAC

---

## 1. Core Concept Explanation (Deep Technical Version)

### Role-Based Access Control (RBAC)

**RBAC** assigns permissions to **roles**, not directly to users. Users are granted roles; roles have privileges. Simplifies management: change role's privileges once, all users with that role are affected.

In PostgreSQL, **roles** and **users** are the same object. A "user" is a role with LOGIN. A "group" is a role without LOGIN. Roles can inherit other roles (GRANT role_a TO role_b).

### Privileges

**Privileges** are permissions on database objects:

| Privilege | Applies To | Meaning |
|-----------|------------|---------|
| SELECT | Table, view | Read rows |
| INSERT | Table | Insert rows |
| UPDATE | Table | Modify rows (can restrict to columns) |
| DELETE | Table | Remove rows |
| TRUNCATE | Table | Empty table |
| REFERENCES | Table | Create FK to table |
| TRIGGER | Table | Create triggers |
| USAGE | Schema, sequence | Use object |
| EXECUTE | Function | Call function |

**GRANT** gives a privilege. **REVOKE** removes it. Privileges are stored in system catalogs; enforced on every statement.

### Hierarchy: Database → Schema → Table

- **Database**: Connect permission (CONNECT). Created by superuser.
- **Schema**: USAGE to access objects in schema. Default: public schema is usable by all.
- **Table**: SELECT, INSERT, UPDATE, DELETE. Must have USAGE on schema first.

### Default Privileges

**Default privileges** apply to **future** objects. When you create a new table, it gets the default privileges you've defined. Useful for ensuring new tables are automatically readable by a reporting role.

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;
```

### Principle of Least Privilege

Grant only what is needed. Read-only app gets SELECT only. Write app gets SELECT, INSERT, UPDATE, DELETE (not TRUNCATE, DROP). Application never connects as superuser.

---

## 2. Why This Matters in Production

### Real-World System Example

Web app: `app_readwrite` role with SELECT, INSERT, UPDATE, DELETE on orders, customers, products. Reporting: `app_readonly` with SELECT only. Admin: `app_admin` with full access on specific schema. Each service connects with its role. Compromised app credential has limited blast radius.

### Scalability Impact

- **Overly broad GRANT**: Granting to PUBLIC or superuser. One breach = full access. Restrict.
- **Connection pooling**: Pool uses one role. Ensure that role has sufficient privileges for all app operations. Or use separate pools per role.

### Performance Impact

- **Row-level security (RLS)**: Adds predicates to queries. Can affect performance. Use indexes that match RLS.
- **Privilege check**: Per-statement. Negligible overhead.

### Data Integrity Implications

- **No DELETE for reporting**: Reporting role has SELECT only. Cannot accidentally delete. Protects data.
- **Separate schema for staging**: App has no access to staging. ETL loads; app reads from production schema only.

### Production Failure Scenario

**Case: App connected as superuser.** Application used postgres superuser. SQL injection in one endpoint exposed full database. Fix: Create role with minimal privileges. Grant only required tables and operations. Use parameterized queries.

---

## 3. PostgreSQL Implementation

### Create Role

```sql
CREATE ROLE app_readonly WITH LOGIN PASSWORD 'secret';
CREATE ROLE app_readwrite WITH LOGIN PASSWORD 'secret';
```

### Grant Table Privileges

```sql
GRANT SELECT ON customers TO app_readonly;
GRANT SELECT ON orders TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON customers TO app_readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO app_readwrite;
GRANT SELECT ON products TO app_readwrite;
```

### Grant Schema

```sql
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
```

### Default Privileges

```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO app_readonly;
-- Future tables in public get SELECT for app_readonly
```

### Revoke

```sql
REVOKE INSERT ON orders FROM app_readwrite;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM old_role;
```

### Role Inheritance

```sql
CREATE ROLE app_readonly;
CREATE ROLE app_user WITH LOGIN;
GRANT app_readonly TO app_user;
-- app_user gets app_readonly's privileges
```

### Row-Level Security (RLS)

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_own ON orders
  FOR ALL
  TO app_user
  USING (customer_id = current_setting('app.current_customer_id')::int);
```

---

## 4. Common Developer Mistakes

### Mistake 1: Connecting as Superuser

Application uses postgres. One bug = full access. Create dedicated role.

### Mistake 2: Granting to PUBLIC

GRANT SELECT ON table TO PUBLIC — all roles get it. Use explicit roles.

### Mistake 3: Forgetting Schema USAGE

GRANT SELECT ON table TO role — fails if role has no USAGE on schema. Grant USAGE first.

### Mistake 4: No Default Privileges

New tables created by developer don't inherit. Reporting role can't see them. Set ALTER DEFAULT PRIVILEGES.

### Mistake 5: Revoking Without CASCADE

REVOKE from role that granted to others. May need REVOKE ... FROM ... CASCADE. Understand grant chain.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between a role and a user?**  
A: In PostgreSQL, same. "User" = role with LOGIN. "Group" = role without LOGIN. Roles can inherit other roles.

**Q: How do you grant read-only access?**  
A: Create role. GRANT USAGE ON SCHEMA. GRANT SELECT ON tables (or ALL TABLES IN SCHEMA). REVOKE other privileges. Connect app as that role.

**Q: What does REVOKE do?**  
A: Removes a privilege from a role. Revoked privilege no longer applies. Does not affect objects already created (e.g., views that use the table).

### Scenario-Based Questions

**Q: How do you ensure a new table is readable by reporting role?**  
A: ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO app_readonly. Future tables get SELECT automatically.

**Q: What is Row-Level Security?**  
A: Policy that restricts which rows a role can see/modify. E.g., users see only their own orders. Enables multi-tenant in single schema.

---

## 6. Advanced Engineering Notes

### Grant Option

Grant with grant option: `GRANT SELECT ON t TO role WITH GRANT OPTION`. Role can grant to others. Use sparingly.

### Role Hierarchy

Roles can be members of roles. `GRANT admin TO alice`. Alice gets admin's privileges. Admin can be a "group" role (no LOGIN).

### RLS vs Application Filtering

RLS enforces in database—cannot be bypassed by buggy app. Application filtering can be bypassed. For sensitive data, use RLS.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Create role app_readonly. Grant SELECT on customers, orders. Connect as app_readonly. Verify SELECT works, INSERT fails.
2. Create role app_readwrite. Grant SELECT, INSERT, UPDATE, DELETE. Test.
3. ALTER DEFAULT PRIVILEGES. Create new table. Verify app_readonly can SELECT.

---

## 8. Summary in 10 Bullet Points

1. **RBAC**: Privileges on roles; users get roles. Manageable; principle of least privilege.
2. **GRANT**: Grant privilege to role. SELECT, INSERT, UPDATE, DELETE, etc.
3. **REVOKE**: Remove privilege. Explicit and immediate.
4. **Schema USAGE**: Required before table access. Grant USAGE ON SCHEMA.
5. **Default privileges**: ALTER DEFAULT PRIVILEGES. Apply to future objects.
6. **Least privilege**: Grant only what's needed. Read-only gets SELECT.
7. **Never superuser**: Application uses dedicated role. Limits blast radius.
8. **Role = user**: In PostgreSQL, role with LOGIN is "user."
9. **RLS**: Row-level security. Restrict rows per role. Policy with USING.
10. **Test privileges**: Connect as role, verify permissions. Include in CI.
