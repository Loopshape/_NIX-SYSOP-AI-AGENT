#!/usr/bin/env python3
import json
import sys

prompt = sys.argv[1]
outfile = sys.argv[2]

node = {
    "agent": "core",
    "type": "logic_node",
    "content": f"Python agent processed prompt: {prompt}",
    "tokens": []
}

with open(outfile, "w") as f:
    json.dump(node, f, indent=2)

