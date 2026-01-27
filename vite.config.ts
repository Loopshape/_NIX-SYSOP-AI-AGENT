import path from 'path';
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

const GEMINI_API_KEY="AIzaSyD4eva8xXXqFmXvE_t3WTYjMJOZrE4LTUo"

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, '.', '');
    return {
      base: './', // Ensure relative paths for build
      server: {
        port: 8080,
        host: '127.0.0.1',
        proxy: {
            '/ollama': {
                target: 'http://localhost:11434',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/ollama/, '')
            },
            '/api': {
                target: 'http://localhost:11434/api',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/api/, '')
            }
        }
      },
      build: {
        target: 'esnext',
        minify: 'esbuild',
        cssCodeSplit: true,
        rollupOptions: {
            output: {
                manualChunks: {
                    'vendor-react': ['react', 'react-dom'],
                    'vendor-genai': ['@google/genai'],
                    'vendor-utils': ['gsap']
                }
            }
        }
      },
      plugins: [react()],
      define: {
        'process.env.API_KEY': JSON.stringify(env.GEMINI_API_KEY),
        'process.env.GEMINI_API_KEY': JSON.stringify(env.GEMINI_API_KEY)
      },
      resolve: {
        alias: {
          '@': path.resolve(__dirname, '.'),
        }
      }
    };
});

