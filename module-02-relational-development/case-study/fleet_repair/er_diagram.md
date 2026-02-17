# Fleet Repair System — ER Diagram

## Mermaid Diagram

```mermaid
erDiagram
    CUSTOMER ||--o{ VEHICLE : "owns"
    VEHICLE ||--o{ REPAIR_ORDER : "has"
    TECHNICIAN ||--o{ REPAIR_ORDER : "works on"
    REPAIR_ORDER ||--|{ PART_USAGE : "uses"
    PART ||--o{ PART_USAGE : "used in"

    CUSTOMER {
        bigint id PK
        varchar company_name
        varchar contact_person
        varchar phone
        text address
    }

    VEHICLE {
        bigint id PK
        bigint customer_id FK
        varchar vin UK
        varchar make
        varchar model
        int year
        varchar license_plate
    }

    TECHNICIAN {
        bigint id PK
        varchar name
        varchar specialization
        date hire_date
    }

    REPAIR_ORDER {
        bigint id PK
        bigint vehicle_id FK
        bigint technician_id FK
        date opened_date
        date completed_date
        varchar status
        numeric labor_hours
        numeric parts_cost
    }

    PART {
        bigint id PK
        varchar part_number UK
        text description
        numeric unit_cost
        int quantity_in_stock
    }

    PART_USAGE {
        bigint id PK
        bigint repair_order_id FK
        bigint part_id FK
        int quantity_used
        numeric unit_price
    }
```

## Relationships

| From | To | Cardinality |
|------|-----|-------------|
| Customer | Vehicle | 1:N |
| Vehicle | Repair Order | 1:N |
| Technician | Repair Order | 1:N |
| Repair Order | Part Usage | 1:N |
| Part | Part Usage | 1:N |

## Normalization Notes

- **3NF**: No transitive dependencies. Part usage stores unit_price at time of use (snapshot).
- **Junction**: Part Usage resolves N:M between Repair Order and Part.
