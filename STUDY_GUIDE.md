# SQL Mastery Course — Step-by-Step Study Guide

A practical guide to using this repository for self-study. Follow phases in order; each builds on the previous.

---

## Tools & Software Required (Windows)

### Essential

| Tool | Purpose | Install |
|------|---------|---------|
| **Docker Desktop** | Run PostgreSQL in a container | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) — Download Docker Desktop for Windows |
| **Git** | Clone and manage the repo | [git-scm.com/download/win](https://git-scm.com/download/win) — Git for Windows |
| **VS Code** or **Cursor** | Edit SQL, Markdown, config files | [code.visualstudio.com](https://code.visualstudio.com/) or [cursor.com](https://cursor.com/) |
| **PowerShell** or **Windows Terminal** | Run commands, connect to PostgreSQL | Built-in (Windows 10/11) or [aka.ms/terminal](https://aka.ms/terminal) |

### PostgreSQL Client (choose one)

| Tool | Purpose | Install |
|------|---------|---------|
| **psql** (CLI) | Command-line SQL client | Comes with PostgreSQL. Use Docker: `docker exec -it sqlcourse-postgres psql -U sqlcourse -d sqlcourse` |
| **pgAdmin** | GUI for PostgreSQL | [pgadmin.org](https://www.pgadmin.org/download/) — or use Docker: `docker-compose up -d` (pgAdmin included) |
| **DBeaver** | Universal DB GUI (free) | [dbeaver.io](https://dbeaver.io/download/) — Community Edition |
| **Azure Data Studio** | Lightweight SQL client | [aka.ms/azuredatastudio](https://aka.ms/azuredatastudio) — with PostgreSQL extension |

### Optional (Module 5+)

| Tool | Purpose | Install |
|------|---------|---------|
| **Python 3.10+** | Application integration, psycopg2 | [python.org/downloads](https://www.python.org/downloads/) — Check "Add to PATH" |
| **Node.js** (optional) | If using Node + pg driver | [nodejs.org](https://nodejs.org/) |

### Windows-Specific Notes

- **Docker Desktop**: Requires WSL 2 or Hyper-V. Enable in Windows Features if prompted.
- **Path**: Add Python and Git to PATH during installation.
- **Line endings**: Git may convert CRLF ↔ LF. Usually fine; if SQL scripts fail, check encoding.
- **PowerShell**: Use `.\` for scripts: `.\docker-compose up -d`. Or use Git Bash for Unix-like commands.

---

## Phase 0: Setup (Day 1)

### 1. Install Prerequisites

- Install **Docker Desktop** → Start Docker
- Install **Git**
- Install a **PostgreSQL client** (pgAdmin or DBeaver recommended for beginners)

### 2. Clone and Configure

```powershell
# Clone (adjust URL to your fork if applicable)
git clone https://github.com/yourusername/sql_course-1.git
cd sql_course-1

# Copy environment template
copy .env.example .env

# Edit .env with Notepad or VS Code — set passwords if desired
notepad .env
```

### 3. Start PostgreSQL

```powershell
# PostgreSQL only
docker-compose up -d

# PostgreSQL + pgAdmin (GUI)
docker-compose --profile tools up -d
```

pgAdmin will be at http://localhost:5050 (email/password from `.env` or defaults: admin@sqlcourse.local / admin).

### 4. Verify Connection

**Option A — psql (inside container):**

```powershell
docker exec -it sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

Then in psql:

```sql
SELECT version();
\q
```

**Option B — pgAdmin (if using `--profile tools`):**

- Open http://localhost:5050
- Add server: host `postgres` (Docker service name), port `5432`, database `sqlcourse`, user `sqlcourse`, password from `.env` (default: `sqlcourse`)

**Option C — DBeaver:**

- New Connection → PostgreSQL
- Host: `localhost`, Port: `5432`, Database: `sqlcourse`, User: `sqlcourse`, Password: from `.env`

### 5. Load Module 1 Schema

**Option A — PowerShell (pipe file into container):**

```powershell
Get-Content module-01-sql-concepts/project/schema.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
Get-Content module-01-sql-concepts/project/constraints.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
Get-Content module-01-sql-concepts/project/seed_data.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

**Option B — pgAdmin or DBeaver (easiest on Windows):**

1. Connect to the database (localhost:5432, sqlcourse/sqlcourse).
2. Open each file: `module-01-sql-concepts/project/schema.sql`, then `constraints.sql`, then `seed_data.sql`.
3. Execute (F5 or Run).

**Option C — Git Bash (if installed):**

```bash
docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse < module-01-sql-concepts/project/schema.sql
docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse < module-01-sql-concepts/project/constraints.sql
docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse < module-01-sql-concepts/project/seed_data.sql
```

---

## Phase 1: Foundation (Weeks 1–2) — Module 1

**Goal:** Relational model, ER modeling, DDL, constraints, basic queries.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-01-sql-concepts/theory/` (01–05) |
| 2 | Read Book 1 chapters | `docs/book-chapters/BOOK1-CH01` through `BOOK1-CH06` |
| 3 | Do labs | `labs/01-postgres-setup.md`, `02-er-modeling-exercise.md` |
| 4 | Build project | `project/` — schema, constraints, seed data |
| 5 | Practice queries | Run SELECT, INSERT, UPDATE on seed data |
| 6 | Review interview questions | `module-01-sql-concepts/interview_questions.md` |

**Per-module pattern:** Theory → Book chapters → Labs → Project → Interview questions.

---

## Phase 2: Design (Weeks 3–4) — Module 2

**Goal:** SDLC, normalization, anomalies, indexes.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-02-relational-development/theory/` |
| 2 | Read Book 2 chapters | `docs/book-chapters/BOOK2-CH01` through `BOOK2-CH04` |
| 3 | Do labs | `01-normalization-exercise.md`, `02-index-design-lab.md` |
| 4 | Case study | `case-study/fleet_repair/` — requirements, ER, denormalization |
| 5 | Interview prep | `module-02-relational-development/interview_questions.md` |

---

## Phase 3: Queries (Weeks 5–7) — Module 3

**Goal:** SELECT, subqueries, JOINs, set operators, cursors.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-03-sql-queries/theory/` |
| 2 | Read Book 3 chapters | `docs/book-chapters/BOOK3-CH01` through `BOOK3-CH05` |
| 3 | Do labs | `03-slow-query-debugging.md` |
| 4 | Use EXPLAIN | `module-03-sql-queries/performance/explain_analyze_breakdown.md` |
| 5 | Practice | Run all query examples from Book 3 chapters on your schema |

---

## Phase 4: Security (Weeks 8–9) — Module 4

**Goal:** ACID, locking, RBAC, error handling, backup.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-04-data-security/theory/` |
| 2 | Read Book 4 chapters | `docs/book-chapters/BOOK4-CH01` through `BOOK4-CH04` |
| 3 | Labs & backup | `backup-recovery/` — pg_dump, WAL, PITR |
| 4 | Case studies | `docs/PRODUCTION_FAILURES.md` |

---

## Phase 5: Integration (Weeks 10–12) — Module 5

**Goal:** Parameterized queries, stored procedures, triggers, connection pooling.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-05-application-integration/theory/` |
| 2 | Read Book 5 chapters | `docs/book-chapters/BOOK5-CH01` through `BOOK5-CH07` |
| 3 | Mini backend | `labs/03-api-postgres-demo/`, `mini-backend/` |
| 4 | Practice | Write Python scripts with psycopg2, parameterized queries, procedures |

**Python on Windows:** `pip install psycopg2-binary` (or `psycopg` for psycopg3).

---

## Phase 6: JSON (Weeks 13–14) — Module 6

**Goal:** JSONB, operators, indexes, hybrid schema.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-06-json-semi-structured/theory/` |
| 2 | Read Book 6 chapters | `docs/book-chapters/BOOK6-CH01` through `BOOK6-CH04` |
| 3 | Labs | `04-practical-use-cases.md` |
| 4 | Practice | Add JSONB columns, use `->`, `->>`, `@>`, GIN indexes |

---

## Phase 7: Tuning (Weeks 15–16) — Module 7

**Goal:** Index tuning, partitioning, monitoring, bottlenecks.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read theory | `module-07-performance-tuning/theory/` |
| 2 | Read Book 7 chapters | `docs/book-chapters/BOOK7-CH01` through `BOOK7-CH03` |
| 3 | Labs | `01-slow-db-simulation`, `02-optimization-report`, `04-dba-troubleshooting-guide` |
| 4 | Practice | Run EXPLAIN ANALYZE, use pg_stat_activity, pg_stat_statements |

---

## Phase 8: Capstone (Weeks 17–20)

**Goal:** End-to-end e-commerce database.

| Step | What to Do | Where |
|------|------------|-------|
| 1 | Read requirements | `capstone/ecommerce-database-system/` |
| 2 | Design schema | ER diagram, normalization |
| 3 | Implement | Schema, indexes, security, procedures |
| 4 | Document | Design decisions, trade-offs |

---

## Ongoing: Interview Prep

| When | What |
|------|------|
| After each module | `module-XX/.../interview_questions.md` |
| Before interviews | `interview-prep/questions/` (beginner → advanced) |
| Scenarios | `interview-prep/scenarios/troubleshooting.md` |
| Quick reference | `interview-prep/flashcards/sql_glossary.md` |
| Appendices | `docs/book-chapters/BOOK8-Appendix-A-Glossary.md`, `BOOK8-Appendix-B-Reserved-Words.md` |

---

## Study Tips

1. **Follow the pattern:** Theory → Book chapters → Labs → Project per module.
2. **Run every SQL example** — use the Online Retail schema or create small test tables.
3. **Complete the Mini Exercises** — each Book chapter ends with a practical task.
4. **Timebox:** ~10 hrs/week part-time ≈ 12–16 weeks; full-time ≈ 6–8 weeks.
5. **Take notes** — summarize concepts, mistakes, and interview-style answers.

---

## Quick Reference: File Map

| Purpose | Location |
|---------|----------|
| Theory per module | `module-XX/.../theory/*.md` |
| Labs | `module-XX/.../labs/*.md` |
| Projects | `module-01/.../project/`, `module-02/.../case-study/`, `capstone/` |
| Deep-dive chapters | `docs/book-chapters/BOOK*-CH*.md` |
| Interview prep | `interview-prep/` |
| Roadmap | `docs/COURSE_ROADMAP.md` |
| Book mapping | `docs/BOOK_MAPPING.md` |

---

## Troubleshooting (Windows)

| Issue | Solution |
|-------|----------|
| Docker won't start | Enable WSL 2 or Hyper-V in Windows Features. Restart. |
| `docker-compose` not found | Use `docker compose` (no hyphen) in newer Docker Desktop. |
| psql not found | Use `docker exec -it sqlcourse-postgres psql ...` instead of local psql. |
| Permission denied on .env | Run terminal as Administrator or check file permissions. |
| Python/pip not found | Reinstall Python, check "Add to PATH". Restart terminal. |
| Line ending errors in SQL | In Git: `git config core.autocrlf true` or open files in VS Code and set LF. |
