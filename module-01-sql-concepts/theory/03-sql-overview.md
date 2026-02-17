# Getting to Know SQL

## What SQL Is

**Structured Query Language** — a declarative language for defining and manipulating relational data. You describe *what* you want; the DBMS figures out *how*.

## What SQL Does

- **Define** schemas (tables, indexes, views)
- **Manipulate** data (INSERT, UPDATE, DELETE)
- **Query** data (SELECT)
- **Control** access (GRANT, REVOKE)
- **Manage** transactions (BEGIN, COMMIT, ROLLBACK)

## What SQL Does NOT Do

- **No control flow** in standard SQL (no if/else, loops) — use procedural extensions (PL/pgSQL) or application code
- **No I/O** (file, network) — database is the data store
- **No UI** — you need an application layer
- **Vendor-specific** — each DBMS extends the standard (PostgreSQL vs MySQL vs Oracle)

## ISO/IEC SQL Standard

- SQL-86, SQL-89, SQL-92, SQL:1999, SQL:2003, SQL:2008, SQL:2011, SQL:2016
- PostgreSQL aims for compliance; check docs for deviations
- Use standard syntax when possible for portability

## Choosing PostgreSQL

- Open source, ACID-compliant
- Advanced features: JSONB, full-text search, partitioning, window functions
- Extensible (custom types, functions)
- Industry adoption: Instagram, Uber, Spotify use it

## Interview Insight

**Q: What's the difference between SQL and NoSQL?**

A: SQL is relational, schema-first, ACID, best for structured data and complex queries. NoSQL (document, key-value, graph) trades consistency or structure for scale/flexibility. Hybrid: PostgreSQL's JSONB gives you both in one system.
