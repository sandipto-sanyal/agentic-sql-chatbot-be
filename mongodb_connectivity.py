"""Generic MongoDB connector: upsert, retrieve and delete records.

Configuration comes from .env (same keys as vector_store.py):

    MONGODB_URI          connection string
    MONGODB_VECTOR_DB    database name
    MONGODB_COLLECTION   default collection name

Usage:

    from mongodb_connectivity import MongoConnector

    with MongoConnector() as db:
        db.upsert([{"name": "Asha", "dept": "Sales"}], match_on=["name"])
        rows = db.retrieve({"dept": "Sales"}, projection={"name": 1}, limit=10)
        db.delete({"name": "Asha"})

A 24-character hex string passed as `_id` (in a record or a query) is converted to an
ObjectId automatically. Returned records have `_id` as a string so they serialize to JSON.
"""

import os
from typing import Any, Optional, Sequence, Union

from bson import ObjectId
from dotenv import load_dotenv
from pymongo import MongoClient, ReplaceOne, UpdateOne
from pymongo.collection import Collection

load_dotenv(override=True)

ID_FIELD = "_id"


def _normalize_id(value: Any) -> Any:
    """Convert a 24-char hex string to ObjectId; return anything else unchanged."""
    if isinstance(value, str) and len(value) == 24 and ObjectId.is_valid(value):
        return ObjectId(value)
    return value


def _normalize_query(query: Optional[dict[str, Any]]) -> dict[str, Any]:
    query = dict(query or {})
    if ID_FIELD in query:
        value = query[ID_FIELD]
        if isinstance(value, dict) and "$in" in value:
            query[ID_FIELD] = {**value, "$in": [_normalize_id(v) for v in value["$in"]]}
        else:
            query[ID_FIELD] = _normalize_id(value)
    return query


def _serialize(doc: dict[str, Any]) -> dict[str, Any]:
    if ID_FIELD in doc and isinstance(doc[ID_FIELD], ObjectId):
        doc[ID_FIELD] = str(doc[ID_FIELD])
    return doc


class MongoConnector:
    def __init__(
        self,
        collection_name: Optional[str] = None,
        database_name: Optional[str] = None,
        uri: Optional[str] = None,
        client: Optional[MongoClient] = None,
    ):
        self._owns_client = client is None
        self._client = client if client is not None else MongoClient(uri or os.environ["MONGODB_URI"])
        database = self._client[database_name or os.environ["MONGODB_VECTOR_DB"]]
        self.collection: Collection = database[collection_name or os.environ["MONGODB_COLLECTION"]]

    # ---- lifecycle -------------------------------------------------------

    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def __enter__(self) -> "MongoConnector":
        return self

    def __exit__(self, *exc_info) -> None:
        self.close()

    # ---- upsert ----------------------------------------------------------

    def upsert(
        self,
        records: Union[dict[str, Any], Sequence[dict[str, Any]]],
        match_on: Sequence[str] = (ID_FIELD,),
        replace: bool = False,
    ) -> dict[str, int]:
        """Insert each record, or update the existing one whose `match_on` fields equal it.

        - `match_on`: fields that identify a record (default `_id`). Every record must
          contain them. Example: match_on=["employee_id"] updates by a business key.
        - replace=False (default): fields in the record are set on the existing document;
          other fields are kept.
        - replace=True: the existing document is overwritten by the record.

        Returns counts: {"matched": ..., "modified": ..., "upserted": ...}.
        """
        if isinstance(records, dict):
            records = [records]
        if not match_on:
            raise ValueError("match_on must name at least one field")

        operations = []
        for record in records:
            if not isinstance(record, dict):
                raise TypeError(f"each record must be a dict, got {type(record).__name__}")
            missing = [field for field in match_on if field not in record]
            if missing:
                raise ValueError(f"record is missing match_on field(s) {missing}: {record!r}")

            key = {field: _normalize_id(record[field]) for field in match_on}
            if replace:
                operations.append(ReplaceOne(key, {**record, **key}, upsert=True))
            else:
                changes = {k: _normalize_id(v) if k == ID_FIELD else v
                           for k, v in record.items() if k not in match_on}
                if not changes:
                    raise ValueError(f"record has no fields beyond match_on: {record!r}")
                operations.append(UpdateOne(key, {"$set": changes}, upsert=True))

        if not operations:
            return {"matched": 0, "modified": 0, "upserted": 0}

        result = self.collection.bulk_write(operations, ordered=False)
        return {
            "matched": result.matched_count,
            "modified": result.modified_count,
            "upserted": result.upserted_count,
        }

    # ---- retrieve --------------------------------------------------------

    def retrieve(
        self,
        query: Optional[dict[str, Any]] = None,
        projection: Optional[dict[str, Any]] = None,
        sort: Optional[list[tuple[str, int]]] = None,
        skip: int = 0,
        limit: int = 0,
    ) -> list[dict[str, Any]]:
        """Return all records matching `query` (a MongoDB filter; None/{} means all).

        `sort` is a list like [("created_at", -1)]. `limit=0` means no limit.
        """
        cursor = self.collection.find(_normalize_query(query), projection)
        if sort:
            cursor = cursor.sort(sort)
        if skip:
            cursor = cursor.skip(skip)
        if limit:
            cursor = cursor.limit(limit)
        return [_serialize(doc) for doc in cursor]

    def retrieve_one(
        self,
        query: Optional[dict[str, Any]] = None,
        projection: Optional[dict[str, Any]] = None,
    ) -> Optional[dict[str, Any]]:
        """Return the first record matching `query`, or None."""
        doc = self.collection.find_one(_normalize_query(query), projection)
        return _serialize(doc) if doc is not None else None

    # ---- delete ----------------------------------------------------------

    def delete(
        self,
        query: dict[str, Any],
        many: bool = True,
        allow_empty_query: bool = False,
    ) -> int:
        """Delete records matching `query`. Returns the number deleted.

        An empty query would delete the whole collection, so it is refused unless
        allow_empty_query=True is passed explicitly. many=False deletes only one match.
        """
        filter_ = _normalize_query(query)
        if not filter_ and not allow_empty_query:
            raise ValueError("refusing to delete with an empty query; pass allow_empty_query=True to delete everything")

        if many:
            result = self.collection.delete_many(filter_)
        else:
            result = self.collection.delete_one(filter_)
        return result.deleted_count
if __name__ == "__main__":
    with MongoConnector() as db:
        db.upsert([{"name": "Asha", "dept": "Sales"}], match_on=["name"])
        rows = db.retrieve({"dept": "Sales"}, projection={"name": 1}, limit=10)
        print(rows)
        db.delete({"name": "Asha"})