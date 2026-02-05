#!/bin/env node

// tool-api.js (Native Fetch version)

const prompt = process.argv.slice(2).join(' ');
const MODEL = 'glm-4.7:cloud';
const OLLAMA_URL = 'http://localhost:11434/api/chat';

if (!prompt) {
  console.error('Usage: node tool-api.js "Your prompt"');
  process.exit(1);
}

async function runModel() {
  try {
    const response = await fetch(OLLAMA_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: MODEL,
        messages: [{ role: 'user', content: prompt }],
        stream: true
      }),
    });

    if (!response.ok) throw new Error(`Ollama API Error: ${response.statusText}`);

    // Handle streaming chunks
    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = decoder.decode(value);
      // Ollama sends multiple JSON objects per chunk sometimes, split by newlines
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (!line.trim()) continue;
        try {
          const json = JSON.parse(line);
          if (json.message && json.message.content) {
            process.stdout.write(json.message.content);
          }
        } catch (e) {
          // Ignore parse errors for partial chunks
        }
      }
    }
    console.log();

  } catch (error) {
    console.error('Error:', error.message);
  }
}

runModel();
