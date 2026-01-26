// agents/cube.js
import fs from "fs";
import path from "path";

export async function runCube(prompt, outputPath) {
  const result = {
    agent: "cube",
    prompt,
    response: `Processed by CUBE (JavaScript / DOM): ${prompt}`,
    timestamp: Date.now()
  };
  fs.writeFileSync(outputPath, JSON.stringify(result, null, 2), "utf-8");
  console.log(`[CUBE] Output saved to ${outputPath}`);
}

if (process.argv[1].endsWith("cube.js")) {
  const prompt = process.argv[2] || "test prompt";
  const outputPath = process.argv[3] || path.join(process.cwd(), "cube.json");
  runCube(prompt, outputPath);
}
