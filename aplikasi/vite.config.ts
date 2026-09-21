import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

/**
 * Konfigurasi Vite.
 * - `host: true` + `allowedHosts: true` supaya aplikasi bisa dibuka dari HP
 *   maupun dari pratinjau (proxy) di lingkungan pengembangan.
 * - `base` default '/' (cocok untuk Cloudflare Static Assets).
 */
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    port: 5173,
    strictPort: false,
    allowedHosts: true,
  },
  preview: {
    host: true,
    port: 4173,
    allowedHosts: true,
  },
})
