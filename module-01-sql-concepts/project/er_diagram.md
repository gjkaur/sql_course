# Online Retail System — ER Diagram

## Entity-Relationship Diagram (Mermaid)

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : "places"
    ORDER ||--|{ ORDER_ITEM : "contains"
    PRODUCT ||--o{ ORDER_ITEM : "appears in"

    CUSTOMER {
        bigint id PK
        varchar name
        varchar email UK
        varchar phone
        text address
        timestamptz created_at
    }

    PRODUCT {
        bigint id PK
        varchar name
        text description
        numeric price
        varchar category
        boolean active
        timestamptz created_at
    }

    ORDER {
        bigint id PK
        bigint customer_id FK
        varchar status
        timestamptz order_date
        timestamptz created_at
    }

    ORDER_ITEM {
        bigint id PK
        bigint order_id FK
        bigint product_id FK
        int quantity
        numeric unit_price
    }
```

## Relationship Summary

| From | To | Cardinality | Description |
|------|-----|-------------|-------------|
| Customer | Order | 1:N | One customer places many orders |
| Order | Order Item | 1:N | One order contains many line items |
| Product | Order Item | 1:N | One product can appear in many order items |

## Key Design Decisions

- **Surrogate keys**: All tables use `id BIGSERIAL` for stable, simple joins
- **Order price snapshot**: `order_items.unit_price` stores price at order time (products.price can change)
- **Customer email**: UNIQUE for login/identity
- **Product active**: Soft delete — keep history, hide from catalog
