// agents/line.js
import fs from "fs";
import path from "path";

export async function runLine(prompt, outputPath) {
  const result = {
    agent: "line",
    prompt,
    response: `Processed by LINE (JSON / API): ${prompt}`,
    timestamp: Date.now()
  };
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), "utf-8");
  console.log(`[LINE] Output saved to ${outputPath}`);
}

if (process.argv[1].endsWith("line.js")) {
  const prompt = process.argv[2] || "test prompt";
  const outputPath = process.argv[3] || path.join(process.cwd(), "line.json");
  runLine(prompt, outputPath);
}
