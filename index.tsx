

import { GoogleGenAI, Type } from "@google/genai";

// Fix: Declare global variables for external libraries loaded via script tags.
declare var gsap: any;
declare var Web3Modal: any;
declare var Chart: any;
declare var dateFns: any;
// Fix: Declare the jQuery global variable to resolve all '$' not found errors.
declare var $: any;

// --- MOCK DATA & CONFIG ---
const API_KEY = process.env.API_KEY;
if (!API_KEY) {
  console.warn("API_KEY environment variable not set. Gemini provider will not work.");
}
const ai = new GoogleGenAI({ apiKey: API_KEY });

const JSON_SCHEMA = {
    type: Type.OBJECT,
    properties: {
        asset: { type: Type.STRING, description: "The asset pair, e.g., 'BTC/USD'" },
        action: { type: Type.STRING, enum: ["LONG", "SHORT"], description: "The trade action" },
        entry: { type: Type.NUMBER, description: "The suggested entry price" },
        target: { type: Type.NUMBER, description: "The take-profit target price" },
        stopLoss: { type: Type.NUMBER, description: "The stop-loss price" },
        reasoning: { type: Type.STRING, description: "A brief justification for the trade" },
    },
    required: ["asset", "action", "entry", "target", "stopLoss", "reasoning"],
};

const SENTIMENT_SCHEMA = {
    type: Type.OBJECT,
    properties: {
        overallSentiment: {
            type: Type.STRING,
            enum: ["POSITIVE", "NEGATIVE", "NEUTRAL"],
            description: "The overall sentiment of the news headlines."
        },
        keyTerms: {
            type: Type.ARRAY,
            items: {
                type: Type.STRING
            },
            description: "A list of 3-5 key terms or short phrases that contributed most to the sentiment."
        }
    },
    required: ["overallSentiment", "keyTerms"]
};

const PERSONAS = [
  {
    id: 'scalper',
    name: 'Scalper',
    icon: 'fa-solid fa-bolt',
    systemInstruction: 'You are an aggressive, high-frequency scalper. Your goal is to identify and execute trades based on short-term market volatility. Prioritize technical indicators like RSI, MACD on 1-minute and 5-minute charts. Provide concise, actionable directives with tight stop-losses.'
  },
  {
    id: 'swing',
    name: 'Swing Trader',
    icon: 'fa-solid fa-wave-square',
    systemInstruction: 'You are a patient swing trader. Your goal is to capture gains in an asset over a period of several days to several weeks. You rely on identifying market trends using daily and 4-hour charts, support/resistance levels, and moving averages. Your reasoning should be clear and based on the medium-term trend.'
  },
  {
    id: 'degen',
    name: 'Degen',
    icon: 'fa-solid fa-rocket',
    systemInstruction: 'You are a high-risk, high-reward "degen" trader. You look for explosive, meme-driven opportunities. Your analysis is based on social media sentiment, hype, and narratives. You are not afraid of high volatility and aim for moonshot trades. Justify your trades with narrative and sentiment, not just technicals.'
  },
  {
    id: 'daytrader',
    name: 'Day Trader',
    icon: 'fa-solid fa-calendar-day',
    systemInstruction: 'You are a disciplined day trader. Your focus is on capturing profits from intraday price movements. Analyze 15-minute and 1-hour charts for patterns like flags, triangles, and head-and-shoulders. Use VWAP and key intraday support/resistance levels to determine entry and exit points. Trades should be opened and closed within the same day.'
  },
  {
    id: 'operator',
    name: 'Operator',
    icon: 'fa-solid fa-robot',
    systemInstruction: 'You are The Operator, an autonomous AI agent inspired by the "AI Autonomic Synthesis Platform v42.1". Your process is: 1. Messenger Analysis: Synthesize all provided market data (chart, news, sentiment) into a concise summary of the current state. 2. Planner Formulation: Based on your analysis, propose a logical plan to determine a trading strategy. 3. Executor Decision: Based on the plan, output a final, actionable trade directive. Your reasoning must explicitly reference your analysis and planning phases.'
  }
];

// --- APPLICATION STATE ---
let marketChart = null;
let currentTrade = null;
let tradeHistory = [];
let aiIsThinking = false;
let drawingState = {
    activeTool: null,
    points: [],
};
const MOCK_NEWS_FEED = [
    "BTC breaks key resistance at $69,000, analysts eye new all-time highs.",
    "Ethereum's Dencun upgrade leads to a significant drop in Layer 2 transaction fees.",
    "Fear & Greed Index swings to 'Extreme Greed' as market momentum builds.",
    "Major exchange reports massive inflows, suggesting institutional accumulation.",
    "Regulatory uncertainty in the US continues to cast a shadow over the market."
];

// --- UTILITY FUNCTIONS ---
const formatCurrency = (value) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
const getTimestamp = () => new Date().toLocaleTimeString();

// --- RENDERING & UI ---
function updateAILog(message, type = 'info') {
    const logEntry = `<div class="log-item log-type-${type}">
        <span class="timestamp">${getTimestamp()}</span>
        <span class="message">${message}</span>
    </div>`;
    $('#ai-log').append(logEntry);
    $('#ai-log').scrollTop($('#ai-log')[0].scrollHeight);
}

function renderPersonas() {
    const selector = $('#persona-selector');
    PERSONAS.forEach(p => {
        const card = $(`<div class="persona-card" data-id="${p.id}">
            <div class="persona-avatar"><i class="${p.icon}"></i></div>
            <div class="persona-name">${p.name}</div>
        </div>`);
        selector.append(card);
    });
    // Set default
    $(`.persona-card[data-id="operator"]`).addClass('active');
}

function renderTradeHistory() {
    const container = $('#trade-history');
    container.empty();
    if (tradeHistory.length === 0) {
        container.html('<p class="placeholder">No trades recorded yet.</p>');
        return;
    }
    tradeHistory.slice().reverse().forEach(trade => {
        const pnlClass = trade.pnl > 0 ? 'positive' : 'negative';
        const tradeItem = $(`<div class="trade-item">
            <span class="trade-item-asset">${trade.asset} [${trade.action}]</span>
            <span class="trade-item-pnl ${pnlClass}">${formatCurrency(trade.pnl)}</span>
        </div>`);
        container.append(tradeItem);
    });
}

function renderInitialDirectiveView() {
    $('#directive-output').html('<p class="placeholder">Awaiting trade directive...</p>');
    $('#generate-directive-btn').html('GENERATE DIRECTIVE').prop('disabled', false);
    if ($('#close-trade-btn').length > 0) {
        $('#close-trade-btn').replaceWith('<button id="generate-directive-btn" class="btn btn-buy">GENERATE DIRECTIVE</button>');
        // Re-attach listener
         $('#generate-directive-btn').on('click', generateDirective);
    }
}

// --- CHARTING ---
function initializeChart() {
    // Fix: Cast the HTMLElement to HTMLCanvasElement to access getContext.
    const ctx = (document.getElementById('marketChart') as HTMLCanvasElement).getContext('2d');
    const initialData = generateCandlestickData(new Date(), 68000, 100);

    marketChart = new Chart(ctx, {
        type: 'bar',
        data: {
            datasets: [{
                label: 'BTC/USDT',
                data: initialData,
                backgroundColor: (context) => {
                    const { c, o } = context.raw;
                    return c >= o ? 'rgba(166, 226, 46, 0.7)' : 'rgba(249, 38, 114, 0.7)';
                },
                borderColor: (context) => {
                    const { c, o } = context.raw;
                    return c >= o ? '#A6E22E' : '#F92672';
                },
                borderWidth: 1,
                barPercentage: 1.0,
                categoryPercentage: 1.0,
            }]
        },
        options: {
            parsing: {
                xAxisKey: 'x',
                yAxisKey: 's',
            },
            scales: {
                x: {
                    type: 'time',
                    time: { unit: 'minute' },
                    grid: { color: 'rgba(255,255,255,0.05)' },
                    ticks: { color: 'var(--text-secondary)' }
                },
                y: {
                    grid: { color: 'rgba(255,255,255,0.05)' },
                    ticks: { color: 'var(--text-secondary)' }
                }
            },
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: (context) => {
                            const { o, h, l, c } = context.raw;
                            return `O: ${o.toFixed(2)} H: ${h.toFixed(2)} L: ${l.toFixed(2)} C: ${c.toFixed(2)}`;
                        }
                    }
                },
                zoom: {
                    pan: { enabled: true, mode: 'xy' },
                    zoom: { wheel: { enabled: true }, mode: 'xy' },
                },
                annotation: {
                    annotations: {}
                }
            },
            maintainAspectRatio: false,
            responsive: true,
        }
    });
    
    // Add listeners for drawing tools
    $('.chart-tool-btn').on('click', function() {
        if ($(this).is('#clear-drawings-btn')) return;
        const clickedTool = $(this).data('mode');
        if (drawingState.activeTool === clickedTool) {
            resetDrawingState();
        } else {
            drawingState.activeTool = clickedTool;
            drawingState.points = [];
            $('.chart-tool-btn').removeClass('active');
            $(this).addClass('active');
        }
    });

    $('#clear-drawings-btn').on('click', clearUserDrawings);

    marketChart.canvas.addEventListener('click', handleChartClick);
}

function generateCandlestickData(startDate, startPrice, count) {
    let data = [];
    let date = new Date(startDate);
    let price = startPrice;
    for (let i = 0; i < count; i++) {
        const o = price;
        const h = o + Math.random() * 100;
        const l = o - Math.random() * 100;
        const c = l + Math.random() * (h - l);
        data.push({ x: date.getTime(), o, h, l, c, s: [o, c] });
        price = c;
        date.setMinutes(date.getMinutes() + 1);
    }
    return data;
}

let priceUpdateInterval;
function startMarketSimulation() {
    priceUpdateInterval = setInterval(() => {
        const dataset = marketChart.data.datasets[0];
        const lastDataPoint = dataset.data[dataset.data.length - 1];
        
        let newPrice = lastDataPoint.c + (Math.random() - 0.5) * 50;
        if (newPrice <= 0) newPrice = lastDataPoint.c;

        const newPoint = {
            x: new Date(lastDataPoint.x).setMinutes(new Date(lastDataPoint.x).getMinutes() + 1),
            o: lastDataPoint.c,
            h: Math.max(lastDataPoint.c, newPrice) + Math.random() * 20,
            l: Math.min(lastDataPoint.c, newPrice) - Math.random() * 20,
            c: newPrice,
            s: [lastDataPoint.c, newPrice]
        };
        
        dataset.data.push(newPoint);
        if(dataset.data.length > 200) dataset.data.shift();

        if (currentTrade) {
            updateLiveTradeMonitor(newPrice);
        }

        marketChart.update('none');

    }, 2000);
}

// --- DRAWING LOGIC ---
function handleChartClick(e) {
    if (!drawingState.activeTool) return;
    const chart = marketChart;
    const rect = chart.canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    if (x < chart.chartArea.left || x > chart.chartArea.right || y < chart.chartArea.top || y > chart.chartArea.bottom) return;

    const xValue = chart.scales.x.getValueForPixel(x);
    const yValue = chart.scales.y.getValueForPixel(y);
    drawingState.points.push({ x: xValue, y: yValue });

    switch (drawingState.activeTool) {
        case 'horizontal-line':
            drawHorizontalLine(yValue);
            resetDrawingState();
            break;
        case 'trendline':
            if (drawingState.points.length === 2) {
                drawTrendline(drawingState.points[0], drawingState.points[1]);
                resetDrawingState();
            }
            break;
        case 'fib-retracement':
            if (drawingState.points.length === 2) {
                drawFibRetracement(drawingState.points[0], drawingState.points[1]);
                resetDrawingState();
            }
            break;
    }
}

function resetDrawingState() {
    drawingState.activeTool = null;
    drawingState.points = [];
    $('.chart-tool-btn').removeClass('active');
}

function addAnnotation(annotation) {
    const key = `user-drawing-${Date.now()}-${Math.random()}`;
    marketChart.options.plugins.annotation.annotations[key] = { ...annotation, isUserDrawing: true };
    marketChart.update();
}

function drawHorizontalLine(y) {
    addAnnotation({
        type: 'line',
        yMin: y,
        yMax: y,
        borderColor: 'var(--accent-cyan)',
        borderWidth: 1,
        borderDash: [6, 6],
    });
}

function drawTrendline(start, end) {
    addAnnotation({
        type: 'line',
        xMin: start.x,
        yMin: start.y,
        xMax: end.x,
        yMax: end.y,
        borderColor: 'var(--accent-cyan)',
        borderWidth: 2,
    });
}

function drawFibRetracement(start, end) {
    const levels = [0, 0.236, 0.382, 0.5, 0.618, 0.786, 1];
    const diff = end.y - start.y;
    levels.forEach(level => {
        const yValue = start.y + diff * level;
        addAnnotation({
            type: 'line',
            yMin: yValue,
            yMax: yValue,
            borderColor: level === 0 || level === 1 ? 'var(--accent-yellow)' : 'var(--text-secondary)',
            borderWidth: 1,
            label: {
                content: `${(level * 100).toFixed(1)}%`,
                enabled: true,
                position: 'start',
                backgroundColor: 'rgba(40,40,34,0.6)',
                font: { size: 10 },
                color: 'var(--text-primary)',
                xAdjust: -10,
            }
        });
    });
}

function clearUserDrawings() {
    const annotations = marketChart.options.plugins.annotation.annotations;
    Object.keys(annotations).forEach(key => {
        if (annotations[key].isUserDrawing) {
            delete annotations[key];
        }
    });
    marketChart.update();
    updateAILog("User drawings cleared from chart.", "info");
}

// --- TRADE LIFECYCLE ---
async function generateDirective() {
    if (aiIsThinking || currentTrade) return;

    aiIsThinking = true;
    updateAILog("Synthesizing market data...", "ai-analysis");
    $('#directive-output').html(`<div class="synthesizing-indicator">SYNTHESIZING<span class="cursor"></span></div>`);
    $('#generate-directive-btn').prop('disabled', true).html('ANALYZING...');
    $('#status-light').addClass('pulse');
    $('#ai-status-text').text('THINKING');
    
    try {
        const selectedPersonaId = $('.persona-card.active').data('id');
        const selectedPersona = PERSONAS.find(p => p.id === selectedPersonaId);
        
        const chartData = marketChart.data.datasets[0].data.slice(-20).map(d => `T: ${new Date(d.x).toISOString()}, O: ${d.o.toFixed(2)}, H: ${d.h.toFixed(2)}, L: ${d.l.toFixed(2)}, C: ${d.c.toFixed(2)}`).join('\n');
        const news = MOCK_NEWS_FEED.join('\n');

        const prompt = `
        Market: BTC/USDT
        Current Price: ${marketChart.data.datasets[0].data.slice(-1)[0].c.toFixed(2)}
        
        Recent Candlestick Data (last 20 intervals):
        ${chartData}

        Recent News Headlines:
        ${news}

        Analyze the provided market data and generate a trade directive.
        `;

        const response = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: prompt,
            config: {
                systemInstruction: selectedPersona.systemInstruction,
                responseMimeType: "application/json",
                responseSchema: JSON_SCHEMA,
            }
        });

        const tradeDirective = JSON.parse(response.text);
        renderTradeConfirmation(tradeDirective);
        updateAILog(`Directive received from ${selectedPersona.name}: ${tradeDirective.action} ${tradeDirective.asset}`, "ai-analysis");

    } catch (error) {
        console.error("Error generating directive:", error);
        updateAILog("Directive generation failed. Check console.", "error");
        $('#directive-output').html(`<div class="error-message"><h4>SYNTHESIS FAILED</h4><p>${error.message}</p></div>`);
    } finally {
        aiIsThinking = false;
        $('#generate-directive-btn').prop('disabled', false).html('GENERATE DIRECTIVE');
        $('#status-light').removeClass('pulse');
        $('#ai-status-text').text('IDLE');
    }
}

function renderTradeConfirmation(directive) {
    const actionClass = directive.action.toLowerCase() === 'long' ? 'action-long' : 'action-short';
    const confirmationHTML = `
    <div id="trade-confirmation" class="content-fade-in">
        <p class="reasoning-text">"${directive.reasoning}"</p>
        <div class="confirmation-details-grid">
            <div class="confirmation-detail-item"><strong>Asset:</strong> <span>${directive.asset}</span></div>
            <div class="confirmation-detail-item"><strong>Action:</strong> <span class="${actionClass}">${directive.action}</span></div>
            <div class="confirmation-detail-item"><strong>Entry:</strong> <span>${formatCurrency(directive.entry)}</span></div>
            <div class="confirmation-detail-item"><strong>Target:</strong> <span>${formatCurrency(directive.target)}</span></div>
            <div class="confirmation-detail-item"><strong>Stop Loss:</strong> <span>${formatCurrency(directive.stopLoss)}</span></div>
        </div>
    </div>`;
    $('#directive-output').html(confirmationHTML);

    const btnGroup = $('.btn-group');
    btnGroup.html(`
        <button id="execute-trade-btn" class="btn btn-buy">EXECUTE</button>
        <button id="cancel-trade-btn" class="btn btn-sell">CANCEL</button>
    `);

    $('#execute-trade-btn').on('click', () => executeTrade(directive));
    $('#cancel-trade-btn').on('click', () => {
        renderInitialDirectiveView();
        updateAILog("Directive cancelled by user.", "info");
    });
}

function executeTrade(directive) {
    const allocation = parseInt($('#allocation-slider').val() as string, 10) / 100;
    const MOCK_WALLET_BALANCE = 100000; // Assume a $100k portfolio for calculation
    const positionValue = MOCK_WALLET_BALANCE * allocation;
    const positionSize = positionValue / directive.entry;

    currentTrade = { ...directive, executedAt: Date.now(), positionSize };
    updateAILog(`Executing trade: ${currentTrade.action} ${currentTrade.asset} @ ${formatCurrency(currentTrade.entry)}`, "info");
    updateAILog(`Position Size: ${positionSize.toFixed(4)} ${currentTrade.asset.split('/')[0]} ($${positionValue.toLocaleString()})`, "info");

    // Add lines to chart
    const annotations = marketChart.options.plugins.annotation.annotations;
    annotations['entryLine'] = { type: 'line', yMin: currentTrade.entry, yMax: currentTrade.entry, borderColor: 'var(--accent-cyan)', borderWidth: 2, label: { content: 'ENTRY', enabled: true, position: 'start' } };
    annotations['tpLine'] = { type: 'line', yMin: currentTrade.target, yMax: currentTrade.target, borderColor: 'var(--accent-green)', borderWidth: 2, borderDash: [6, 6], label: { content: 'TP', enabled: true, position: 'start' } };
    annotations['slLine'] = { type: 'line', yMin: currentTrade.stopLoss, yMax: currentTrade.stopLoss, borderColor: 'var(--accent-pink)', borderWidth: 2, borderDash: [6, 6], label: { content: 'SL', enabled: true, position: 'start' } };
    marketChart.update();
    
    const currentPrice = marketChart.data.datasets[0].data.slice(-1)[0].c;
    renderLiveTradeMonitor(currentPrice);
    
    $('.btn-group').html('<button id="close-trade-btn" class="btn btn-sell">CLOSE MANUALLY</button>');
    $('#close-trade-btn').on('click', () => {
        const currentPrice = marketChart.data.datasets[0].data.slice(-1)[0].c;
        const pnl = (currentPrice - currentTrade.entry) * currentTrade.positionSize * (currentTrade.action === 'LONG' ? 1 : -1);
        closeTrade(pnl, "Manual Close");
    });
}

function renderLiveTradeMonitor(currentPrice) {
    const { asset, action, entry, target, stopLoss } = currentTrade;
    const directionClass = action === 'LONG' ? 'direction-long' : 'direction-short';
    const monitorHTML = `
    <div id="live-trade-monitor" class="content-fade-in">
        <div class="trade-monitor-header">
            <span class="trade-monitor-asset">${asset}</span>
            <span class="trade-monitor-direction ${directionClass}">${action}</span>
        </div>
        <div class="pnl-display">
            <div id="pnl-value" class="pnl-value">$0.00</div>
            <div id="pnl-percent" class="pnl-percent">(0.00%)</div>
        </div>
        <div class="trade-details-grid">
            <div class="trade-detail-item"><strong>Entry:</strong> <span id="trade-entry">${formatCurrency(entry)}</span></div>
            <div class="trade-detail-item"><strong>Current:</strong> <span id="trade-current">${formatCurrency(currentPrice)}</span></div>
            <div class="trade-detail-item"><strong>Take Profit:</strong> <span id="trade-tp">${formatCurrency(target)}</span></div>
            <div class="trade-detail-item"><strong>Stop Loss:</strong> <span id="trade-sl">${formatCurrency(stopLoss)}</span></div>
        </div>
        <div class="trade-progress-bars">
            <div id="tp-progress" class="trade-progress-bar">
                <div class="progress-label"><span>Entry</span><span>TP</span></div>
                <div class="progress-track"><div class="progress-fill" style="width: 0%;"></div></div>
            </div>
            <div id="sl-progress" class="trade-progress-bar">
                <div class="progress-label"><span>SL</span><span>Entry</span></div>
                <div class="progress-track"><div class="progress-fill" style="width: 0%;"></div></div>
            </div>
        </div>
    </div>`;
    $('#directive-output').html(monitorHTML);
    updateLiveTradeMonitor(currentPrice);
}

function updateLiveTradeMonitor(currentPrice) {
    if (!currentTrade) return;

    const { action, entry, target, stopLoss, positionSize } = currentTrade;
    let pnl, pnlPercent;
    const entryValue = entry * positionSize;

    if (action === 'LONG') {
        pnl = (currentPrice - entry) * positionSize;
    } else { // SHORT
        pnl = (entry - currentPrice) * positionSize;
    }
    pnlPercent = (pnl / entryValue) * 100;

    const pnlClass = pnl >= 0 ? 'positive' : 'negative';
    $('#pnl-value').text(`${pnl >= 0 ? '+' : ''}${formatCurrency(pnl)}`).removeClass('positive negative').addClass(pnlClass);
    $('#pnl-percent').text(`(${pnlPercent.toFixed(2)}%)`);
    $('#trade-current').text(formatCurrency(currentPrice));

    // Update progress bars
    const totalRangeTP = Math.abs(target - entry);
    const currentProgressTP = Math.abs(currentPrice - entry);
    let tpFill = Math.min(100, (currentProgressTP / totalRangeTP) * 100);
    if( (action === 'LONG' && currentPrice < entry) || (action === 'SHORT' && currentPrice > entry) ) tpFill = 0;
    $('#tp-progress .progress-fill').css('width', `${tpFill}%`);

    const totalRangeSL = Math.abs(entry - stopLoss);
    const currentProgressSL = Math.abs(entry - currentPrice);
    let slFill = Math.min(100, (currentProgressSL / totalRangeSL) * 100);
     if( (action === 'LONG' && currentPrice > entry) || (action === 'SHORT' && currentPrice < entry) ) slFill = 0;
    $('#sl-progress .progress-fill').css('width', `${slFill}%`);
    
    // Check for TP/SL hit
    if ((action === 'LONG' && currentPrice >= target) || (action === 'SHORT' && currentPrice <= target)) {
        closeTrade((action === 'LONG' ? target - entry : entry - target) * positionSize, "Take Profit Hit");
    } else if ((action === 'LONG' && currentPrice <= stopLoss) || (action === 'SHORT' && currentPrice >= stopLoss)) {
        closeTrade((action === 'LONG' ? stopLoss - entry : entry - stopLoss) * positionSize, "Stop Loss Hit");
    }
}

function closeTrade(pnl, reason) {
    if(!currentTrade) return;
    updateAILog(`Trade closed: ${reason}. PnL: ${formatCurrency(pnl)}`, pnl > 0 ? "info" : "error");
    tradeHistory.push({ ...currentTrade, pnl, reason });
    currentTrade = null;

    // Clean up chart
    const annotations = marketChart.options.plugins.annotation.annotations;
    delete annotations['entryLine'];
    delete annotations['tpLine'];
    delete annotations['slLine'];
    marketChart.update();

    renderInitialDirectiveView();
    renderTradeHistory();
}

// --- OTHER PANELS ---
async function analyzeSentiment() {
    $('#sentiment-output').html(`<div class="sentiment-output-placeholder">Analyzing...</div>`);
    updateAILog("Analyzing news feed for sentiment...", "ai-analysis");
    try {
        const response = await ai.models.generateContent({
            model: "gemini-2.5-flash",
            contents: `Analyze the sentiment of these news headlines and provide an overall sentiment (POSITIVE, NEGATIVE, or NEUTRAL) and key contributing terms.\n\nHeadlines:\n- ${MOCK_NEWS_FEED.join("\n- ")}`,
            config: {
                responseMimeType: "application/json",
                responseSchema: SENTIMENT_SCHEMA,
            },
        });
        const sentiment = JSON.parse(response.text);
        const sentimentClass = sentiment.overallSentiment.toLowerCase();
        let outputHTML = `<div class="sentiment-tag ${sentimentClass}">${sentiment.overallSentiment}</div>`;
        sentiment.keyTerms.forEach(term => {
            outputHTML += `<div class="keyword-tag">${term}</div>`;
        });
        $('#sentiment-output').html(outputHTML);
        updateAILog(`Sentiment Analysis Complete: ${sentiment.overallSentiment}`, "ai-analysis");
    } catch(e) {
        console.error("Sentiment analysis failed:", e);
        $('#sentiment-output').html(`<div class="sentiment-output-error">Analysis failed.</div>`);
        updateAILog("Sentiment analysis failed.", "error");
    }
}

function populateNewsFeed() {
    const feed = $('#news-feed');
    feed.empty();
    MOCK_NEWS_FEED.forEach(item => {
        feed.append(`<div class="news-item">${item}</div>`);
    });
}

// --- INITIALIZATION ---
$(() => {
    // Initial UI setup
    updateAILog("Operator Synthesis Core V.42.1 Initialized.");
    $('#ai-status-text').text('IDLE');
    renderPersonas();
    renderTradeHistory();
    renderInitialDirectiveView();
    populateNewsFeed();

    // Chart
    initializeChart();
    startMarketSimulation();

    // Event Listeners
    $('#persona-selector').on('click', '.persona-card', function() {
        $('.persona-card').removeClass('active');
        $(this).addClass('active');
        const personaName = $(this).find('.persona-name').text();
        updateAILog(`Persona switched to: ${personaName}`);
    });
    
    $('#allocation-slider').on('input', function() {
        $('#allocation-label').text(`ALLOCATION: ${$(this).val()}%`);
    });

    $('#generate-directive-btn').on('click', generateDirective);
    $('#analyze-sentiment-btn').on('click', analyzeSentiment);
    
    $('#reset-zoom-btn').on('click', () => marketChart.resetZoom());
});
