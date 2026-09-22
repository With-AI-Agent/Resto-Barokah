/**
 * LayarDapur (T4-01, T4-10) — papan antrean masakan (bagian dapur).
 *
 * T4-01: tiket makanan urut FIFO TERTUA DI ATAS, diurutkan dari `dikirimPada`
 * (waktu kirim MENURUT PELADEN — bukan waktu terima di klien), tampilan besar
 * terbaca dari jauh, lebar jaringan untuk penyegaran realtime dihubungkan
 * lewat pembaruan `tiket` dari kontainer (komponen murni tanpa jaringan).
 * T4-10: keadaan kosong/muat/gagal ramah; saat jaringan putus tampil antrean
 * cadangan dari perangkat + tanda "Tertunda" (sumber kebenaran tetap peladen);
 * `modeTv` membesarkan jarak & huruf untuk TV/monitor dapur. Tanpa animasi
 * (menghormati "kurangi gerak").
 */
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KartuPesanan, type TiketPesanan } from './KartuPesanan'
import { TombolHabis } from './TombolHabis'

export type KeadaanPapan = 'memuat' | 'gagal' | 'siap' | 'sebagian'

/** Urut FIFO: tertua (dikirimPada) di kiri/atas — sumber waktu = peladen. */
export function urutFifo(tiket: TiketPesanan[]): TiketPesanan[] {
  return [...tiket].sort((a, b) => a.dikirimPada.localeCompare(b.dikirimPada))
}

/** Hanya tiket yang punya bagian diminta (item batal tidak dihitung). */
export function saringBagian(tiket: TiketPesanan[], bagian: 'dapur' | 'bar'): TiketPesanan[] {
  return tiket.filter((t) => t.items.some((i) => i.tujuan === bagian && i.status !== 'batal'))
}

export function LayarDapur({
  tiket,
  waktuSekarang,
  keadaan = 'siap',
  ambangMenit = [10, 20],
  modeTv = false,
  antreanCadangan,
  onMulaiMasak,
  onSelesaiMasak,
  onTandaiHabis,
  onCoba,
  onKeBar,
}: {
  tiket: TiketPesanan[]
  waktuSekarang: string
  keadaan?: KeadaanPapan
  ambangMenit?: readonly [number, number]
  modeTv?: boolean
  antreanCadangan?: TiketPesanan[]
  onMulaiMasak?: (itemId: string) => void
  onSelesaiMasak?: (itemId: string) => void
  onTandaiHabis?: (menuItemId: string, namaMenu: string) => void
  onCoba?: () => void
  onKeBar?: () => void
}) {
  const tertunda = keadaan === 'sebagian'
  const sumber = keadaan === 'gagal' || tertunda ? antreanCadangan ?? [] : tiket
  const papan = urutFifo(saringBagian(sumber, 'dapur'))

  const menuHabis = new Map<string, string>()
  for (const t of papan) {
    for (const i of t.items) {
      if (i.tujuan === 'dapur' && i.status !== 'batal') menuHabis.set(i.menuItemId, i.namaSaatItu)
    }
  }

  return (
    <section
      data-testid="layar-dapur"
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
        <h2 style={{ margin: 0, fontSize: 'var(--t-6)' }}>Antrean Dapur</h2>
        {tertunda ? <Lencana nada="warn">Tertunda — menampilkan antrean tersimpan</Lencana> : null}
        {keadaan === 'gagal' ? <Lencana nada="danger">Koneksi terputus</Lencana> : null}
        {onKeBar ? (
          <Tombol ragam="biasa" onClick={onKeBar}>
            <span data-testid="ke-bar">Ke Layar Bar</span>
          </Tombol>
        ) : null}
      </header>

      {keadaan === 'memuat' ? <KeadaanMemuat judul="Memuat antrean pesanan dapur..." /> : null}

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
          judul="Tidak ada antrean pesanan yang perlu dimasak."
          keterangan="Tiket baru akan muncul di sini begitu kasir mengirim ke dapur."
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
              bagian="dapur"
              waktuSekarang={waktuSekarang}
              ambangMenit={ambangMenit}
              onMulaiMasak={onMulaiMasak}
              onSelesaiMasak={onSelesaiMasak}
            />
            {onTandaiHabis ? (
              <div style={{ marginTop: 'var(--s-2)', display: 'grid', gap: 'var(--s-2)' }}>
                {[...menuHabis.entries()]
                  .filter(([menuId]) =>
                    t.items.some((i) => i.menuItemId === menuId && i.tujuan === 'dapur'),
                  )
                  .map(([menuId, nama]) => (
                    <TombolHabis
                      key={menuId}
                      namaMenu={nama}
                      onTandai={() => onTandaiHabis(menuId, nama)}
                    />
                  ))}
              </div>
            ) : null}
          </div>
        ))}
      </div>
    </section>
  )
}
