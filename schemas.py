from typing import *
import bson
class MetadataType(TypedDict):
    type: str
    database: str
    plotly_code:str
    
class SimilarDocumentType(TypedDict):
    _id: str
    text:str
    metadata:MetadataType