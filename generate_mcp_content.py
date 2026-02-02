import os
import json

base_dir = "mcp"

tools = {
    "webpack": {
        "webpack.config.js": """const path = require('path');

module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: ['style-loader', 'css-loader'],
      },
    ],
  },
};""",
        "workflow.sh": """#!/bin/bash
# Webpack Workflow
npm install --save-dev webpack webpack-cli style-loader css-loader
echo "Webpack dependencies installed."
"""
    },
    "jquery": {
        "workflow.sh": """#!/bin/bash
# JQuery Workflow
npm install jquery
echo "JQuery installed."
""",
        "usage.js": """import $ from "jquery";
$(document).ready(function() {
    console.log("JQuery is ready!");
});"""
    },
    "greensock": {
        "workflow.sh": """#!/bin/bash
# GSAP Workflow
npm install gsap
echo "GSAP installed."
""",
        "animation.js": """import { gsap } from "gsap";
gsap.to(".box", { rotation: 27, x: 100, duration: 1 });"""
    },
    "threejs": {
        "workflow.sh": """#!/bin/bash
# Three.js Workflow
npm install three
echo "Three.js installed."
""",
        "scene.js": """import * as THREE from 'three';

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera( 75, window.innerWidth / window.innerHeight, 0.1, 1000 );
const renderer = new THREE.WebGLRenderer();
renderer.setSize( window.innerWidth, window.innerHeight );
document.body.appendChild( renderer.domElement );

const geometry = new THREE.BoxGeometry();
const material = new THREE.MeshBasicMaterial( { color: 0x00ff00 } );
const cube = new THREE.Mesh( geometry, material );
scene.add( cube );

camera.position.z = 5;

function animate() {
	requestAnimationFrame( animate );
	cube.rotation.x += 0.01;
	cube.rotation.y += 0.01;
	renderer.render( scene, camera );
}
animate();"""
    },
    "auth2": {
        "workflow.sh": """#!/bin/bash
# Auth0/Oauth2 Workflow Setup
echo "Setting up Auth0 context..."
""",
        "auth_config.json": """{
  "domain": "YOUR_DOMAIN",
  "clientId": "YOUR_CLIENT_ID",
  "audience": "YOUR_API_IDENTIFIER"
}"""
    },
    "github": {
        "ci_workflow.yml": """name: CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run a one-line script
      run: echo Hello, world!""",
        "workflow.sh": """#!/bin/bash
# GitHub Actions Setup
mkdir -p .github/workflows
cp mcp/github/ci_workflow.yml .github/workflows/main.yml
echo "GitHub CI workflow initialized."
"""
    },
    "intellisense": {
        "jsconfig.json": """{
  "compilerOptions": {
    "module": "commonjs",
    "target": "es6",
    "checkJs": true
  },
  "exclude": ["node_modules", "**/node_modules/*"]
}""",
        "workflow.sh": """#!/bin/bash
# Intellisense Setup
cp mcp/intellisense/jsconfig.json .
echo "Intellisense configured (jsconfig.json)."
"""
    },
    "nodejs": {
        "package.json": """{
  "name": "nexus-project",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}""",
        "server.js": """const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => res.send('Hello Nexus!'));

app.listen(port, () => console.log(`Example app listening on port ${port}!`));""",
        "workflow.sh": """#!/bin/bash
# NodeJS Setup
npm init -y
npm install express
echo "NodeJS project initialized."
"""
    },
    "gulp": {
        "gulpfile.js": """const { src, dest } = require('gulp');

function defaultTask(cb) {
  // place code for your default task here
  cb();
}

exports.default = defaultTask;""",
        "workflow.sh": """#!/bin/bash
# Gulp Setup
npm install --global gulp-cli
npm install --save-dev gulp
echo "Gulp configured."
"""
    },
    "lodash": {
        "workflow.sh": """#!/bin/bash
# Lodash Setup
npm install lodash
echo "Lodash installed."
"""
    },
    "harp": {
        "harp.json": """{
  "globals": {
    "title": "Nexus AI Project"
  }
}""",
        "workflow.sh": """#!/bin/bash
# Harp Setup
npm install -g harp
echo "Harp installed."
"""
    },
    "composer": {
        "composer.json": """{
    "name": "nexus/project",
    "require": {}
}""",
        "workflow.sh": """#!/bin/bash
# PHP Composer Setup
# Assumes composer is in PATH or downloads it
if ! command -v composer &> /dev/null
then
    echo "Composer could not be found. Downloading..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
else
    echo "Composer detected."
fi
composer install
"""
    },
    "bootstrap4": {
        "index.html": """<!doctype html>
<html lang="en">
  <head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/css/bootstrap.min.css">

    <title>Nexus AI - Bootstrap 4</title>
  </head>
  <body>
    <h1>Hello, Nexus!</h1>

    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.6.0/dist/js/bootstrap.bundle.min.js"></script>
  </body>
</html>""",
        "workflow.sh": """#!/bin/bash
# Bootstrap 4 Setup
npm install bootstrap@4.6.0 jquery popper.js
echo "Bootstrap 4 installed."
"""
    }
}

# Create files
for tool, files in tools.items():
    tool_dir = os.path.join(base_dir, tool)
    for filename, content in files.items():
        file_path = os.path.join(tool_dir, filename)
        with open(file_path, 'w') as f:
            f.write(content)
        if filename.endswith(".sh"):
            os.chmod(file_path, 0o755)

# Create Master Loader
loader_content = """#!/bin/bash
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
"""

with open(os.path.join(base_dir, "loader.sh"), "w") as f:
    f.write(loader_content)
os.chmod(os.path.join(base_dir, "loader.sh"), 0o755)

print("MCP generation complete.")
