const CACHE_NAME = 'sajian-pwa-v1'
const BERKAS_STATIS = [
  '/',
  '/index.html',
  '/manifest.webmanifest',
  '/favicon.svg',
  '/logo-google.svg',
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(BERKAS_STATIS).catch(() => {
        // Fallback jika ada berkas yang belum siap saat install
      })
    })
  )
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key)
          }
        })
      )
    })
  )
  self.clients.claim()
})

self.addEventListener('fetch', (event) => {
  // Hanya tangani permintaan GET HTTP/HTTPS
  if (event.request.method !== 'GET' || !event.request.url.startsWith('http')) {
    return
  }

  event.respondWith(
    fetch(event.request)
      .then((networkResponse) => {
        // Simpan ke cache jika sukses
        if (networkResponse.ok && event.request.url.startsWith(self.location.origin)) {
          const klon = networkResponse.clone()
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, klon))
        }
        return networkResponse
      })
      .catch(() => {
        // Jika offline, ambil dari cache
        return caches.match(event.request).then((cachedResponse) => {
          if (cachedResponse) return cachedResponse
          if (event.request.mode === 'navigate') {
            return caches.match('/index.html')
          }
          return new Response('Offline - Jaringan terputus', {
            status: 503,
            headers: { 'Content-Type': 'text/plain; charset=utf-8' },
          })
        })
      })
  )
})
