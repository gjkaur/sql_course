# Entity-Relationship Modeling

## Purpose

ER modeling translates business requirements into a logical schema before writing SQL. It catches design flaws early and facilitates stakeholder communication.

## Core Elements

### Entities

- **Entity**: A "thing" we store data about (Customer, Product, Order)
- **Entity Type**: The schema/table definition
- **Entity Instance**: A specific row

### Attributes

- **Simple**: Single value (name, price)
- **Composite**: Multiple components (address = street + city + zip)
- **Derived**: Computed (age from birth_date)
- **Multi-valued**: Multiple values (phone numbers) — often become separate tables

### Relationships

- **Cardinality**: 1:1, 1:N, N:M
- **1:N**: One customer has many orders → `orders.customer_id` FK
- **N:M**: Products and orders (many-to-many) → junction table `order_items`

### Crow's Foot Notation

```
Customer ----< Order          (one customer, many orders)
Order >----< Product         (via order_items)
```

## Modeling Process

1. **Identify entities** from nouns in requirements
2. **Identify relationships** from verbs (places, contains, belongs to)
3. **Add attributes** and assign to entities
4. **Determine keys** (primary, foreign)
5. **Resolve N:M** with junction tables

## Design Decisions

- **When to split**: If an attribute has multiple values or is optional and rarely used, consider a separate table.
- **When to denormalize**: For read-heavy reporting; accept redundancy for query speed (Module 2).

## Interview Insight

**Q: How do you model a many-to-many relationship?**

A: Create a junction (associative) table with FKs to both sides. The junction can have its own attributes (e.g., `order_items` has `quantity`, `unit_price`). The composite of both FKs often forms the primary key.
