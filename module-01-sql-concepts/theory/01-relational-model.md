# Understanding the Relational Model

## Why It Matters for Engineers

The relational model (Codd, 1970) underpins every major database you'll use: PostgreSQL, MySQL, SQL Server, Oracle. Understanding it helps you design schemas that scale and avoid anti-patterns.

## Core Concepts

### Relations = Tables

- A **relation** is a set of tuples (rows) with named attributes (columns)
- No duplicate rows (sets are unique)
- Order of rows is irrelevant
- Each cell contains a single atomic value

### Why the Relational Model Won

| Model | Limitation |
|-------|------------|
| Hierarchical | Rigid parent-child; hard to query across branches |
| Network | Complex pointer navigation; brittle schema changes |
| Relational | Declarative queries; logical independence from physical storage |

**Declarative** means you specify *what* you want, not *how* to get it. The optimizer chooses the best execution plan.

### Keys

- **Primary Key**: Uniquely identifies a row. Choose immutable, minimal attributes.
- **Foreign Key**: References another table's primary key. Enforces referential integrity.
- **Candidate Key**: Any minimal set of columns that uniquely identifies a row.
- **Surrogate Key**: Artificial key (e.g., auto-increment ID). Use when natural keys are composite or unstable.

### Functional Dependencies

`A → B` means: for each value of A, there is exactly one value of B.

Example: `customer_id → customer_name`. Knowing the ID determines the name.

This concept drives **normalization** (Module 2).

## Interview Insight

**Q: Why use a surrogate key instead of a natural key?**

A: Natural keys (e.g., email, SSN) can change, be composite, or expose PII. Surrogate keys (UUID, serial) are stable, simple for joins, and don't leak business meaning. Trade-off: you need a UNIQUE constraint on the natural key if it must stay unique.
