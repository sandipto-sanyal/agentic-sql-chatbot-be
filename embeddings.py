"""Azure OpenAI embedding model, built on LangChain.

Reads its configuration from the environment (see .env):

    AZURE_OPENAI_ENDPOINT   e.g. https://my-resource.openai.azure.com/
    AZURE_OPENAI_API_KEY    Azure OpenAI key
    EMBEDDING_MODEL         name of the *embedding deployment* in Azure
    AZURE_OPENAI_API_VERSION (optional, defaults to 2024-10-21)

Usage:

    from embeddings import get_embedding_model

    embedder = get_embedding_model()
    vector = embedder.embed_query("how many employees are in sales?")
    vectors = embedder.embed_documents(["doc one", "doc two"])
"""

import os
from functools import lru_cache

from dotenv import load_dotenv
from langchain_openai import AzureOpenAIEmbeddings

load_dotenv(override=True)

DEFAULT_API_VERSION = "2024-10-21"


@lru_cache(maxsize=1)
def get_embedding_model() -> AzureOpenAIEmbeddings:
    """Return a shared AzureOpenAIEmbeddings instance.

    Raises KeyError if a required environment variable is missing.
    """
    return AzureOpenAIEmbeddings(
        azure_endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
        api_key=os.environ["AZURE_OPENAI_API_KEY"],
        azure_deployment=os.environ["EMBEDDING_MODEL"],
        api_version=os.getenv("AZURE_OPENAI_API_VERSION", DEFAULT_API_VERSION),
    )


def embed_query(text: str) -> list[float]:
    """Embed a single piece of text."""
    return get_embedding_model().embed_query(text)


def embed_documents(texts: list[str]) -> list[list[float]]:
    """Embed a batch of texts."""
    return get_embedding_model().embed_documents(texts)


if __name__ == "__main__":
    vector = embed_query("hello world")
    print(f"Embedding dimension: {len(vector)}")
