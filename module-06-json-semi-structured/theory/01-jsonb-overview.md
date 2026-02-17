# JSONB Overview

## JSON vs JSONB

| Type | Storage | Indexing | Use Case |
|------|---------|----------|----------|
| JSON | Text, reparsed on read | Limited | Exact formatting needed |
| JSONB | Binary, pre-parsed | GIN, btree | Querying, indexing |

**Recommendation**: Use JSONB for most cases.

## Operators

- `->` : Get JSON object field as JSON
- `->>` : Get as text
- `#>` : Path (e.g., `'{"a":{"b":1}}'::jsonb #> '{a,b}'`)
- `#>>` : Path as text
- `@>` : Contains (left contains right)
- `?` : Key exists
- `?|` : Any key exists
- `?&` : All keys exist

## Functions

- `jsonb_build_object('k', v)` : Build object
- `jsonb_agg()` : Aggregate to JSON array
- `jsonb_array_elements()` : Expand array to rows
- `jsonb_each()` : Expand object to key-value rows
