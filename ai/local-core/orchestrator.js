// orchestrator.js - Autonomous AI Orchestration
import { spawn } from "child_process";
import path from "path";
import fs from "fs";

const __dirname = path.resolve();

// CONFIG
const BASE_DIR = path.join(__dirname);
const AGENTS_DIR = path.join(BASE_DIR, "agents");
const PROJECTS_DIR = path.resolve(BASE_DIR, "../../ai_projects");

// UTILS
function log(msg) {
  const time = new Date().toISOString();
  console.log(`[ORCHESTRATOR][${time}] ${msg}`);
}

// CREATE PROJECT FOLDER
const timestamp = Date.now();
const PROJECT_FOLDER = path.join(PROJECTS_DIR, `nemodian-qfai-${timestamp}`);
fs.mkdirSync(PROJECT_FOLDER, { recursive: true });
log(`Project folder: ${PROJECT_FOLDER}`);

// AGENTS
const AGENTS = ["core", "loop", "wave", "coin", "code"];

async function runAgent(agent, prompt) {
  const agentJs = path.join(AGENTS_DIR, `${agent}.js`);
  if (!fs.existsSync(agentJs)) {
    log(`Warning: ${agent}.js not found, skipping.`);
    return;
  }

  return new Promise((resolve, reject) => {
    log(`Running agent: ${agent}`);
    const outFile = path.join(PROJECT_FOLDER, `${agent}.json`);
    const proc = spawn("node", [agentJs, prompt, outFile], { stdio: "inherit" });

    proc.on("close", (code) => {
      if (code === 0) {
        log(`Agent ${agent} finished successfully`);
        resolve();
      } else {
        reject(new Error(`Agent ${agent} exited with code ${code}`));
      }
    });
  });
}

// FUSION
async function runFusion() {
  log("Starting fusion / generate.js");
  const genJs = path.join(BASE_DIR, "generate.js");
  return new Promise((resolve, reject) => {
    const proc = spawn("node", [genJs, PROJECT_FOLDER], { stdio: "inherit" });

    proc.on("close", (code) => {
      if (code === 0) {
        log("Fusion complete");
        resolve();
      } else {
        reject(new Error(`Fusion exited with code ${code}`));
      }
    });
  });
}

// MAIN ORCHESTRATION
async function main() {
  const prompt = process.argv.slice(2).join(" ");
  if (!prompt) {
    console.error("Usage: node orchestrator.js <prompt>");
    process.exit(1);
  }

  try {
    for (const agent of AGENTS) {
      await runAgent(agent, prompt);
    }

    await runFusion();

    const finalAnswer = path.join(PROJECT_FOLDER, "final_answer.txt");
    if (fs.existsSync(finalAnswer)) {
      const answerText = fs.readFileSync(finalAnswer, "utf-8");
      log("FINAL ANSWER:");
      console.log(answerText);
    } else {
      log("No final_answer.txt generated.");
    }
  } catch (err) {
    console.error("[ORCHESTRATOR] ERROR:", err);
  }
}

main();

