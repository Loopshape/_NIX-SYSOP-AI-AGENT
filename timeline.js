import fs from "fs";

const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2();
let selected = null;

window.addEventListener("click", e=>{
  mouse.x = (e.clientX / innerWidth) * 2 - 1;
  mouse.y = -(e.clientY / innerHeight) * 2 + 1;
  raycaster.setFromCamera(mouse,camera);
  const hits = raycaster.intersectObjects(Object.values(nodes));
  if(hits.length){
    selected = hits[0].object;
    const hash = selected.userData.hash;
    showNode(hash);
  }

export function saveEvent(genesis, md5, agent, token, sha, parent) {
  const rec = {
    genesis,
    md5,
    agent,
    token,
    sha,
    parent: parent || null,
    time: Date.now()
  };
  fs.appendFileSync("memory/timeline.db", JSON.stringify(rec) + "\n");
}

export function getBranch(md5) {
  return fs.readFileSync("memory/timeline.db","utf8")
    .split("\n")
    .map(x => JSON.parse(x))
    .filter(e => e.md5 === md5);
}

});
