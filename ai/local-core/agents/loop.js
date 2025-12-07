// agents/loop.js
import fs from "fs";
import path from "path";

// Example agent processing function
export async function runLoop(prompt, outputPath) {
  // Simulate some "AI work" for the prompt
  const result = {
    agent: "loop",
    prompt,
    response: `Processed by LOOP: ${prompt}`,
    timestamp: Date.now()
  };

  // Save JSON output
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), "utf-8");
  console.log(`[LOOP] Output saved to ${outputPath}`);
}

// If called directly via node for testing
if (process.argv[1].endsWith("loop.js")) {
  const prompt = process.argv[2] || "test prompt";
  const outputPath = process.argv[3] || path.join(process.cwd(), "loop.json");
  runLoop(prompt, outputPath);
}

