import React, { useState, useEffect, useRef } from 'react';
import { nexusEngine } from '../services/nexusEngine';

interface ModelMetadata {
  name: string;
  digest: string;
  details: {
    format?: string;
    family?: string;
    parameter_size?: string;
    quantization?: string;
    modified_at?: string;
    size?: number;
  };
}

interface StreamingChunk {
  chunk: string;
  agent: string;
  done: boolean;
}

const App: React.FC = () => {
  const [prompt, setPrompt] = useState('');
  const [response, setResponse] = useState('');
  const [loading, setLoading] = useState(false);
  const [models, setModels] = useState<ModelMetadata[]>([]);
  const [selectedModel, setSelectedModel] = useState('');
  const [modelDetails, setModelDetails] = useState<ModelMetadata | null>(null);
  const [errors, setErrors] = useState<string[]>([]);
  const [streaming, setStreaming] = useState(false);
  const [streamChunks, setStreamChunks] = useState<StreamingChunk[]>([]);
  const [activeStream, setActiveStream] = useState<string>('');
  const streamContainerRef = useRef<HTMLDivElement>(null);

  // Load models on mount
  useEffect(() => {
    loadModels();
  }, []);

  const loadModels = async () => {
    try {
      const availableModels = await nexusEngine.getModels();
      setModels(availableModels);
      
      if (availableModels.length > 0) {
        const defaultModel = availableModels.find(m => m.name.includes('llama'))?.name || availableModels[0].name;
        setSelectedModel(defaultModel);
        nexusEngine.setActiveModel(defaultModel);
      }
    } catch (error) {
      console.error('Failed to load models:', error);
      setErrors(prev => [...prev, 'Failed to load models']);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!prompt.trim()) return;
    
    setLoading(true);
    setResponse('');
    setErrors([]);
    setStreamChunks([]);
    
    if (selectedModel) {
      nexusEngine.setActiveModel(selectedModel);
    }
    
    try {
      const result = await nexusEngine.processPrompt(prompt, {
        model: selectedModel,
        agent: 'CODE',
        stream: streaming,
        context: [{
          signInsights: 'Symbolic interpretation of patterns',
          loopOptimizations: 'Iterative refinement patterns',
          corePrinciples: 'Fundamental logical axioms'
        }]
      });
      
      setResponse(result.result);
      
      if (result.fallbackUsed) {
        setErrors(prev => [...prev, 'Fallback to Gemini was used']);
      }
      
      if (result.errors.length > 0) {
        setErrors(prev => [...prev, ...result.errors]);
      }
      
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      setErrors(prev => [...prev, `Processing failed: ${errorMessage}`]);
    } finally {
      setLoading(false);
    }
  };

  const handleModelSelect = (modelName: string) => {
    setSelectedModel(modelName);
    const model = models.find(m => m.name === modelName);
    setModelDetails(model || null);
  };

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100 p-6">
      <div className="max-w-6xl mx-auto">
        <header className="mb-8">
          <h1 className="text-3xl font-bold text-green-400">NEXUS AI Orchestrator</h1>
          <p className="text-gray-400 mt-2">Multi-Agent System with Streaming Support</p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-1 space-y-6">
            <div className="bg-gray-800 rounded-lg p-4">
              <h3 className="text-lg font-semibold mb-3">🧠 Ollama Models</h3>
              
              <div className="space-y-3">
                <select
                  value={selectedModel}
                  onChange={(e) => handleModelSelect(e.target.value)}
                  className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm"
                  disabled={loading}
                >
                  <option value="">Select a model...</option>
                  {models.map(model => (
                    <option key={model.name} value={model.name}>
                      {model.name}
                    </option>
                  ))}
                </select>
                
                {modelDetails && (
                  <div className="bg-gray-900 rounded p-3 text-sm space-y-2">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Family:</span>
                      <span>{modelDetails.details.family || 'Unknown'}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Digest:</span>
                      <span className="font-mono text-xs">
                        {modelDetails.digest.substring(0, 16)}...
                      </span>
                    </div>
                  </div>
                )}
              </div>
              
              <div className="mt-4 pt-4 border-t border-gray-700">
                <label className="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    checked={streaming}
                    onChange={(e) => setStreaming(e.target.checked)}
                    className="rounded"
                  />
                  <span>Enable Streaming</span>
                </label>
              </div>
            </div>
          </div>
          
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-gray-800 rounded-lg p-4">
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">
                    Enter Prompt for CODE Agent
                  </label>
                  <textarea
                    value={prompt}
                    onChange={(e) => setPrompt(e.target.value)}
                    rows={4}
                    className="w-full bg-gray-700 border border-gray-600 rounded px-3 py-2 text-sm"
                    placeholder="Describe what you want the CODE agent to implement..."
                    disabled={loading}
                  />
                </div>
                
                <div className="flex justify-between items-center">
                  <button
                    type="submit"
                    disabled={loading || !prompt.trim()}
                    className="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:opacity-50"
                  >
                    {loading ? 'Processing...' : 'Send to CODE Agent'}
                  </button>
                </div>
              </form>
            </div>
            
            {response && (
              <div className="bg-gray-800 rounded-lg p-4">
                <h3 className="text-lg font-semibold mb-3">🤖 Response</h3>
                <div className="bg-gray-900 rounded p-4 whitespace-pre-wrap font-mono text-sm">
                  {response}
                </div>
              </div>
            )}
            
            {errors.length > 0 && (
              <div className="bg-red-900/30 border border-red-700 rounded-lg p-4">
                <h3 className="text-lg font-semibold text-red-300 mb-2">⚠️ Errors</h3>
                <ul className="space-y-1">
                  {errors.map((error, index) => (
                    <li key={index} className="text-sm text-red-200">
                      • {error}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default App;
