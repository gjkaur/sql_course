# Module 6: Interview Questions

## JSONB Basics

1. **What is the difference between JSON and JSONB?**
   - JSON: text storage, reparsed on read. JSONB: binary, pre-parsed, supports indexing. Use JSONB for querying.

2. **What operators does GIN index support for JSONB?**
   - @> (contains), ? (key exists), ?| (any key), ?& (all keys).

3. **How do you extract a value from JSONB as text?**
   - `column->>'key'` or `column #>> '{path}'`.

## Indexing

4. **When would you use a GIN index on JSONB?**
   - When querying with @>, ?, ?|, ?&. For equality on a specific path, use expression index: `((payload->>'key'))`.

5. **What is an expression index?**
   - Index on an expression (e.g., `(payload->>'page')`) rather than a column. Enables index scan for that expression.

## Design

6. **When would you use JSONB vs relational columns?**
   - JSONB: variable schema, rarely filtered, external data. Relational: frequently filtered, need FK, strict schema.

7. **What are the downsides of storing data in JSONB?**
   - No FK into nested values, harder to enforce constraints, more complex queries.
