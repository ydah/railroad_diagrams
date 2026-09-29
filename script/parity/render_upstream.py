"""Render serialized Ruby examples with the pinned upstream Python library."""

import json
import os
import sys

sys.path.insert(0, os.path.abspath(sys.argv[1]))
import railroad  # noqa: E402


def node(data):
    args = [node(value) if isinstance(value, dict) and "class" in value else value
            for value in data["args"]]
    return getattr(railroad, data["class"])(*args)


result = {}
for name, data in json.load(sys.stdin).items():
    try:
        diagram = node(data)
        output = []
        diagram.writeSvg(output.append)
        result[name] = {
            "svg": "".join(output),
            "metrics": [diagram.width, diagram.up, diagram.height, diagram.down],
        }
    except Exception as error:  # Report each example without hiding the others.
        result[name] = {"error": "%s: %s" % (type(error).__name__, error)}

json.dump(result, sys.stdout, ensure_ascii=False)
