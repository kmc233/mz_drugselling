import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  define: {
    'process.env.NODE_ENV': JSON.stringify('production')
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    cssCodeSplit: false,
    lib: {
      entry: 'src/main.js',
      name: 'MZPhone',
      formats: ['iife'],
      fileName: () => 'scripts/phone_vue.js',
      cssFileName: 'css/phone_vue'
    }
  }
});
