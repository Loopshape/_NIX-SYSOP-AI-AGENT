// Test script for Ollama fallback mechanisms
const { nexusEngine } = require('./services/nexusEngine');

async function runTests() {
  console.log('🚀 Starting Ollama Fallback Tests');
  console.log('================================');
  
  // Test 1: Normal query
  console.log('\n📝 Test 1: Normal Ollama Query');
  try {
    const result = await nexusEngine.processPrompt('Hello, respond with OK', {
      model: 'llama3',
      stream: false
    });
    
    console.log(`✓ Success: ${result.success}`);
    console.log(`  Fallback used: ${result.fallbackUsed}`);
    console.log(`  Response length: ${result.result.length}`);
  } catch (error) {
    console.log(`✗ Failed: ${error.message}`);
  }
  
  // Test 2: Simulated connection error
  console.log('\n📝 Test 2: Simulated Connection Error');
  try {
    process.env.OLLAMA_HOST = 'http://localhost:9999';
    
    const result = await nexusEngine.processPrompt('Test connection error', {
      model: 'llama3',
      stream: false
    });
    
    console.log(`✓ Handled gracefully`);
    console.log(`  Fallback used: ${result.fallbackUsed}`);
    console.log(`  Errors: ${result.errors.length}`);
  } catch (error) {
    console.log(`✗ Unhandled: ${error.message}`);
  } finally {
    process.env.OLLAMA_HOST = 'http://localhost:11434';
  }
  
  console.log('\n✅ All tests completed');
  console.log('================================');
}

runTests().catch(console.error);
