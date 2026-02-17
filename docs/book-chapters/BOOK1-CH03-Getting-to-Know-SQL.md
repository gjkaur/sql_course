# BOOK 1 – Chapter 3: Getting to Know SQL

---

## 1. Core Concept Explanation (Deep Technical Version)

### SQL as a Data Sublanguage

SQL is a **data sublanguage**, not a general-purpose programming language. It is designed exclusively for defining, manipulating, and controlling data in relational databases. It lacks constructs that general-purpose languages have: no unbounded loops, no arbitrary branching, no file I/O, no network sockets. This is intentional—SQL's domain is data, and it delegates everything else to host languages or the DBMS.

A **sublanguage** implies that SQL is embedded within or called from another language. You write application logic in Python, Java, or Go; you invoke SQL when you need to read or write the database. The division of responsibility is clear: the host handles control flow and I/O; SQL handles set-at-a-time data operations.

### Turing Completeness and Why SQL Isn't

A language is **Turing-complete** if it can express any computation that a Turing machine can perform. C, Java, Python—all are Turing-complete. They can loop indefinitely, branch arbitrarily, and simulate any algorithm.

**Standard SQL is not Turing-complete.** You cannot write an unbounded loop in pure SQL. You cannot implement a general recursive algorithm without extensions (e.g., recursive CTEs, which are bounded by the data). This limitation is by design: SQL is declarative. You specify *what* you want; the DBMS figures out *how*. Introducing arbitrary control flow would undermine that model and make optimization harder.

**Vendor extensions** (e.g., PL/pgSQL, T-SQL, PL/SQL) add procedural constructs—loops, conditionals, variables—making them Turing-complete. When you write a stored procedure in PL/pgSQL, you are no longer in "pure" SQL; you are in an extended dialect.

### The SQL Joke (Voltaire's SQL)

"SQL is not structured, not restricted to queries, and not a language."

- **Not structured**: In programming, "structured" often means single-entry, single-exit control flow (no GOTO). SQL has no control flow in the traditional sense.
- **Not restricted to queries**: SQL does DDL (CREATE, ALTER), DML (INSERT, UPDATE, DELETE), DCL (GRANT, REVOKE). SELECT is just one operation.
- **Not a language**: In the sense of Turing-complete; it's a sublanguage.

### Origin: SEQUEL to SQL

IBM developed **SEQUEL** (Structured English Query Language) for its System/38 RDBMS. The name reflected the English-like, structured syntax. Legal concerns over the trademark led to dropping the vowels: **SQL**. The "Structured Query Language" expansion is a backronym—widespread but historically inaccurate.

**Oracle** (Relational Software, Inc., 1979) was the first standalone RDBMS to market, beating IBM's SQL/DS. Oracle's success established SQL as the de facto standard before ANSI standardized it in 1986 (SQL-86).

### ISO/IEC SQL Standard Evolution

| Version | Year | Notable Additions |
|---------|------|-------------------|
| SQL-86 | 1986 | First ANSI standard |
| SQL-89 | 1989 | Referential integrity |
| SQL-92 | 1992 | Major revision; JOIN syntax, schema manipulation |
| SQL:1999 | 1999 | CTEs, triggers, stored procedures, user-defined types |
| SQL:2003 | 2003 | XML, sequences, window functions |
| SQL:2008 | 2008 | MERGE, TRUNCATE |
| SQL:2011 | 2011 | Temporal tables (system-versioned) |
| SQL:2016 | 2016 | JSON, polymorphic table functions |

**No DBMS is fully compliant.** Vendors implement subsets and add extensions. PostgreSQL, for example, has strong JSON support (JSONB) and arrays—beyond the standard—while some standard features (e.g., full temporal SQL:2011) are partial or absent. Portability requires sticking to common subsets and testing.

### Database vs DBMS vs Database Application

- **Database**: The structured collection of data (tables, rows, indexes). The data itself.
- **DBMS**: The engine that stores, retrieves, and secures the database. PostgreSQL, MySQL, Oracle.
- **Database application**: The program (e.g., web app, CLI tool) that uses the DBMS to operate on the database. The application connects to the DBMS; the DBMS accesses the database.

---

## 2. Why This Matters in Production

### Real-World System Example

A microservices architecture: each service uses a different language (Go, Python, Node). All communicate with PostgreSQL via SQL (or an ORM that generates SQL). The SQL standard ensures that the same query works regardless of which service issues it. Vendor lock-in (e.g., Oracle-specific syntax) would force rewrites when switching databases.

### Scalability Impact

- **SQL as interface**: The DBMS can optimize, cache, and parallelize. Application code doesn't need to know how.
- **Non-SQL interfaces**: Custom protocols or ORMs that bypass SQL can limit optimization. Standard SQL gives the planner maximum flexibility.

### Performance Impact

- **Declarative**: "SELECT * FROM orders WHERE status = 'shipped'"—planner chooses index scan, sequential scan, or parallel scan. You don't specify the algorithm.
- **Procedural (in DB)**: PL/pgSQL loops row-by-row can be 10–100x slower than set-based SQL. Use SQL for bulk operations; use procedural code only when necessary.

### Data Integrity Implications

- **DDL in SQL**: Schema changes are transactional in PostgreSQL. CREATE TABLE, ALTER TABLE are part of the language; the DBMS enforces consistency.
- **DCL in SQL**: GRANT, REVOKE live in the catalog. Security is enforced by the DBMS, not by each application.

### Production Failure Scenario

**Case: Oracle-to-PostgreSQL migration.** A team assumed "SQL is SQL." They discovered Oracle's `(+)` outer join syntax, `CONNECT BY` hierarchies, and `ROWNUM` had no direct PostgreSQL equivalents. Migration took months. Lesson: Know your target DBMS. Use standard syntax (e.g., `LEFT JOIN`, recursive CTEs, `LIMIT`) when possible; document and isolate vendor-specific code.

---

## 3. PostgreSQL Implementation

### Verifying SQL Capabilities

```sql
-- PostgreSQL version and standard compliance
SELECT version();

-- List available extensions (many add SQL functions)
SELECT * FROM pg_available_extensions;

-- Check if a feature exists (e.g., JSONB)
SELECT '{"a":1}'::jsonb ->> 'a';
```

### Standard vs PostgreSQL-Specific

```sql
-- Standard: LIMIT/OFFSET
SELECT * FROM orders ORDER BY id LIMIT 10 OFFSET 20;

-- PostgreSQL: Also supports LIMIT/OFFSET (same as standard)
-- Some DBs use TOP (SQL Server) or FETCH FIRST (standard alternative)

-- Standard: Boolean
SELECT true, false;

-- PostgreSQL: Full boolean type; some DBs use 0/1 or 'Y'/'N'

-- PostgreSQL-specific: RETURNING (also in Oracle, SQL Server)
INSERT INTO customers (name, email) VALUES ('Alice', 'alice@x.com')
RETURNING id, created_at;
```

### Embedding SQL in Application (Python/psycopg2)

```python
import psycopg2

conn = psycopg2.connect("dbname=sqlcourse user=sqlcourse")
cur = conn.cursor()

# Parameterized query (prevents SQL injection)
cur.execute("SELECT * FROM customers WHERE id = %s", (42,))
rows = cur.fetchall()

# DML with transaction
cur.execute("INSERT INTO orders (customer_id, status) VALUES (%s, %s)", (1, 'pending'))
conn.commit()

cur.close()
conn.close()
```

### Choosing PostgreSQL Over Alternatives

| Criterion | PostgreSQL | MySQL | SQL Server | Oracle |
|-----------|------------|-------|------------|--------|
| Open source | Yes | Yes (GPL) | No | No |
| ACID | Full | InnoDB | Full | Full |
| JSON/JSONB | Excellent | Good | Good | Good |
| Window functions | Full | 8.0+ | Full | Full |
| CTEs (WITH) | Full | 8.0+ | Full | Full |
| Extensibility | High | Lower | Medium | High |
| Licensing cost | Free | Free | Paid | Paid |

---

## 4. Common Developer Mistakes

### Mistake 1: Assuming SQL Is Turing-Complete

Writing complex procedural logic in SQL (nested loops, state machines) when a host language would be clearer. Use SQL for data operations; use application code for control flow.

### Mistake 2: Ignoring the Standard

Using `SELECT TOP 10` (SQL Server) or `LIMIT 10` (MySQL/PostgreSQL) without knowing the standard (`FETCH FIRST 10 ROWS ONLY`). For portability, prefer standard syntax or abstract behind a repository layer.

### Mistake 3: Treating All DBMSs as Interchangeable

Assuming Oracle SQL runs on PostgreSQL. Date arithmetic, string functions, and NULL handling differ. Test on target DBMS early.

### Mistake 4: Using SQL for Non-Data Tasks

Generating reports in SQL when a reporting tool (Metabase, Looker) or application layer would be better. SQL is for data; formatting, scheduling, and delivery are application concerns.

### Mistake 5: Confusing Database and DBMS

Saying "the database is down" when the DBMS process crashed. The database (data) may be intact; the DBMS (engine) is what restarts. Precision matters in incident response.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: Why is SQL called a data sublanguage?**  
A: It handles only data operations—definition, manipulation, control. It lacks general-purpose features (loops, I/O, networking). It is embedded in or called from host languages for full applications.

**Q: Is SQL Turing-complete?**  
A: Standard SQL is not. It has no unbounded loops or arbitrary control flow. Procedural extensions (PL/pgSQL, T-SQL) are Turing-complete.

**Q: What is the difference between a database and a DBMS?**  
A: Database = the data (tables, rows). DBMS = the software that stores, retrieves, and secures it (e.g., PostgreSQL). The application talks to the DBMS; the DBMS operates on the database.

### Scenario-Based Questions

**Q: You need to migrate from MySQL to PostgreSQL. What do you watch for?**  
A: Syntax (AUTO_INCREMENT vs SERIAL, backticks vs double quotes), functions (DATE_ADD vs INTERVAL), boolean (TINYINT vs BOOLEAN), case sensitivity. Use a migration tool, run tests, and isolate DB-specific code.

**Q: When would you use a stored procedure vs application code?**  
A: Stored procedure: multi-step logic that must be atomic, reduce round-trips, or enforce logic at the DB layer. Application: business logic that changes often, needs unit tests, or involves external services.

### Optimization Questions

**Q: Why is set-based SQL usually faster than row-by-row processing?**  
A: Set-based operations let the planner use indexes, parallel execution, and bulk I/O. Row-by-row (cursor, loop) does N round-trips and N index lookups. One set operation can replace thousands of row operations.

---

## 6. Advanced Engineering Notes

### Internal Behavior

- **Query parsing**: SQL text → parse tree → semantic analysis → rewrite (views, rules) → planner → executor. The planner is the brain; it chooses algorithms.
- **Standard vs implementation**: The standard defines *behavior*, not *implementation*. Two DBMSs can be compliant and produce different plans for the same query.

### Tradeoffs

| Approach | Pros | Cons |
|----------|------|------|
| Pure SQL | Portable, declarative, optimizable | Limited expressiveness |
| PL/pgSQL | Full control flow, fewer round-trips | DBMS lock-in, harder to test |
| ORM | Language-native, less SQL to write | Generated SQL can be suboptimal |
| Raw SQL in app | Full control, testable | More code, injection risk if not parameterized |

### Design Alternatives

- **NoSQL**: Document (MongoDB), key-value (Redis), graph (Neo4j). Use when workload doesn't fit relational (flexible schema, graph traversals). SQL remains dominant for OLTP and reporting.
- **NewSQL**: CockroachDB, TiDB. SQL interface with distributed storage. For scale-out when single-node PostgreSQL isn't enough.

---

## 7. Mini Practical Exercise

### Hands-On SQL Task

Connect to PostgreSQL and run:

1. `SELECT version();` — confirm you're on PostgreSQL.
2. `SELECT current_database(), current_user;` — confirm database and user.
3. `\dt` (psql) or `SELECT tablename FROM pg_tables WHERE schemaname = 'public';` — list tables.
4. A simple SELECT from one of the course tables (e.g., `SELECT * FROM customers LIMIT 5;`).

### Schema Modification Task

Create a table using only standard SQL where possible. Use `SERIAL` (PostgreSQL) or `BIGSERIAL` for the primary key—document that this is PostgreSQL-specific (standard uses `IDENTITY` in SQL:2003+).

```sql
-- PostgreSQL
CREATE TABLE demo (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100)
);

-- Standard SQL:2016 (IDENTITY)
-- CREATE TABLE demo (
--   id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--   name VARCHAR(100)
-- );
```

### Query Challenge

Write a query that would be difficult or impossible in a non-Turing-complete language without recursion: "Find all ancestors of employee X in an organizational hierarchy." Use a recursive CTE. This demonstrates that SQL, with extensions, can handle recursive structures—bounded by the data, not unbounded loops.

```sql
WITH RECURSIVE hierarchy AS (
  SELECT id, name, manager_id, 1 AS level
  FROM employees WHERE id = 42
  UNION ALL
  SELECT e.id, e.name, e.manager_id, h.level + 1
  FROM employees e
  JOIN hierarchy h ON e.id = h.manager_id
)
SELECT * FROM hierarchy;
```

---

## 8. Summary in 10 Bullet Points

1. **SQL is a data sublanguage**—for data only; host languages handle control flow and I/O.
2. **Standard SQL is not Turing-complete**—no unbounded loops; procedural extensions (PL/pgSQL) are.
3. **SQL ≠ "Structured Query Language"**—original name was SEQUEL; SQL is a legal truncation.
4. **ISO/IEC standard**—SQL-86 through SQL:2016; no DBMS is fully compliant; use for portability guidance.
5. **Database vs DBMS vs application**—data, engine, and program are distinct concepts.
6. **Declarative**—you specify what; the planner chooses how; enables optimization.
7. **Vendor extensions**—lock-in risk; document and isolate non-standard code.
8. **PostgreSQL**—open source, strong standard compliance, JSONB, extensibility.
9. **Embedding**—SQL is called from host languages via parameterized queries; never concatenate user input.
10. **Set-based over row-based**—prefer bulk SQL operations over cursors/loops for performance.
