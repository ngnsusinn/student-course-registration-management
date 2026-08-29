import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Dev: FE :5173 proxy /api + /images -> Express :3000
// Prod: build ra dist/ — Express phục vụ trực tiếp (1 cổng như portal)
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:3000',
      '/images': 'http://localhost:3000',
    },
  },
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 1200,
  },
});
