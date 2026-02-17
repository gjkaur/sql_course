# BOOK 8 – Appendix B: SQL Reserved Words

---

## Overview

**Reserved words** have special meaning in SQL. Using them as identifiers (table names, column names) can cause parser errors. **Non-reserved** keywords have special meaning only in certain contexts and can be used as identifiers elsewhere.

**PostgreSQL**: Many "reserved" words are allowed as column labels (e.g., `SELECT 1 AS CHECK`). Quoting with double quotes allows use as identifier: `"order"` for a table named order.

**Rule**: If you get parser errors with a keyword as identifier, try quoting: `"user"`, `"order"`, `"group"`.

---

## Commonly Problematic Words (Avoid as Identifiers)

These often cause issues when used as table or column names without quoting:

| Word | Context | Alternative |
|------|---------|-------------|
| **ORDER** | ORDER BY | Use `orders` (table) |
| **USER** | CURRENT_USER | Use `user_id`, `username` |
| **GROUP** | GROUP BY | Use `group_name`, `groups` |
| **KEY** | PRIMARY KEY | Use `api_key`, `key_name` |
| **TABLE** | CREATE TABLE | Use `table_name` |
| **SELECT** | SELECT | Never as identifier |
| **FROM** | FROM | Never as identifier |
| **WHERE** | WHERE | Never as identifier |
| **CHECK** | CHECK constraint | Use `check_number`, `health_check` |
| **DEFAULT** | DEFAULT value | Use `default_value` |
| **INDEX** | CREATE INDEX | Use `index_name` |
| **LEVEL** | Isolation level | Use `log_level`, `access_level` |
| **ROLE** | GRANT role | Use `role_name`, `user_role` |
| **SESSION** | Session variable | Use `session_id` |
| **TYPE** | Data type | Use `type_name`, `event_type` |
| **VIEW** | CREATE VIEW | Use `view_name` |
| **CASE** | CASE expression | Use `case_id`, `support_case` |
| **END** | END (block) | Use `end_date`, `end_time` |
| **NULL** | NULL value | Never as identifier |
| **TRUE**, **FALSE** | Boolean | Use `is_active`, `flag` |

---

## PostgreSQL: Reserved vs Non-Reserved

**Reserved** (not allowed as table/column names without quoting): ALL, AND, ANY, ARRAY, AS, ASC, ASYMMETRIC, AUTHORIZATION, BINARY, BOTH, CASE, CAST, CHECK, COLLATE, COLUMN, CONNECT, CONSTRAINT, CORRESPONDING, CREATE, CROSS, CURRENT_CATALOG, CURRENT_DATE, CURRENT_ROLE, CURRENT_SCHEMA, CURRENT_TIME, CURRENT_TIMESTAMP, CURRENT_USER, DEC, DEFAULT, DEFERRABLE, DESC, DISTINCT, DO, ELSE, END, EXCEPT, FALSE, FETCH, FOR, FOREIGN, FREEZE, FROM, FULL, GRANT, GROUP, HAVING, IN, INITIALLY, INNER, INTERSECT, INTO, IS, JOIN, LATERAL, LEADING, LEFT, LIKE, LIMIT, LOCALTIME, LOCALTIMESTAMP, NOT, NULL, OFFSET, ON, ONLY, OR, ORDER, OUTER, OVERLAPS, PLACING, PRIMARY, REFERENCES, RETURNING, RIGHT, SELECT, SESSION_USER, SIMILAR, SOME, SYMMETRIC, TABLE, TABLESAMPLE, THEN, TO, TRAILING, TRUE, UNION, UNIQUE, USER, USING, VARIADIC, WHEN, WHERE, WINDOW, WITH.

**Non-reserved** (allowed as identifiers in most contexts): ADD, ADMIN, AGGREGATE, ALTER, ANALYZE, ATTACH, ATTRIBUTE, BACKWARD, BEFORE, BEGIN, BY, CACHE, CALL, CALLED, CASCADE, CASCADED, CATALOG, CHAIN, CHARACTERISTICS, CHECKPOINT, CLASS, CLOSE, CLUSTER, COALESCE, COLLATION, COLUMNS, COMMENT, COMMENTS, COMMIT, COMMITTED, CONFIGURATION, CONFLICT, CONNECTION, CONSTRAINTS, CONTENT, CONTINUE, CONVERSION, COPY, COST, CREATE, CSV, CUBE, CURRENT, CURSOR, CYCLE, DATA, DATABASE, DAY, DEALLOCATE, DECLARE, DEFAULT, DEFAULTS, DEFERRED, DEFINER, DELETE, DELIMITER, DELIMITERS, DEPENDS, DETACH, DICTIONARY, DISABLE, DISCARD, DOCUMENT, DOMAIN, DOUBLE, DROP, EACH, ENABLE, ENCODING, ENCRYPTED, ENUM, ESCAPE, EVENT, EXCLUDE, EXCLUDING, EXCLUSIVE, EXECUTE, EXPLAIN, EXTENSION, EXTERNAL, FAMILY, FILTER, FIRST, FOLLOWING, FORCE, FORWARD, FUNCTION, FUNCTIONS, GLOBAL, GRANTED, HANDLER, HEADER, HOLD, HOUR, IDENTITY, IF, IMMEDIATE, IMMUTABLE, IMPLICIT, IMPORT, INCLUDE, INCLUDING, INCREMENT, INDEX, INDEXES, INHERIT, INHERITS, INITIAL, INLINE, INPUT, INSENSITIVE, INSERT, INSTEAD, INVOKER, ISOLATION, LABEL, LANGUAGE, LARGE, LAST, LEAKPROOF, LISTEN, LOAD, LOCAL, LOCATION, LOCK, LOCKED, LOGGED, MAPPING, MATERIALIZED, MAXVALUE, METHOD, MINUTE, MINVALUE, MODE, MONTH, MOVE, NAME, NAMES, NATIONAL, NESTED, NEW, NEXT, NO, NORMALIZED, NOTHING, NOTIFY, NOTNULL, NOWAIT, NULLS, OBJECT, OF, OFF, OIDS, OPERATOR, OPTION, OPTIONS, ORDINALITY, OVER, OVERRIDE, OWNED, OWNER, PARALLEL, PARSER, PARTITION, PASSING, PASSWORD, PLANS, POLICY, PRECEDING, PREPARE, PREPARED, PRESERVE, PRIOR, PRIVILEGES, PROCEDURAL, PROCEDURE, PROCEDURES, PROGRAM, PUBLICATION, QUOTE, RANGE, READ, REASSIGN, RECHECK, RECURSIVE, REF, REFERENCING, REFRESH, REINDEX, RELATIVE, RELEASE, RENAME, REPEATABLE, REPLACE, REPLICA, RESET, RESTART, RESTRICT, RETURN, RETURNS, REVOKE, ROLE, ROLLBACK, ROUTINE, ROUTINES, ROWS, RULE, SAVEPOINT, SCHEMA, SCHEMAS, SCROLL, SEARCH, SECOND, SECURITY, SEQUENCE, SEQUENCES, SERIALIZABLE, SERVER, SESSION, SET, SETS, SHARE, SHOW, SIMPLE, SKIP, SNAPSHOT, SQL, STABLE, STANDALONE, START, STATEMENT, STATISTICS, STDIN, STDOUT, STORAGE, STORED, STRICT, STRIP, SUBSCRIPTION, SUPPORT, SYSID, SYSTEM, TABLES, TABLESPACE, TEMP, TEMPLATE, TEMPORARY, TEXT, TIES, TRANSACTION, TRANSFORM, TRIGGER, TRUNCATE, TRUSTED, TYPE, TYPES, UNBOUNDED, UNCOMMITTED, UNENCRYPTED, UNKNOWN, UNLISTEN, UNLOGGED, UNTIL, UPDATE, VACUUM, VALID, VALIDATE, VALIDATOR, VALUE, VARYING, VERSION, VIEW, VIEWS, VOLATILE, WHITESPACE, WORK, WRAPPER, WRITE, XML, XMLATTRIBUTES, XMLCONCAT, XMLELEMENT, XMLEXISTS, XMLFOREST, XMLNAMESPACES, XMLPARSE, XMLPI, XMLROOT, XMLSERIALIZE, XMLTABLE, YEAR, YES, ZONE.

---

## Using Reserved Words as Identifiers

```sql
-- Quoting allows reserved word as identifier
CREATE TABLE "order" (id SERIAL PRIMARY KEY);
SELECT * FROM "order";

-- Column alias with AS
SELECT 1 AS "check";

-- Best practice: avoid reserved words. Use orders, user_id, group_name.
```

---

## Full List

The complete list of SQL key words for PostgreSQL is maintained in the official documentation:

**PostgreSQL Appendix C: SQL Key Words**  
https://www.postgresql.org/docs/current/sql-keywords-appendix.html

The table classifies each keyword as reserved or non-reserved and notes special cases (e.g., "requires AS" for column labels).

---

## Summary

1. **Avoid** reserved words as identifiers when possible.
2. **Quote** with double quotes if you must use one: `"order"`.
3. **Use alternatives**: `orders` instead of `order`, `user_id` instead of `user`.
4. **Check** the official list when adding new tables/columns.
5. **Non-reserved** words are generally safe but can have special meaning in context (e.g., `position` in SUBSTRING).
