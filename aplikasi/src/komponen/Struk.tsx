/**
 * Struk.tsx (T5-03) — rincian tagihan dengan pajak & service TERPISAH.
 *
 * Aturan yang mengikat komponen ini (DoD T5-03 + TECH_SPEC §9 ART-3):
 *
 *  1. **Struk tidak pernah menghitung uang.** Semua angka (subtotal, diskon,
 *     PB1, service, total) datang dari peladen — `hitung_total()` yang menulis
 *     kolom-kolom itu di baris `pesanan`. Kalau layar menghitung sendiri
 *     (mis. `subtotal * 0.1`), ia akan berbeda dari uang yang benar-benar
 *     tercatat begitu ada diskon atau pembulatan, dan resto mencetak struk yang
 *     tidak cocok dengan kasnya. Padanan buktinya: `supabase/tes/pajak_service.sql`.
 *
 *  2. **Baris "Pembulatan" adalah SELISIH, bukan angka baru.** Peladen
 *     membulatkan TOTAL ke bawah mengikuti pengaturan resto (none/100/500/1000),
 *     sementara baris pajak & service tidak ikut berubah. Supaya rincian di
 *     kertas tetap menjumlah persis ke total, selisihnya dicetak terbuka —
 *     bukan disembunyikan, karena pelanggan berhak tahu.
 *
 *  3. **Pajak/service 0 % tetap punya barisnya.** Resto yang belum kena PB1
 *     harus terlihat memang tidak memungut, bukan seolah menyembunyikan baris.
 *
 * Komponen ini MURNI: tidak ada jaringan, tidak ada jam perangkat yang dipakai
 * untuk keputusan uang. Tata letaknya sengaja satu kolom sempit supaya cocok
 * untuk pratinjau layar maupun cetak termal 58/80 mm nanti.
 */
import { rupiah, tanggalLokal } from '../lib/format'

export interface ItemStruk {
  nama: string
  qty: number
  hargaSatuan: number
  subtotal: number
  catatan?: string
}

export interface PembayaranStruk {
  metode: string
  jumlah: number
  diterima?: number | null
  referensi?: string | null
}

/**
 * Angka uang pesanan SEBAGAIMANA DICATAT PELADEN. Nama medannya sengaja sama
 * dengan kolom tabel `pesanan` supaya tidak ada ruang untuk salah petakan.
 */
export interface DataStruk {
  nomor: number
  /** ISO dari peladen — bukan `new Date()` di perangkat. */
  tanggal: string
  namaResto?: string
  header?: string
  footer?: string
  namaMeja?: string | null
  item: ItemStruk[]
  subtotal: number
  totalDiskon: number
  pajak: number
  service: number
  total: number
}

/**
 * Selisih pembulatan = total − (subtotal − diskon + pajak + service).
 *
 * Nilainya 0 bila resto tidak memakai pembulatan, dan NEGATIF bila total
 * dibulatkan ke bawah (pelanggan diuntungkan). Dicetak supaya rincian struk
 * selalu menjumlah persis ke total.
 */
export function selisihPembulatan(data: DataStruk): number {
  return data.total - (data.subtotal - data.totalDiskon + data.pajak + data.service)
}

/** Satu baris rincian: label di kiri, angka di kanan. */
function Baris({
  label,
  nilai,
  penanda,
  tebal = false,
}: {
  label: string
  nilai: string
  penanda: string
  tebal?: boolean
}) {
  return (
    <div className="struk-baris" data-testid={`struk-${penanda}`}>
      <span className={tebal ? 'struk-label struk-tebal' : 'struk-label'}>{label}</span>
      <span className={tebal ? 'struk-nilai struk-tebal' : 'struk-nilai'}>{nilai}</span>
    </div>
  )
}

export function Struk({
  data,
  pembayaran = [],
  kembalian = 0,
}: {
  data: DataStruk
  pembayaran?: PembayaranStruk[]
  /** Kembalian SAH dari peladen (balasan RPC `bayar_pesanan`). */
  kembalian?: number
}) {
  const pembulatan = selisihPembulatan(data)
  const totalDibayar = pembayaran.reduce((jumlah, bayar) => jumlah + bayar.jumlah, 0)
  const sisa = Math.max(0, data.total - totalDibayar)
  const sudahBayar = pembayaran.length > 0
  const lunas = sudahBayar && sisa === 0

  return (
    <article className="struk" data-testid="struk">
      <header className="struk-kepala">
        {data.header ? <p className="struk-header">{data.header}</p> : null}
        {data.namaResto ? <h2 className="struk-nama-resto">{data.namaResto}</h2> : null}
        <p className="small muted">
          No. {data.nomor} · {tanggalLokal(new Date(data.tanggal))}
          {data.namaMeja ? ` · ${data.namaMeja}` : ''}
        </p>
      </header>

      <div className="struk-item">
        {data.item.map((item, urutan) => (
          <div
            className="struk-baris-item"
            key={`${item.nama}-${urutan}`}
            data-testid={`struk-item-${urutan}`}
          >
            <span className="struk-item-nama">{item.nama}</span>
            <span className="small muted">
              {item.qty} × {rupiah(item.hargaSatuan)}
            </span>
            <span className="struk-nilai">{rupiah(item.subtotal)}</span>
            {item.catatan ? <span className="small muted">{item.catatan}</span> : null}
          </div>
        ))}
      </div>

      <div className="struk-rincian">
        <Baris label="Subtotal" nilai={rupiah(data.subtotal)} penanda="subtotal" />
        {/* Diskon hanya dicetak bila memang ada; strukyang ringkas lebih mudah dibaca. */}
        {data.totalDiskon > 0 ? (
          <Baris label="Diskon" nilai={`−${rupiah(data.totalDiskon)}`} penanda="diskon" />
        ) : null}
        {/* Pajak & service SELALU dicetak, termasuk saat 0 % (DoD T5-03). */}
        <Baris label="PB1 (pajak)" nilai={rupiah(data.pajak)} penanda="pajak" />
        <Baris label="Service" nilai={rupiah(data.service)} penanda="service" />
        {pembulatan !== 0 ? (
          <Baris
            label="Pembulatan"
            nilai={`${pembulatan < 0 ? '−' : '+'}${rupiah(Math.abs(pembulatan))}`}
            penanda="pembulatan"
          />
        ) : null}
        <Baris label="Total" nilai={rupiah(data.total)} penanda="total" tebal />
      </div>

      {sudahBayar ? (
        <div className="struk-bayar">
          {pembayaran.map((bayar, urutan) => (
            <Baris
              key={`${bayar.metode}-${urutan}`}
              label={bayar.referensi ? `${bayar.metode} (${bayar.referensi})` : bayar.metode}
              nilai={rupiah(bayar.jumlah)}
              penanda={`bayar-${urutan}`}
            />
          ))}
          {/* Kembalian = angka peladen, bukan (diterima − total) versi layar. */}
          <Baris label="Kembalian" nilai={rupiah(kembalian)} penanda="kembalian" />
          {lunas ? (
            <p className="struk-lunas" data-testid="struk-lunas">
              LUNAS
            </p>
          ) : (
            <Baris label="Sisa tagihan" nilai={rupiah(sisa)} penanda="sisa" />
          )}
        </div>
      ) : null}

      {data.footer ? <footer className="struk-kaki">{data.footer}</footer> : null}
    </article>
  )
}
