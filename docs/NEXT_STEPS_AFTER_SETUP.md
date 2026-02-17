# Next Steps After Setup — Detailed Guide

You've started PostgreSQL with a fresh database. Follow these steps in order.

---

## Step 1: Wait for PostgreSQL to Be Ready (10–15 seconds)

PostgreSQL needs a few seconds to initialize. Check it's healthy:

```powershell
docker ps
```

You should see `sqlcourse-postgres` with status **Up** and **(healthy)**.

---

## Step 2: Connect with DBeaver

1. Open **DBeaver**.
2. **Database** → **New Database Connection** → **PostgreSQL** → **Next**.
3. Enter:
   - **Host:** `localhost`
   - **Port:** `5432`
   - **Database:** `sqlcourse`
   - **Username:** `sqlcourse`
   - **Password:** *(leave blank — trust auth)*
   - Check **Save password** (optional).
4. Click **Test Connection**.
   - If prompted to download drivers, click **Download**.
   - You should see "Connected".
5. Click **Finish**.

---

## Step 3: Load the Module 1 Schema

You need to run three SQL files in order. Choose one method:

### Method A: DBeaver (recommended)

1. In DBeaver, expand your connection → **sqlcourse** → **Schemas** → **public**.
2. Right-click the connection → **SQL Editor** → **Open SQL Script**.
3. Open: `module-01-sql-concepts/project/schema.sql`
4. Press **Ctrl+Enter** (or click Execute) to run the whole script.
5. Repeat for:
   - `module-01-sql-concepts/project/constraints.sql`
   - `module-01-sql-concepts/project/seed_data.sql`

### Method B: PowerShell

```powershell
cd "C:\Users\GURINDER\Gurinder Data\My_GitHub\sql_course-1"

Get-Content module-01-sql-concepts/project/schema.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
Get-Content module-01-sql-concepts/project/constraints.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
Get-Content module-01-sql-concepts/project/seed_data.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

---

## Step 4: Verify the Schema

In DBeaver:

1. Right-click **sqlcourse** → **Refresh** (or F5).
2. Expand **sqlcourse** → **Schemas** → **public** → **Tables**.

You should see tables such as:
- `customers`
- `products`
- `categories`
- `orders`
- `order_items`

3. Right-click a table (e.g. `customers`) → **View Data**.
   - You should see sample rows from the seed data.

---

## Step 5: Run Your First Query

1. Right-click the connection → **SQL Editor** → **New SQL Script**.
2. Type:

```sql
SELECT * FROM customers LIMIT 5;
```

3. Press **Ctrl+Enter** to run.
4. You should see 5 customer rows.

---

## Step 6: Start Module 1 Learning

### Day 1 — Theory

1. Read: `module-01-sql-concepts/theory/01-relational-model.md`
2. Read: `docs/book-chapters/BOOK1-CH01-Understanding-Relational-Databases.md`

### Day 2 — ER Modeling

1. Read: `module-01-sql-concepts/theory/02-er-modeling.md`
2. Do: `module-01-sql-concepts/labs/02-er-modeling-exercise.md`
3. Read: `docs/book-chapters/BOOK1-CH02-Modeling-a-System.md`

### Day 3 — DDL & Schema

1. Read: `module-01-sql-concepts/theory/03-sql-overview.md`
2. Read: `module-01-sql-concepts/theory/04-ddl-dml-dcl.md`
3. Inspect the project schema: `module-01-sql-concepts/project/schema.sql`

### Day 4 — Constraints & Data Types

1. Read: `module-01-sql-concepts/theory/05-data-types-constraints.md`
2. Inspect: `module-01-sql-concepts/project/constraints.sql`
3. Read: `docs/book-chapters/BOOK1-CH06-Drilling-Down-to-SQL-Nitty-Gritty.md`

### Day 5 — Practice

1. Open: `module-01-sql-concepts/project/exercises.sql`
2. Try each exercise in DBeaver.
3. Check: `module-01-sql-concepts/project/solutions/exercises_solutions.sql` if stuck.
4. Review: `module-01-sql-concepts/interview_questions.md`

---

## Step 7: Useful DBeaver Shortcuts

| Action | Shortcut |
|--------|----------|
| Execute SQL | Ctrl+Enter |
| New SQL script | Ctrl+] |
| Format SQL | Ctrl+Shift+F |
| View table data | Right-click table → View Data |
| Refresh | F5 |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Connection refused" | Wait 15 seconds after `docker-compose up -d`. Check `docker ps`. |
| "Password authentication failed" | Leave password blank (trust auth). If you changed docker-compose recently, run `.\setup.ps1` to recreate the DB. |
| "Relation does not exist" | Run schema.sql, constraints.sql, seed_data.sql in order. |
| Tables empty after seed_data | Check for errors in the Messages tab when running seed_data.sql. |

---

## What's Next?

After Module 1, continue with [STUDY_GUIDE.md](../STUDY_GUIDE.md) Phase 2 (Module 2: Relational Development).
