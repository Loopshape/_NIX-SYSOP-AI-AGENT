import fs from "fs";

export function detectHallucination(md5, shaList) {
  if (!fs.existsSync("memory/timeline.db")) return false;
  const history = fs.readFileSync("memory/timeline.db","utf8").split("\n");
  let mismatch = 0;

  for (const h of history) {
    if (!h) continue;
    try {
      const e = JSON.parse(h);
      if (e.md5 === md5 && !shaList.includes(e.sha)) {
        mismatch++;
      }
    } catch (err) {
      // ignore parse errors
    }
  }

  return mismatch > 3;
}
