from sqlalchemy.ext.declarative import as_declarative, declared_attr
import sqlalchemy as sa
from datetime import datetime
from typing import Any

@as_declarative()
class Base:
    id = sa.Column(sa.Integer, primary_key=True, index=True)
    created_at = sa.Column(sa.DateTime, default=datetime.utcnow)
    updated_at = sa.Column(sa.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __name__: str

    @declared_attr
    def __tablename__(cls) -> str:
        return cls.__name__.lower() 