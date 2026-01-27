<?php
header("Content-Type: application/json; charset=utf-8");
$prompt = $_POST["prompt"] ?? null;
if (!$prompt) { echo json_encode(["error"=>"No prompt provided"]); exit; }
// Run as 'ai' user
$python_path = escapeshellarg("/home/loop/_/ai_orchestrator/crew/ai_orchestrator.py");
$prompt_escaped = escapeshellarg($prompt);
$cmd = "sudo -u ai python3 $python_path $prompt_escaped 2>&1";
$output = shell_exec($cmd);
echo $output;
