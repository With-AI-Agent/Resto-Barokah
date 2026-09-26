import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lapis } from '../../komponen/Lapis'
import { Lencana } from '../../komponen/Lencana'
import { Toast } from '../../komponen/Toast'
import { Tombol } from '../../komponen/Tombol'
import { klienSupabase } from '../../lib/supabase'

export interface PenyewaItem {
  id: string
  nama: string
  slug: string
  status: 'aktif' | 'nonaktif'
  zona_waktu: string
  mata_uang: string
  kontak_telepon?: string | null
  kontak_email?: string | null
  dibuat_pada: string
  diubah_pada?: string | null
  jumlah_cabang: number
  owner_nama?: string | null
  owner_email?: string | null
}

export interface FormPenyewaBaru {
  nama: string
  slug: string
  zona_waktu: string
  mata_uang: string
  kontak_telepon: string
  kontak_email: string
  cabang_nama: string
  cabang_alamat: string
  cabang_telepon: string
  owner_nama: string
  owner_email: string
  owner_pin: string
}

export interface PenyewaProps {
  daftarAwal?: PenyewaItem[]
  onMuatUlang?: () => Promise<PenyewaItem[]>
  onSimpanPenyewa?: (payload: FormPenyewaBaru) => Promise<{ berhasil: boolean; pesan: string }>
  onSetStatusPenyewa?: (
    id: string,
    status: 'aktif' | 'nonaktif',
    alasan?: string,
  ) => Promise<{ berhasil: boolean; pesan: string }>
}

const DATA_CONTOH_PENYEWA: PenyewaItem[] = [
  {
    id: '11111111-1111-1111-1111-111111111111',
    nama: 'Kedai Oasis',
    slug: 'kedai-oasis',
    status: 'aktif',
    zona_waktu: 'Asia/Jakarta',
    mata_uang: 'IDR',
    kontak_telepon: '081234567890',
    kontak_email: 'halo@kedai-oasis.test',
    dibuat_pada: '2026-09-01T08:00:00Z',
    jumlah_cabang: 2,
    owner_nama: 'Bu Oasis',
    owner_email: 'owner.a@contoh.test',
  },
  {
    id: '22222222-2222-2222-2222-222222222222',
    nama: 'Warung Bandung',
    slug: 'warung-bandung',
    status: 'aktif',
    zona_waktu: 'Asia/Jakarta',
    mata_uang: 'IDR',
    kontak_telepon: '082198765432',
    kontak_email: 'admin@warungbandung.test',
    dibuat_pada: '2026-09-10T09:30:00Z',
    jumlah_cabang: 1,
    owner_nama: 'Pak Jajang',
    owner_email: 'owner.b@contoh.test',
  },
]

function ambilPesanGalat(err: unknown): string {
  if (err instanceof Error) return err.message
  if (typeof err === 'object' && err !== null && 'message' in err) {
    return String((err as { message: unknown }).message)
  }
  return String(err)
}

function bersihkanSlug(teks: string): string {
  return teks
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 30)
}

export function LayarPenyewaPlatform({
  daftarAwal = DATA_CONTOH_PENYEWA,
  onMuatUlang,
  onSimpanPenyewa,
  onSetStatusPenyewa,
}: PenyewaProps) {
  const [daftarPenyewa, setDaftarPenyewa] = useState<PenyewaItem[]>(daftarAwal)
  const [cari, setCari] = useState<string>('')
  const [filterStatus, setFilterStatus] = useState<'semua' | 'aktif' | 'nonaktif'>('semua')
  const [sedangMemuat, setSedangMemuat] = useState<boolean>(false)

  // Status Toast
  const [toastPesan, setToastPesan] = useState<string | null>(null)
  const [toastNada, setToastNada] = useState<'sukses' | 'gagal'>('sukses')

  // Modal Tambah Penyewa Baru
  const [modalTambah, setModalTambah] = useState<boolean>(false)
  const [formTambah, setFormTambah] = useState<FormPenyewaBaru>({
    nama: '',
    slug: '',
    zona_waktu: 'Asia/Jakarta',
    mata_uang: 'IDR',
    kontak_telepon: '',
    kontak_email: '',
    cabang_nama: 'Cabang Utama',
    cabang_alamat: '',
    cabang_telepon: '',
    owner_nama: '',
    owner_email: '',
    owner_pin: '',
  })
  const [galatForm, setGalatForm] = useState<string | null>(null)
  const [sedangSimpan, setSedangSimpan] = useState<boolean>(false)

  // Modal Nonaktifkan Penyewa
  const [modalNonaktif, setModalNonaktif] = useState<boolean>(false)
  const [penyewaDipilih, setPenyewaDipilih] = useState<PenyewaItem | null>(null)
  const [alasanNonaktif, setAlasanNonaktif] = useState<string>('')
  const [sedangUbahStatus, setSedangUbahStatus] = useState<boolean>(false)

  const tunjukkanToast = (pesan: string, nada: 'sukses' | 'gagal' = 'sukses') => {
    setToastPesan(pesan)
    setToastNada(nada)
  }

  const muatDataUlang = async () => {
    if (onMuatUlang) {
      setSedangMemuat(true)
      try {
        const data = await onMuatUlang()
        setDaftarPenyewa(data)
      } catch (err: unknown) {
        tunjukkanToast(ambilPesanGalat(err), 'gagal')
      } finally {
        setSedangMemuat(false)
      }
      return
    }

    const sb = klienSupabase()
    if (!sb) return

    setSedangMemuat(true)
    try {
      const { data, error } = await sb.rpc('ambil_daftar_penyewa', {
        p_cari: cari.trim() || null,
        p_status: filterStatus === 'semua' ? null : filterStatus,
      })
      if (error) throw error
      if (data) {
        setDaftarPenyewa(data as PenyewaItem[])
      }
    } catch (err: unknown) {
      tunjukkanToast(ambilPesanGalat(err), 'gagal')
    } finally {
      setSedangMemuat(false)
    }
  }

  const tanganiBukaTambah = () => {
    setFormTambah({
      nama: '',
      slug: '',
      zona_waktu: 'Asia/Jakarta',
      mata_uang: 'IDR',
      kontak_telepon: '',
      kontak_email: '',
      cabang_nama: 'Cabang Utama',
      cabang_alamat: '',
      cabang_telepon: '',
      owner_nama: '',
      owner_email: '',
      owner_pin: '',
    })
    setGalatForm(null)
    setModalTambah(true)
  }

  const tanganiUbahNamaResto = (namaBaru: string) => {
    setFormTambah((prev) => ({
      ...prev,
      nama: namaBaru,
      slug: prev.slug === '' || prev.slug === bersihkanSlug(prev.nama) ? bersihkanSlug(namaBaru) : prev.slug,
    }))
  }

  const tanganiSimpanPenyewaBaru = async () => {
    setGalatForm(null)

    if (!formTambah.nama.trim()) {
      setGalatForm('Nama restoran wajib diisi.')
      return
    }
    if (!formTambah.owner_nama.trim()) {
      setGalatForm('Nama Owner pertama wajib diisi.')
      return
    }
    if (!formTambah.owner_email.trim() || !formTambah.owner_email.includes('@')) {
      setGalatForm('Email Owner pertama tidak valid.')
      return
    }
    if (!formTambah.owner_pin || !/^\d{6}$/.test(formTambah.owner_pin)) {
      setGalatForm('PIN Owner wajib 6 digit angka.')
      return
    }

    setSedangSimpan(true)
    try {
      if (onSimpanPenyewa) {
        const res = await onSimpanPenyewa(formTambah)
        if (!res.berhasil) throw new Error(res.pesan)
        tunjukkanToast(res.pesan, 'sukses')
      } else {
        const sb = klienSupabase()
        if (sb) {
          const { error } = await sb.rpc('buat_penyewa', {
            p_nama: formTambah.nama.trim(),
            p_slug: formTambah.slug.trim() || null,
            p_zona_waktu: formTambah.zona_waktu,
            p_mata_uang: formTambah.mata_uang,
            p_kontak_telepon: formTambah.kontak_telepon.trim() || null,
            p_kontak_email: formTambah.kontak_email.trim() || null,
            p_cabang_nama: formTambah.cabang_nama.trim() || 'Cabang Utama',
            p_cabang_alamat: formTambah.cabang_alamat.trim() || null,
            p_cabang_telepon: formTambah.cabang_telepon.trim() || null,
            p_owner_nama: formTambah.owner_nama.trim(),
            p_owner_email: formTambah.owner_email.trim().toLowerCase(),
            p_owner_pin: formTambah.owner_pin,
          })
          if (error) throw error
          tunjukkanToast(`Penyewa "${formTambah.nama}" berhasil didaftarkan.`, 'sukses')
        } else {
          // Simulasi lokal
          const itemBaru: PenyewaItem = {
            id: `penyewa-${Date.now()}`,
            nama: formTambah.nama.trim(),
            slug: formTambah.slug.trim() || bersihkanSlug(formTambah.nama),
            status: 'aktif',
            zona_waktu: formTambah.zona_waktu,
            mata_uang: formTambah.mata_uang,
            kontak_telepon: formTambah.kontak_telepon.trim() || null,
            kontak_email: formTambah.kontak_email.trim() || null,
            dibuat_pada: new Date().toISOString(),
            jumlah_cabang: 1,
            owner_nama: formTambah.owner_nama.trim(),
            owner_email: formTambah.owner_email.trim(),
          }
          setDaftarPenyewa((prev) => [itemBaru, ...prev])
          tunjukkanToast(`Penyewa "${formTambah.nama}" berhasil didaftarkan (simulasi).`, 'sukses')
        }
      }

      setModalTambah(false)
      await muatDataUlang()
    } catch (err: unknown) {
      setGalatForm(ambilPesanGalat(err))
    } finally {
      setSedangSimpan(false)
    }
  }

  const tanganiBukaNonaktifkan = (item: PenyewaItem) => {
    setPenyewaDipilih(item)
    setAlasanNonaktif('')
    setModalNonaktif(true)
  }

  const tanganiKonfirmasiNonaktif = async () => {
    if (!penyewaDipilih) return
    if (!alasanNonaktif.trim() || alasanNonaktif.trim().length < 5) {
      tunjukkanToast('Alasan penonaktifan wajib diisi minimal 5 karakter.', 'gagal')
      return
    }

    setSedangUbahStatus(true)
    try {
      if (onSetStatusPenyewa) {
        const res = await onSetStatusPenyewa(penyewaDipilih.id, 'nonaktif', alasanNonaktif.trim())
        if (!res.berhasil) throw new Error(res.pesan)
        tunjukkanToast(res.pesan, 'sukses')
      } else {
        const sb = klienSupabase()
        if (sb) {
          const { error } = await sb.rpc('set_status_penyewa', {
            p_penyewa_id: penyewaDipilih.id,
            p_status: 'nonaktif',
            p_alasan: alasanNonaktif.trim(),
          })
          if (error) throw error
          tunjukkanToast(`Penyewa "${penyewaDipilih.nama}" dinonaktifkan.`, 'sukses')
        } else {
          // Simulasi
          setDaftarPenyewa((prev) =>
            prev.map((p) => (p.id === penyewaDipilih.id ? { ...p, status: 'nonaktif' } : p)),
          )
          tunjukkanToast(`Penyewa "${penyewaDipilih.nama}" dinonaktifkan (simulasi).`, 'sukses')
        }
      }

      setModalNonaktif(false)
      setPenyewaDipilih(null)
      await muatDataUlang()
    } catch (err: unknown) {
      tunjukkanToast(ambilPesanGalat(err), 'gagal')
    } finally {
      setSedangUbahStatus(false)
    }
  }

  const tanganiAktifkanKembali = async (item: PenyewaItem) => {
    setSedangMemuat(true)
    try {
      if (onSetStatusPenyewa) {
        const res = await onSetStatusPenyewa(item.id, 'aktif')
        if (!res.berhasil) throw new Error(res.pesan)
        tunjukkanToast(res.pesan, 'sukses')
      } else {
        const sb = klienSupabase()
        if (sb) {
          const { error } = await sb.rpc('set_status_penyewa', {
            p_penyewa_id: item.id,
            p_status: 'aktif',
          })
          if (error) throw error
          tunjukkanToast(`Penyewa "${item.nama}" diaktifkan kembali.`, 'sukses')
        } else {
          setDaftarPenyewa((prev) =>
            prev.map((p) => (p.id === item.id ? { ...p, status: 'aktif' } : p)),
          )
          tunjukkanToast(`Penyewa "${item.nama}" diaktifkan kembali (simulasi).`, 'sukses')
        }
      }
      await muatDataUlang()
    } catch (err: unknown) {
      tunjukkanToast(ambilPesanGalat(err), 'gagal')
    } finally {
      setSedangMemuat(false)
    }
  }

  // Saring daftar berdasarkan cari & status
  const daftarTersaring = daftarPenyewa.filter((p) => {
    const cocokCari =
      !cari.trim() ||
      p.nama.toLowerCase().includes(cari.toLowerCase().trim()) ||
      p.slug.toLowerCase().includes(cari.toLowerCase().trim())
    const cocokStatus = filterStatus === 'semua' || p.status === filterStatus
    return cocokCari && cocokStatus
  })

  const totalResto = daftarPenyewa.length
  const totalAktif = daftarPenyewa.filter((p) => p.status === 'aktif').length
  const totalNonaktif = daftarPenyewa.filter((p) => p.status === 'nonaktif').length
  const totalCabang = daftarPenyewa.reduce((acc, cur) => acc + (cur.jumlah_cabang || 0), 0)

  return (
    <div style={{ maxWidth: '1100px', margin: '0 auto', padding: 'var(--s-4)' }}>
      {/* Toast Notifikasi */}
      {toastPesan && (
        <Toast
          pesan={toastPesan}
          nada={toastNada}
          aksi={
            <Tombol ragam="polos" onClick={() => setToastPesan(null)}>
              ✕
            </Tombol>
          }
        />
      )}

      {/* Header Layar Platform */}
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
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)', marginBottom: 'var(--s-1)' }}>
            <h1 style={{ fontSize: 'var(--t-5)', fontWeight: 800, margin: 0 }}>
              Kelola Resto Penyewa
            </h1>
            <Lencana nada="accent">Pemilik Platform</Lencana>
          </div>
          <p style={{ margin: 0, color: 'var(--teks-redup)', fontSize: 'var(--t-2)' }}>
            Mendaftarkan restoran baru, konfigurasi cabang pertama, akun Owner pusat, dan isolasi data total (PRD M1).
          </p>
        </div>

        <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
          <Tombol
            ragam="utama"
            onClick={tanganiBukaTambah}
            data-aksi="platform.buat_penyewa"
          >
            ➕ Tambah Penyewa Baru
          </Tombol>
        </div>
      </div>

      {/* Kartu Ringkasan Statistik */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: 'var(--s-3)',
          marginBottom: 'var(--s-4)',
        }}
      >
        <Kartu>
          <div style={{ fontSize: 'var(--t-1)', color: 'var(--teks-redup)' }}>Total Restoran</div>
          <div style={{ fontSize: 'var(--t-5)', fontWeight: 800, marginTop: 'var(--s-1)' }}>
            {totalResto}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: 'var(--t-1)', color: 'var(--teks-redup)' }}>Restoran Aktif</div>
          <div style={{ fontSize: 'var(--t-5)', fontWeight: 800, color: 'var(--success)', marginTop: 'var(--s-1)' }}>
            {totalAktif}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: 'var(--t-1)', color: 'var(--teks-redup)' }}>Nonaktif (Dibekukan)</div>
          <div style={{ fontSize: 'var(--t-5)', fontWeight: 800, color: 'var(--warn)', marginTop: 'var(--s-1)' }}>
            {totalNonaktif}
          </div>
        </Kartu>
        <Kartu>
          <div style={{ fontSize: 'var(--t-1)', color: 'var(--teks-redup)' }}>Total Seluruh Cabang</div>
          <div style={{ fontSize: 'var(--t-5)', fontWeight: 800, color: 'var(--accent)', marginTop: 'var(--s-1)' }}>
            {totalCabang}
          </div>
        </Kartu>
      </div>

      {/* Kontrol Pencarian & Filter */}
      <div style={{ marginBottom: 'var(--s-4)' }}>
        <Kartu>
          <div
            style={{
              display: 'flex',
              flexWrap: 'wrap',
              gap: 'var(--s-3)',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <div style={{ flex: '1 1 300px' }}>
              <KolomIsian
                label="Cari Nama Resto atau Slug"
                nilai={cari}
                onUbah={setCari}
                contoh="mis. Oasis atau bandung"
              />
            </div>

            <div style={{ display: 'flex', gap: 'var(--s-2)', alignItems: 'center' }}>
              <span style={{ fontSize: 'var(--t-1)', color: 'var(--teks-redup)' }}>Filter Status:</span>
              <Tombol
                ragam={filterStatus === 'semua' ? 'utama' : 'biasa'}
                onClick={() => setFilterStatus('semua')}
              >
                Semua ({totalResto})
              </Tombol>
              <Tombol
                ragam={filterStatus === 'aktif' ? 'utama' : 'biasa'}
                onClick={() => setFilterStatus('aktif')}
              >
                Aktif ({totalAktif})
              </Tombol>
              <Tombol
                ragam={filterStatus === 'nonaktif' ? 'utama' : 'biasa'}
                onClick={() => setFilterStatus('nonaktif')}
              >
                Nonaktif ({totalNonaktif})
              </Tombol>
            </div>
          </div>
        </Kartu>
      </div>

      {/* Daftar Tabel Penyewa */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
        {sedangMemuat && (
          <div style={{ textAlign: 'center', padding: 'var(--s-4)', color: 'var(--teks-redup)' }}>
            Memuat daftar resto penyewa...
          </div>
        )}

        {!sedangMemuat && daftarTersaring.length === 0 && (
          <Kartu>
            <div style={{ textAlign: 'center', padding: 'var(--s-4)' }}>
              <div style={{ fontSize: '2rem', marginBottom: 'var(--s-2)' }}>🏢</div>
              <h3 style={{ margin: '0 0 var(--s-1) 0' }}>Tidak ada resto ditemukan</h3>
              <p style={{ color: 'var(--teks-redup)', margin: 0, fontSize: 'var(--t-2)' }}>
                Silakan sesuaikan kata kunci pencarian atau daftarkan penyewa baru.
              </p>
            </div>
          </Kartu>
        )}

        {!sedangMemuat &&
          daftarTersaring.map((item) => {
            const adalahAktif = item.status === 'aktif'
            return (
              <div
                key={item.id}
                style={{
                  borderLeft: `4px solid ${adalahAktif ? 'var(--success)' : 'var(--warn)'}`,
                  borderRadius: 'var(--radius-md)',
                }}
              >
                <Kartu>
                  <div
                    style={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      flexWrap: 'wrap',
                      gap: 'var(--s-3)',
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
                        <h3 style={{ margin: 0, fontSize: 'var(--t-4)', fontWeight: 700 }}>{item.nama}</h3>
                        <Lencana nada={adalahAktif ? 'success' : 'warn'}>
                          {adalahAktif ? 'Aktif' : 'Nonaktif'}
                        </Lencana>
                        <span
                          style={{
                            fontSize: 'var(--t-1)',
                            background: 'var(--surface-2)',
                            padding: '2px 8px',
                            borderRadius: 'var(--radius-sm)',
                            fontFamily: 'monospace',
                          }}
                        >
                          /{item.slug}
                        </span>
                      </div>

                      <div
                        style={{
                          display: 'flex',
                          flexWrap: 'wrap',
                          gap: 'var(--s-4)',
                          marginTop: 'var(--s-2)',
                          fontSize: 'var(--t-2)',
                          color: 'var(--teks-redup)',
                        }}
                      >
                        <div>📍 {item.jumlah_cabang} Cabang</div>
                        <div>👤 Owner: {item.owner_nama || '-'} ({item.owner_email || '-'})</div>
                        <div>⏰ {item.zona_waktu} ({item.mata_uang})</div>
                        {item.kontak_telepon && <div>📞 {item.kontak_telepon}</div>}
                      </div>
                    </div>

                    {/* Tombol Aksi Status */}
                    <div style={{ display: 'flex', gap: 'var(--s-2)', alignItems: 'center' }}>
                      {adalahAktif ? (
                        <Tombol
                          ragam="kecil"
                          onClick={() => tanganiBukaNonaktifkan(item)}
                          data-aksi="platform.set_status_penyewa"
                        >
                          ⏸️ Nonaktifkan
                        </Tombol>
                      ) : (
                        <Tombol
                          ragam="utama"
                          onClick={() => tanganiAktifkanKembali(item)}
                          data-aksi="platform.set_status_penyewa"
                        >
                          ▶️ Aktifkan Kembali
                        </Tombol>
                      )}
                    </div>
                  </div>
                </Kartu>
              </div>
            )
          })}
      </div>

      {/* Modal Tambah Resto Baru */}
      <Lapis
        buka={modalTambah}
        judul="Daftarkan Restoran / Penyewa Baru"
        onTutup={() => setModalTambah(false)}
        kaki={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--s-2)' }}>
            <Tombol ragam="polos" onClick={() => setModalTambah(false)}>
              Batal
            </Tombol>
            <Tombol
              ragam="utama"
              onClick={tanganiSimpanPenyewaBaru}
              nonaktif={sedangSimpan}
              data-aksi="platform.buat_penyewa"
            >
              {sedangSimpan ? 'Mendaftarkan...' : 'Daftarkan Resto'}
            </Tombol>
          </div>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
          {galatForm && (
            <div
              style={{
                padding: 'var(--s-2) var(--s-3)',
                background: 'var(--danger-soft)',
                color: 'var(--danger)',
                borderRadius: 'var(--radius-sm)',
                fontSize: 'var(--t-2)',
              }}
            >
              ⚠️ {galatForm}
            </div>
          )}

          <h4 style={{ margin: '0 0 var(--s-1) 0', fontSize: 'var(--t-3)' }}>1. Identitas Restoran</h4>
          <KolomIsian
            label="Nama Restoran / Penyewa"
            nilai={formTambah.nama}
            onUbah={tanganiUbahNamaResto}
            contoh="mis. Resto Sederhana Barokah"
            wajib
          />

          <KolomIsian
            label="Slug Publik (Alamat Tautan Katalog)"
            nilai={formTambah.slug}
            onUbah={(s) => setFormTambah((prev) => ({ ...prev, slug: bersihkanSlug(s) }))}
            contoh="mis. resto-sederhana"
            keterangan="Huruf kecil alfanumerik dan strip (2-31 karakter)."
          />

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--s-2)' }}>
            <div className="kolom-isian">
              <label className="label">Zona Waktu</label>
              <select
                className="input"
                value={formTambah.zona_waktu}
                onChange={(e) => setFormTambah((prev) => ({ ...prev, zona_waktu: e.target.value }))}
              >
                <option value="Asia/Jakarta">WIB (Asia/Jakarta)</option>
                <option value="Asia/Makassar">WITA (Asia/Makassar)</option>
                <option value="Asia/Jayapura">WIT (Asia/Jayapura)</option>
                <option value="UTC">UTC</option>
              </select>
            </div>
            <KolomIsian
              label="Mata Uang"
              nilai={formTambah.mata_uang}
              onUbah={(m) => setFormTambah((prev) => ({ ...prev, mata_uang: m.toUpperCase() }))}
              contoh="IDR"
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--s-2)' }}>
            <KolomIsian
              label="Kontak Telepon Resto"
              nilai={formTambah.kontak_telepon}
              onUbah={(t) => setFormTambah((prev) => ({ ...prev, kontak_telepon: t }))}
              contoh="081234567890"
            />
            <KolomIsian
              label="Kontak Email Resto"
              nilai={formTambah.kontak_email}
              onUbah={(e) => setFormTambah((prev) => ({ ...prev, kontak_email: e }))}
              contoh="info@resto.test"
            />
          </div>

          <hr style={{ border: 'none', borderTop: '1px solid var(--border)', margin: 'var(--s-2) 0' }} />

          <h4 style={{ margin: '0 0 var(--s-1) 0', fontSize: 'var(--t-3)' }}>2. Cabang Pertama</h4>
          <KolomIsian
            label="Nama Cabang Pertama"
            nilai={formTambah.cabang_nama}
            onUbah={(c) => setFormTambah((prev) => ({ ...prev, cabang_nama: c }))}
            contoh="Cabang Utama"
            wajib
          />
          <KolomIsian
            label="Alamat Cabang"
            nilai={formTambah.cabang_alamat}
            onUbah={(a) => setFormTambah((prev) => ({ ...prev, cabang_alamat: a }))}
            contoh="Jl. Merdeka No. 12"
          />

          <hr style={{ border: 'none', borderTop: '1px solid var(--border)', margin: 'var(--s-2) 0' }} />

          <h4 style={{ margin: '0 0 var(--s-1) 0', fontSize: 'var(--t-3)' }}>3. Akun Owner Pertama</h4>
          <KolomIsian
            label="Nama Lengkap Owner"
            nilai={formTambah.owner_nama}
            onUbah={(n) => setFormTambah((prev) => ({ ...prev, owner_nama: n }))}
            contoh="Budi Santoso"
            wajib
          />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--s-2)' }}>
            <KolomIsian
              label="Email Owner"
              jenis="email"
              nilai={formTambah.owner_email}
              onUbah={(e) => setFormTambah((prev) => ({ ...prev, owner_email: e }))}
              contoh="budi.owner@resto.test"
              wajib
            />
            <KolomIsian
              label="PIN Awal Owner (6 Angka)"
              jenis="password"
              nilai={formTambah.owner_pin}
              onUbah={(p) => setFormTambah((prev) => ({ ...prev, owner_pin: p.replace(/\D/g, '').slice(0, 6) }))}
              contoh="mis. 741852"
              keterangan="Wajib 6 digit, bukan pola lemah (mis. 123456)."
              wajib
            />
          </div>
        </div>
      </Lapis>

      {/* Modal Konfirmasi Nonaktifkan Penyewa */}
      <Lapis
        buka={modalNonaktif}
        judul={`Nonaktifkan Penyewa: ${penyewaDipilih?.nama || ''}`}
        onTutup={() => setModalNonaktif(false)}
        kaki={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--s-2)' }}>
            <Tombol ragam="polos" onClick={() => setModalNonaktif(false)}>
              Batal
            </Tombol>
            <Tombol
              ragam="bahaya"
              onClick={tanganiKonfirmasiNonaktif}
              nonaktif={sedangUbahStatus}
              data-aksi="platform.set_status_penyewa"
            >
              {sedangUbahStatus ? 'Memproses...' : 'Konfirmasi Nonaktifkan'}
            </Tombol>
          </div>
        }
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}>
          <div
            style={{
              padding: 'var(--s-3)',
              background: 'var(--warn-soft)',
              color: 'var(--warn)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--t-2)',
              lineHeight: 1.5,
            }}
          >
            🛡️ <strong>Keamanan Data Terjamin:</strong> Data transaksi, pesanan kasir, shift kasir, dan riwayat cabang resto ini <strong>tetap tersimpan aman dan tidak akan dihapus</strong>.
            <br />
            Penonaktifan akan membekukan akses masuk pegawai dan operasional kasir restoran ini hingga diaktifkan kembali.
          </div>

          <KolomIsian
            label="Alasan Penonaktifan (Wajib minimal 5 karakter)"
            nilai={alasanNonaktif}
            onUbah={setAlasanNonaktif}
            contoh="mis. Langganan expired atau permintaan pemilik"
            keterangan="Alasan akan dicatat secara kekal di jejak audit platform."
            wajib
          />
        </div>
      </Lapis>
    </div>
  )
}
