// agents/work.js
import fs from "fs";
import path from "path";

export async function runWork(prompt, outputPath) {
  const result = {
    agent: "work",
    prompt,
    response: `Processed by WORK (PHP / Python backend): ${prompt}`,
    timestamp: Date.now()
  };
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), "utf-8");
  console.log(`[WORK] Output saved to ${outputPath}`);
}

if (process.argv[1].endsWith("work.js")) {
  const prompt = process.argv[2] || "test prompt";
  const outputPath = process.argv[3] || path.join(process.cwd(), "work.json");
  runWork(prompt, outputPath);
}
