/**
 * Meja.tsx — Pengaturan Meja, Area, & Unduh Kode QR Stand Meja (T9-04 / PRD M2 & M4).
 *
 * Mengizinkan Owner Resto (atau staf berizin atur_pengaturan) untuk:
 *  1. Mengelola tata letak meja & area kedai tanpa koding.
 *  2. Menambah meja baru dengan nomor/nama meja unik per cabang.
 *  3. Mengubah nama meja, area penempatan, dan status aktif/nonaktif.
 *  4. Menonaktifkan meja yang rusak/direnovasi secara aman (meja yang sedang
 *     memiliki pesanan aktif dicegah agar tidak ditinggal menggantung).
 *  5. Menghapus meja yang belum pernah memiliki riwayat transaksi.
 *  6. Menyaring daftar meja berdasarkan area (Utama, Lantai 2, Outdoor, VIP, dll).
 *  7. Menampilkan kartu stand akrilik kode QR tajam per meja yang siap diunduh
 *     (format SVG vektor presisi) dan siap dicetak langsung.
 */

import { useState, useId } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { buatQrMatriks } from '../../lib/qrcode'

export interface ItemMeja {
  id: string
  cabang_id: string
  nama: string
  area: string
  status: 'kosong' | 'terisi' | 'siap'
  aktif: boolean
  diubah_pada?: string
}

export interface MejaProps {
  daftarMejaAwal?: ItemMeja[]
  daftarAreaAwal?: string[]
  cabangId?: string
  namaResto?: string
  hanyaBaca?: boolean
  onSimpanMeja?: (data: {
    id?: string
    cabang_id: string
    nama: string
    area: string
    aktif: boolean
  }) => Promise<{ berhasil: boolean; meja?: ItemMeja; pesan?: string }>
  onHapusMeja?: (mejaId: string) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
}

const DATA_MEJA_CONTOH: ItemMeja[] = [
  {
    id: 'aaa00000-0000-0000-0000-000000000001',
    cabang_id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'Meja 1',
    area: 'Dalam',
    status: 'kosong',
    aktif: true,
  },
  {
    id: 'aaa00000-0000-0000-0000-000000000002',
    cabang_id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'Meja 2',
    area: 'Teras',
    status: 'terisi',
    aktif: true,
  },
  {
    id: 'aaa00000-0000-0000-0000-000000000003',
    cabang_id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'Meja 3',
    area: 'Dalam',
    status: 'kosong',
    aktif: true,
  },
  {
    id: 'aaa00000-0000-0000-0000-000000000004',
    cabang_id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'VIP 1',
    area: 'VIP Lounge',
    status: 'siap',
    aktif: true,
  },
  {
    id: 'aaa00000-0000-0000-0000-000000000005',
    cabang_id: 'a1a1a1a1-0000-0000-0000-000000000001',
    nama: 'Meja 4',
    area: 'Teras',
    status: 'kosong',
    aktif: false,
  },
]

export function Meja({
  daftarMejaAwal = DATA_MEJA_CONTOH,
  daftarAreaAwal = ['Dalam', 'Teras', 'VIP Lounge'],
  cabangId = 'a1a1a1a1-0000-0000-0000-000000000001',
  namaResto = 'Resto Barokah',
  hanyaBaca = false,
  onSimpanMeja,
  onHapusMeja,
  onKembali,
}: MejaProps) {
  const [daftarMeja, setDaftarMeja] = useState<ItemMeja[]>(daftarMejaAwal)
  const [filterArea, setFilterArea] = useState<string>('Semua')
  const [pesanStatus, setPesanStatus] = useState<{
    jenis: 'sukses' | 'galat'
    teks: string
  } | null>(null)

  // State Modal Tambah / Edit Meja
  const [modalBuka, setModalBuka] = useState(false)
  const [editMejaId, setEditMejaId] = useState<string | null>(null)
  const [formNama, setFormNama] = useState('')
  const [formArea, setFormArea] = useState('Utama')
  const [formAreaBaru, setFormAreaBaru] = useState('')
  const [formAktif, setFormAktif] = useState(true)
  const [sedangSimpan, setSedangSimpan] = useState(false)
  const [galatForm, setGalatForm] = useState<string | null>(null)

  // State Modal Stand QR Meja
  const [modalQrBuka, setModalQrBuka] = useState(false)
  const [mejaTerpilihQr, setMejaTerpilihQr] = useState<ItemMeja | null>(null)
  const [tersalinTautan, setTersalinTautan] = useState(false)

  // Ekstrak daftar area unik
  const daftarAreaUnik = Array.from(
    new Set([...daftarAreaAwal, ...daftarMeja.map((m) => m.area || 'Utama')]),
  ).filter(Boolean)

  const areaPilihanFilter = ['Semua', ...daftarAreaUnik]

  // Filter daftar meja
  const mejaTerfilter = daftarMeja.filter((m) => {
    if (filterArea === 'Semua') return true
    return m.area === filterArea
  })

  // Statistik
  const totalMeja = daftarMeja.length
  const totalAktif = daftarMeja.filter((m) => m.aktif).length
  const totalNonaktif = totalMeja - totalAktif

  // Buka modal untuk tambah meja
  const bukaModalTambah = () => {
    setEditMejaId(null)
    setFormNama('')
    setFormArea(daftarAreaUnik[0] || 'Utama')
    setFormAreaBaru('')
    setFormAktif(true)
    setGalatForm(null)
    setModalBuka(true)
  }

  // Buka modal untuk edit meja
  const bukaModalEdit = (meja: ItemMeja) => {
    setEditMejaId(meja.id)
    setFormNama(meja.nama)
    setFormArea(daftarAreaUnik.includes(meja.area) ? meja.area : '__baru__')
    setFormAreaBaru(daftarAreaUnik.includes(meja.area) ? '' : meja.area)
    setFormAktif(meja.aktif)
    setGalatForm(null)
    setModalBuka(true)
  }

  // Buka modal QR meja
  const bukaModalQr = (meja: ItemMeja) => {
    setMejaTerpilihQr(meja)
    setTersalinTautan(false)
    setModalQrBuka(true)
  }

  // Simpan Meja (Tambah atau Ubah)
  const handleSimpanForm = async () => {
    setGalatForm(null)
    const namaBersih = formNama.trim()
    if (!namaBersih) {
      setGalatForm('Nomor atau nama meja wajib diisi.')
      return
    }

    const areaFinal =
      formArea === '__baru__' ? formAreaBaru.trim() || 'Utama' : formArea.trim() || 'Utama'

    // Validasi keunikan nama meja di cabang
    const namaKembar = daftarMeja.some(
      (m) =>
        m.nama.toLowerCase() === namaBersih.toLowerCase() &&
        m.cabang_id === cabangId &&
        m.id !== editMejaId,
    )
    if (namaKembar) {
      setGalatForm(`Nomor/nama meja "${namaBersih}" sudah digunakan di cabang ini.`)
      return
    }

    setSedangSimpan(true)
    try {
      if (onSimpanMeja) {
        const hasil = await onSimpanMeja({
          id: editMejaId || undefined,
          cabang_id: cabangId,
          nama: namaBersih,
          area: areaFinal,
          aktif: formAktif,
        })

        if (!hasil.berhasil) {
          setGalatForm(hasil.pesan || 'Gagal menyimpan data meja.')
          setSedangSimpan(false)
          return
        }

        if (hasil.meja) {
          if (editMejaId) {
            setDaftarMeja((prev) =>
              prev.map((m) => (m.id === editMejaId ? (hasil.meja as ItemMeja) : m)),
            )
          } else {
            setDaftarMeja((prev) => [...prev, hasil.meja as ItemMeja])
          }
        }
      } else {
        // Fallback lokal client-side state
        if (editMejaId) {
          setDaftarMeja((prev) =>
            prev.map((m) =>
              m.id === editMejaId
                ? {
                    ...m,
                    nama: namaBersih,
                    area: areaFinal,
                    aktif: formAktif,
                    diubah_pada: new Date().toISOString(),
                  }
                : m,
            ),
          )
        } else {
          const mejaBaru: ItemMeja = {
            id: `meja-${Date.now()}`,
            cabang_id: cabangId,
            nama: namaBersih,
            area: areaFinal,
            status: 'kosong',
            aktif: formAktif,
            diubah_pada: new Date().toISOString(),
          }
          setDaftarMeja((prev) => [...prev, mejaBaru])
        }
      }

      setPesanStatus({
        jenis: 'sukses',
        teks: editMejaId
          ? `Meja "${namaBersih}" berhasil diperbarui.`
          : `Meja "${namaBersih}" berhasil ditambahkan ke area "${areaFinal}".`,
      })
      setModalBuka(false)
    } catch (err: unknown) {
      setGalatForm(err instanceof Error ? err.message : 'Terjadi kesalahan saat menyimpan.')
    } finally {
      setSedangSimpan(false)
    }
  }

  // Toggle status aktif/nonaktif cepat
  const handleToggleAktif = async (meja: ItemMeja) => {
    if (hanyaBaca) return
    const statusBaru = !meja.aktif

    // Jika ingin menonaktifkan dan sedang terisi pesanan, cegah
    if (!statusBaru && meja.status === 'terisi') {
      setPesanStatus({
        jenis: 'galat',
        teks: `Meja "${meja.nama}" sedang terisi tamu! Selesaikan pesanan terlebih dahulu sebelum menonaktifkan.`,
      })
      return
    }

    try {
      if (onSimpanMeja) {
        const hasil = await onSimpanMeja({
          id: meja.id,
          cabang_id: meja.cabang_id,
          nama: meja.nama,
          area: meja.area,
          aktif: statusBaru,
        })
        if (!hasil.berhasil) {
          setPesanStatus({
            jenis: 'galat',
            teks: hasil.pesan || 'Gagal mengubah status aktif meja.',
          })
          return
        }
      }

      setDaftarMeja((prev) => prev.map((m) => (m.id === meja.id ? { ...m, aktif: statusBaru } : m)))
      setPesanStatus({
        jenis: 'sukses',
        teks: statusBaru
          ? `Meja "${meja.nama}" kini AKTIF dan siap menerima pesanan.`
          : `Meja "${meja.nama}" dinonaktifkan (tidak menerima pesanan baru).`,
      })
    } catch (err: unknown) {
      setPesanStatus({
        jenis: 'galat',
        teks: err instanceof Error ? err.message : 'Gagal mengubah status aktif meja.',
      })
    }
  }

  // Hapus Meja
  const handleHapusMeja = async (meja: ItemMeja) => {
    if (hanyaBaca) return
    if (!window.confirm(`Yakin ingin menghapus meja "${meja.nama}" dari cabang ini?`)) {
      return
    }

    try {
      if (onHapusMeja) {
        const hasil = await onHapusMeja(meja.id)
        if (!hasil.berhasil) {
          setPesanStatus({
            jenis: 'galat',
            teks: hasil.pesan || 'Meja tidak dapat dihapus jika memiliki riwayat transaksi.',
          })
          return
        }
      }

      setDaftarMeja((prev) => prev.filter((m) => m.id !== meja.id))
      setPesanStatus({
        jenis: 'sukses',
        teks: `Meja "${meja.nama}" berhasil dihapus.`,
      })
    } catch (err: unknown) {
      setPesanStatus({
        jenis: 'galat',
        teks: err instanceof Error ? err.message : 'Gagal menghapus meja.',
      })
    }
  }

  // Generator tautan QR meja
  const tautanPublikMeja = (namaMeja: string) => {
    const origin =
      typeof window !== 'undefined' && window.location?.origin
        ? window.location.origin
        : 'https://resto-barokah.dev'
    return `${origin}/katalog?meja=${encodeURIComponent(namaMeja)}`
  }

  // Unduh stand akrilik SVG A6
  const unduhSvgStand = (meja: ItemMeja) => {
    const urlTarget = tautanPublikMeja(meja.nama)
    const matriks = buatQrMatriks(urlTarget)
    const N = matriks.length
    const margin = 2
    const total = N + margin * 2

    let pathD = ''
    for (let r = 0; r < N; r++) {
      for (let c = 0; c < N; c++) {
        if (matriks[r][c]) {
          pathD += `M${c + margin},${r + margin}h1v1h-1z `
        }
      }
    }

    const svgKonten = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 580" width="400" height="580">
  <rect width="100%" height="100%" fill="white"/>
  <rect x="15" y="15" width="370" height="550" rx="16" fill="whitesmoke" stroke="gainsboro" stroke-width="2"/>
  <circle cx="200" cy="55" r="22" fill="honeydew"/>
  <text x="200" y="62" font-family="sans-serif" font-size="20" text-anchor="middle" fill="forestgreen">🍽️</text>
  <text x="200" y="105" font-family="sans-serif" font-size="18" font-weight="bold" text-anchor="middle" fill="black">${namaResto}</text>
  <text x="200" y="128" font-family="sans-serif" font-size="12" text-anchor="middle" fill="dimgray">Area: ${meja.area || 'Utama'}</text>
  <rect x="110" y="145" width="180" height="42" rx="8" fill="honeydew" stroke="darkseagreen" stroke-width="1"/>
  <text x="200" y="172" font-family="sans-serif" font-size="17" font-weight="bold" text-anchor="middle" fill="darkgreen">${meja.nama.toUpperCase()}</text>
  <g transform="translate(100, 205)">
    <rect x="-10" y="-10" width="220" height="220" rx="12" fill="white" stroke="gainsboro" stroke-width="1"/>
    <svg viewBox="0 0 ${total} ${total}" width="200" height="200">
      <rect width="100%" height="100%" fill="white"/>
      <path d="${pathD.trim()}" fill="black"/>
    </svg>
  </g>
  <text x="200" y="455" font-family="sans-serif" font-size="14" font-weight="bold" text-anchor="middle" fill="black">Pindai untuk Melihat Menu</text>
  <text x="200" y="478" font-family="sans-serif" font-size="11" text-anchor="middle" fill="dimgray">Arahkan kamera ponsel Anda ke kode QR di atas</text>
  <text x="200" y="525" font-family="sans-serif" font-size="9" text-anchor="middle" fill="gray">${urlTarget}</text>
</svg>`

    const blob = new Blob([svgKonten], { type: 'image/svg+xml' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `stand-qr-${meja.nama.toLowerCase().replace(/\s+/g, '-')}.svg`
    link.click()
    URL.revokeObjectURL(link.href)
  }

  const idSelectArea = useId()

  return (
    <div className="pengaturan-meja" data-testid="pengaturan-meja">
      {/* Header Halaman */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: 'var(--s-3)',
          marginBottom: 'var(--s-4)',
        }}
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
            <span style={{ fontSize: '1.75rem' }}>🪑</span>
            <h2
              style={{
                fontSize: 'var(--t-5)',
                fontWeight: 800,
                color: 'var(--text)',
                margin: 0,
              }}
            >
              Pengaturan Meja & Area
            </h2>
          </div>
          <p
            style={{
              fontSize: 'var(--t-2)',
              color: 'var(--text-muted)',
              marginTop: 'var(--s-1)',
              marginBottom: 0,
            }}
          >
            Kelola tata letak meja kedai, atur area penempatan, dan unduh stand akrilik kode QR per
            meja.
          </p>
        </div>

        <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu pengaturan">
              ← Kembali
            </Tombol>
          )}
          {!hanyaBaca && (
            <Tombol ragam="utama" onClick={bukaModalTambah} nama="Tambah Meja Baru">
              ➕ Tambah Meja
            </Tombol>
          )}
        </div>
      </div>

      {/* Pesan Status / Notifikasi */}
      {pesanStatus && (
        <div
          role="status"
          aria-live="polite"
          data-testid="pesan-status-meja"
          style={{
            padding: 'var(--s-3)',
            borderRadius: 'var(--radius-md)',
            marginBottom: 'var(--s-4)',
            background: pesanStatus.jenis === 'sukses' ? 'var(--surface-2)' : 'var(--surface)',
            borderLeft: `4px solid ${
              pesanStatus.jenis === 'sukses' ? 'var(--success)' : 'var(--danger)'
            }`,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span style={{ fontSize: 'var(--t-2)', color: 'var(--text)' }}>
            {pesanStatus.jenis === 'sukses' ? '✅ ' : '⚠️ '}
            {pesanStatus.teks}
          </span>
          <Tombol ragam="polos" onClick={() => setPesanStatus(null)} nama="Tutup notifikasi status">
            ✕
          </Tombol>
        </div>
      )}

      {/* Ringkasan Statistik Meja */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 'var(--s-3)',
          marginBottom: 'var(--s-4)',
        }}
      >
        <Kartu>
          <div style={{ padding: 'var(--s-2)', textAlign: 'center' }}>
            <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>Total Meja</span>
            <div
              style={{ fontSize: 'var(--t-6)', fontWeight: 800, color: 'var(--text)' }}
              data-testid="stat-total-meja"
            >
              {totalMeja}
            </div>
          </div>
        </Kartu>
        <Kartu>
          <div style={{ padding: 'var(--s-2)', textAlign: 'center' }}>
            <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>Meja Aktif</span>
            <div
              style={{ fontSize: 'var(--t-6)', fontWeight: 800, color: 'var(--success)' }}
              data-testid="stat-meja-aktif"
            >
              {totalAktif}
            </div>
          </div>
        </Kartu>
        <Kartu>
          <div style={{ padding: 'var(--s-2)', textAlign: 'center' }}>
            <span style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
              Meja Nonaktif
            </span>
            <div
              style={{
                fontSize: 'var(--t-6)',
                fontWeight: 800,
                color: totalNonaktif > 0 ? 'var(--danger)' : 'var(--text-muted)',
              }}
              data-testid="stat-meja-nonaktif"
            >
              {totalNonaktif}
            </div>
          </div>
        </Kartu>
      </div>

      {/* Bilah Filter Tab Area */}
      <div
        style={{
          display: 'flex',
          gap: 'var(--s-2)',
          flexWrap: 'wrap',
          marginBottom: 'var(--s-4)',
          alignItems: 'center',
        }}
        role="tablist"
        aria-label="Penyaringan Meja Berdasarkan Area"
      >
        <span
          style={{
            fontSize: 'var(--t-2)',
            fontWeight: 600,
            color: 'var(--text-muted)',
            marginRight: 'var(--s-1)',
          }}
        >
          Area:
        </span>
        {areaPilihanFilter.map((area) => {
          const aktif = filterArea === area
          return (
            <Tombol
              key={area}
              ragam={aktif ? 'utama' : 'biasa'}
              onClick={() => setFilterArea(area)}
              nama={`Filter area ${area}`}
            >
              {area === 'Semua' ? '🏢 Semua Area' : `📍 ${area}`}
            </Tombol>
          )
        })}
      </div>

      {/* Grid Kartu Meja */}
      {mejaTerfilter.length === 0 ? (
        <Kartu judul="Belum Ada Meja">
          <div
            style={{
              padding: 'var(--s-5)',
              textAlign: 'center',
              color: 'var(--text-muted)',
            }}
          >
            <p style={{ margin: 0 }}>
              Tidak ada meja di area "{filterArea}". Tekan tombol "Tambah Meja" untuk mendaftarkan
              nomor meja baru.
            </p>
          </div>
        </Kartu>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
            gap: 'var(--s-3)',
          }}
          data-testid="daftar-kartu-meja"
        >
          {mejaTerfilter.map((meja) => {
            const statusNada =
              meja.status === 'terisi' ? 'accent' : meja.status === 'siap' ? 'success' : 'netral'

            return (
              <div
                key={meja.id}
                className="kartu-item-meja"
                data-testid={`kartu-meja-${meja.id}`}
                style={{
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-lg)',
                  padding: 'var(--s-3)',
                  boxShadow: 'var(--sh-1)',
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  opacity: meja.aktif ? 1 : 0.65,
                }}
              >
                <div>
                  {/* Baris Atas: Nomor Meja & Lencana Aktif */}
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      marginBottom: 'var(--s-2)',
                    }}
                  >
                    <h3
                      style={{
                        margin: 0,
                        fontSize: 'var(--t-4)',
                        fontWeight: 800,
                        color: 'var(--text)',
                      }}
                    >
                      {meja.nama}
                    </h3>
                    <Lencana nada={meja.aktif ? 'success' : 'netral'}>
                      {meja.aktif ? '🟢 Aktif' : '⚪ Nonaktif'}
                    </Lencana>
                  </div>

                  {/* Info Area & Status Harian */}
                  <div
                    style={{
                      display: 'flex',
                      gap: 'var(--s-2)',
                      flexWrap: 'wrap',
                      marginBottom: 'var(--s-3)',
                      fontSize: 'var(--t-1)',
                    }}
                  >
                    <Lencana nada="info">📍 {meja.area || 'Utama'}</Lencana>
                    <Lencana nada={statusNada}>Status: {meja.status}</Lencana>
                  </div>
                </div>

                {/* Tombol-tombol Aksi Meja */}
                <div
                  style={{
                    display: 'flex',
                    flexWrap: 'wrap',
                    gap: 'var(--s-1)',
                    marginTop: 'var(--s-2)',
                    borderTop: '1px solid var(--border)',
                    paddingTop: 'var(--s-2)',
                  }}
                >
                  <Tombol
                    ragam="polos"
                    onClick={() => bukaModalQr(meja)}
                    nama={`Lihat kode QR ${meja.nama}`}
                  >
                    📱 QR Meja
                  </Tombol>

                  {!hanyaBaca && (
                    <>
                      <Tombol
                        ragam="biasa"
                        onClick={() => bukaModalEdit(meja)}
                        nama={`Ubah meja ${meja.nama}`}
                      >
                        ✏️ Ubah
                      </Tombol>
                      <Tombol
                        ragam="polos"
                        onClick={() => handleToggleAktif(meja)}
                        nama={`Ganti status aktif ${meja.nama}`}
                      >
                        {meja.aktif ? '⏸️ Nonaktifkan' : '▶️ Aktifkan'}
                      </Tombol>
                      <Tombol
                        ragam="bahaya"
                        onClick={() => handleHapusMeja(meja)}
                        nama={`Hapus meja ${meja.nama}`}
                      >
                        🗑️
                      </Tombol>
                    </>
                  )}
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* ===================================================================== */}
      {/* MODAL 1: TAMBAH / UBAH MEJA                                           */}
      {/* ===================================================================== */}
      <Lapis
        buka={modalBuka}
        judul={editMejaId ? 'Ubah Informasi Meja' : 'Tambah Meja Baru'}
        onTutup={() => !sedangSimpan && setModalBuka(false)}
        kaki={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--s-2)' }}>
            <Tombol
              ragam="biasa"
              onClick={() => setModalBuka(false)}
              nonaktif={sedangSimpan}
              nama="Batal simpan meja"
            >
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={handleSimpanForm}
              nonaktif={sedangSimpan}
              nama="Simpan data meja"
            >
              {sedangSimpan ? 'Menyimpan...' : 'Simpan Meja'}
            </Tombol>
          </div>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
          {galatForm && (
            <div
              role="alert"
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface)',
                borderLeft: '4px solid var(--danger)',
                color: 'var(--danger)',
                fontSize: 'var(--t-2)',
              }}
            >
              ⚠️ {galatForm}
            </div>
          )}

          <KolomIsian
            label="Nomor atau Nama Meja"
            nilai={formNama}
            onUbah={setFormNama}
            contoh="Misal: 01, Meja 12, VIP-A"
            wajib
            keterangan="Nomor meja harus unik di cabang ini."
          />

          <div className="kolom-isian">
            <label className="label" htmlFor={idSelectArea}>
              Area Penempatan
            </label>
            <select
              id={idSelectArea}
              className="input"
              value={formArea}
              onChange={(e) => setFormArea(e.target.value)}
              style={{
                width: '100%',
                padding: 'var(--s-2)',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
                background: 'var(--surface)',
                color: 'var(--text)',
              }}
            >
              {daftarAreaUnik.map((area) => (
                <option key={area} value={area}>
                  {area}
                </option>
              ))}
              <option value="__baru__">+ Tambah Area Baru...</option>
            </select>
          </div>

          {formArea === '__baru__' && (
            <KolomIsian
              label="Nama Area Baru"
              nilai={formAreaBaru}
              onUbah={setFormAreaBaru}
              contoh="Misal: Balkon, Lantai 3, Taman Depan"
              wajib
            />
          )}

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--s-2)',
              padding: 'var(--s-2)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
            }}
          >
            <input
              type="checkbox"
              id="cek-meja-aktif"
              checked={formAktif}
              onChange={(e) => setFormAktif(e.target.checked)}
              style={{ width: '18px', height: '18px', cursor: 'pointer' }}
            />
            <label
              htmlFor="cek-meja-aktif"
              style={{ fontSize: 'var(--t-2)', color: 'var(--text)', cursor: 'pointer' }}
            >
              <strong>Aktifkan meja ini</strong> (siap menerima pesanan)
            </label>
          </div>
        </div>
      </Lapis>

      {/* ===================================================================== */}
      {/* MODAL 2: PRATINJAU & UNDUH STAND QR MEJA                              */}
      {/* ===================================================================== */}
      <Lapis
        buka={modalQrBuka}
        judul={mejaTerpilihQr ? `Stand Kode QR — ${mejaTerpilihQr.nama}` : 'Stand Kode QR Meja'}
        onTutup={() => setModalQrBuka(false)}
        kaki={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--s-2)' }}>
            <Tombol ragam="biasa" onClick={() => setModalQrBuka(false)} nama="Tutup modal QR">
              Tutup
            </Tombol>
            {mejaTerpilihQr && (
              <Tombol
                ragam="utama"
                onClick={() => unduhSvgStand(mejaTerpilihQr)}
                nama="Unduh Stand Akrilik SVG"
              >
                ⬇️ Unduh Stand Akrilik (SVG)
              </Tombol>
            )}
          </div>
        }
      >
        {mejaTerpilihQr && (
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 'var(--s-3)',
            }}
            data-testid="wadah-modal-qr-meja"
          >
            {/* Kartu Stand Akrilik Pratinjau */}
            <div
              style={{
                width: '100%',
                maxWidth: '320px',
                background: 'white',
                border: '2px solid var(--border)',
                borderRadius: 'var(--radius-lg)',
                padding: 'var(--s-4)',
                textAlign: 'center',
                boxShadow: 'var(--sh-2)',
                color: 'black',
              }}
            >
              <div style={{ fontSize: '1.75rem', marginBottom: 'var(--s-1)' }}>🍽️</div>
              <h4
                style={{
                  margin: 0,
                  fontSize: 'var(--t-3)',
                  fontWeight: 800,
                  color: 'var(--text)',
                }}
              >
                {namaResto}
              </h4>
              <p
                style={{
                  margin: 'var(--s-1) 0',
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Area: {mejaTerpilihQr.area || 'Utama'}
              </p>

              {/* Lencana Nomor Meja Stand */}
              <div
                style={{
                  background: 'var(--success-soft)',
                  border: '1px solid var(--border)',
                  color: 'var(--success)',
                  padding: 'var(--s-1) var(--s-3)',
                  borderRadius: 'var(--radius-md)',
                  fontWeight: 800,
                  fontSize: 'var(--t-4)',
                  display: 'inline-block',
                  margin: 'var(--s-2) 0',
                }}
              >
                {mejaTerpilihQr.nama.toUpperCase()}
              </div>

              {/* Kode QR SVG */}
              <div
                style={{
                  background: 'white',
                  padding: 'var(--s-2)',
                  borderRadius: 'var(--radius-md)',
                  border: '1px solid var(--border)',
                  display: 'inline-block',
                  margin: 'var(--s-2) auto',
                }}
              >
                {(() => {
                  const urlTarget = tautanPublikMeja(mejaTerpilihQr.nama)
                  const matriks = buatQrMatriks(urlTarget)
                  const N = matriks.length
                  const margin = 2
                  const total = N + margin * 2

                  let pathD = ''
                  for (let r = 0; r < N; r++) {
                    for (let c = 0; c < N; c++) {
                      if (matriks[r][c]) {
                        pathD += `M${c + margin},${r + margin}h1v1h-1z `
                      }
                    }
                  }

                  return (
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      viewBox={`0 0 ${total} ${total}`}
                      width={170}
                      height={170}
                      role="img"
                      aria-label={`QR Meja ${mejaTerpilihQr.nama}`}
                      style={{ display: 'block' }}
                    >
                      <rect width="100%" height="100%" fill="white" />
                      <path d={pathD.trim()} fill="black" />
                    </svg>
                  )
                })()}
              </div>

              <div
                style={{
                  fontSize: 'var(--t-2)',
                  fontWeight: 700,
                  marginTop: 'var(--s-2)',
                  color: 'var(--text)',
                }}
              >
                Pindai untuk Melihat Menu
              </div>
              <p
                style={{
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                  margin: 'var(--s-1) 0 0 0',
                }}
              >
                Arahkan kamera ponsel Anda ke kode QR di atas
              </p>
            </div>

            {/* Tautan & Tombol Salin */}
            <div
              style={{
                width: '100%',
                maxWidth: '320px',
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--s-2)',
              }}
            >
              <div
                style={{
                  fontSize: 'var(--t-1)',
                  padding: 'var(--s-1) var(--s-2)',
                  background: 'var(--surface-2)',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--border)',
                  wordBreak: 'break-all',
                  color: 'var(--text-muted)',
                  fontFamily: 'monospace',
                }}
              >
                {tautanPublikMeja(mejaTerpilihQr.nama)}
              </div>

              <Tombol
                ragam={tersalinTautan ? 'biasa' : 'utama'}
                onClick={async () => {
                  try {
                    await navigator.clipboard.writeText(tautanPublikMeja(mejaTerpilihQr.nama))
                    setTersalinTautan(true)
                    setTimeout(() => setTersalinTautan(false), 2500)
                  } catch {
                    setTersalinTautan(true)
                    setTimeout(() => setTersalinTautan(false), 2500)
                  }
                }}
                nama="Salin tautan meja"
              >
                {tersalinTautan ? '✓ Tautan Tersalin!' : '📋 Salin Tautan Meja'}
              </Tombol>
            </div>
          </div>
        )}
      </Lapis>
    </div>
  )
}
