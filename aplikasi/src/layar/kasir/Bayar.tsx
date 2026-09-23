/**
 * Bayar.tsx (T5-01) — layar pembayaran kasir: metode + uang diterima.
 *
 * Komponen ini MURNI: tidak ada jaringan di dalamnya. Kabel datanya di
 * `src/hook/useBayar.ts` (metode aktif dari `metode_bayar`, pencatatan uang lewat
 * RPC `bayar_pesanan` — migrasi 0039).
 *
 * Aturan yang dipegang (DoD T5-01 + DECISIONS_LOG [Fase 5/2026-09-23]):
 *  - Metode bayar datang dari peladen dan HANYA yang aktif; layar tidak punya
 *    daftar metode bawaan sendiri (dulu `LayarKasir` mengeras-kodekan
 *    'tunai' | 'qris' | 'kartu' — itu yang diganti di sini).
 *  - Tombol uang cepat: Uang pas / 50rb / 100rb (PRD M6).
 *  - **Kembalian yang ditampilkan sebelum konfirmasi adalah PERKIRAAN** untuk
 *    membantu mata kasir. Angka SAH adalah `kembalian` dari balasan peladen, dan
 *    layar menampilkannya besar setelah pembayaran tercatat.
 *  - Konfirmasi nilai sebelum dieksekusi + tombol batal yang mudah (mitigasi
 *    risiko T5-01: salah tekan nominal).
 *  - Pembayaran sebagian sah (split bill): bila masih ada sisa, layar menawarkan
 *    "Bayar sisa" — pesanan belum lunas sampai total tertutup.
 */
import { useMemo, useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lapis } from '../../komponen/Lapis'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { rupiah } from '../../lib/format'

export interface MetodeBayar {
  id: string
  nama: string
  jenis: 'tunai' | 'non_tunai'
  butuhReferensi: boolean
  urutan: number
}

export interface Tagihan {
  id: string
  nomor: number
  /** Total pesanan dari peladen (`hitung_total`) — layar tidak menghitung ulang. */
  total: number
  /** Uang yang sudah tercatat masuk untuk tagihan ini. */
  sudahDibayar: number
}

/** Hasil pembayaran SAH dari peladen (dipetakan `useBayar`). */
export interface BarisTagihan {
  jumlah: number
  kembalian: number
  totalDibayar: number
  totalPesanan: number
  lunas: boolean
  dobel: boolean
  sisa: number
}

export interface HasilBayar {
  jumlah: number
  kembalian: number
  totalDibayar: number
  totalPesanan: number
  lunas: boolean
  dobel: boolean
}

/** Nominal cepat selain "uang pas" (PRD M6: 50rb/100rb/uang pas). */
export const UANG_CEPAH = [50_000, 100_000] as const

/** `Rp` besar untuk kembalian: kelas rancangan v3, tanpa warna keras di komponen. */
function KembalianBesar({ nilai }: { nilai: number }) {
  return (
    <div className="kembalian-besar" data-testid="kembalian">
      <span className="small muted">Kembalian</span>
      <strong className="kembalian-nilai">{rupiah(nilai)}</strong>
    </div>
  )
}

export function Bayar({
  tagihan,
  metode,
  keadaan = 'siap',
  pesan,
  terakhir,
  onBayar,
  onCoba,
  onLanjut,
  onBatal,
}: {
  tagihan: Tagihan
  metode: MetodeBayar[]
  keadaan?: 'memuat' | 'gagal' | 'siap' | 'mengirim' | 'berhasil'
  pesan?: string | null
  terakhir?: BarisTagihan | null
  onBayar?: (masukan: {
    metodeId: string
    jumlah: number
    diterima?: number | null
    referensi?: string | null
  }) => Promise<HasilBayar | null> | void
  onCoba?: () => void
  onLanjut?: () => void
  onBatal?: () => void
}) {
  const sisa = Math.max(0, tagihan.total - tagihan.sudahDibayar)
  const [metodeId, setMetodeId] = useState<string | null>(metode[0]?.id ?? null)
  const [diterima, setDiterima] = useState('')
  const [referensi, setReferensi] = useState('')
  const [konfirmasi, setKonfirmasi] = useState(false)
  const [galat, setGalat] = useState<string | null>(null)

  const terpilih = metode.find((m) => m.id === metodeId) ?? metode[0] ?? null
  const tunai = terpilih?.jenis === 'tunai'

  const nilaiDiterima = useMemo(() => {
    const hasil = Number(diterima.replace(/[^0-9]/g, ''))
    return Number.isFinite(hasil) ? hasil : 0
  }, [diterima])

  // Perkiraan untuk mata kasir saja — angka sah datang dari peladen.
  const perkiraanKembalian = tunai ? Math.max(0, nilaiDiterima - sisa) : 0
  const jumlahBayar = sisa

  const siapKirim =
    terpilih !== null &&
    jumlahBayar > 0 &&
    (!tunai || nilaiDiterima >= jumlahBayar) &&
    (!terpilih.butuhReferensi || referensi.trim().length > 0)

  function pilihMetode(id: string) {
    setMetodeId(id)
    setGalat(null)
  }

  async function eksekusi() {
    setKonfirmasi(false)
    setGalat(null)
    if (!terpilih) return
    const hasil = await onBayar?.({
      metodeId: terpilih.id,
      jumlah: jumlahBayar,
      diterima: tunai ? nilaiDiterima : null,
      referensi: terpilih.butuhReferensi ? referensi.trim() : null,
    })
    if (!hasil) {
      // Pesan galat asli ditampilkan oleh `pesan` dari kontainer; di sini cukup
      // penanda lokal supaya fokus kasir kembali ke form.
      setGalat('Pembayaran belum tercatat. Periksa pesan di bawah lalu coba lagi.')
      return
    }
    setDiterima('')
    setReferensi('')
  }

  if (keadaan === 'memuat') {
    return <KeadaanMemuat judul="Memuat metode pembayaran..." />
  }

  if (keadaan === 'gagal') {
    return (
      <KeadaanGagal
        judul="Gagal memuat metode pembayaran"
        keterangan={pesan ?? 'Periksa sambungan internet lalu coba lagi.'}
        onCoba={onCoba}
      />
    )
  }

  if (keadaan === 'berhasil' && terakhir) {
    return (
      <Kartu judul={terakhir.lunas ? 'Pembayaran lunas' : 'Pembayaran tercatat'}>
        <div className="stack">
          {terakhir.dobel ? (
            <Lencana nada="warn">Kunci idempoten sama — pembayaran tidak dicatat dua kali</Lencana>
          ) : null}
          <p>
            Uang masuk <strong>{rupiah(terakhir.jumlah)}</strong> · total dibayar{' '}
            {rupiah(terakhir.totalDibayar)} dari {rupiah(terakhir.totalPesanan)}
          </p>
          <KembalianBesar nilai={terakhir.kembalian} />
          {terakhir.lunas ? (
            <Lencana nada="success">Tagihan No. {tagihan.nomor} lunas</Lencana>
          ) : (
            <Lencana nada="info">Sisa tagihan {rupiah(terakhir.sisa)}</Lencana>
          )}
          <div className="baris-aksi">
            {terakhir.lunas ? null : (
              <Tombol ragam="utama" onClick={onLanjut}>
                Bayar sisa {rupiah(terakhir.sisa)}
              </Tombol>
            )}
            <Tombol ragam="biasa" onClick={onLanjut}>
              {terakhir.lunas ? 'Selesai' : 'Tutup'}
            </Tombol>
          </div>
        </div>
      </Kartu>
    )
  }

  if (metode.length === 0) {
    return (
      <KeadaanKosong
        judul="Belum ada metode bayar aktif"
        keterangan="Aktifkan minimal satu metode bayar di Pengaturan sebelum kasir menerima uang."
      />
    )
  }

  return (
    <>
      <Kartu judul={`Bayar tagihan No. ${tagihan.nomor}`}>
        <div className="stack">
          <div className="baris-tagihan">
            <span className="small muted">Total tagihan</span>
            <strong>{rupiah(tagihan.total)}</strong>
          </div>
          {tagihan.sudahDibayar > 0 ? (
            <div className="baris-tagihan">
              <span className="small muted">Sudah dibayar</span>
              <span>{rupiah(tagihan.sudahDibayar)}</span>
            </div>
          ) : null}
          <div className="baris-tagihan" data-testid="sisa-tagihan">
            <span className="small muted">Yang harus dibayar</span>
            <strong>{rupiah(sisa)}</strong>
          </div>

          <fieldset className="metode-bayar">
            <legend className="label">Metode pembayaran</legend>
            <div className="baris-aksi">
              {metode.map((m) => (
                <span key={m.id} data-testid={`metode-${m.nama}`} data-jenis={m.jenis}>
                  <Tombol
                    ragam={m.id === terpilih?.id ? 'utama' : 'biasa'}
                    onClick={() => pilihMetode(m.id)}
                  >
                    {m.nama}
                  </Tombol>
                </span>
              ))}
            </div>
          </fieldset>

          {tunai ? (
            <>
              <KolomIsian
                label="Uang diterima"
                nilai={diterima}
                onUbah={setDiterima}
                jenis="number"
                wajib
                keterangan="Kembalian dihitung peladen; angka di bawah hanya perkiraan."
                galat={
                  nilaiDiterima > 0 && nilaiDiterima < sisa
                    ? `Uang diterima kurang ${rupiah(sisa - nilaiDiterima)}.`
                    : undefined
                }
              />
              <div className="baris-aksi">
                <Tombol ragam="kecil" onClick={() => setDiterima(String(sisa))}>
                  Uang pas
                </Tombol>
                {UANG_CEPAH.map((nominal) => (
                  <Tombol key={nominal} ragam="kecil" onClick={() => setDiterima(String(nominal))}>
                    {rupiah(nominal)}
                  </Tombol>
                ))}
              </div>
              <KembalianBesar nilai={perkiraanKembalian} />
            </>
          ) : (
            <KolomIsian
              label="Nomor referensi"
              nilai={referensi}
              onUbah={setReferensi}
              wajib={terpilih?.butuhReferensi}
              keterangan="Nomor bukti transfer/QRIS — disimpan apa adanya di jejak pembayaran."
            />
          )}

          {galat ? (
            <p className="small" role="alert">
              {galat}
            </p>
          ) : null}
          {pesan ? (
            <p className="small" role="alert">
              {pesan}
            </p>
          ) : null}

          <div className="baris-aksi">
            <span data-testid="tinjau">
              <Tombol ragam="utama" nonaktif={!siapKirim} onClick={() => setKonfirmasi(true)}>
                Tinjau pembayaran
              </Tombol>
            </span>
            <span data-testid="batal">
              <Tombol ragam="biasa" onClick={onBatal}>
                Batal
              </Tombol>
            </span>
          </div>
        </div>
      </Kartu>

      <Lapis
        buka={konfirmasi}
        judul="Periksa dulu sebelum dicatat"
        onTutup={() => setKonfirmasi(false)}
        kaki={
          <>
            <span data-testid="konfirmasi-bayar">
              <Tombol
                ragam="utama"
                nonaktif={keadaan === 'mengirim'}
                onClick={() => void eksekusi()}
              >
                {keadaan === 'mengirim' ? 'Mencatat...' : 'Ya, catat pembayaran'}
              </Tombol>
            </span>
            <Tombol ragam="biasa" onClick={() => setKonfirmasi(false)}>
              Periksa lagi
            </Tombol>
          </>
        }
      >
        <div className="stack">
          <div className="baris-tagihan">
            <span className="small muted">Metode</span>
            <strong>{terpilih?.nama}</strong>
          </div>
          <div className="baris-tagihan">
            <span className="small muted">Jumlah dicatat</span>
            <strong>{rupiah(jumlahBayar)}</strong>
          </div>
          {tunai ? (
            <>
              <div className="baris-tagihan">
                <span className="small muted">Uang diterima</span>
                <span>{rupiah(nilaiDiterima)}</span>
              </div>
              <KembalianBesar nilai={perkiraanKembalian} />
              <p className="small muted">
                Kembalian di atas perkiraan layar. Angka sah dihitung peladen dan tampil sesudah
                pembayaran tercatat.
              </p>
            </>
          ) : (
            <div className="baris-tagihan">
              <span className="small muted">Referensi</span>
              <span>{referensi.trim() || '—'}</span>
            </div>
          )}
          {sisa < tagihan.total ? (
            <p className="small muted">
              Ini pembayaran sebagian: sesudah ini sisa tagihan {rupiah(sisa)} belum lunas.
            </p>
          ) : null}
        </div>
      </Lapis>
    </>
  )
}
