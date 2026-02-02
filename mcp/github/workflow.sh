#!/bin/bash
# GitHub Actions Setup
mkdir -p .github/workflows
cp mcp/github/ci_workflow.yml .github/workflows/main.yml
echo "GitHub CI workflow initialized."
