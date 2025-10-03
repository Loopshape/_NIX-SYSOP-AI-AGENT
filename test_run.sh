#!/usr/bin/env bash
# ~/.bin/ai — CLI with optional syntax-highlighted outputs

AI_HOME="$HOME/.local_ai"
PYTHON_BIN="python3"

highlight_output() {
    local text="$1"
    local lang="$2"

    "$PYTHON_BIN" - <<EOF
import sys
from rich.console import Console
from rich.syntax import Syntax

console = Console()
output = """$text"""
syntax = Syntax(output, "$lang", theme="monokai", line_numbers=True)
console.print(syntax)
EOF
}

run_ai() {
    local prompt="$1"
    local response
    # replace this with your AI engine call
    if [[ "$prompt" =~ "capital of Germany" ]]; then
        response="The capital of Germany is Berlin."
        lang="text"
    elif [[ "$prompt" =~ "def " ]]; then
        response="def greet(name):\n    return f'Hello, {name}!'"
        lang="python"
    else
        response="$prompt"
        lang="text"
    fi

    highlight_output "$response" "$lang"
}

if [ $# -lt 1 ]; then
    echo "Usage: ai 'your prompt'"
    exit 1
fi

run_ai "$*"