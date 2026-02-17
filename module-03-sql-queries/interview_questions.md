# Module 3: Interview Questions

## SELECT & Clauses

1. **What is the execution order of SELECT?**
   - FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT

2. **Why can't you use a column alias from SELECT in WHERE?**
   - WHERE runs before SELECT; alias doesn't exist yet.

3. **What is the difference between WHERE and HAVING?**
   - WHERE filters rows before aggregation; HAVING filters groups after.

## Subqueries

4. **When would you use EXISTS instead of IN?**
   - When subquery returns many rows; EXISTS can short-circuit. Also NOT EXISTS avoids NULL issues with NOT IN.

5. **What is a correlated subquery?**
   - Subquery references outer query; executed once per outer row. Often slower; consider JOIN.

## JOINs

6. **What is the difference between INNER and LEFT JOIN?**
   - INNER: only matching rows. LEFT: all from left; match from right or NULL.

7. **When would you use FULL OUTER JOIN?**
   - When you need all rows from both tables, matched where possible (e.g., comparing two lists).

8. **ON vs WHERE for JOIN conditions?**
   - ON: join condition. For INNER JOIN, equivalent. For LEFT JOIN, WHERE filters out NULLs (turns into INNER effectively).

## Set Operators

9. **UNION vs UNION ALL?**
   - UNION removes duplicates; UNION ALL keeps them. UNION ALL is faster when duplicates are impossible.

10. **What does INTERSECT do?**
    - Rows that appear in both result sets.

## Performance

11. **How do you debug a slow query?**
    - EXPLAIN (ANALYZE, BUFFERS); look for Seq Scan, high cost, bad row estimates.

12. **When is a Seq Scan acceptable?**
    - Small table, or when most rows are returned (index wouldn't help).

13. **What is keyset pagination?**
    - WHERE id > last_seen_id ORDER BY id LIMIT n. O(1) vs OFFSET's O(n). No random page access.
