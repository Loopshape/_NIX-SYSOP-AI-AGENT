// agents/code.js
import fs from "fs";
import path from "path";

// Example agent processing function
export async function runCode(prompt, outputPath) {
  // Simulate some "AI work" for the prompt
  const result = {
    agent: "code",
    prompt,
    response: `Processed by CODE: ${prompt}`,
    timestamp: Date.now()
  };

  // Save JSON output
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), "utf-8");
  console.log(`[CODE] Output saved to ${outputPath}`);
}

// If called directly via node for testing
if (process.argv[1].endsWith("code.js")) {
  const prompt = process.argv[2] || "test prompt";
  const outputPath = process.argv[3] || path.join(process.cwd(), "code.json");
  runCode(prompt, outputPath);
}

