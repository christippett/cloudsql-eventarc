from devtools import pprint

from utils import CloudSQLQuery


def main(cloudevent):
    payload = cloudevent.data.get("protoPayload")
    assert "request" in payload
    query = CloudSQLQuery(**payload["request"])
    pprint(query)
