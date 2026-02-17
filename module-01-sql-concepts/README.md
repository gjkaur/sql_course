# Module 1: SQL Concepts

**Book 1** of SQL All-In-One For Dummies | **Level:** Beginner

## Learning Objectives

By the end of this module, you will:

- Understand the relational model and why it dominates modern databases
- Model a system using Entity-Relationship diagrams
- Know SQL's role (DDL, DML, DCL) and its limitations
- Design schemas with appropriate data types and constraints
- Create a working Online Retail database with seed data

## Week 1 Roadmap (5 Days)

| Day | Topic | Deliverable |
|-----|-------|-------------|
| 1 | PostgreSQL setup, relational model theory | Docker running, first `psql` connection |
| 2 | ER modeling, Online Retail case study | ER diagram |
| 3 | DDL, schema creation | `schema.sql` |
| 4 | Constraints, data integrity | `constraints.sql` |
| 5 | Seed data, exercises | `seed_data.sql`, `exercises.sql` |

## Structure

```
module-01-sql-concepts/
├── theory/          # Engineer-focused summaries
├── labs/            # PostgreSQL setup, ER modeling
├── project/         # Online Retail System
└── interview_questions.md
```

## Quick Start

```bash
# From repo root
docker-compose up -d
psql -h localhost -U sqlcourse -d sqlcourse -f module-01-sql-concepts/project/schema.sql
psql -h localhost -U sqlcourse -d sqlcourse -f module-01-sql-concepts/project/constraints.sql
psql -h localhost -U sqlcourse -d sqlcourse -f module-01-sql-concepts/project/seed_data.sql
```
