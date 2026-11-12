"""Update the `metadata` field of one document in the vector collection, by _id.

Uses the same .env settings and collection as vector_store.py:

    MONGODB_URI, MONGODB_VECTOR_DB, MONGODB_COLLECTION

Usage:

    from document_update import update_metadata

    result = update_metadata("65f1c0ffee0000000000abcd", {"database": "employees"})
    print(result.matched_count, result.modified_count)

By default the given keys are merged into the existing metadata, so other keys are kept.
Pass replace=True to overwrite the whole metadata object instead.
"""

from typing import Any, Optional

from bson import ObjectId
from bson.errors import InvalidId
from pymongo.collection import Collection
from pymongo.results import UpdateResult


from vector_store import get_collection

METADATA_FIELD = "metadata"


def _to_object_id(object_id: Any) -> ObjectId:
    if isinstance(object_id, ObjectId):
        return object_id
    try:
        return ObjectId(str(object_id))
    except (InvalidId, TypeError) as exc:
        raise ValueError(f"not a valid ObjectId: {object_id!r}") from exc


def update_metadata(
    object_id: Any,
    metadata: dict[str, Any],
    replace: bool = False,
    collection: Optional[Collection] = None,
) -> UpdateResult:
    """Update the metadata of the document with the given `_id`.

    `object_id` may be an ObjectId or its 24-character hex string.
    With replace=False (default) each key in `metadata` is set on the existing
    metadata and other keys are left alone. With replace=True the whole metadata
    object is overwritten with `metadata`.

    The text and embedding are not touched, so no new embedding call is made.
    Returns the pymongo UpdateResult; check `matched_count` to see whether a
    document with that _id existed.
    """
    if not isinstance(metadata, dict):
        raise TypeError("metadata must be a dict")

    coll = collection if collection is not None else get_collection()
    _id = _to_object_id(object_id)

    if replace:
        update = {"$set": {METADATA_FIELD: metadata}}
    else:
        if not metadata:
            raise ValueError("metadata is empty; nothing to merge")
        update = {"$set": {f"{METADATA_FIELD}.{key}": value for key, value in metadata.items()}}

    return coll.update_one({"_id": _id}, update)


if __name__ == "__main__":
    result = update_metadata(
        object_id="6af569c9a4052c5ddc00b7fc",          # replace with a real _id
        metadata={"plotly_code": "test plotly js code"},
    )
    print(f"matched={result.matched_count} modified={result.modified_count}")
