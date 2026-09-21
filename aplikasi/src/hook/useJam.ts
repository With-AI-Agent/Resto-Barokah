import { useEffect, useState } from 'react'

/** Jam berdenyut tiap detik (untuk header/layar dapur). */
export function useJam(selangMs = 1000): Date {
  const [sekarang, setSekarang] = useState(() => new Date())

  useEffect(() => {
    const id = window.setInterval(() => setSekarang(new Date()), selangMs)
    return () => window.clearInterval(id)
  }, [selangMs])

  return sekarang
}
