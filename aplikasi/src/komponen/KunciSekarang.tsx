import { Tombol } from './Tombol'
import { Lencana } from './Lencana'

export interface KunciSekarangProps {
  onKunci: () => void
  dalamPeringatan?: boolean
  sisaDetik?: number
  onBatalkanPeringatan?: () => void
}

export function KunciSekarang({
  onKunci,
  dalamPeringatan = false,
  sisaDetik = 0,
  onBatalkanPeringatan,
}: KunciSekarangProps) {
  return (
    <div className="bar-kunci flex items-center gap-2">
      {dalamPeringatan && (
        <div
          role="alert"
          className="peringatan-kunci flex items-center gap-2 px-3 py-1 bg-amber-100 text-amber-800 rounded border border-amber-300 animate-pulse"
        >
          <span className="text-sm">
            Sesi akan terkunci dalam <strong>{sisaDetik} detik</strong> karena tidak ada aktivitas.
          </span>
          {onBatalkanPeringatan && (
            <Tombol ragam="biasa" onClick={onBatalkanPeringatan}>
              Saya Masih di Sini
            </Tombol>
          )}
        </div>
      )}

      <Tombol ragam="biasa" onClick={onKunci}>
        <span className="flex items-center gap-1.5">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
          <span>Kunci Sekarang</span>
          {dalamPeringatan && <Lencana nada="warn">{sisaDetik}d</Lencana>}
        </span>
      </Tombol>
    </div>
  )
}
