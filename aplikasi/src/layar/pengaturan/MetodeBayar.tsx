/**
 * MetodeBayar.tsx — Pengaturan Metode Pembayaran & Aturan Tip (PRD M2 / T9-07)
 *
 * Mengelola metode pembayaran restoran dan konfigurasi penerimaan tip sukarela:
 *  - Tambah, edit, aktifkan/nonaktifkan metode pembayaran (Tunai, QRIS, Transfer, EDC, dll).
 *  - Urutan tampil metode pembayaran saat kasir melunasi pesanan.
 *  - Atur kewajiban nomor referensi (wajib untuk non-tunai, dilarang untuk tunai).
 *  - Hapus metode pembayaran (hanya jika belum memiliki riwayat transaksi).
 *  - Aturan tip restoran: bolehkan/larang tip, cara hitung (sukarela, persen, nominal),
 *    serta konfigurasi opsi pilihan tip cepat bagi pelanggan.
 */

import { useState, useId } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { Toast } from '../../komponen/Toast'

export interface ItemMetodeBayar {
  id: string
  nama: string
  jenis: 'tunai' | 'non_tunai'
  butuh_referensi: boolean
  aktif: boolean
  urutan: number
}

export interface DataAturanTip {
  izinkan_tip: boolean
  cara_hitung_tip: 'sukarela' | 'persen' | 'nominal'
  pilihan_tip_persen: number[]
  pilihan_tip_nominal: number[]
}

export interface MetodeBayarProps {
  daftarMetodeAwal?: ItemMetodeBayar[]
  aturanTipAwal?: Partial<DataAturanTip>
  onSimpanMetode?: (data: {
    id?: string
    nama: string
    jenis: 'tunai' | 'non_tunai'
    butuh_referensi: boolean
    aktif: boolean
    urutan?: number
  }) => Promise<{ berhasil: boolean; pesan?: string }>
  onHapusMetode?: (id: string) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanUrutanMetode?: (
    daftar: Array<{ id: string; urutan: number }>,
  ) => Promise<{ berhasil: boolean; pesan?: string }>
  onSimpanAturanTip?: (data: DataAturanTip) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

const METODE_DEFAULT: ItemMetodeBayar[] = [
  { id: 'm1', nama: 'Tunai', jenis: 'tunai', butuh_referensi: false, aktif: true, urutan: 1 },
  { id: 'm2', nama: 'QRIS', jenis: 'non_tunai', butuh_referensi: true, aktif: true, urutan: 2 },
  {
    id: 'm3',
    nama: 'Debit / Kartu',
    jenis: 'non_tunai',
    butuh_referensi: true,
    aktif: true,
    urutan: 3,
  },
  {
    id: 'm4',
    nama: 'Transfer Bank',
    jenis: 'non_tunai',
    butuh_referensi: true,
    aktif: true,
    urutan: 4,
  },
]

const ATURAN_TIP_DEFAULT: DataAturanTip = {
  izinkan_tip: false,
  cara_hitung_tip: 'sukarela',
  pilihan_tip_persen: [5, 10, 15],
  pilihan_tip_nominal: [2000, 5000, 10000],
}

export function MetodeBayar({
  daftarMetodeAwal = METODE_DEFAULT,
  aturanTipAwal,
  onSimpanMetode,
  onHapusMetode,
  onSimpanUrutanMetode,
  onSimpanAturanTip,
  onKembali,
  hanyaBaca = false,
}: MetodeBayarProps) {
  const [daftarMetode, setDaftarMetode] = useState<ItemMetodeBayar[]>(() =>
    [...daftarMetodeAwal].sort((a, b) => a.urutan - b.urutan),
  )

  const [aturanTip, setAturanTip] = useState<DataAturanTip>(() => ({
    ...ATURAN_TIP_DEFAULT,
    ...aturanTipAwal,
  }))

  const [inputPersen, setInputPersen] = useState<string>(() =>
    (aturanTipAwal?.pilihan_tip_persen || ATURAN_TIP_DEFAULT.pilihan_tip_persen).join(', '),
  )
  const [inputNominal, setInputNominal] = useState<string>(() =>
    (aturanTipAwal?.pilihan_tip_nominal || ATURAN_TIP_DEFAULT.pilihan_tip_nominal).join(', '),
  )

  // Status Modal Form Tambah / Edit Metode
  const [modalMetodeBuka, setModalMetodeBuka] = useState(false)
  const [idEditMetode, setIdEditMetode] = useState<string | null>(null)
  const [formNama, setFormNama] = useState('')
  const [formJenis, setFormJenis] = useState<'tunai' | 'non_tunai'>('non_tunai')
  const [formButuhRef, setFormButuhRef] = useState(true)
  const [formAktif, setFormAktif] = useState(true)
  const [formUrutan, setFormUrutan] = useState(0)

  // Status Modal Hapus Metode
  const [modalHapusBuka, setModalHapusBuka] = useState(false)
  const [metodeMauDihapus, setMetodeMauDihapus] = useState<ItemMetodeBayar | null>(null)

  // Feedback Toast & Loading State
  const [memuat, setMemuat] = useState(false)
  const [pesanToast, setPesanToast] = useState<{
    pesan: string
    nada: 'sukses' | 'gagal' | 'info'
  } | null>(null)

  const formIdPrefix = useId()

  const bukaModalTambah = () => {
    setIdEditMetode(null)
    setFormNama('')
    setFormJenis('non_tunai')
    setFormButuhRef(true)
    setFormAktif(true)
    setFormUrutan(daftarMetode.length + 1)
    setModalMetodeBuka(true)
  }

  const bukaModalEdit = (metode: ItemMetodeBayar) => {
    setIdEditMetode(metode.id)
    setFormNama(metode.nama)
    setFormJenis(metode.jenis)
    setFormButuhRef(metode.butuh_referensi)
    setFormAktif(metode.aktif)
    setFormUrutan(metode.urutan)
    setModalMetodeBuka(true)
  }

  const bukaModalHapus = (metode: ItemMetodeBayar) => {
    setMetodeMauDihapus(metode)
    setModalHapusBuka(true)
  }

  // Tangani perubahan Jenis Metode pada Form
  const handleUbahJenis = (jenis: 'tunai' | 'non_tunai') => {
    setFormJenis(jenis)
    if (jenis === 'tunai') {
      setFormButuhRef(false)
    } else {
      setFormButuhRef(true)
    }
  }

  // Simpan Metode (Tambah / Edit)
  const handleSimpanMetode = async () => {
    const namaBersih = formNama.trim()
    if (namaBersih.length < 2) {
      setPesanToast({ pesan: 'Nama metode pembayaran minimal 2 karakter.', nada: 'gagal' })
      return
    }

    // Validasi duplikasi nama
    const namaKembar = daftarMetode.some(
      (m) => m.nama.toLowerCase() === namaBersih.toLowerCase() && m.id !== idEditMetode,
    )
    if (namaKembar) {
      setPesanToast({
        pesan: `Metode pembayaran dengan nama "${namaBersih}" sudah terdaftar.`,
        nada: 'gagal',
      })
      return
    }

    // Validasi minimal 1 metode aktif
    if (!formAktif) {
      const aktifLainnya = daftarMetode.filter((m) => m.aktif && m.id !== idEditMetode)
      if (aktifLainnya.length === 0) {
        setPesanToast({
          pesan: 'Minimal harus ada satu metode pembayaran yang aktif.',
          nada: 'gagal',
        })
        return
      }
    }

    setMemuat(true)
    try {
      if (onSimpanMetode) {
        const res = await onSimpanMetode({
          id: idEditMetode ?? undefined,
          nama: namaBersih,
          jenis: formJenis,
          butuh_referensi: formButuhRef,
          aktif: formAktif,
          urutan: formUrutan,
        })
        if (!res.berhasil) {
          setPesanToast({ pesan: res.pesan || 'Gagal menyimpan metode pembayaran.', nada: 'gagal' })
          setMemuat(false)
          return
        }
      }

      // Update state lokal
      setDaftarMetode((lama) => {
        if (idEditMetode) {
          return lama
            .map((m) =>
              m.id === idEditMetode
                ? {
                    ...m,
                    nama: namaBersih,
                    jenis: formJenis,
                    butuh_referensi: formButuhRef,
                    aktif: formAktif,
                    urutan: formUrutan,
                  }
                : m,
            )
            .sort((a, b) => a.urutan - b.urutan)
        } else {
          const itemBaru: ItemMetodeBayar = {
            id: `metode-${Date.now()}`,
            nama: namaBersih,
            jenis: formJenis,
            butuh_referensi: formButuhRef,
            aktif: formAktif,
            urutan: formUrutan,
          }
          return [...lama, itemBaru].sort((a, b) => a.urutan - b.urutan)
        }
      })

      setPesanToast({
        pesan: `Metode "${namaBersih}" berhasil disimpan.`,
        nada: 'sukses',
      })
      setModalMetodeBuka(false)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
      setPesanToast({ pesan: msg, nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  // Toggle Cepat Aktif/Nonaktif
  const handleToggleAktif = async (metode: ItemMetodeBayar) => {
    if (hanyaBaca) return
    const statusBaru = !metode.aktif

    if (!statusBaru) {
      const aktifLainnya = daftarMetode.filter((m) => m.aktif && m.id !== metode.id)
      if (aktifLainnya.length === 0) {
        setPesanToast({
          pesan: 'Minimal harus ada satu metode pembayaran yang aktif.',
          nada: 'gagal',
        })
        return
      }
    }

    setMemuat(true)
    try {
      if (onSimpanMetode) {
        const res = await onSimpanMetode({
          id: metode.id,
          nama: metode.nama,
          jenis: metode.jenis,
          butuh_referensi: metode.butuh_referensi,
          aktif: statusBaru,
          urutan: metode.urutan,
        })
        if (!res.berhasil) {
          setPesanToast({ pesan: res.pesan || 'Gagal mengubah status aktif.', nada: 'gagal' })
          setMemuat(false)
          return
        }
      }

      setDaftarMetode((lama) =>
        lama.map((m) => (m.id === metode.id ? { ...m, aktif: statusBaru } : m)),
      )
      setPesanToast({
        pesan: `Metode "${metode.nama}" ${statusBaru ? 'diaktifkan' : 'dinonaktifkan'}.`,
        nada: 'sukses',
      })
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
      setPesanToast({ pesan: msg, nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  // Geser Urutan (Naik / Turun)
  const handleGeserUrutan = async (indeks: number, arah: 'naik' | 'turun') => {
    if (hanyaBaca) return
    const indeksTarget = arah === 'naik' ? indeks - 1 : indeks + 1
    if (indeksTarget < 0 || indeksTarget >= daftarMetode.length) return

    const daftarBaru = [...daftarMetode]
    const itemDipindah = daftarBaru[indeks]
    daftarBaru[indeks] = daftarBaru[indeksTarget]
    daftarBaru[indeksTarget] = itemDipindah

    // Re-index urutan 1..N
    const daftarUpdate = daftarBaru.map((item, idx) => ({
      ...item,
      urutan: idx + 1,
    }))

    setDaftarMetode(daftarUpdate)

    if (onSimpanUrutanMetode) {
      setMemuat(true)
      try {
        const payload = daftarUpdate.map((m) => ({ id: m.id, urutan: m.urutan }))
        const res = await onSimpanUrutanMetode(payload)
        if (!res.berhasil) {
          setPesanToast({ pesan: res.pesan || 'Gagal memperbarui urutan.', nada: 'gagal' })
        } else {
          setPesanToast({ pesan: 'Urutan metode pembayaran diperbarui.', nada: 'sukses' })
        }
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
        setPesanToast({ pesan: msg, nada: 'gagal' })
      } finally {
        setMemuat(false)
      }
    }
  }

  // Hapus Metode
  const handleHapusMetode = async () => {
    if (!metodeMauDihapus) return

    // Validasi tidak boleh hapus satu-satunya metode aktif
    if (metodeMauDihapus.aktif) {
      const aktifLainnya = daftarMetode.filter((m) => m.aktif && m.id !== metodeMauDihapus.id)
      if (aktifLainnya.length === 0) {
        setPesanToast({
          pesan: 'Tidak dapat menghapus satu-satunya metode pembayaran aktif.',
          nada: 'gagal',
        })
        setModalHapusBuka(false)
        return
      }
    }

    setMemuat(true)
    try {
      if (onHapusMetode) {
        const res = await onHapusMetode(metodeMauDihapus.id)
        if (!res.berhasil) {
          setPesanToast({
            pesan:
              res.pesan ||
              'Metode pembayaran tidak dapat dihapus karena sudah memiliki riwayat transaksi.',
            nada: 'gagal',
          })
          setMemuat(false)
          setModalHapusBuka(false)
          return
        }
      }

      setDaftarMetode((lama) => lama.filter((m) => m.id !== metodeMauDihapus.id))
      setPesanToast({
        pesan: `Metode "${metodeMauDihapus.nama}" berhasil dihapus.`,
        nada: 'sukses',
      })
      setModalHapusBuka(false)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
      setPesanToast({ pesan: msg, nada: 'gagal' })
    } finally {
      setMemuat(false)
      setMetodeMauDihapus(null)
    }
  }

  // Simpan Aturan Tip
  const handleSimpanAturanTip = async () => {
    if (hanyaBaca) return

    // Parse daftar persen
    const parsedPersen = inputPersen
      .split(',')
      .map((s) => parseFloat(s.trim()))
      .filter((n) => !isNaN(n) && n > 0 && n <= 100)
      .sort((a, b) => a - b)

    // Parse daftar nominal
    const parsedNominal = inputNominal
      .split(',')
      .map((s) => parseInt(s.trim(), 10))
      .filter((n) => !isNaN(n) && n > 0)
      .sort((a, b) => a - b)

    const payload: DataAturanTip = {
      izinkan_tip: aturanTip.izinkan_tip,
      cara_hitung_tip: aturanTip.cara_hitung_tip,
      pilihan_tip_persen: parsedPersen.length > 0 ? parsedPersen : [5, 10, 15],
      pilihan_tip_nominal: parsedNominal.length > 0 ? parsedNominal : [2000, 5000, 10000],
    }

    setMemuat(true)
    try {
      if (onSimpanAturanTip) {
        const res = await onSimpanAturanTip(payload)
        if (!res.berhasil) {
          setPesanToast({ pesan: res.pesan || 'Gagal menyimpan aturan tip.', nada: 'gagal' })
          setMemuat(false)
          return
        }
      }

      setAturanTip(payload)
      setPesanToast({ pesan: 'Aturan tip berhasil diperbarui.', nada: 'sukses' })
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Terjadi kesalahan sistem.'
      setPesanToast({ pesan: msg, nada: 'gagal' })
    } finally {
      setMemuat(false)
    }
  }

  return (
    <div className="pengaturan-metode-bayar" data-testid="pengaturan-metode-bayar">
      {/* Toast Notifikasi */}
      {pesanToast && (
        <div style={{ marginBottom: '1rem' }}>
          <Toast pesan={pesanToast.pesan} nada={pesanToast.nada} />
        </div>
      )}

      {/* Header Halaman */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '0.75rem',
          marginBottom: '1.5rem',
        }}
      >
        <div>
          <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 600 }}>
            Metode Pembayaran & Aturan Tip
          </h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--text-muted)', fontSize: '0.875rem' }}>
            Kelola opsi penerimaan kasir, nomor referensi, serta aturan tip sukarela pelanggan.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu pengaturan">
              Kembali
            </Tombol>
          )}
          {!hanyaBaca && (
            <Tombol ragam="utama" onClick={bukaModalTambah} nama="Tambah metode pembayaran baru">
              + Tambah Metode
            </Tombol>
          )}
        </div>
      </div>

      {/* ===================================================================== */}
      {/* SEKSI 1: DAFTAR METODE PEMBAYARAN                                      */}
      {/* ===================================================================== */}
      <Kartu judul="Daftar Metode Pembayaran Aktif">
        <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1rem' }}>
          Metode pembayaran aktif akan muncul di layar kasir saat melunasi pesanan. Urutan tampil
          dapat digeser naik/turun sesuai kebutuhan meja kasir Anda.
        </p>

        <div style={{ overflowX: 'auto' }}>
          <table
            style={{
              width: '100%',
              borderCollapse: 'collapse',
              textAlign: 'left',
              fontSize: '0.875rem',
            }}
          >
            <thead>
              <tr
                style={{ borderBottom: '2px solid var(--border)', background: 'var(--surface-2)' }}
              >
                <th style={{ padding: '0.75rem', width: '60px', textAlign: 'center' }}>Urutan</th>
                <th style={{ padding: '0.75rem' }}>Nama Metode</th>
                <th style={{ padding: '0.75rem' }}>Jenis</th>
                <th style={{ padding: '0.75rem' }}>No. Referensi</th>
                <th style={{ padding: '0.75rem' }}>Status</th>
                <th style={{ padding: '0.75rem', textAlign: 'right' }}>Aksi</th>
              </tr>
            </thead>
            <tbody>
              {daftarMetode.map((item, idx) => (
                <tr
                  key={item.id}
                  style={{
                    borderBottom: '1px solid var(--border)',
                    opacity: item.aktif ? 1 : 0.65,
                    background: item.aktif ? 'transparent' : 'var(--surface-2)',
                  }}
                >
                  <td style={{ padding: '0.75rem', textAlign: 'center', fontWeight: 600 }}>
                    {idx + 1}
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    <div style={{ fontWeight: 600, color: 'var(--text)' }}>{item.nama}</div>
                    {item.jenis === 'tunai' && (
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        Otomatis hitung kembalian kasir
                      </span>
                    )}
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    <Lencana nada={item.jenis === 'tunai' ? 'accent' : 'info'}>
                      {item.jenis === 'tunai' ? 'Tunai' : 'Non-Tunai'}
                    </Lencana>
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    {item.butuh_referensi ? (
                      <Lencana nada="warn">Wajib Diisi</Lencana>
                    ) : (
                      <span style={{ color: 'var(--text-muted)' }}>Tidak Butuh</span>
                    )}
                  </td>
                  <td style={{ padding: '0.75rem' }}>
                    <Lencana nada={item.aktif ? 'success' : 'netral'}>
                      {item.aktif ? '● Aktif' : '○ Nonaktif'}
                    </Lencana>
                  </td>
                  <td style={{ padding: '0.75rem', textAlign: 'right' }}>
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'flex-end',
                        gap: '0.35rem',
                      }}
                    >
                      {!hanyaBaca && (
                        <>
                          <Tombol
                            ragam="biasa"
                            onClick={() => handleToggleAktif(item)}
                            nonaktif={memuat}
                            nama={`Ubah status ${item.nama}`}
                          >
                            {item.aktif ? 'Nonaktifkan' : 'Aktifkan'}
                          </Tombol>
                          <Tombol
                            ragam="biasa"
                            onClick={() => handleGeserUrutan(idx, 'naik')}
                            nonaktif={idx === 0 || memuat}
                            nama={`Geser naik ${item.nama}`}
                          >
                            ▲
                          </Tombol>
                          <Tombol
                            ragam="biasa"
                            onClick={() => handleGeserUrutan(idx, 'turun')}
                            nonaktif={idx === daftarMetode.length - 1 || memuat}
                            nama={`Geser turun ${item.nama}`}
                          >
                            ▼
                          </Tombol>
                          <Tombol
                            ragam="biasa"
                            onClick={() => bukaModalEdit(item)}
                            nonaktif={memuat}
                            nama={`Edit ${item.nama}`}
                          >
                            Edit
                          </Tombol>
                          <Tombol
                            ragam="bahaya"
                            onClick={() => bukaModalHapus(item)}
                            nonaktif={memuat}
                            nama={`Hapus ${item.nama}`}
                          >
                            Hapus
                          </Tombol>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Kartu>

      {/* ===================================================================== */}
      {/* SEKSI 2: ATURAN TIP RESTORAN                                          */}
      {/* ===================================================================== */}
      <div style={{ marginTop: '1.5rem' }}>
        <Kartu judul="Aturan Tip Pelanggan">
          <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1.25rem' }}>
            Restoran dapat memilih apakah ingin menerima tip sukarela dari pelanggan. Seluruh
            pencatatan tip diisolasi terpisah dari setoran omzet pokok restoran demi transparansi
            kasir dan pembagian tip staf.
          </p>

          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '1.25rem',
              maxWidth: '640px',
            }}
          >
            {/* Sakelar Izinkan Tip */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem',
                padding: '0.75rem',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius-md)',
                border: '1px solid var(--border)',
              }}
            >
              <input
                type="checkbox"
                id={`${formIdPrefix}-izinkan-tip`}
                checked={aturanTip.izinkan_tip}
                onChange={(e) =>
                  setAturanTip((prev) => ({ ...prev, izinkan_tip: e.target.checked }))
                }
                disabled={hanyaBaca}
                style={{ width: '20px', height: '20px', cursor: 'pointer' }}
              />
              <label
                htmlFor={`${formIdPrefix}-izinkan-tip`}
                style={{ fontSize: '0.925rem', color: 'var(--text)', cursor: 'pointer' }}
              >
                <strong>Bolehkan Pelanggan Memberikan Tip</strong>
                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  Jika diaktifkan, opsi tip sukarela akan tersedia di kasir dan struk pembayaran.
                </div>
              </label>
            </div>

            {/* Opsi Cara Hitung Tip */}
            {aturanTip.izinkan_tip && (
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '1rem',
                  padding: '1rem',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  background: 'var(--surface)',
                }}
              >
                <div>
                  <label
                    style={{
                      display: 'block',
                      fontSize: '0.875rem',
                      fontWeight: 600,
                      marginBottom: '0.5rem',
                    }}
                  >
                    Model Rekomendasi Tip
                  </label>
                  <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                    <label
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.35rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                      }}
                    >
                      <input
                        type="radio"
                        name="cara_hitung_tip"
                        value="sukarela"
                        checked={aturanTip.cara_hitung_tip === 'sukarela'}
                        onChange={() =>
                          setAturanTip((prev) => ({ ...prev, cara_hitung_tip: 'sukarela' }))
                        }
                        disabled={hanyaBaca}
                      />
                      Nominal Bebas (Sukarela)
                    </label>

                    <label
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.35rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                      }}
                    >
                      <input
                        type="radio"
                        name="cara_hitung_tip"
                        value="persen"
                        checked={aturanTip.cara_hitung_tip === 'persen'}
                        onChange={() =>
                          setAturanTip((prev) => ({ ...prev, cara_hitung_tip: 'persen' }))
                        }
                        disabled={hanyaBaca}
                      />
                      Pilihan Persentase (e.g. 5%, 10%)
                    </label>

                    <label
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.35rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                      }}
                    >
                      <input
                        type="radio"
                        name="cara_hitung_tip"
                        value="nominal"
                        checked={aturanTip.cara_hitung_tip === 'nominal'}
                        onChange={() =>
                          setAturanTip((prev) => ({ ...prev, cara_hitung_tip: 'nominal' }))
                        }
                        disabled={hanyaBaca}
                      />
                      Pilihan Pecahan Cepat (e.g. Rp2.000, Rp5.000)
                    </label>
                  </div>
                </div>

                {/* Input Pilihan Persentase */}
                {aturanTip.cara_hitung_tip === 'persen' && (
                  <div>
                    <KolomIsian
                      label="Daftar Persentase Tip Cepat (% dipisahkan koma)"
                      nilai={inputPersen}
                      onUbah={setInputPersen}
                      contoh="Misal: 5, 10, 15, 20"
                      nonaktif={hanyaBaca}
                    />
                    <div
                      style={{
                        fontSize: '0.75rem',
                        color: 'var(--text-muted)',
                        marginTop: '0.25rem',
                      }}
                    >
                      Persentase dihitung dari subtotal bersih pesanan (sebelum pajak & service).
                    </div>
                  </div>
                )}

                {/* Input Pilihan Nominal Pecahan Cepat */}
                {aturanTip.cara_hitung_tip === 'nominal' && (
                  <div>
                    <KolomIsian
                      label="Daftar Nominal Tip Cepat (Rupiah dipisahkan koma)"
                      nilai={inputNominal}
                      onUbah={setInputNominal}
                      contoh="Misal: 2000, 5000, 10000, 20000"
                      nonaktif={hanyaBaca}
                    />
                    <div
                      style={{
                        fontSize: '0.75rem',
                        color: 'var(--text-muted)',
                        marginTop: '0.25rem',
                      }}
                    >
                      Pecahan tombol cepat yang disuguhkan kasir pada saat pembayaran.
                    </div>
                  </div>
                )}
              </div>
            )}

            {!hanyaBaca && (
              <div>
                <Tombol
                  ragam="utama"
                  onClick={handleSimpanAturanTip}
                  nonaktif={memuat}
                  nama="Simpan seluruh konfigurasi aturan tip"
                >
                  {memuat ? 'Menyimpan...' : 'Simpan Aturan Tip'}
                </Tombol>
              </div>
            )}
          </div>
        </Kartu>
      </div>

      {/* ===================================================================== */}
      {/* MODAL 1: TAMBAH / EDIT METODE PEMBAYARAN                               */}
      {/* ===================================================================== */}
      <Lapis
        buka={modalMetodeBuka}
        judul={idEditMetode ? 'Edit Metode Pembayaran' : 'Tambah Metode Pembayaran Baru'}
        onTutup={() => setModalMetodeBuka(false)}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', minWidth: '320px' }}>
          <KolomIsian
            label="Nama Metode Pembayaran"
            nilai={formNama}
            onUbah={setFormNama}
            contoh="Misal: QRIS BCA, Mandiri EDC, GoPay, OVO"
            wajib
          />

          <div>
            <label
              style={{
                display: 'block',
                fontSize: '0.875rem',
                fontWeight: 600,
                marginBottom: '0.5rem',
              }}
            >
              Jenis Pembayaran
            </label>
            <div style={{ display: 'flex', gap: '1rem' }}>
              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.35rem',
                  cursor: 'pointer',
                  fontSize: '0.875rem',
                }}
              >
                <input
                  type="radio"
                  name="jenis_metode"
                  value="tunai"
                  checked={formJenis === 'tunai'}
                  onChange={() => handleUbahJenis('tunai')}
                />
                Tunai (Cash)
              </label>

              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.35rem',
                  cursor: 'pointer',
                  fontSize: '0.875rem',
                }}
              >
                <input
                  type="radio"
                  name="jenis_metode"
                  value="non_tunai"
                  checked={formJenis === 'non_tunai'}
                  onChange={() => handleUbahJenis('non_tunai')}
                />
                Non-Tunai (QRIS / Transfer / Kartu)
              </label>
            </div>
          </div>

          <div
            style={{
              padding: '0.75rem',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
            }}
          >
            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                cursor: formJenis === 'tunai' ? 'not-allowed' : 'pointer',
              }}
            >
              <input
                type="checkbox"
                checked={formButuhRef}
                onChange={(e) => setFormButuhRef(e.target.checked)}
                disabled={formJenis === 'tunai' || formJenis === 'non_tunai'}
              />
              <span>
                <strong>Wajib Isi Nomor Referensi / Approval Code</strong>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  {formJenis === 'tunai'
                    ? 'Pembayaran tunai dilarang mewajibkan nomor referensi.'
                    : 'Pembayaran non-tunai wajib mencatat nomor referensi perbankan.'}
                </div>
              </span>
            </label>
          </div>

          <div
            style={{
              padding: '0.75rem',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
            }}
          >
            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                cursor: 'pointer',
              }}
            >
              <input
                type="checkbox"
                checked={formAktif}
                onChange={(e) => setFormAktif(e.target.checked)}
              />
              <span>
                <strong>Status Aktif</strong>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  Tampilkan opsi metode ini pada kasir saat transaksi pembayaran.
                </div>
              </span>
            </label>
          </div>

          <div
            style={{
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '0.5rem',
              marginTop: '0.5rem',
            }}
          >
            <Tombol
              ragam="biasa"
              onClick={() => setModalMetodeBuka(false)}
              nama="Batal simpan metode"
            >
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={handleSimpanMetode}
              nonaktif={memuat || formNama.trim().length < 2}
              nama="Konfirmasi simpan metode pembayaran"
            >
              {memuat ? 'Menyimpan...' : 'Simpan'}
            </Tombol>
          </div>
        </div>
      </Lapis>

      {/* ===================================================================== */}
      {/* MODAL 2: KONFIRMASI HAPUS METODE                                      */}
      {/* ===================================================================== */}
      <Lapis
        buka={modalHapusBuka}
        judul="Hapus Metode Pembayaran"
        onTutup={() => setModalHapusBuka(false)}
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', minWidth: '320px' }}>
          <p style={{ margin: 0, fontSize: '0.875rem' }}>
            Apakah Anda yakin ingin menghapus metode pembayaran{' '}
            <strong>"{metodeMauDihapus?.nama}"</strong>?
          </p>

          <div
            style={{
              padding: '0.75rem',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--border)',
              fontSize: '0.8rem',
              color: 'var(--text-muted)',
            }}
          >
            ⚠️ <em>Catatan Keamanan:</em> Jika metode ini sudah pernah digunakan dalam transaksi
            pembayaran apa pun, sistem akan menolak penghapusan demi menjaga integritas pembukuan
            kasir. Silakan nonaktifkan metode bila tidak ingin digunakan lagi.
          </div>

          <div
            style={{
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '0.5rem',
              marginTop: '0.5rem',
            }}
          >
            <Tombol
              ragam="biasa"
              onClick={() => setModalHapusBuka(false)}
              nama="Batal hapus metode"
            >
              Batal
            </Tombol>
            <Tombol
              ragam="bahaya"
              onClick={handleHapusMetode}
              nonaktif={memuat}
              nama="Konfirmasi hapus metode pembayaran"
            >
              {memuat ? 'Menghapus...' : 'Ya, Hapus'}
            </Tombol>
          </div>
        </div>
      </Lapis>
    </div>
  )
}
