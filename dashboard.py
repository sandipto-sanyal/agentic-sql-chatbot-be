from typing import *
from schemas import SimilarDocumentType
import os
from dotenv import load_dotenv
load_dotenv(override=True)
from vector_store import get_collection
from bson import ObjectId
from mysql_connectivity import MySQLConnector
import pandas as pd
import json
import re
import ast
from employee_agentic_chatbot import generate_plotly_vizualizer_code, \
    put_plotly_code_in_metadata


class TraceDirectiveType(TypedDict):
    x: str
    y: str
    text: str
    name: str
    color_by: Optional[str]
    type:str
    
class Traces(TypedDict):
    x: List[str|int|float]
    y: List[str|int|float]
    text: List[str|int|float]
    name: str
    type:str|None
    
class GetDataType(TypedDict):
    data: List[Dict[str, str|int|float]]
    traces: List[Traces]
    layout: Dict[str, Any]


def get_dashboards(database:str, id:str|None=None)->List[SimilarDocumentType]:
    """Return every record whose metadata.database equals `database`.

    If `id` is given, only the record with that `_id` is matched.
    The embedding vector is excluded from the result; `_id` is returned as a string.
    Results are sorted by `created_at`, newest first.
    """
    query: dict[str, Any] = {"metadata.database": {"$eq": database}}
    if id is not None:
        query["_id"] = ObjectId(id)
    cursor = get_collection().find(query, {"embedding": 0}).sort("created_at", -1)
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

def build_mask(df: pd.DataFrame, condition: str) -> pd.Series:
    mask = eval(condition, {"__builtins__": {}}, {"df": df})
    if not isinstance(mask, pd.Series) or mask.dtype != bool:
        raise ValueError(f"filter_condition must produce a boolean Series: {condition!r}")
    return mask.fillna(False)




def parse_trace_directives(trace_directives:str) -> List[TraceDirectiveType]:
    """Parse the LLM's JSON, removing any ```json / ``` Markdown fences around it."""
    cleaned = re.sub(r"^```(?:json)?\s*|\s*```$", "", trace_directives.strip())
    return json.loads(cleaned)

def json_safe_records(df:pd.DataFrame) -> List[Dict[str, Any]]:
    """Rows as plain JSON types. to_json handles numpy ints/floats, NaN and Decimal,
    which to_dict and tolist leave as objects that Flask cannot serialize."""
    return json.loads(df.to_json(orient='records'))

def json_safe_column(series:pd.Series) -> List[Any]:
    return json.loads(series.to_json(orient='records'))

def give_traces_per_category(df:pd.DataFrame,
                             color_by:str,
                             trace_directive:TraceDirectiveType
                             ) -> List[Traces]:
    # get discrete values
    traces:List[Traces] = []
    # dropna: a null never equals anything, so it would produce an empty "nan" trace
    discrete_color_by_values = df[color_by].dropna().unique()
    for value in discrete_color_by_values:
        mask = df[color_by] == value
        trace:Traces = {
        "x":json_safe_column(df.loc[mask, trace_directive['x']]),
        "y":json_safe_column(df.loc[mask, trace_directive['y']]),
        "name":str(value),
        "type":trace_directive['type'],
        "text":None 
        }
        traces.append(trace)
    return traces

def create_traces(data:pd.DataFrame,
                  trace_directives:str
                  )->List[Traces]:
    trace_directive_json = parse_trace_directives(trace_directives)
    traces: List[Traces] = []
    for trace_directive in trace_directive_json:
        df = data.copy()
        # if filter condition found in trace_directive, filter the dataframe
        if trace_directive.get('color_by'):
            color_by = trace_directive['color_by']            
            traces.extend(give_traces_per_category(df, color_by, trace_directive))
        else:
            trace:Traces = {
                "x":json_safe_column(df[trace_directive['x']]),
                "y":json_safe_column(df[trace_directive['y']]),
                "name":trace_directive['name'],
                "type":trace_directive['type'],
                "text":None
            }
            traces.append(trace)
    return traces

def regenerate_dashboard(
    mongodb_object_id:str,
    query:str,
    task:str,
    extra_instruction:str=""
):
    '''Regenerates the dashboard logic using LLM'''
    plotly_details = generate_plotly_vizualizer_code.invoke(
        {"query": query, "task":task+extra_instruction}
    )
    output = put_plotly_code_in_metadata.invoke({**plotly_details, "mongodb_object_id":mongodb_object_id})
    return output
    


def create_layout(data:pd.DataFrame, trace_directives:str) -> Dict[str, Any]:
    trace_directive_json = parse_trace_directives(trace_directives)
    first =trace_directive_json[0] if trace_directive_json else {}
    return {
        "xaxis": {"title": {"text": first.get('x', '')}},
        "yaxis": {"title": {"text": first.get('y', '')}},
    }

    

def get_data(database:str,
             query:str,
             trace_directives:str,
             ) -> GetDataType:
    connected_db = MySQLConnector(database_name=database)
    data:pd.DataFrame = connected_db.execute_query(query)
    return {
        "data": json_safe_records(data),
        "traces": create_traces(data=data, trace_directives=trace_directives),
        "layout":create_layout(data=data, trace_directives=trace_directives)
        }

if __name__ == '__main__':
    with open("test.json", "r", encoding='utf-8') as f:
        test_data = json.load(f)
    query = test_data['metadata']['query']
 
    plotly_code = test_data['metadata']['plotly_code']
    dashboard_data = get_data(
        database = "employees",
        query=query,
        trace_directives=plotly_code
    )
    pass