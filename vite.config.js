import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import elm from 'vite-plugin-elm'

const root = resolve(import.meta.dirname, 'html')

export default defineConfig({
  root,
  publicDir: resolve(import.meta.dirname, 'public'),
  plugins: [elm()],
  build: {
    outDir: resolve(import.meta.dirname, 'dist'),
    emptyOutDir: true,
    rollupOptions: {
      input: {
        index: resolve(root, 'index.html'),
        privacy: resolve(root, 'privacy/index.html'),
        woordle6: resolve(root, 'woordle6/index.html'),
        wordle: resolve(root, 'wordle/index.html'),
        wordle6: resolve(root, 'wordle6/index.html'),
      },
    },
  },
})
