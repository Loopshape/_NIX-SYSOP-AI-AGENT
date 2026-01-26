const path = require('path');
const fs = require('fs');

const ALLOWED_ROOT = path.resolve(__dirname, '../../'); // Allow access to project root

function validatePath(targetPath) {
    const resolvedPath = path.resolve(targetPath);
    if (!resolvedPath.startsWith(ALLOWED_ROOT)) {
        throw new Error(`Access denied: Path ${targetPath} is outside allowed root.`);
    }
    return resolvedPath;
}

function sanitizeInput(input) {
    if (typeof input !== 'string') return input;
    // Basic sanitization
    return input.replace(/[<>]/g, '');
}

module.exports = { validatePath, sanitizeInput };
