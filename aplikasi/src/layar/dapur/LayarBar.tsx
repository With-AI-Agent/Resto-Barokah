/**
 * LayarBar (T4-02) — papan antrean minuman (bagian bar).
 *
 * Dipisah otomatis dari pesanan yang sama berdasarkan `pesanan_item.tujuan`
 * (salinan dari kategori menu — lihat migrasi 0033). Satu pesanan boleh muncul
 * di dua layar, masing-masing melihat bagiannya sendiri. Tata letak & keadaan
 * menyamai LayarDapur (kontrak DAFTAR_LAYAR.dapur).
 */
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KartuPesanan, type TiketPesanan } from './KartuPesanan'
import { urutFifo, saringBagian, type KeadaanPapan } from './LayarDapur'

export function LayarBar({
  tiket,
  waktuSekarang,
  keadaan = 'siap',
  ambangMenit = [10, 20],
  modeTv = false,
  antreanCadangan,
  onMulaiMasak,
  onSelesaiMasak,
  onCoba,
  onKeDapur,
}: {
  tiket: TiketPesanan[]
  waktuSekarang: string
  keadaan?: KeadaanPapan
  ambangMenit?: readonly [number, number]
  modeTv?: boolean
  antreanCadangan?: TiketPesanan[]
  onMulaiMasak?: (itemId: string) => void
  onSelesaiMasak?: (itemId: string) => void
  onCoba?: () => void
  onKeDapur?: () => void
}) {
  const tertunda = keadaan === 'sebagian'
  const sumber = keadaan === 'gagal' || tertunda ? antreanCadangan ?? [] : tiket
  const papan = urutFifo(saringBagian(sumber, 'bar'))

  return (
    <section
      data-testid="layar-bar"
      data-mode-tv={modeTv ? 'ya' : 'tidak'}
      data-tertunda={tertunda || keadaan === 'gagal' ? 'ya' : 'tidak'}
      style={{
        display: 'grid',
        gap: modeTv ? 'var(--s-5)' : 'var(--s-4)',
        padding: 'var(--s-3)',
        fontSize: modeTv ? 'var(--t-5)' : 'var(--t-3)',
      }}
    >
      <header style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)', flexWrap: 'wrap' }}>
        <h2 style={{ margin: 0, fontSize: 'var(--t-6)' }}>Antrean Bar</h2>
        {tertunda ? <Lencana nada="warn">Tertunda — menampilkan antrean tersimpan</Lencana> : null}
        {keadaan === 'gagal' ? <Lencana nada="danger">Koneksi terputus</Lencana> : null}
        {onKeDapur ? (
          <Tombol ragam="biasa" onClick={onKeDapur}>
            <span data-testid="ke-dapur">Ke Layar Dapur</span>
          </Tombol>
        ) : null}
      </header>

      {keadaan === 'memuat' ? <KeadaanMemuat judul="Memuat antrean pesanan bar..." /> : null}

      {keadaan === 'gagal' && papan.length === 0 ? (
        <KeadaanGagal
          judul="Gagal memuat antrean"
          keterangan="Periksa sambungan. Antrean tersimpan di perangkat akan tampil bila ada."
          onCoba={onCoba}
        />
      ) : null}

      {(keadaan === 'siap' || keadaan === 'sebagian' || (keadaan === 'gagal' && papan.length > 0)) &&
      papan.length === 0 ? (
        <KeadaanKosong
          judul="Belum ada pesanan minuman."
          keterangan="Bagian bar dari pesanan kasir akan muncul di sini."
        />
      ) : null}

      <div
        data-testid="papan-antrean"
        style={{
          display: 'grid',
          gridTemplateColumns: modeTv ? 'repeat(auto-fill, minmax(28rem, 1fr))' : 'repeat(auto-fill, minmax(18rem, 1fr))',
          gap: modeTv ? 'var(--s-5)' : 'var(--s-3)',
        }}
      >
        {papan.map((t) => (
          <div key={t.id} data-testid={`kartu-${t.id}`}>
            <KartuPesanan
              tiket={t}
              bagian="bar"
              waktuSekarang={waktuSekarang}
              ambangMenit={ambangMenit}
              onMulaiMasak={onMulaiMasak}
              onSelesaiMasak={onSelesaiMasak}
            />
          </div>
        ))}
      </div>
    </section>
  )
}
