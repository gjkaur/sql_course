# JOINs and Set Operators

## JOIN Types

### INNER JOIN

Only rows with match in both tables. Default JOIN.

### LEFT JOIN (LEFT OUTER)

All rows from left; match from right or NULL.

### RIGHT JOIN

All rows from right; match from left or NULL. Rarely used; prefer flipping tables and using LEFT.

### FULL OUTER JOIN

All rows from both; match or NULL. Use for "everything from both, matched where possible."

### CROSS JOIN

Cartesian product. Rarely intended; use for generating combinations.

## ON vs WHERE

- **ON**: Join condition (which rows match)
- **WHERE**: Filter after join

For INNER JOIN, `ON a.x = b.y AND a.z = 1` is equivalent to `ON a.x = b.y WHERE a.z = 1`. For LEFT JOIN, moving condition to WHERE can change result (filters out NULLs from non-matching right rows).

## Set Operators

### UNION

Combine result sets; removes duplicates. Use `UNION ALL` to keep duplicates (faster).

### INTERSECT

Rows in both results.

### EXCEPT

Rows in first but not second (set difference).

**Requirements**: Same number of columns; compatible types. Column names from first query.
