const fs = require('fs');
const path = require('path');
const { validatePath } = require('./safety');

function read_file(filePath) {
    const validPath = validatePath(filePath);
    if (!fs.existsSync(validPath)) return { error: 'File not found' };
    const stats = fs.statSync(validPath);
    if (stats.size > 1024 * 1024) return { error: 'File too large (max 1MB)' };
    return { content: fs.readFileSync(validPath, 'utf8') };
}

function write_file(filePath, content) {
    const validPath = validatePath(filePath);
    fs.mkdirSync(path.dirname(validPath), { recursive: true });
    fs.writeFileSync(validPath, content, 'utf8');
    return { success: true, path: validPath };
}

function list_files(dirPath) {
    const validPath = validatePath(dirPath);
    if (!fs.existsSync(validPath)) return { error: 'Directory not found' };
    return { files: fs.readdirSync(validPath) };
}

module.exports = { read_file, write_file, list_files };
