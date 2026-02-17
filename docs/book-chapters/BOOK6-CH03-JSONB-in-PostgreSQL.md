# BOOK 6 – Chapter 3: JSONB in PostgreSQL

---

## 1. Core Concept Explanation (Deep Technical Version)

### JSONB: Binary JSON

**JSONB** stores JSON in a decomposed binary format. Parsed once on insert; no parse on read. Supports indexing (GIN, expression indexes). Order of keys not preserved; duplicate keys collapsed (last wins). Whitespace normalized.

### Indexing Strategies

**GIN (Generalized Inverted Index)**:
- Supports: `@>` (contains), `?` (key exists), `?|` (any key), `?&` (all keys)
- Use for: containment queries, "has key" checks, full document search
- Syntax: `CREATE INDEX idx ON t USING GIN (jsonb_column);`

**Expression index (btree)**:
- For equality on specific path: `((payload->>'event_type'))`
- Use for: `WHERE payload->>'key' = 'value'`
- Often faster than GIN for single-key equality
- Syntax: `CREATE INDEX idx ON t ((payload->>'event_type'));`

**Composite expression index**:
- `((payload->>'user_id'), (payload->>'created_at'))` for multi-column filter/sort

### Key Functions

| Function | Purpose |
|----------|---------|
| `jsonb_build_object(k, v, ...)` | Build object from key-value pairs |
| `jsonb_agg(expr)` | Aggregate rows to JSON array |
| `jsonb_array_elements(jsonb)` | Expand array to rows (set-returning) |
| `jsonb_each(jsonb)` | Expand object to key-value rows |
| `jsonb_object_keys(jsonb)` | List keys |
| `jsonb_set(target, path, new_value)` | Update value at path |
| `jsonb_insert(target, path, new_value)` | Insert at path |
| `row_to_json(record)` | Convert row to JSON |
| `to_jsonb(any)` | Convert any type to JSONB |

### LATERAL with jsonb_array_elements

```sql
SELECT e.id, elem->>'product_id' AS product_id, (elem->>'qty')::int AS qty
FROM orders e,
LATERAL jsonb_array_elements(e.items) AS elem;
```

LATERAL allows the subquery to reference columns from the left side. Essential for expanding arrays per row.

---

## 2. Why This Matters in Production

### Real-World System Example

Events table: 10M rows. Payload JSONB. Query: "clicks on page X in last hour." Without index: seq scan. With `CREATE INDEX ON events ((payload->>'page'), (created_at))`: index scan. Sub-second.

### Scalability Impact

- **GIN size**: GIN indexes can be large. Monitor. Partial index if only subset of rows queried.
- **Update cost**: JSONB updates rewrite the value. GIN index updated. Consider immutable append (e.g., event log) vs in-place update.

### Performance Impact

- **@> vs ->>**: @> can use GIN. ->> equality needs expression index. Choose index to match query pattern.
- **Avoid full scan**: If filtering on JSON path, add index. Otherwise O(n).

### Data Integrity Implications

- **No schema**: Application must validate. Consider CHECK with jsonb_typeof or custom function for critical paths.
- **Nested updates**: jsonb_set returns new value. UPDATE ... SET col = jsonb_set(col, path, val).

---

## 3. PostgreSQL Implementation

### GIN Index

```sql
CREATE INDEX idx_events_payload ON events USING GIN (payload);

-- Queries that use it:
SELECT * FROM events WHERE payload @> '{"event_type": "click"}';
SELECT * FROM events WHERE payload ? 'user_id';
```

### Expression Index

```sql
CREATE INDEX idx_events_page ON events ((payload->>'page'));
CREATE INDEX idx_events_user_created ON events ((payload->>'user_id'), created_at);

SELECT * FROM events WHERE payload->>'page' = '/checkout' AND created_at > NOW() - INTERVAL '1 hour';
```

### jsonb_agg and jsonb_build_object

```sql
SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name)) FROM products;
SELECT jsonb_build_object('order_id', id, 'items', (SELECT jsonb_agg(items) FROM order_items WHERE order_id = orders.id))
FROM orders;
```

### Array Expansion

```sql
SELECT id, elem
FROM orders,
LATERAL jsonb_array_elements(items) AS elem
WHERE elem->>'product_id' = '123';
```

---

## 4. Common Developer Mistakes

### Mistake 1: GIN for Equality on Single Key

GIN works but expression index is often faster for `payload->>'key' = 'value'`. Use expression index for hot equality path.

### Mistake 2: No Index on JSON Path

Filtering without index = seq scan. Add index for production queries.

### Mistake 3: jsonb_set in UPDATE Without Assignment

`jsonb_set` returns value. Must assign: `UPDATE t SET col = jsonb_set(col, '{k}', '"v"')`.

### Mistake 4: Wrong Type in jsonb_set

Value must be JSONB. `jsonb_set(col, '{k}', '5')` — 5 is invalid (needs quotes for string). Use `to_jsonb(5)` or `'"5"'::jsonb`.

### Mistake 5: LATERAL Missing for jsonb_array_elements

`SELECT * FROM t, jsonb_array_elements(t.arr)` — need LATERAL or it's a cross join. Use `LATERAL jsonb_array_elements(t.arr) AS elem`.

---

## 5. Interview Deep-Dive Section

**Q: When would you use a GIN index on JSONB?**  
A: When querying with @>, ?, ?|, ?&. For equality on a specific path, use expression index: `((payload->>'key'))`.

**Q: What is an expression index?**  
A: Index on an expression (e.g., `(payload->>'page')`) rather than column. Enables index scan for that expression.

**Q: How do you expand a JSON array to rows?**  
A: `jsonb_array_elements(arr)`. Use with LATERAL to reference other columns: `FROM t, LATERAL jsonb_array_elements(t.arr) AS elem`.

---

## 6. Advanced Engineering Notes

### Partial GIN Index

```sql
CREATE INDEX idx_events_clicks ON events USING GIN (payload)
WHERE payload->>'event_type' = 'click';
```

Smaller index. Use when querying a subset.

### jsonb_path_query

JSON Path (SQL:2016): More powerful path language. `jsonb_path_query_first(payload, '$.user.email')`.

### Index on Nested Path

```sql
CREATE INDEX idx ON t ((payload #>> '{user,id}'));
```

---

## 7. Mini Practical Exercise

1. Create GIN index on JSONB. Run EXPLAIN on @> and ? queries. Verify index scan.
2. Create expression index on path. Compare performance vs GIN for equality.
3. Use jsonb_array_elements with LATERAL. Join to main table.
4. Build JSON from relational query: jsonb_agg, jsonb_build_object.

---

## 8. Summary in 10 Bullet Points

1. **JSONB**: Binary, pre-parsed. Indexable. Preferred over json.
2. **GIN**: @>, ?, ?|, ?&. Containment, key existence.
3. **Expression index**: `(col->>'key')` for equality. Often faster.
4. **jsonb_agg**: Rows to array. **jsonb_build_object**: Key-value to object.
5. **jsonb_array_elements**: Array to rows. Use LATERAL.
6. **jsonb_set**: Update at path. Returns new value; assign in UPDATE.
7. **to_jsonb**: Cast to JSONB. For numbers, dates in jsonb_set.
8. **Partial GIN**: WHERE clause. Smaller index for subset.
9. **Index match query**: Design index for actual query pattern.
10. **LATERAL**: Required for jsonb_array_elements to reference outer row.
