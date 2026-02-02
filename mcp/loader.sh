#!/bin/bash
# MCP Loader for Nexus AI
# Usage: source mcp/loader.sh

MCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function mcp_install() {
    local tool=$1
    if [ -d "$MCP_DIR/$tool" ]; then
        if [ -f "$MCP_DIR/$tool/workflow.sh" ]; then
            echo "[MCP] Installing $tool..."
            "$MCP_DIR/$tool/workflow.sh"
        else
            echo "[MCP] No workflow script found for $tool"
        fi
    else
        echo "[MCP] Tool $tool not found in registry."
    fi
}

function mcp_list() {
    echo "Available MCP Tools:"
    ls "$MCP_DIR" | grep -v "loader.sh"
}

export -f mcp_install
export -f mcp_list
