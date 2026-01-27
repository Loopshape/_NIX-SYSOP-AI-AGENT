// ==UserScript==
// @name         NEXUS-AI-Agent-System
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Autonomous multi-agent AI system with full web integration.
// @author       Loop
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_addStyle
// @require      https://code.jquery.com/jquery-3.6.0.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/gsap/3.9.1/gsap.min.js
// ==/UserScript==

(function() {
    'use strict';

    const BACKEND_URL = "http://localhost:8000";

    // Styles
    GM_addStyle(`
        #nexus-dashboard {
            position: fixed;
            top: 20px;
            right: 20px;
            width: 400px;
            height: 600px;
            background: rgba(10, 10, 15, 0.95);
            color: #00ffcc;
            border: 1px solid #00ffcc;
            border-radius: 8px;
            z-index: 999999;
            display: none;
            flex-direction: column;
            font-family: 'Courier New', Courier, monospace;
            box-shadow: 0 0 20px rgba(0, 255, 204, 0.3);
            overflow: hidden;
        }
        #nexus-header {
            padding: 10px;
            background: rgba(0, 255, 204, 0.1);
            border-bottom: 1px solid #00ffcc;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        #nexus-content {
            flex-grow: 1;
            padding: 10px;
            overflow-y: auto;
            font-size: 12px;
        }
        #nexus-3d-memory {
            height: 200px;
            background: #000;
            margin-bottom: 10px;
            border: 1px solid #333;
        }
        #nexus-footer {
            padding: 10px;
            border-top: 1px solid #00ffcc;
        }
        #nexus-input {
            width: 100%;
            background: #000;
            color: #00ffcc;
            border: 1px solid #00ffcc;
            padding: 5px;
            outline: none;
        }
        .agent-pill {
            display: inline-block;
            padding: 2px 6px;
            margin: 2px;
            border: 1px solid #00ffcc;
            border-radius: 4px;
            font-size: 10px;
        }
    `);

    // UI Structure
    const dashboard = $(`
        <div id="nexus-dashboard">
            <div id="nexus-header">
                <span>NEXUS-AI-AGENT-SYSTEM</span>
                <span id="nexus-close" style="cursor:pointer">X</span>
            </div>
            <div id="nexus-content">
                <div id="nexus-3d-memory"></div>
                <div id="agent-pool">
                    <span class="agent-pill">CORE</span>
                    <span class="agent-pill">CUBE</span>
                    <span class="agent-pill">LOOP</span>
                    <span class="agent-pill">SIGN</span>
                    <span class="agent-pill">LINE</span>
                    <span class="agent-pill">COIN</span>
                    <span class="agent-pill">WORK</span>
                    <span class="agent-pill">CODE</span>
                </div>
                <hr>
                <div id="nexus-logs"></div>
            </div>
            <div id="nexus-footer">
                <input type="text" id="nexus-input" placeholder="Enter command or prompt...">
            </div>
        </div>
    `).appendTo('body');

    // Toggle Dashboard (CTRL+ALT+ENTER)
    $(document).keydown(function(e) {
        if (e.ctrlKey && e.altKey && e.which === 13) {
            dashboard.fadeToggle();
            if (dashboard.is(':visible')) {
                initThreeJS();
            }
        }
    });

    $('#nexus-close').click(() => dashboard.fadeOut());

    // Three.js Visualization
    let scene, camera, renderer, cube;
    function initThreeJS() {
        if (scene) return;
        const container = document.getElementById('nexus-3d-memory');
        scene = new THREE.Scene();
        camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
        renderer = new THREE.WebGLRenderer({ alpha: true });
        renderer.setSize(container.clientWidth, container.clientHeight);
        container.appendChild(renderer.domElement);

        const geometry = new THREE.IcosahedronGeometry(1, 1);
        const material = new THREE.MeshBasicMaterial({ color: 0x00ffcc, wireframe: true });
        cube = new THREE.Mesh(geometry, material);
        scene.add(cube);

        camera.position.z = 5;

        function animate() {
            requestAnimationFrame(animate);
            cube.rotation.x += 0.01;
            cube.rotation.y += 0.01;
            renderer.render(scene, camera);
        }
        animate();
    }

    // Backend Communication
    function sendPrompt(text) {
        const logs = $('#nexus-logs');
        logs.append(`<div style="color:#aaa">> ${text}</div>`);
        
        GM_xmlhttpRequest({
            method: "POST",
            url: `${BACKEND_URL}/process`,
            data: JSON.stringify({ prompt: text, context: document.title }),
            headers: { "Content-Type": "application/json" },
            onload: function(response) {
                const data = JSON.parse(response.responseText);
                if (data.best) {
                    logs.append(`<div style="margin-top:5px; color:#fff">[${data.best.agent}] ${data.best.response}</div>`);
                    animateMemory();
                }
            },
            onerror: function(err) {
                logs.append(`<div style="color:red">Error: Backend unreachable</div>`);
            }
        });
    }

    function animateMemory() {
        if (cube) {
            gsap.to(cube.scale, { x: 1.5, y: 1.5, z: 1.5, duration: 0.2, yoyo: true, repeat: 1 });
        }
    }

    $('#nexus-input').keypress(function(e) {
        if (e.which === 13) {
            const val = $(this).val();
            if (val) {
                sendPrompt(val);
                $(this).val('');
            }
        }
    });

    // DOM Diffing & Heatmaps
    let lastDOM = "";
    function syncDOM() {
        const currentDOM = document.body.innerText;
        if (lastDOM && lastDOM !== currentDOM) {
            console.log("NEXUS: DOM Change Detected");
            highlightChanges();
        }
        lastDOM = currentDOM;
    }

    function highlightChanges() {
        $('*').each(function() {
            if ($(this).children().length === 0 && $(this).text().trim().length > 0) {
                if ($(this).data('nexus-observed') !== $(this).text()) {
                    $(this).css('outline', '1px solid rgba(0, 255, 204, 0.5)');
                    $(this).data('nexus-observed', $(this).text());
                }
            }
        });
    }

    // Heatmap Simulation
    function showHeatmap() {
        const heatmap = $('<div id="nexus-heatmap"></div>').appendTo('body').css({
            position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
            pointerEvents: 'none', zIndex: 999998, background: 'rgba(0, 255, 204, 0.05)'
        });
        
        for (let i = 0; i < 50; i++) {
            $('<div class="heat-point"></div>').appendTo(heatmap).css({
                position: 'absolute',
                top: Math.random() * 100 + '%',
                left: Math.random() * 100 + '%',
                width: '50px', height: '50px',
                borderRadius: '50%',
                background: 'radial-gradient(circle, rgba(0,255,204,0.3) 0%, transparent 70%)'
            });
        }
        setTimeout(() => heatmap.fadeOut(2000, () => heatmap.remove()), 3000);
    }

    // Update Dashboard UI with more controls
    function addControls() {
        $('#nexus-header').append(`
            <div style="display:flex; gap:5px">
                <button id="nexus-heatmap-btn" style="font-size:8px; cursor:pointer; background:none; border:1px solid #00ffcc; color:#00ffcc">HEAT</button>
                <button id="nexus-sync-btn" style="font-size:8px; cursor:pointer; background:none; border:1px solid #00ffcc; color:#00ffcc">SYNC</button>
            </div>
        `);

        $('#nexus-heatmap-btn').click(showHeatmap);
        $('#nexus-sync-btn').click(syncDOM);
    }

    addControls();
    setInterval(syncDOM, 5000);

})();
