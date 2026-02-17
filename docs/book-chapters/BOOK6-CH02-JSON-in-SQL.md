# BOOK 6 – Chapter 2: JSON in SQL

---

## 1. Core Concept Explanation (Deep Technical Version)

### JSON: JavaScript Object Notation

**JSON** is a lightweight, text-based format for key-value pairs and arrays. Native to JavaScript; widely used in APIs, configs, logs. SQL standard (SQL:2016) added JSON support. PostgreSQL has `json` and `jsonb` types.

### JSON vs JSONB (PostgreSQL)

| Type | Storage | Parsing | Indexing | Use Case |
|------|---------|---------|----------|----------|
| **json** | Text, exact | Reparsed on read | Limited | Preserve formatting, exact whitespace |
| **jsonb** | Binary, decomposed | Pre-parsed | GIN, btree | Querying, filtering, indexing |

**Recommendation**: Use **JSONB** for almost all cases. Only use `json` when you need to preserve exact formatting (e.g., pretty-print output).

### JSON Structure

- **Object**: `{"key": "value", "nested": {"a": 1}}`
- **Array**: `[1, 2, "three"]`
- **Values**: string, number, boolean, null

### Extraction Operators

- `->` : Get field as JSON (preserves type). `'{"a":1}'::jsonb -> 'a'` → `1` (jsonb)
- `->>` : Get as text. `'{"a":1}'::jsonb ->> 'a'` → `'1'` (text)
- `#>` : Path (array of keys). `'{"a":{"b":1}}'::jsonb #> '{a,b}'` → `1`
- `#>>` : Path as text.

**Path**: For nested access. `column #> '{user,address,city}'` = `column->user->address->city`.

### Containment and Existence

- `@>` : Left contains right. `'{"a":1,"b":2}' @> '{"a":1}'` → true
- `?` : Key exists. `'{"a":1}' ? 'a'` → true
- `?|` : Any key exists. `'{"a":1}' ?| array['a','c']` → true
- `?&` : All keys exist. `'{"a":1,"b":2}' ?& array['a','b']` → true

---

## 2. Why This Matters in Production

### Real-World System Example

Event table: `payload JSONB`. Events: click, purchase, view. Each has different fields. `payload->>'event_type'`, `payload->'user'->>'id'`. Filter: `WHERE payload->>'page' = '/checkout'`. Index on expression for hot paths.

### Scalability Impact

- **GIN index**: Supports @>, ?, ?|, ?&. Enables index scan for containment queries.
- **Expression index**: `((payload->>'event_type'))` for equality. Often faster than GIN for single-key equality.

### Performance Impact

- **JSONB**: Pre-parsed. No parse on read. Faster than json for queries.
- **Path extraction**: `->>` for text. Cast to int/date if needed for comparison.

### Data Integrity Implications

- **Type in JSON**: Numbers, strings, booleans. No DATE type—store as string (ISO 8601) or epoch. Validate in application.
- **Null vs missing**: `payload->'key'` returns NULL if missing. `payload->>'key'` returns NULL. Check with `?` for existence.

---

## 3. PostgreSQL Implementation

### Basic Operators

```sql
SELECT 
  payload->'user' AS user_obj,
  payload->>'event_type' AS event_type,
  payload #>> '{user,email}' AS email
FROM events
WHERE payload->>'event_type' = 'purchase';
```

### Containment

```sql
SELECT * FROM products
WHERE attributes @> '{"color": "red"}';

SELECT * FROM events
WHERE payload ? 'user_id';
```

### Building JSON

```sql
SELECT jsonb_build_object('id', id, 'name', name, 'price', price) FROM products;
SELECT jsonb_agg(row_to_json(t)) FROM (SELECT * FROM customers LIMIT 5) t;
```

### Array Expansion

```sql
SELECT id, elem
FROM events,
LATERAL jsonb_array_elements(payload->'items') AS elem;
```

---

## 4. Common Developer Mistakes

### Mistake 1: Using json Instead of jsonb

Unless you need exact formatting, use jsonb. Better performance, indexing.

### Mistake 2: No Index on Filtered Path

`WHERE payload->>'key' = 'x'` without index = seq scan. Add expression index.

### Mistake 3: Wrong Operator for Type

`->` returns JSON. For comparison with text, use `->>`. `payload->>'id' = '1'` not `payload->'id' = '1'` (different types).

### Mistake 4: Storing Dates as Non-ISO

Store `"2024-02-15"` (ISO) for sortability and casting. Avoid `"02/15/2024"`.

### Mistake 5: Assuming Key Exists

`payload->>'key'` returns NULL if missing. Use `payload ? 'key'` to check existence.

---

## 5. Interview Deep-Dive Section

**Q: What is the difference between JSON and JSONB?**  
A: JSON: text storage, reparsed on read. JSONB: binary, pre-parsed, supports indexing. Use JSONB for querying.

**Q: How do you extract a value from JSONB as text?**  
A: `column->>'key'` or `column #>> '{path}'`. Use `->` for JSON result, `->>` for text.

**Q: What operators does GIN index support for JSONB?**  
A: @> (contains), ? (key exists), ?| (any key), ?& (all keys).

---

## 6. Advanced Engineering Notes

### jsonb_set, jsonb_insert

```sql
SELECT jsonb_set('{"a":1}'::jsonb, '{b}', '2');  -- {"a":1,"b":2}
```

### Casting

```sql
SELECT (payload->>'amount')::numeric FROM events;
SELECT (payload->>'created_at')::timestamptz FROM events;
```

---

## 7. Mini Practical Exercise

1. Create table with JSONB. Insert object with nested structure. Extract with ->, ->>, #>>.
2. Query with @> and ?. Add GIN index. Compare EXPLAIN before/after.
3. Use jsonb_agg to build array from rows.

---

## 8. Summary in 10 Bullet Points

1. **JSON**: Key-value, arrays. Text-based. SQL:2016 support.
2. **JSONB**: Binary, pre-parsed. Use for querying. Preferred.
3. **->** : Get as JSON. **->>** : Get as text.
4. **#>>** : Path as text. **#>** : Path as JSON.
5. **@>** : Contains. **?** : Key exists.
6. **GIN index**: @>, ?, ?|, ?&. For containment queries.
7. **Expression index**: `(payload->>'key')` for equality.
8. **jsonb_build_object, jsonb_agg**: Build JSON in query.
9. **jsonb_array_elements**: Expand array to rows.
10. **Store ISO dates**: Sortable, castable to timestamptz.
