# SQL Mastery Course

A production-grade PostgreSQL SQL course for backend and data engineers. Transform theoretical SQL knowledge into job-ready skills with schema design, performance tuning, security, and real-world projects.

**Based on:** *SQL All-In-One For Dummies, 3rd Edition* by Allen G. Taylor

## Highlights

- **7 modules** + capstone — from SQL basics to DBA-level tuning
- **35+ engineer-level chapter docs** — deep technical explanations, PostgreSQL examples, interview Q&A
- **Production focus** — real failure scenarios, best practices, common mistakes
- **Interview prep** — beginner to advanced questions, troubleshooting scenarios, SQL glossary

## Study Guide

- **[Step-by-step study guide](STUDY_GUIDE.md)** — Phased learning plan, Windows setup, tools required, and troubleshooting.
- **[Next steps after setup](docs/NEXT_STEPS_AFTER_SETUP.md)** — DBeaver connection, loading schema, and starting Module 1.

## Prerequisites

- **Docker** and Docker Compose (for reproducible PostgreSQL environment)
- **psql** or any PostgreSQL client (pgAdmin, DBeaver, etc.)
- Basic programming knowledge (Python for Module 5+)
- Terminal/command line familiarity

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/sql_course-1.git
cd sql_course-1

# Copy environment template and set credentials
cp .env.example .env
# Edit .env with your preferred passwords

# Start PostgreSQL and pgAdmin
docker-compose up -d

# Connect to PostgreSQL (default: localhost:5432)
psql -h localhost -U sqlcourse -d sqlcourse

# Run Module 1 schema
\i module-01-sql-concepts/project/schema.sql
\i module-01-sql-concepts/project/constraints.sql
\i module-01-sql-concepts/project/seed_data.sql
```

## Module Summary

| Module | Focus | Level | Est. Hours |
|--------|-------|-------|------------|
| [Module 1](module-01-sql-concepts/) | SQL Concepts | Beginner | 8-10 |
| [Module 2](module-02-relational-development/) | Relational Database Development | Intermediate | 12-15 |
| [Module 3](module-03-sql-queries/) | SQL Queries | Intermediate | 15-20 |
| [Module 4](module-04-data-security/) | Data Security & Transactions | Advanced | 12-15 |
| [Module 5](module-05-application-integration/) | SQL Integration with Applications | Advanced | 15-20 |
| [Module 6](module-06-json-semi-structured/) | JSON & Semi-Structured Data | Advanced | 8-10 |
| [Module 7](module-07-performance-tuning/) | Performance & Tuning | DBA | 12-15 |
| [Capstone](capstone/ecommerce-database-system/) | Enterprise E-Commerce System | Portfolio | 20-30 |

## Book Chapter Deep-Dives

Engineer-level documentation for every chapter of the source book. Each includes: core concepts, production relevance, PostgreSQL examples, common mistakes, interview questions, and practical exercises.

| Book | Chapters | Docs |
|------|----------|------|
| Book 1: SQL Concepts | 6 | [Ch 1–6](docs/book-chapters/) |
| Book 2: Relational Development | 4 | [Ch 1–4](docs/book-chapters/) |
| Book 3: SQL Queries | 5 | [Ch 1–5](docs/book-chapters/) |
| Book 4: Data Security | 4 | [Ch 1–4](docs/book-chapters/) |
| Book 5: SQL and Programming | 7 | [Ch 1–7](docs/book-chapters/) |
| Book 6: SQL, XML, and JSON | 4 | [Ch 1–4](docs/book-chapters/) |
| Book 7: Database Tuning | 3 | [Ch 1–3](docs/book-chapters/) |
| Book 8: Appendices | 2 | [Glossary](docs/book-chapters/BOOK8-Appendix-A-Glossary.md), [Reserved Words](docs/book-chapters/BOOK8-Appendix-B-Reserved-Words.md) |

→ [Full book-to-module mapping](docs/BOOK_MAPPING.md)

## Portfolio Projects

- **[Online Retail System](module-01-sql-concepts/project/)** — Schema design, constraints, seed data
- **[Fleet Repair System](module-02-relational-development/case-study/fleet_repair/)** — Normalization, index strategy, EXPLAIN analysis
- **[Enterprise E-Commerce Database](capstone/ecommerce-database-system/)** — Full production-grade schema, security, performance

## Interview Prep

- [Beginner Questions](interview-prep/questions/beginner.md)
- [Intermediate Questions](interview-prep/questions/intermediate.md)
- [Advanced Questions](interview-prep/questions/advanced.md)
- [Troubleshooting Scenarios](interview-prep/scenarios/troubleshooting.md)
- [SQL Glossary](interview-prep/flashcards/sql_glossary.md)

## Documentation

- [Course Roadmap](docs/COURSE_ROADMAP.md)
- [Book-to-Module Mapping](docs/BOOK_MAPPING.md)
- [Production Failure Case Studies](docs/PRODUCTION_FAILURES.md)
- [Book Chapters](docs/book-chapters/) — All 35+ chapter documents

## License

MIT License — See [LICENSE](LICENSE) for details.
