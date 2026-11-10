from typing import Any, Optional

import numpy as np
from pymongo.collection import Collection

from embeddings import embed_query
from vector_store import get_collection


def cosine_similarity(query_vec: np.ndarray, matrix: np.ndarray) -> np.ndarray:
    """Cosine similarity between one vector and each row of a matrix.

    Returns an array of shape (n_rows,) with values in [-1, 1].
    """
    eps = 1e-12
    q_norm = np.linalg.norm(query_vec) + eps
    m_norms = np.linalg.norm(matrix, axis=1) + eps
    return (matrix @ query_vec) / (m_norms * q_norm)


def search_cosine(
    query: str,
    k: int = 5,
    metadata_filter: Optional[dict[str, Any]] = None,
    collection: Optional[Collection] = None,
) -> list[dict[str, Any]]:
    """Find the k documents most similar to `query` by cosine similarity.

    Fetches the stored embeddings (optionally narrowed by a plain Mongo filter
    such as {"metadata.dept": "sales"}) and ranks them client-side. No vector
    index is needed, but every matching document is transferred, so this suits
    small to medium collections.
    """
    coll = collection if collection is not None else get_collection()
    docs = list(coll.find(metadata_filter or {}, {"text": 1, "metadata": 1, "embedding": 1}))
    if not docs:
        return []

    query_vec = np.asarray(embed_query(query), dtype=np.float32)
    matrix = np.asarray([d["embedding"] for d in docs], dtype=np.float32)
    scores = cosine_similarity(query_vec, matrix)

    top = np.argsort(-scores)[:k]
    return [
        {
            "_id": docs[i]["_id"],
            "text": docs[i].get("text"),
            "metadata": docs[i].get("metadata", {}),
            "score": float(scores[i]),
        }
        for i in top
    ]



if __name__ == '__main__':
    query = "python"
    collections = search_cosine(query=query)
    print(collections)