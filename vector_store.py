"""Store embeddings in Azure Cosmos DB for MongoDB (vCore / DocumentDB).

Configuration comes from .env:

    MONGODB_URI              connection string for the Cosmos DB cluster
    MONGODB_VECTOR_DB        database name
    MONGODB_COLLECTION       collection name

Embeddings are produced by embeddings.py (Azure OpenAI via LangChain).

Usage:

    from vector_store import ensure_vector_index, store_embedding, store_embeddings

    ensure_vector_index()                       # once, creates the vector index
    store_embedding("how many sales staff?", metadata={"source": "chat"})
    store_embeddings(["doc one", "doc two"], metadatas=[{...}, {...}])
"""

import os
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Optional, Sequence

from dotenv import load_dotenv
import pymongo
from pymongo import MongoClient, ReplaceOne
from pymongo.collection import Collection
from pymongo.database import Database
import bson
from embeddings import embed_documents, embed_query

load_dotenv(override=True)

EMBEDDING_FIELD = "embedding"
TEXT_FIELD = "text"
VECTOR_INDEX_NAME = "embedding_vector_index"
METADATA_DATABASE_INDEX_NAME = "metadata_database_index"
# Must match the output size of the embedding deployment
# (text-embedding-3-small -> 1536).
EMBEDDING_DIMENSIONS = int(os.getenv("EMBEDDING_DIMENSIONS", "1536"))


@lru_cache(maxsize=1)
def _client() -> MongoClient:
    return MongoClient(os.environ["MONGODB_URI"])


def get_database() -> Database:
    return _client()[os.environ["MONGODB_VECTOR_DB"]]


def get_collection() -> Collection:
    return get_database()[os.environ["MONGODB_COLLECTION"]]


def ensure_vector_index(
    num_lists: int = 1,
    similarity: str = "COS",
    collection: Optional[Collection] = None,
) -> None:
    """Create the IVF vector index on the embedding field if it does not exist.

    Safe to call repeatedly. `num_lists` is the IVF partition count; for small
    collections 1 is fine, Azure recommends roughly rows/1000 for larger ones.
    `similarity` is one of "COS", "L2", "IP".
    """
    coll = collection if collection is not None else get_collection()
    existing = {idx["name"] for idx in coll.list_indexes()}
    if VECTOR_INDEX_NAME in existing:
        return

    coll.database.command(
        {
            "createIndexes": coll.name,
            "indexes": [
                {
                    "name": VECTOR_INDEX_NAME,
                    "key": {EMBEDDING_FIELD: "cosmosSearch"},
                    "cosmosSearchOptions": {
                        "kind": "vector-ivf",
                        "numLists": num_lists,
                        "similarity": similarity,
                        "dimensions": EMBEDDING_DIMENSIONS,
                    },
                }
            ],
        }
    )


def ensure_metadata_index(collection: Optional[Collection] = None) -> str:
    """Create a regular index on `metadata.database` so searches can filter by it.

    Safe to call repeatedly: pymongo's create_index is a no-op when the index
    already exists. Returns the index name.
    """
    coll = collection if collection is not None else get_collection()
    return coll.create_index([("metadata.database", 1)], name=METADATA_DATABASE_INDEX_NAME)


def _build_doc(
    text: str,
    vector: list[float],
    metadata: Optional[dict[str, Any]],
) -> dict[str, Any]:
    return {
        TEXT_FIELD: text,
        EMBEDDING_FIELD: vector,
        "metadata": metadata or {},
        "created_at": datetime.now(timezone.utc),
    }


def store_embedding(
    text: str,
    metadata: Optional[dict[str, Any]] = None,
    doc_id: Any = None,
    collection: Optional[Collection] = None,
) -> bson.ObjectId:
    """Embed `text` and store it. Returns the stored document's _id.

    If `doc_id` is given, an existing document with that _id is replaced
    (upsert); otherwise a new document with an auto-generated _id is inserted.
    """
    coll = collection if collection is not None else get_collection()
    doc = _build_doc(text, embed_query(text), metadata)

    if doc_id is None:
        return coll.insert_one(doc).inserted_id

    doc["_id"] = doc_id
    coll.replace_one({"_id": doc_id}, doc, upsert=True)
    return doc_id


def store_embeddings(
    texts: Sequence[str],
    metadatas: Optional[Sequence[Optional[dict[str, Any]]]] = None,
    doc_ids: Optional[Sequence[Any]] = None,
    collection: Optional[Collection] = None,
) -> pymongo.results.InsertManyResult:
    """Embed many texts in one batch and store them. Returns the count written.

    `metadatas` and `doc_ids`, when given, must be the same length as `texts`.
    Docs with a `doc_id` are upserted; the rest are inserted.
    """
    if not texts:
        return 0
    if metadatas is not None and len(metadatas) != len(texts):
        raise ValueError("metadatas must be the same length as texts")
    if doc_ids is not None and len(doc_ids) != len(texts):
        raise ValueError("doc_ids must be the same length as texts")

    coll = collection if collection is not None else get_collection()
    vectors = embed_documents(list(texts))

    inserts: list[dict[str, Any]] = []
    upserts: list[ReplaceOne] = []
    for i, (text, vector) in enumerate(zip(texts, vectors)):
        meta = metadatas[i] if metadatas is not None else None
        doc = _build_doc(text, vector, meta)
        if doc_ids is not None and doc_ids[i] is not None:
            doc["_id"] = doc_ids[i]
            upserts.append(ReplaceOne({"_id": doc["_id"]}, doc, upsert=True))
        else:
            inserts.append(doc)
    results = None
    if inserts:
        results = coll.insert_many(inserts)
    if upserts:
        results = coll.bulk_write(upserts)
    return results

if __name__ == "__main__":
    text = "python is great"
    ensure_vector_index()                       # once, creates the vector index
    ensure_metadata_index()                     # once, creates the metadata.database index
    results = store_embedding(
        text=text,
        metadata={"type":"sample message", "database":"testing"}
        )
    print(results)
    
    
