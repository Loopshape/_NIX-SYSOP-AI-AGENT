import fs from "fs";

// --- Browser-specific code ---
if (typeof window !== 'undefined') {
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();
    let selected = null;

    window.addEventListener("click", e => {
        mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
        mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
        if (typeof camera !== 'undefined' && typeof nodes !== 'undefined') {
            raycaster.setFromCamera(mouse, camera);
            const hits = raycaster.intersectObjects(Object.values(nodes));
            if (hits.length) {
                selected = hits[0].object;
                const hash = selected.userData.hash;
                if (typeof showNode === 'function') {
                    showNode(hash);
                }
            }
        }
    });
}

// --- Node.js / Module code ---
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
    try {
        if (!fs.existsSync("memory")) {
            fs.mkdirSync("memory", { recursive: true });
        }
        fs.appendFileSync("memory/timeline.db", JSON.stringify(rec) + "\n");
    } catch (error) {
        console.error("Error saving event:", error);
    }
}

export function getBranch(md5) {
    try {
        if (!fs.existsSync("memory/timeline.db")) return [];
        return fs.readFileSync("memory/timeline.db", "utf8")
            .split("\n")
            .filter(line => line.trim())
            .map(x => JSON.parse(x))
            .filter(e => e.md5 === md5);
    } catch (error) {
        console.error("Error getting branch:", error);
        return [];
    }
}