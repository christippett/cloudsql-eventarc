from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field, validator


def to_camel(string: str) -> str:
    s = "".join(word.capitalize() for word in string.split("_"))
    return s[0].lower() + s[1:]


class AuditClass(Enum):
    READ = "READ"
    WRITE = "WRITE"
    FUNCTION = "FUNCTION"
    ROLE = "ROLE"
    DDL = "DDL"
    MISC = "MISC"
    MISC_SET = "MISC_SET"
    ALL = "ALL"


class AuditType(Enum):
    SESSION = "SESSION"
    OBJECT = "OBJECT"


class ObjectType(Enum):
    TABLE = "TABLE"
    INDEX = "INDEX"
    SEQUENCE = "SEQUENCE"
    TOASTVALUE = "TOAST TABLE"
    VIEW = "VIEW"
    MATVIEW = "MATERIALIZED VIEW"
    COMPOSITE_TYPE = "COMPOSITE TYPE"
    FOREIGN_TABLE = "FOREIGN TABLE"
    FUNCTION = "FUNCTION"
    UNKNOWN = "UNKNOWN"


class CloudSQLQuery(BaseModel):
    type: str = Field(alias="@type")
    audit_class: AuditClass
    audit_type: AuditType
    user: str
    command: str
    parameter: str
    statement: str
    statement_id: int
    substatement_id: int
    database: str
    database_session_id: int
    object: Optional[str]
    object_type: Optional[ObjectType]
    chunk_count: int
    chunk_index: int

    class Config:
        alias_generator = to_camel
        use_enum_values = True

    @validator("*", pre=True)
    def empty_str_to_none(cls, v):
        return None if v == "" else v
