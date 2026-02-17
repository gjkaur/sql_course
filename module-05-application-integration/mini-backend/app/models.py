"""
Module 5: Pydantic models for API
"""

from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class CustomerCreate(BaseModel):
    name: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None


class CustomerResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: Optional[str] = None
    address: Optional[str] = None
    created_at: str
