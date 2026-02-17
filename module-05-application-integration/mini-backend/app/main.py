"""
Module 5: Mini Backend - FastAPI + PostgreSQL
Run: uvicorn app.main:app --reload
"""

from fastapi import FastAPI, HTTPException, Depends
from app.db import get_db, init_db
from app.models import CustomerCreate, CustomerResponse

app = FastAPI(title="SQL Course Mini Backend", version="1.0")


@app.on_event("startup")
async def startup():
    init_db()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/customers", response_model=list[CustomerResponse])
def list_customers(db=Depends(get_db)):
    with db.cursor() as cur:
        cur.execute("SELECT id, name, email, phone, address, created_at FROM customers ORDER BY id")
        rows = cur.fetchall()
    return [
        {"id": r[0], "name": r[1], "email": r[2], "phone": r[3], "address": r[4], "created_at": str(r[5])}
        for r in rows
    ]


@app.get("/customers/{customer_id}", response_model=CustomerResponse)
def get_customer(customer_id: int, db=Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            "SELECT id, name, email, phone, address, created_at FROM customers WHERE id = %s",
            (customer_id,),
        )
        row = cur.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Customer not found")
    return {
        "id": row[0],
        "name": row[1],
        "email": row[2],
        "phone": row[3],
        "address": row[4],
        "created_at": str(row[5]),
    }


@app.post("/customers", response_model=CustomerResponse)
def create_customer(customer: CustomerCreate, db=Depends(get_db)):
    with db.cursor() as cur:
        cur.execute(
            "INSERT INTO customers (name, email, phone, address) VALUES (%s, %s, %s, %s) RETURNING id, name, email, phone, address, created_at",
            (customer.name, customer.email, customer.phone, customer.address),
        )
        row = cur.fetchone()
    db.commit()
    return {
        "id": row[0],
        "name": row[1],
        "email": row[2],
        "phone": row[3],
        "address": row[4],
        "created_at": str(row[5]),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
