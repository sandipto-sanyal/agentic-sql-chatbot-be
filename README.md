# sample_flask_project
 This is a sample flask project
 
 # Setup
 Using any environment creation tool create a new environment. Below example shows how to do it from conda
 - ```conda create -n flask_env python=3.11.0```
 - ```conda activate flask_env```
 - ```pip install flask flask-cors```

 Open a command prompt in the project directory then run ```python app.py```.

 # Structure of project
 Since this project is created using Flask framework, it has to follow particular project structure for proper functioning.
 1. All .html files to be placed in ./templates
 1. All other static contents to be placed inside ./static. ./static may be optionally sub-divided into:
    1. ./static/css: To host custom CSS files
    1. ./static/js: To host custom js files
    1. ./static/fonts: To put custom fonts
    1. ./static/media: To put media contents like images, videos etc.

   
# Python Debugging Launch.json Configs
- https://code.visualstudio.com/docs/python/debugging#_set-configuration-options

# Sample Query for filtering in MongoDB
To view the queries using simple filters
```json
{ text: "python is great" }
```


# Searching documents in MongoDB

The `.env` points at **Azure Cosmos DB for MongoDB (vCore)**. The steps below were run against that cluster and work there. MongoDB Atlas uses a different vector-search syntax, covered in the last section. That part is untested here.

Prerequisites: documents are stored with `store_embedding` / `store_embeddings` from `vector_store.py`, and `ensure_vector_index()` has been run once for the collection.

## Method 1: Vector (semantic) search

Finds documents by meaning. The query text is embedded, then the nearest stored vectors are returned.

1. Embed the query with `embed_query` from `embeddings.py`.
2. Run a `$search` aggregation with a `cosmosSearch` stage on the `embedding` path.
3. Project `text` and the `searchScore` (higher means more similar).

```python
from embeddings import embed_query
from vector_store import get_collection

def search_similar(query: str, k: int = 5):
    qv = embed_query(query)
    pipeline = [
        {"$search": {"cosmosSearch": {"vector": qv, "path": "embedding", "k": k},
                     "returnStoredSource": True}},
        {"$project": {"text": 1, "metadata": 1, "score": {"$meta": "searchScore"}}},
    ]
    return list(get_collection().aggregate(pipeline))
```

## Method 2: Vector search with a metadata filter

Narrows the semantic search to documents matching a condition, for example one department.

1. Create a regular index on each field you filter by. Cosmos rejects the query otherwise, with `The index for filter path 'metadata.dept' was not found`.
2. Add a `filter` inside `cosmosSearch`.

```python
coll = get_collection()
coll.create_index([("metadata.dept", 1)])          # once per filtered field

qv = embed_query("how many people work in sales?")
pipeline = [
    {"$search": {"cosmosSearch": {"vector": qv, "path": "embedding", "k": 5,
                                  "filter": {"metadata.dept": "sales"}},
                 "returnStoredSource": True}},
    {"$project": {"text": 1, "score": {"$meta": "searchScore"}}},
]
results = list(coll.aggregate(pipeline))
```

## Method 3: Plain filter and text queries (`find`)

No embedding and no vector index needed. Use it for exact matches, metadata lookups, or simple keyword matching.

```python
coll = get_collection()

# Keyword match (case-insensitive regex, no ranking)
coll.find({"text": {"$regex": "sales", "$options": "i"}}, {"embedding": 0})

# Exact metadata match
coll.find({"metadata.dept": "admin"}, {"embedding": 0})

# By _id
coll.find_one({"_id": "fixed-1"}, {"embedding": 0})
```

Always exclude `embedding` from results (`{"embedding": 0}`) unless you need the raw vector. It is 1536 numbers per document.

## Method 4: Hybrid search (vector and keyword in one app flow)

Cosmos vCore does not combine the two in one stage. Run Method 1 or 2 and Method 3, then merge them in Python. Keep the vector results in ranked order and boost documents that also match the keyword.

```python
def hybrid_search(query: str, k: int = 10):
    vector_hits = search_similar(query, k=k)
    keyword_ids = {d["_id"] for d in get_collection().find(
        {"text": {"$regex": query, "$options": "i"}}, {"_id": 1})}
    for hit in vector_hits:
        hit["keyword_match"] = hit["_id"] in keyword_ids
    # Keyword matches first, then by similarity score
    return sorted(vector_hits, key=lambda h: (not h["keyword_match"], -h["score"]))
```

## Choosing a method

| Need | Method |
|---|---|
| Find by meaning, even with different wording | 1 |
| Semantic search limited to a category or status | 2 |
| Exact value, ID, or substring match | 3 |
| Meaning plus exact terms, when both matter | 4 |

## MongoDB Atlas (untested with this project)

If the database is moved to MongoDB Atlas, the vector query changes:

1. In Atlas, open the cluster, go to **Atlas Search** and create a **Vector Search** index on the `embedding` field with `dimensions: 1536` and `similarity: cosine`. Add a `filter` field for each metadata path you want to filter on.
2. Replace the `$search` / `cosmosSearch` stage with `$vectorSearch`:

```python
pipeline = [
    {"$vectorSearch": {
        "index": "embedding_vector_index",   # the Atlas index name
        "path": "embedding",
        "queryVector": qv,
        "numCandidates": 100,                # candidates scanned before limit
        "limit": 5,
        "filter": {"metadata.dept": "sales"} # optional, needs filter field in index
    }},
    {"$project": {"text": 1, "score": {"$meta": "vectorSearchScore"}}},
]
```

3. For keyword search with ranking, Atlas Search offers a `$search` stage with a `text` operator (`{"text": {"query": "...", "path": "text"}}`), which needs a Search index on `text`. Atlas also supports `$rankFusion` for combining vector and text results in one query, which removes the Python merge in Method 4.
