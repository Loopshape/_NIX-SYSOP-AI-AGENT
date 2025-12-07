#!/usr/bin/env node
import fs from "fs";
import path from "path";

// Project folder from argument
const projectDir = process.argv[2];
if (!projectDir) {
  console.error("Usage: node generate.js <project-folder>");
  process.exit(1);
}

// Helper: compute a naive vector similarity score
const cosineSim = (vecA, vecB) => {
  const dot = vecA.reduce((sum, v, i) => sum + v * vecB[i], 0);
  const magA = Math.sqrt(vecA.reduce((sum, v) => sum + v * v, 0));
  const magB = Math.sqrt(vecB.reduce((sum, v) => sum + v * v, 0));
  return dot / (magA * magB + 1e-12);
};

// Step 1: Read all JSON nodes
const jsonFiles = fs.readdirSync(projectDir)
  .filter(f => f.endsWith(".json"))
  .map(f => path.join(projectDir, f));

const nodes = jsonFiles.map(f => {
  try {
    return JSON.parse(fs.readFileSync(f, "utf-8"));
  } catch (err) {
    console.error(`[generate] Failed to parse ${f}`, err);
    return null;
  }
}).filter(Boolean);

// Step 2: Extract vectors from nodes
// Assume each node has {embedding: [number], text: "…"} format
const embeddings = nodes.map(n => n.embedding || []);
const texts = nodes.map(n => n.text || "");

// Step 3: Compute weighted fusion
let finalVector = [];
if (embeddings.length > 0) {
  const dim = embeddings[0].length;
  finalVector = new Array(dim).fill(0);
  for (let i = 0; i < dim; i++) {
    finalVector[i] = embeddings.reduce((sum, vec) => sum + (vec[i] || 0), 0) / embeddings.length;
  }
}

// Step 4: Select the node closest to fused vector
let bestIndex = 0;
let bestScore = -Infinity;
embeddings.forEach((vec, i) => {
  const score = cosineSim(vec, finalVector);
  if (score > bestScore) {
    bestScore = score;
    bestIndex = i;
  }
});

// Step 5: Write final answer
const finalAnswer = texts[bestIndex] || "No definitive final answer found.";
fs.writeFileSync(path.join(projectDir, "final_answer.txt"), finalAnswer, "utf-8");

console.log("[generate] Fusion complete. Final answer saved to:", path.join(projectDir, "final_answer.txt"));

