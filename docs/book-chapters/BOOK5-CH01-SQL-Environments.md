# BOOK 5 – Chapter 1: SQL Environments

---

## 1. Core Concept Explanation (Deep Technical Version)

### Where SQL Runs

SQL executes in different **environments** depending on how it is invoked. The environment determines who submits the SQL, how results are consumed, and what host-language integration exists.

### Interactive SQL

**Interactive SQL** is executed directly by a user through a client tool. Examples: psql, pgAdmin, DBeaver, SQL Server Management Studio. User types or pastes SQL; tool sends to DBMS; results displayed in grid or text.

- **Use case**: Ad-hoc queries, administration, debugging, prototyping.
- **Characteristics**: No host language. No variables from application. One-off or exploratory.
- **Limitation**: Not for production application logic. No control flow, no integration with business code.

### Embedded SQL

**Embedded SQL** places SQL statements inside a host language (C, COBOL, Fortran). Preprocessor translates `EXEC SQL` blocks into host-language calls before compilation.

```c
EXEC SQL BEGIN DECLARE SECTION;
  int cust_id;
  char name[100];
EXEC SQL END DECLARE SECTION;

EXEC SQL SELECT name INTO :name FROM customers WHERE id = :cust_id;
```

Host variables (`:name`, `:cust_id`) pass data between SQL and host. **Declare section** defines shared variables. **Cursor** used for multi-row results.

- **Use case**: Legacy systems, mainframe applications. Declining in favor of call-level interfaces.
- **Downside**: Precompiler required. Debugging harder. Vendor-specific.

### Call-Level Interface (CLI)

**CLI** uses a library/API to send SQL as strings. No precompiler. Application builds SQL (or uses parameterized queries) and calls driver functions. ODBC, JDBC, libpq, psycopg2 are CLIs.

```python
cur.execute("SELECT * FROM customers WHERE id = %s", (cust_id,))
rows = cur.fetchall()
```

- **Use case**: Modern applications. Python, Java, Node, Go. Dominant approach.
- **Advantage**: No precompiler. Language-agnostic (same SQL, different drivers). Dynamic SQL.

### Module Language

**Module language** (SQL standard) defines SQL procedures in a separate module. Host program calls them by name. Clean separation: SQL experts write procedures; application developers call them. Modern equivalent: stored procedures + CLI (CALL proc_name).

### Stored Procedures and Triggers

Logic that runs **inside** the database. Invoked by application (CALL) or automatically on data change (trigger). No round-trip for multi-step logic. Covered in Ch 4–5.

---

## 2. Why This Matters in Production

### Real-World System Example

Web app: Uses CLI (psycopg2, JDBC). No embedded SQL. Stored procedures for complex multi-table operations. Interactive SQL (psql) for DBA tasks and debugging.

### Scalability Impact

- **CLI**: Connection per request or pooled. Stateless. Scales horizontally.
- **Embedded**: Tighter coupling. Less common in distributed systems.

### Performance Impact

- **Stored procedure**: Reduces round-trips. One CALL vs many INSERT/UPDATE.
- **Interactive**: No application overhead. But not automated.

### Data Integrity Implications

- **Stored procedure**: Logic in DB. Single source. All clients get same behavior.
- **Application logic**: Each client must implement correctly. Risk of inconsistency.

---

## 3. PostgreSQL Implementation

### Interactive: psql

```bash
psql -h localhost -U app -d mydb
# \dt  -- list tables
# \d customers  -- describe table
# SELECT * FROM customers LIMIT 5;
```

### CLI: psycopg2 (Python)

```python
import psycopg2
conn = psycopg2.connect(host='localhost', dbname='mydb', user='app', password='...')
cur = conn.cursor()
cur.execute("SELECT * FROM customers WHERE id = %s", (1,))
row = cur.fetchone()
cur.close()
conn.close()
```

### CLI: JDBC (Java)

```java
Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost/mydb", "app", "...");
PreparedStatement stmt = conn.prepareStatement("SELECT * FROM customers WHERE id = ?");
stmt.setInt(1, 1);
ResultSet rs = stmt.executeQuery();
```

### Stored Procedure Call (CLI)

```python
cur.execute("CALL create_order(%s, %s)", (customer_id, items))
conn.commit()
```

---

## 4. Common Developer Mistakes

### Mistake 1: Using Interactive SQL for Production Logic

Ad-hoc scripts in cron. No version control, no error handling. Use application code or stored procedures.

### Mistake 2: String Concatenation for SQL in CLI

`"SELECT * FROM t WHERE id = " + user_input` — SQL injection. Use parameterized queries.

### Mistake 3: Assuming Embedded SQL When Using CLI

CLI sends SQL as string. No precompiler. Placeholders are driver-specific (%s, ?, $1).

### Mistake 4: Ignoring Connection Lifecycle

Leaving connections open. Exhausting pool. Always close or return to pool.

---

## 5. Interview Deep-Dive Section

**Q: What is the difference between embedded SQL and CLI?**  
A: Embedded uses precompiler, host variables in declare section. CLI sends SQL as string via API. CLI is dominant; no precompiler.

**Q: When would you use interactive SQL?**  
A: Ad-hoc queries, DBA tasks, debugging. Not for application logic.

---

## 6. Advanced Engineering Notes

### ORM as Abstraction

ORM (SQLAlchemy, Hibernate) generates SQL from object operations. Still uses CLI under the hood. Trade-off: productivity vs control. Know the generated SQL for performance.

---

## 7. Mini Practical Exercise

1. Run psql. Execute SELECT. Observe output.
2. Write Python script with psycopg2. Connect, execute parameterized SELECT, print result.
3. Call a stored procedure from Python.

---

## 8. Summary in 10 Bullet Points

1. **Interactive**: User runs SQL via client (psql). Ad-hoc, admin.
2. **Embedded**: SQL in host code. Precompiler. Legacy.
3. **CLI**: Library sends SQL as string. ODBC, JDBC, psycopg2. Dominant.
4. **Module**: SQL procedures in separate module. Modern: stored procedures.
5. **Stored procedure**: Logic in DB. Called via CALL. Reduces round-trips.
6. **CLI placeholders**: %s (Python), ? (JDBC), $1 (Node). Parameterized.
7. **No precompiler for CLI**: SQL is string. Driver handles.
8. **Interactive ≠ production**: Use for debugging, not app logic.
9. **ORM uses CLI**: Generates SQL. Know underlying queries.
10. **Environment choice**: CLI for apps; interactive for DBA; procedures for shared logic.
