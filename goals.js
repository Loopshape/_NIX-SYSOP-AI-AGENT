import fs from "fs";

let goals = [];

export function addGoal(text) {
  goals.push({ text, created: Date.now(), status: "open" });
  fs.writeFileSync("memory/goals.json", JSON.stringify(goals,null,2));
}

export function nextGoal() {
  return goals.find(g => g.status === "open");
}

export function completeGoal(text) {
  for (const g of goals) {
    if (g.text === text) g.status = "done";
  }
  fs.writeFileSync("memory/goals.json", JSON.stringify(goals,null,2));
}

