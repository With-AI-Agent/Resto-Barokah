import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import { pasangTemaAwal } from './lib/tema'
import './gaya/token/tema.css'
import './gaya/token/dasar.css'
import './gaya/komponen.css'
import './gaya/arah.css'

// tema & kerapatan dipasang sebelum render supaya tidak ada kedipan warna
pasangTemaAwal()

// Daftarkan service worker PWA jika didukung
if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Abaikan jika service worker gagal mendaftar di lingkungan dev/tes
    })
  })
}

const wadah = document.getElementById('root')
if (!wadah) throw new Error('Elemen #root tidak ditemukan di index.html')

createRoot(wadah).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
