let scene, camera, renderer, controls;
let nodes = [];
let links = [];
const nodeMeshes = new THREE.Group();
const linkMeshes = new THREE.Group();

init();
animate();

function init() {
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
    camera.position.z = 50;

    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);

    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;

    scene.add(nodeMeshes);
    scene.add(linkMeshes);

    const ambientLight = new THREE.AmbientLight(0x404040);
    scene.add(ambientLight);
    const pointLight = new THREE.PointLight(0xffffff, 1);
    pointLight.position.set(10, 10, 10);
    scene.add(pointLight);

    fetchData();
    setInterval(fetchData, 5000);

    window.addEventListener('resize', onWindowResize, false);
    window.addEventListener('click', onDocumentMouseDown, false);
}

async function fetchData() {
    try {
        const response = await fetch('/api/graph');
        const data = await response.json();
        updateGraph(data);
    } catch (err) {
        console.error('Error fetching graph data:', err);
    }
}

function updateGraph(data) {
    // Basic force-directed layout simulation (simplified)
    const newNodes = data.map((d, i) => ({
        ...d,
        x: d.x || (Math.random() - 0.5) * 100,
        y: d.y || (Math.random() - 0.5) * 100,
        z: d.z || (Math.random() - 0.5) * 100
    }));

    // Rebuild meshes
    nodeMeshes.clear();
    linkMeshes.clear();

    const geometry = new THREE.SphereGeometry(1, 16, 16);
    
    newNodes.forEach(node => {
        const color = node.entropy > 1.5 ? 0xff4d4d : 0x4dff88;
        const material = new THREE.MeshPhongMaterial({ color });
        const sphere = new THREE.Mesh(geometry, material);
        sphere.position.set(node.x, node.y, node.z);
        sphere.userData = node;
        nodeMeshes.add(sphere);

        if (node.parent) {
            const parent = newNodes.find(n => n.hash === node.parent);
            if (parent) {
                const points = [
                    new THREE.Vector3(node.x, node.y, node.z),
                    new THREE.Vector3(parent.x, parent.y, parent.z)
                ];
                const lineGeometry = new THREE.BufferGeometry().setFromPoints(points);
                const lineMaterial = new THREE.LineBasicMaterial({ color: 0x444444, transparent: true, opacity: 0.5 });
                const line = new THREE.Line(lineGeometry, lineMaterial);
                linkMeshes.add(line);
            }
        }
    });
}

function onDocumentMouseDown(event) {
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();
    mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObjects(nodeMeshes.children);

    if (intersects.length > 0) {
        const node = intersects[0].object.userData;
        window.parent.postMessage({ type: 'NODE_SELECTED', node }, '*');
    }
}

function onWindowResize() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
}

function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
}
