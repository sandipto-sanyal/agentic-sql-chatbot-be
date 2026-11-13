from typing import *
from schemas import SimilarDocumentType
import os
from dotenv import load_dotenv
load_dotenv(override=True)
from vector_store import get_collection
from bson import ObjectId
from mysql_connectivity import MySQLConnector
import pandas as pd

def get_dashboards(database:str, id:str|None=None)->List[SimilarDocumentType]:
    """Return every record whose metadata.database equals `database`.

    If `id` is given, only the record with that `_id` is matched.
    The embedding vector is excluded from the result; `_id` is returned as a string.
    """
    query: dict[str, Any] = {"metadata.database": {"$eq": database}}
    if id is not None:
        query["_id"] = ObjectId(id)
    cursor = get_collection().find(query, {"embedding": 0})
    return [cast(SimilarDocumentType, {**doc, "_id": str(doc["_id"])}) for doc in cursor]


def delete_dashboard(database: str, dashboard_id: str) -> int:
    """Delete the dashboard with `_id == dashboard_id` that belongs to `database`.

    Returns the number of deleted records (0 if no dashboard matched).
    The database check keeps a dashboard from another database from being removed by mistake.
    """
    result = get_collection().delete_one({
        "_id": ObjectId(dashboard_id),
        "metadata.database": {"$eq": database},
    })
    return result.deleted_count


def get_data(database:str,
             query:str
             ):
    connected_db = MySQLConnector(database_name=database)
    data:pd.DataFrame = connected_db.execute_query(query)
    return data.to_dict(orient='records')