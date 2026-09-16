import { Kartu, Lencana, Tombol } from '../../komponen/Toko'
import { rupiah, jamLokal, tanggalLokal } from '../../lib/format'
import { KERAPATAN, TEMA, type KodeTema, type Kerapatan } from '../../lib/tema'
import { useJam } from '../../hook/useJam'
import { useTema } from '../../hook/useTema'

/**
 * Layar bukti Fase 0 (bukan layar produksi).
 * Membuktikan: 10 tema + 2 kerapatan bisa diganti tanpa memuat ulang halaman,
 * token desain v3 hidup di aplikasi, dan komponen dasar tampil sesuai rancangan.
 * Halaman ini diganti layar sungguhan mulai Fase 2.
 */
export default function LayarContoh() {
  const sekarang = useJam()
  const { tema, kerapatan, gantiTema, gantiKerapatan } = useTema()
  const temaAktif = TEMA.find((butir) => butir.kode === tema) ?? TEMA[0]

  return (
    <div className="halaman">
      <header className="kepala-halaman">
        <p className="label">Contoh tampilan · Fase 0</p>
        <h1>Sajian</h1>
        <p className="aksen">Kasir, dapur, laporan, dan pelanggan dalam satu tempat.</p>
        <p className="small muted">
          Sekarang {jamLokal(sekarang)} · {tanggalLokal(sekarang)} · tema aktif{' '}
          <strong>{temaAktif.nama}</strong>
        </p>
      </header>

      <div className="row wrap-row">
        <details className="picker">
          <summary className="btn btn-sm">Ganti tema ({TEMA.length})</summary>
          <div className="picker-panel">
            {TEMA.map((butir) => (
              <button
                key={butir.kode}
                type="button"
                aria-pressed={butir.kode === tema}
                onClick={() => gantiTema(butir.kode as KodeTema)}
                className="tombol-tema"
              >
                <span className="tanda" aria-hidden="true" />
                <span>
                  <strong>{butir.nama}</strong>
                  <small>{butir.keterangan}</small>
                </span>
              </button>
            ))}
          </div>
        </details>

        <div className="segmen" role="group" aria-label="Kerapatan tampilan">
          {KERAPATAN.map((butir) => (
            <button
              key={butir.kode}
              type="button"
              aria-pressed={butir.kode === kerapatan}
              onClick={() => gantiKerapatan(butir.kode as Kerapatan)}
            >
              {butir.nama}
            </button>
          ))}
        </div>
      </div>

      <div className="kisi-2">
        <Kartu>
          <div className="between">
            <div>
              <p className="label">Total belanja</p>
              <p className="angka-besar">{rupiah(27500)}</p>
            </div>
            <Lencana nada="warn">Belum dibayar</Lencana>
          </div>
          <hr className="pemisah" />
          <div className="baris-tombol">
            <Tombol>Simpan pesanan</Tombol>
            <Tombol ragam="biasa">Tahan</Tombol>
            <Tombol ragam="kecil" nonaktif>
              Nanti
            </Tombol>
          </div>
        </Kartu>

        <Kartu>
          <p className="label">Contoh pesanan</p>
          <div className="between">
            <div>
              <p>
                <strong>2 × Nasi Goreng Kampung</strong>
              </p>
              <p className="small muted">Pedas sedang · tambah telur</p>
            </div>
            <p className="mono">{rupiah(55000)}</p>
          </div>
          <hr className="pemisah" />
          <div className="row wrap-row">
            <Lencana nada="success">Lunas</Lencana>
            <Lencana nada="info">Dibungkus</Lencana>
            <Lencana nada="danger">Dibatalkan</Lencana>
          </div>
        </Kartu>
      </div>

      <Kartu>
        <p className="label">Huruf tema</p>
        <div className="contoh-huruf">
          <div>
            <span className="nama-huruf huruf-outfit">Outfit</span>
            <span className="small muted">huruf judul, tegas dan bersih</span>
          </div>
          <div>
            <span className="nama-huruf huruf-bigshoulders">Big Shoulders</span>
            <span className="small muted">huruf judul tema Bara</span>
          </div>
          <div>
            <span className="nama-huruf huruf-youngserif">Young Serif</span>
            <span className="small muted">huruf judul tema Vintage</span>
          </div>
          <div>
            <span className="nama-huruf huruf-bricolage">Bricolage</span>
            <span className="small muted">huruf judul tema Etnik</span>
          </div>
        </div>
      </Kartu>
    </div>
  )
}
