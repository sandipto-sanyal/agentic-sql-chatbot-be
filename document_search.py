from embeddings import embed_query
from vector_store import get_collection
from dotenv import load_dotenv
load_dotenv(override=True)
import os
from typing import *
from schemas import SimilarDocumentType



SEARCH_SCORE_THRESHOLD = float(os.environ.get("SEARCH_SCORE_THRESHOLD","0.90"))

def search_similar(query: str, k: int = 5, database:str|None=None) -> List[SimilarDocumentType]:
    """This outsources the cosine vector search"""
    qv = embed_query(query)
    cosmos_search = {"vector": qv, "path": "embedding", "k": k}
    if database is not None:
        # restrict the vector search to rows stored for this database
        cosmos_search["filter"] = {"metadata.database": {"$eq": database}}
    pipeline = [
        {"$search": {"cosmosSearch": cosmos_search,
                     "returnStoredSource": True}},
        {"$project": {
            "_id":1,
            "text": 1, "metadata": 1, "score": {"$meta": "searchScore"}}},
        {"$match": {"score": {"$gte": SEARCH_SCORE_THRESHOLD}}}
    ]
    documents:List[SimilarDocumentType] = get_collection().aggregate(pipeline)
    
    return [{**doc, "_id": str(doc["_id"]), "mongodb_object_id":str(doc["_id"])} for doc in documents]
    

if __name__ == "__main__":
    query = "python is the greatest"
    collections = search_similar(query=query, database="testing")
    print(collections)