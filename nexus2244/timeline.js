import fs from "fs";

export function saveState(md5, data) {
  fs.appendFileSync("memory/timeline.db", JSON.stringify({ md5, data }) + "\n");
}

export function replay(md5) {
  if (!fs.existsSync("memory/timeline.db")) return [];
  return fs.readFileSync("memory/timeline.db","utf8")
    .split("\n")
    .filter(l => l.includes(md5));
}
