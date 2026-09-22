/**
 * KartuPesanan (T4-03 + T4-08) — kartu tiket untuk layar dapur/bar.
 *
 * T4-03: jenis pesanan (dine-in / bawa pulang / ojol) tegas dengan lencana warna
 * dan label; catatan khusus tampil BESAR; nomor meja jelas.
 * T4-08: penanda waktu tunggu berubah setelah ambang (bawaan 10 & 20 menit) yang
 * bisa diatur; umur dihitung dari WAKTU PELADEN (`dikirimPada` vs `waktuSekarang`
 * yang disuntik peladen) — bukan jam perangkat, supaya jam yang salah tidak
 * memblokir atau menyesatkan layar. Tidak ada animasi/kedipan (menghormati
 * pengaturan "kurangi gerak") — cukup perubahan warna lencana.
 *
 * Catatan warna: semua lewat kelas token (`chip-*`, `var(--*)`) — tanpa warna
 * mentah (periksa-struktur memindai berkas ini).
 */
import { Kartu } from '../../komponen/Kartu'
import { Lencana, type NadaLencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'

export type TipePesananKartu = 'dinein' | 'bawa_pulang' | 'ojol'
export type StatusItemMasak = 'baru' | 'dimasak' | 'siap' | 'batal'

export interface ItemKartuPesanan {
  id: string
  menuItemId: string
  namaSaatItu: string
  qty: number
  catatan: string | null
  status: StatusItemMasak
  tujuan: 'dapur' | 'bar'
}

export interface TiketPesanan {
  id: string
  nomor: number
  tipe: TipePesananKartu
  meja: string | null
  /** Waktu kirim ke dapur menurut PELADEN (ISO) — sumber urutan FIFO. */
  dikirimPada: string
  items: ItemKartuPesanan[]
}

const LABEL_TIPE: Record<TipePesananKartu, string> = {
  dinein: 'Dine-in',
  bawa_pulang: 'Bawa Pulang',
  ojol: 'Ojol',
}

const NADA_TIPE: Record<TipePesananKartu, NadaLencana> = {
  dinein: 'info',
  bawa_pulang: 'accent',
  ojol: 'warn',
}

const LABEL_STATUS: Record<StatusItemMasak, { teks: string; nada: NadaLencana }> = {
  baru: { teks: 'Menunggu', nada: 'netral' },
  dimasak: { teks: 'Dimasak', nada: 'warn' },
  siap: { teks: 'Siap', nada: 'success' },
  batal: { teks: 'Batal', nada: 'danger' },
}

/** Umur tiket dalam menit penuh — memakai waktu peladen yang disuntik, bukan jam perangkat. */
export function umurMenit(dikirimPada: string, waktuSekarang: string): number {
  const awal = new Date(dikirimPada).getTime()
  const akhir = new Date(waktuSekarang).getTime()
  if (Number.isNaN(awal) || Number.isNaN(akhir) || akhir < awal) return 0
  return Math.floor((akhir - awal) / 60_000)
}

export type TingkatWaktu = 'biasa' | 'waspada' | 'mendesak'

/** Tingkat keterlambatan: [ambang waspada, ambang mendesak], menit. */
export function tingkatWaktu(umur: number, ambang: readonly [number, number] = [10, 20]): TingkatWaktu {
  if (umur >= ambang[1]) return 'mendesak'
  if (umur >= ambang[0]) return 'waspada'
  return 'biasa'
}

function nadaWaktu(tingkat: TingkatWaktu): NadaLencana {
  if (tingkat === 'mendesak') return 'danger'
  if (tingkat === 'waspada') return 'warn'
  return 'netral'
}

export function KartuPesanan({
  tiket,
  waktuSekarang,
  ambangMenit = [10, 20],
  bagian = 'dapur',
  onMulaiMasak,
  onSelesaiMasak,
}: {
  tiket: TiketPesanan
  waktuSekarang: string
  ambangMenit?: readonly [number, number]
  bagian?: 'dapur' | 'bar'
  onMulaiMasak?: (itemId: string) => void
  onSelesaiMasak?: (itemId: string) => void
}) {
  const items = tiket.items.filter((i) => i.tujuan === bagian && i.status !== 'batal')
  const umur = umurMenit(tiket.dikirimPada, waktuSekarang)
  const tingkat = tingkatWaktu(umur, ambangMenit)

  return (
    <Kartu judul={`No. ${tiket.nomor}`} aksi={<Lencana nada={NADA_TIPE[tiket.tipe]}>{LABEL_TIPE[tiket.tipe]}</Lencana>}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)', marginBottom: 'var(--s-3)' }}>
        {tiket.tipe === 'dinein' && tiket.meja ? (
          <span
            data-testid="meja-kartu"
            style={{ fontSize: 'var(--t-5)', fontWeight: 700, color: 'var(--teks-utama)' }}
          >
            Meja {tiket.meja}
          </span>
        ) : null}
        <span data-testid="penanda-waktu" data-tingkat={tingkat}>
          <Lencana nada={nadaWaktu(tingkat)}>{umur} menit</Lencana>
        </span>
      </div>

      <ul style={{ listStyle: 'none', margin: 0, padding: 0, display: 'grid', gap: 'var(--s-3)' }}>
        {items.map((item) => (
          <li key={item.id} data-testid={`baris-item-${item.id}`} style={{ borderTop: '1px solid var(--b-netral)', paddingTop: 'var(--s-2)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 'var(--s-2)' }}>
              <span style={{ fontSize: 'var(--t-4)', fontWeight: 700 }}>
                {item.qty} × {item.namaSaatItu}
              </span>
              <Lencana nada={LABEL_STATUS[item.status].nada}>{LABEL_STATUS[item.status].teks}</Lencana>
            </div>
            {item.catatan ? (
              <p
                data-testid={`catatan-item-${item.id}`}
                style={{
                  margin: 'var(--s-2) 0 0',
                  fontSize: 'var(--t-4)',
                  fontWeight: 700,
                  color: 'var(--teks-utama)',
                  background: 'var(--latar-utama)',
                  borderInlineStart: '4px solid var(--warna-aksen)',
                  padding: 'var(--s-2)',
                }}
              >
                ⚠ {item.catatan}
              </p>
            ) : null}
            {item.status === 'baru' && onMulaiMasak ? (
              <div style={{ marginTop: 'var(--s-2)' }}>
                <Tombol ragam="utama" lebar onClick={() => onMulaiMasak(item.id)}>
                  <span data-testid={`mulai-${item.id}`}>Mulai Masak</span>
                </Tombol>
              </div>
            ) : null}
            {item.status === 'dimasak' && onSelesaiMasak ? (
              <div style={{ marginTop: 'var(--s-2)' }}>
                <Tombol ragam="biasa" lebar onClick={() => onSelesaiMasak(item.id)}>
                  <span data-testid={`siap-${item.id}`}>Siap Saji</span>
                </Tombol>
              </div>
            ) : null}
          </li>
        ))}
      </ul>
    </Kartu>
  )
}
