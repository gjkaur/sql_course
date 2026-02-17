# Quick Start — Skip the Hassle

**Trust auth** is enabled — no password needed for DBeaver or psql.

---

## 1. Run setup (one time)

```powershell
cd "C:\Users\GURINDER\Gurinder Data\My_GitHub\sql_course-1"
.\setup.ps1
```

This starts PostgreSQL and loads the schema. Wait for "Done!".

---

## 2. Connect and run SQL

```powershell
docker exec -it sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

You're in. Try:

```sql
SELECT * FROM customers LIMIT 5;
\q
```

(`\q` exits)

---

## 3. Run a SQL file

```powershell
Get-Content module-01-sql-concepts/project/exercises.sql | docker exec -i sqlcourse-postgres psql -U sqlcourse -d sqlcourse
```

---

## DBeaver (optional)

- Host: `localhost` | Port: `5432` | Database: `sqlcourse` | User: `sqlcourse`
- **Password:** leave blank (trust auth)

---

## That's it

Use psql or DBeaver. No password needed.
