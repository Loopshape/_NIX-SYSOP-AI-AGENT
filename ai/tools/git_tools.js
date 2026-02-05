const { execSync } = require('child_process');
const { validatePath } = require('./safety');

function git_status(repoPath) {
    const validPath = validatePath(repoPath);
    try {
        const status = execSync('git status --porcelain', { cwd: validPath }).toString();
        return { status: status || 'Clean' };
    } catch (error) {
        return { error: error.message };
    }
}

function git_commit(repoPath, message) {
    const validPath = validatePath(repoPath);
    if (!message || message.length < 5) return { error: 'Invalid commit message' };
    try {
        execSync('git add .', { cwd: validPath });
        const result = execSync(`git commit -m "${message.replace(/"/g, '\\"')}"`, { cwd: validPath }).toString();
        return { result: result.trim() };
    } catch (error) {
        return { error: error.message };
    }
}

module.exports = { git_status, git_commit };
