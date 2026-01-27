#!/usr/bin/env python3
import sys
from pygments import highlight
from pygments.lexers import (
    PythonLexer,
    BashLexer,
    SqlLexer,
    JavascriptLexer,
    TextLexer,
    guess_lexer
)
from pygments.formatters import TerminalFormatter

code = sys.stdin.read()

# Auto-detect based on keywords if guessing fails
def detect_lexer(code_text):
    lower = code_text.lower()
    if any(k in lower for k in ["def ", "import ", "print("]):
        return PythonLexer()
    if any(k in lower for k in ["#!/bin/bash", "echo ", "apt ", "curl "]):
        return BashLexer()
    if any(k in lower for k in ["select ", "insert ", "update ", "from "]):
        return SqlLexer()
    if any(k in lower for k in ["function ", "const ", "let ", "console.log"]):
        return JavascriptLexer()
    try:
        return guess_lexer(code_text)
    except Exception:
        return TextLexer()

lexer = detect_lexer(code)
print(highlight(code, lexer, TerminalFormatter()), end="")
