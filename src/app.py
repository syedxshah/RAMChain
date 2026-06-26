from pydantic import BaseModel
from typing import Optional

class CreateModel(BaseModel):
    name: str
    size: int=100


class DataModel(BaseModel):
    name: str
    key: str
    value: str
    ttl: Optional[int] = None 

class UpdatedModel(BaseModel):
    name: str
    key: str
    new_value: str

class DeleteDataModel(BaseModel):
    name: str
    key: str

class GetModel(BaseModel):
    name: str
    key: str