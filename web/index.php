<?php
// index.php — single-file AI code editor

// If a prompt is posted, call Python orchestrator
$output = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_POST['prompt'])) {
    $prompt = escapeshellarg($_POST['prompt']);
    $python = '/usr/bin/python3';
    $script = '/home/loop/_/ai_orchestrator/crew/ai_orchestrator.py';

    // Execute Python orchestrator and capture output
    $cmd = "$python $script $prompt 2>&1";
    $output = shell_exec($cmd);
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>AI Code Editor</title>
<style>
body { font-family: sans-serif; margin: 2rem; }
textarea { width: 100%; height: 150px; }
button { margin-top: 10px; padding: 0.5rem 1rem; }
pre { background: #f4f4f4; padding: 1rem; white-space: pre-wrap; }
</style>
</head>
<body>

<h1>AI Code Editor</h1>

<form method="post">
    <textarea name="prompt" placeholder="Enter your prompt..."><?= htmlspecialchars($_POST['prompt'] ?? '') ?></textarea><br>
    <button type="submit">Run Task</button>
</form>

<h2>Output:</h2>
<pre id="output"><?= htmlspecialchars($output) ?></pre>

</body>
</html>

