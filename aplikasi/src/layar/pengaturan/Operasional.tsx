/* eslint-disable react-refresh/only-export-components */
/**
 * Operasional.tsx — Pengaturan Operasional Resto (T9-03 / PRD M2 & M6 / TECH_SPEC §9 ART-3)
 *
 * Mengizinkan Owner Resto (atau staf dengan izin atur_pengaturan) untuk:
 *  1. Mengatur persentase Pajak PB1 (0–100%) & Service Charge (0–100%).
 *  2. Mengatur pembulatan total transaksi (none, 100, 500, 1000).
 *  3. Memilih alur pemesanan (kasir, mandiri, meja, campur).
 *  4. Mengatur jam buka operasional resto.
 *  5. Menyesuaikan header & footer cetakan struk kasir.
 *  6. Mengatur kebijakan tumpuk diskon.
 *  7. Melihat simulasi kalkulasi finansial & pratinjau struk kasir secara real-time.
 */

import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'

export type PembulatanPilihan = 'none' | '100' | '500' | '1000'
export type CaraPesanPilihan = 'kasir' | 'mandiri' | 'meja' | 'campur'

export interface DataOperasional {
  pajak_pb1_persen: number
  service_persen: number
  pembulatan: PembulatanPilihan
  cara_pesan: CaraPesanPilihan
  jam_buka: string
  header_struk: string
  footer_struk: string
  tumpuk_diskon?: boolean
  versi_pengaturan?: string | null
}

export interface OperasionalProps {
  dataAwal?: Partial<DataOperasional>
  onSimpan?: (data: DataOperasional) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

export const DATA_OPERASIONAL_BAWAAN: DataOperasional = {
  pajak_pb1_persen: 10,
  service_persen: 5,
  pembulatan: 'none',
  cara_pesan: 'kasir',
  jam_buka: 'Senin - Minggu 08.00 - 22.00 WIB',
  header_struk: 'Terima kasih atas kunjungan Anda',
  footer_struk: 'Barang yang sudah dibeli tidak dapat ditukar',
  tumpuk_diskon: false,
  versi_pengaturan: null,
}

export const DAFTAR_CARA_PESAN: Array<{
  id: CaraPesanPilihan
  label: string
  keterangan: string
  ikon: string
}> = [
  {
    id: 'kasir',
    label: 'Dilayani Kasir',
    keterangan: 'Pelanggan memesan dan langsung membayar di meja kasir.',
    ikon: '💵',
  },
  {
    id: 'mandiri',
    label: 'Mandiri / Ambil Sendiri',
    keterangan: 'Pelanggan memesan lewat katalog mandiri atau QR meja.',
    ikon: '📱',
  },
  {
    id: 'meja',
    label: 'Pelayan di Meja',
    keterangan: 'Pelayan mendatangi meja mencatat pesanan dengan perangkat staf.',
    ikon: '🍽️',
  },
  {
    id: 'campur',
    label: 'Fleksibel / Campuran',
    keterangan: 'Kombinasi kasir langsung, pelayan di meja, dan pemesanan mandiri.',
    ikon: '🔄',
  },
]

export const DAFTAR_PEMBULATAN: Array<{
  id: PembulatanPilihan
  label: string
  keterangan: string
}> = [
  { id: 'none', label: 'Tanpa Pembulatan', keterangan: 'Nominal sesuai pecahan pas rupiah' },
  { id: '100', label: 'Ke Rp 100', keterangan: 'Dibulatkan ke kelipatan seratus rupiah' },
  { id: '500', label: 'Ke Rp 500', keterangan: 'Dibulatkan ke kelipatan lima ratus rupiah' },
  { id: '1000', label: 'Ke Rp 1.000', keterangan: 'Dibulatkan ke kelipatan seribu rupiah' },
]

/**
 * Hitung simulasi angka struk kasir sesuai rantai ART-3:
 * Subtotal -> Diskon -> PB1 -> Service -> Pembulatan -> Total
 */
export function hitungSimulasiStruk(
  subtotal: number,
  diskon: number,
  pajakPersen: number,
  servicePersen: number,
  pembulatan: PembulatanPilihan,
) {
  const dasar = Math.max(subtotal - diskon, 0)
  const nominalPajak = Math.round((dasar * Math.max(0, pajakPersen)) / 100)
  const nominalService = Math.round((dasar * Math.max(0, servicePersen)) / 100)
  let totalKotor = dasar + nominalPajak + nominalService

  const langkah = pembulatan === 'none' ? 0 : parseInt(pembulatan, 10)
  if (langkah > 0) {
    totalKotor = Math.floor(totalKotor / langkah) * langkah
  }

  return {
    subtotal,
    diskon,
    dasar,
    nominalPajak,
    nominalService,
    total: Math.max(0, totalKotor),
  }
}

export function Operasional({
  dataAwal,
  onSimpan,
  onKembali,
  hanyaBaca = false,
}: OperasionalProps) {
  const [data, setData] = useState<DataOperasional>({
    pajak_pb1_persen: dataAwal?.pajak_pb1_persen ?? DATA_OPERASIONAL_BAWAAN.pajak_pb1_persen,
    service_persen: dataAwal?.service_persen ?? DATA_OPERASIONAL_BAWAAN.service_persen,
    pembulatan: dataAwal?.pembulatan ?? DATA_OPERASIONAL_BAWAAN.pembulatan,
    cara_pesan: dataAwal?.cara_pesan ?? DATA_OPERASIONAL_BAWAAN.cara_pesan,
    jam_buka: dataAwal?.jam_buka ?? DATA_OPERASIONAL_BAWAAN.jam_buka,
    header_struk: dataAwal?.header_struk ?? DATA_OPERASIONAL_BAWAAN.header_struk,
    footer_struk: dataAwal?.footer_struk ?? DATA_OPERASIONAL_BAWAAN.footer_struk,
    tumpuk_diskon: dataAwal?.tumpuk_diskon ?? DATA_OPERASIONAL_BAWAAN.tumpuk_diskon,
    versi_pengaturan: dataAwal?.versi_pengaturan ?? DATA_OPERASIONAL_BAWAAN.versi_pengaturan,
  })

  const [pajakInput, setPajakInput] = useState(String(data.pajak_pb1_persen))
  const [serviceInput, setServiceInput] = useState(String(data.service_persen))

  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [sedangMenyimpan, setSedangMenyimpan] = useState(false)

  // Contoh transaksi dummy untuk live receipt simulation
  const simulasi = hitungSimulasiStruk(
    42000,
    5000,
    data.pajak_pb1_persen,
    data.service_persen,
    data.pembulatan,
  )

  const handlePajakUbah = (val: string) => {
    setPajakInput(val)
    const n = parseFloat(val)
    if (!isNaN(n)) {
      setData((s) => ({ ...s, pajak_pb1_persen: n }))
    }
  }

  const handleServiceUbah = (val: string) => {
    setServiceInput(val)
    const n = parseFloat(val)
    if (!isNaN(n)) {
      setData((s) => ({ ...s, service_persen: n }))
    }
  }

  const validasiFormulir = (): string | null => {
    const pajak = parseFloat(pajakInput)
    if (isNaN(pajak) || pajak < 0 || pajak > 100) {
      return 'Persentase Pajak PB1 harus berupa angka antara 0 sampai 100.'
    }
    const service = parseFloat(serviceInput)
    if (isNaN(service) || service < 0 || service > 100) {
      return 'Persentase Service Charge harus berupa angka antara 0 sampai 100.'
    }
    if (data.jam_buka.trim().length > 200) {
      return 'Keterangan jam buka maksimal 200 karakter.'
    }
    if (data.header_struk.length > 500) {
      return 'Teks header struk maksimal 500 karakter.'
    }
    if (data.footer_struk.length > 500) {
      return 'Teks footer struk maksimal 500 karakter.'
    }
    return null
  }

  const handleSimpan = async () => {
    setPesanSukses(null)
    setPesanGalat(null)

    const galatValidasi = validasiFormulir()
    if (galatValidasi) {
      setPesanGalat(galatValidasi)
      return
    }

    const payload: DataOperasional = {
      ...data,
      pajak_pb1_persen: parseFloat(pajakInput),
      service_persen: parseFloat(serviceInput),
    }

    if (onSimpan) {
      setSedangMenyimpan(true)
      try {
        const hasil = await onSimpan(payload)
        if (hasil.berhasil) {
          setPesanSukses(hasil.pesan || 'Pengaturan operasional berhasil disimpan.')
        } else {
          setPesanGalat(hasil.pesan || 'Gagal menyimpan pengaturan operasional.')
        }
      } catch (err: unknown) {
        const pesan = err instanceof Error ? err.message : 'Terjadi kendala jaringan.'
        setPesanGalat(pesan)
      } finally {
        setSedangMenyimpan(false)
      }
    } else {
      setPesanSukses('Pengaturan operasional berhasil disimpan.')
    }
  }

  return (
    <div className="pengaturan-operasional" data-testid="pengaturan-operasional">
      {/* Header Navigasi Sub-Layar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '1.25rem',
          flexWrap: 'wrap',
          gap: '0.75rem',
        }}
      >
        <div>
          <h2 style={{ margin: 0 }}>Pengaturan Operasional & Kasir</h2>
          <p className="small muted" style={{ margin: '0.25rem 0 0 0' }}>
            Aturan kalkulasi pajak, service charge, pembulatan, alur pemesanan, dan cetakan struk
            kasir.
          </p>
        </div>
        {onKembali && (
          <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke Identitas">
            ← Kembali
          </Tombol>
        )}
      </div>

      {/* Banner Pesan Sukses / Galat */}
      {pesanSukses && (
        <div
          role="status"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius)',
            backgroundColor: 'var(--sukses-latar, var(--kartu-latar))',
            border: '1px solid var(--sukses, green)',
            color: 'var(--sukses-teks, var(--teks))',
          }}
        >
          ✅ {pesanSukses}
        </div>
      )}

      {pesanGalat && (
        <div
          role="alert"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius)',
            backgroundColor: 'var(--bahaya-latar, var(--kartu-latar))',
            border: '1px solid var(--bahaya, red)',
            color: 'var(--bahaya-teks, var(--teks))',
          }}
        >
          ⚠️ {pesanGalat}
        </div>
      )}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '1.25rem',
        }}
      >
        {/* Kolom Kiri: Formulir Pengaturan Operasional */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Kartu 1: Pajak & Service Charge */}
          <Kartu judul="Tarif Pajak & Layanan (ART-3)">
            <p className="small muted" style={{ marginBottom: '1rem' }}>
              Dihitung dari subtotal transaksi setelah potongan diskon.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <KolomIsian
                  label="Pajak PB1 (%)"
                  nilai={pajakInput}
                  onUbah={handlePajakUbah}
                  jenis="number"
                  contoh="10"
                  keterangan="Tarif Pajak Restoran / PB1 (0 s/d 100%)."
                  nonaktif={hanyaBaca}
                />
                <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.5rem' }}>
                  {[0, 10, 11, 12].map((p) => (
                    <Tombol
                      key={p}
                      ragam={data.pajak_pb1_persen === p ? 'utama' : 'biasa'}
                      onClick={() => handlePajakUbah(String(p))}
                      nonaktif={hanyaBaca}
                      nama={`Pilih tarif PB1 ${p} persen`}
                    >
                      {p}%
                    </Tombol>
                  ))}
                </div>
              </div>

              <div>
                <KolomIsian
                  label="Service Charge (%)"
                  nilai={serviceInput}
                  onUbah={handleServiceUbah}
                  jenis="number"
                  contoh="5"
                  keterangan="Biaya layanan restoran (0 s/d 100%)."
                  nonaktif={hanyaBaca}
                />
                <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.5rem' }}>
                  {[0, 5, 7, 10].map((s) => (
                    <Tombol
                      key={s}
                      ragam={data.service_persen === s ? 'utama' : 'biasa'}
                      onClick={() => handleServiceUbah(String(s))}
                      nonaktif={hanyaBaca}
                      nama={`Pilih service charge ${s} persen`}
                    >
                      {s}%
                    </Tombol>
                  ))}
                </div>
              </div>
            </div>
          </Kartu>

          {/* Kartu 2: Aturan Pembulatan Tagihan */}
          <Kartu judul="Aturan Pembulatan Total">
            <p className="small muted" style={{ marginBottom: '0.75rem' }}>
              Diterapkan pada langkah terakhir total tagihan kasir setelah pajak dan service.
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
              {DAFTAR_PEMBULATAN.map((p) => {
                const terpilih = data.pembulatan === p.id
                return (
                  <div
                    key={p.id}
                    onClick={() => !hanyaBaca && setData((s) => ({ ...s, pembulatan: p.id }))}
                    style={{
                      padding: '0.75rem 1rem',
                      borderRadius: 'var(--radius)',
                      border: terpilih ? '2px solid var(--primer)' : '1px solid var(--border)',
                      backgroundColor: terpilih ? 'var(--primer-redup)' : 'var(--latar)',
                      cursor: hanyaBaca ? 'default' : 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <div>
                      <strong>{p.label}</strong>
                      <div className="small muted">{p.keterangan}</div>
                    </div>
                    {terpilih && <Lencana nada="accent">Aktif</Lencana>}
                  </div>
                )
              })}
            </div>
          </Kartu>

          {/* Kartu 3: Alur Cara Pesan */}
          <Kartu judul="Alur Pemesanan Utama">
            <p className="small muted" style={{ marginBottom: '0.75rem' }}>
              Menentukan bagaimana pesanan diterima di cabang kedai Anda.
            </p>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
              {DAFTAR_CARA_PESAN.map((cp) => {
                const terpilih = data.cara_pesan === cp.id
                return (
                  <div
                    key={cp.id}
                    onClick={() => !hanyaBaca && setData((s) => ({ ...s, cara_pesan: cp.id }))}
                    style={{
                      padding: '0.75rem 1rem',
                      borderRadius: 'var(--radius)',
                      border: terpilih ? '2px solid var(--primer)' : '1px solid var(--border)',
                      backgroundColor: terpilih ? 'var(--primer-redup)' : 'var(--latar)',
                      cursor: hanyaBaca ? 'default' : 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.75rem',
                    }}
                  >
                    <span style={{ fontSize: '1.5rem' }}>{cp.ikon}</span>
                    <div style={{ flex: 1 }}>
                      <strong>{cp.label}</strong>
                      <div className="small muted">{cp.keterangan}</div>
                    </div>
                    {terpilih && <Lencana nada="success">Terpilih</Lencana>}
                  </div>
                )
              })}
            </div>
          </Kartu>

          {/* Kartu 4: Jam Operasional & Pesan Struk */}
          <Kartu judul="Jam Buka & Pesan Struk Cetak">
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <KolomIsian
                label="Jam Operasional"
                nilai={data.jam_buka}
                onUbah={(val) => setData((s) => ({ ...s, jam_buka: val }))}
                contoh="Senin - Minggu 08.00 - 22.00 WIB"
                keterangan="Tampil pada katalog online pelanggan dan kepala struk."
                nonaktif={hanyaBaca}
              />

              <KolomIsian
                label="Pesan Kepala Struk (Header)"
                nilai={data.header_struk}
                onUbah={(val) => setData((s) => ({ ...s, header_struk: val }))}
                contoh="KEDAI OASIS BAROKAH - Cabang Utama"
                keterangan="Teks salam pembuka yang dicetak di atas rincian belanja."
                nonaktif={hanyaBaca}
              />

              <KolomIsian
                label="Pesan Penutup Struk (Footer)"
                nilai={data.footer_struk}
                onUbah={(val) => setData((s) => ({ ...s, footer_struk: val }))}
                contoh="Matur Nuwun. Semoga Sehat dan Berkah Selalu!"
                keterangan="Teks ucapan terima kasih yang dicetak di bawah total belanja."
                nonaktif={hanyaBaca}
              />

              {/* Checkbox Tumpuk Diskon */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  paddingTop: '0.5rem',
                  borderTop: '1px solid var(--border)',
                }}
              >
                <input
                  type="checkbox"
                  id="tumpuk-diskon"
                  checked={Boolean(data.tumpuk_diskon)}
                  disabled={hanyaBaca}
                  onChange={(e) => setData((s) => ({ ...s, tumpuk_diskon: e.target.checked }))}
                />
                <label htmlFor="tumpuk-diskon" style={{ cursor: 'pointer', fontSize: '0.9rem' }}>
                  Izinkan penumpukan beberapa diskon / promo dalam satu pesanan
                </label>
              </div>
            </div>
          </Kartu>

          {/* Tombol Simpan Aksi */}
          {!hanyaBaca && (
            <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem' }}>
              <Tombol
                ragam="utama"
                onClick={handleSimpan}
                nonaktif={sedangMenyimpan}
                nama="Simpan Pengaturan Operasional"
              >
                {sedangMenyimpan ? 'Menyimpan…' : 'Simpan Pengaturan Operasional'}
              </Tombol>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setData({
                    pajak_pb1_persen:
                      dataAwal?.pajak_pb1_persen ?? DATA_OPERASIONAL_BAWAAN.pajak_pb1_persen,
                    service_persen:
                      dataAwal?.service_persen ?? DATA_OPERASIONAL_BAWAAN.service_persen,
                    pembulatan: dataAwal?.pembulatan ?? DATA_OPERASIONAL_BAWAAN.pembulatan,
                    cara_pesan: dataAwal?.cara_pesan ?? DATA_OPERASIONAL_BAWAAN.cara_pesan,
                    jam_buka: dataAwal?.jam_buka ?? DATA_OPERASIONAL_BAWAAN.jam_buka,
                    header_struk: dataAwal?.header_struk ?? DATA_OPERASIONAL_BAWAAN.header_struk,
                    footer_struk: dataAwal?.footer_struk ?? DATA_OPERASIONAL_BAWAAN.footer_struk,
                    tumpuk_diskon: dataAwal?.tumpuk_diskon ?? DATA_OPERASIONAL_BAWAAN.tumpuk_diskon,
                  })
                  setPajakInput(
                    String(dataAwal?.pajak_pb1_persen ?? DATA_OPERASIONAL_BAWAAN.pajak_pb1_persen),
                  )
                  setServiceInput(
                    String(dataAwal?.service_persen ?? DATA_OPERASIONAL_BAWAAN.service_persen),
                  )
                  setPesanSukses(null)
                  setPesanGalat(null)
                }}
                nonaktif={sedangMenyimpan}
                nama="Reset Pengaturan ke Semula"
              >
                Batal / Reset
              </Tombol>
            </div>
          )}
        </div>

        {/* Kolom Kanan: Pratinjau Struk Kasir & Simulasi Finansial (Live Preview) */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <Kartu judul="Pratinjau Struk Kasir (Simulasi Langsung)">
            <p className="small muted" style={{ marginBottom: '1rem' }}>
              Tampilan struk belanja cetak kasir dengan kalkulasi real-time sesuai pengaturan aktif
              di sebelah kiri.
            </p>

            {/* Kertas Struk Simulasi */}
            <div
              style={{
                fontFamily: 'monospace',
                fontSize: '0.85rem',
                backgroundColor: 'var(--latar)',
                border: '1px dashed var(--border)',
                borderRadius: 'var(--radius)',
                padding: '1.25rem',
                lineHeight: 1.4,
              }}
            >
              {/* Kop & Header Struk */}
              <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
                <div style={{ fontWeight: 'bold', fontSize: '1rem' }}>RESTO BAROKAH</div>
                <div className="small muted">{data.jam_buka || '08.00 - 22.00 WIB'}</div>
                {data.header_struk && (
                  <div style={{ margin: '0.35rem 0', fontStyle: 'italic' }}>
                    "{data.header_struk}"
                  </div>
                )}
                <div style={{ borderBottom: '1px dashed var(--border)', margin: '0.5rem 0' }} />
              </div>

              {/* Rincian Contoh Belanja */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>1x Nasi Goreng Spesial</span>
                <span>Rp 35.000</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>1x Es Teh Manis</span>
                <span>Rp 7.000</span>
              </div>

              <div style={{ borderBottom: '1px dashed var(--border)', margin: '0.5rem 0' }} />

              {/* Ringkasan Finansial ART-3 */}
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Subtotal:</span>
                <span>Rp {simulasi.subtotal.toLocaleString('id-ID')}</span>
              </div>

              <div
                style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--primer)' }}
              >
                <span>Diskon Kupon:</span>
                <span>-Rp {simulasi.diskon.toLocaleString('id-ID')}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Dasar Pengenaan Pajak:</span>
                <span>Rp {simulasi.dasar.toLocaleString('id-ID')}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Pajak PB1 ({data.pajak_pb1_persen}%):</span>
                <span>Rp {simulasi.nominalPajak.toLocaleString('id-ID')}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Service Charge ({data.service_persen}%):</span>
                <span>Rp {simulasi.nominalService.toLocaleString('id-ID')}</span>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span>Aturan Pembulatan:</span>
                <span>
                  {data.pembulatan === 'none' ? 'Pas (0)' : `Kelipatan ${data.pembulatan}`}
                </span>
              </div>

              <div style={{ borderBottom: '1px dashed var(--border)', margin: '0.5rem 0' }} />

              {/* Total Akhir */}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontWeight: 'bold',
                  fontSize: '1.05rem',
                }}
              >
                <span>TOTAL AKHIR:</span>
                <span>Rp {simulasi.total.toLocaleString('id-ID')}</span>
              </div>

              <div style={{ borderBottom: '1px dashed var(--border)', margin: '0.5rem 0' }} />

              {/* Footer Struk */}
              <div style={{ textAlign: 'center', marginTop: '0.75rem' }}>
                <div className="small muted">
                  Mode Layanan: {DAFTAR_CARA_PESAN.find((c) => c.id === data.cara_pesan)?.label}
                </div>
                {data.footer_struk && (
                  <div style={{ marginTop: '0.35rem', fontStyle: 'italic' }}>
                    "{data.footer_struk}"
                  </div>
                )}
              </div>
            </div>

            {/* Peringatan Integritas Finansial ART-3 */}
            <div
              style={{
                marginTop: '1rem',
                padding: '0.75rem',
                borderRadius: 'var(--radius)',
                backgroundColor: 'var(--kartu-latar)',
                border: '1px solid var(--border)',
                fontSize: '0.85rem',
              }}
            >
              🔒 <strong>Jaminan Keamanan Finansial:</strong>
              <div className="small muted" style={{ marginTop: '0.25rem' }}>
                Perubahan persentase pajak atau biaya layanan disalin ke transaksi baru. Transaksi
                dan struk lama yang telah dibayar lunas tidak akan pernah terpengaruh oleh perubahan
                ini.
              </div>
            </div>
          </Kartu>
        </div>
      </div>
    </div>
  )
}
