/**
 * Kampanye.tsx (T8-11) — Pengaturan Kampanye Voucher oleh Admin / Pemilik Resto.
 *
 * Ref: PRD M10 (aturan diatur admin) & M2 (hak akses admin/pemilik).
 *
 * Jaminan Teknis (DoD T8-11):
 *  1. Pengaturan persen / nominal, minimum belanja, batas potongan (plafon maksimal),
 *     masa berlaku (mulai & selesai), kuota voucher, anggaran, cabang berlaku.
 *  2. Pratinjau aturan dalam bahasa manusia ramah awam secara reaktif real-time.
 *  3. Validasi ketat mencegah aturan mustahil (persen > 100%, nominal <= 0, kuota <= 0,
 *     anggaran < nilai voucher, tanggal selesai <= tanggal mulai).
 *  4. Antarmuka daftar kampanye, penambahan kampanye baru, penyuntingan, dan sakelar
 *     aktif / nonaktifkan kampanye.
 */
import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { rupiah } from '../../lib/format'

export interface DataKampanyeAdmin {
  id: string
  nama: string
  kode_kampanye: string
  jenis: 'persen' | 'nominal'
  nilai: number
  min_belanja: number
  maks_potongan: number | null
  mulai: string
  selesai: string
  kuota: number
  anggaran_maks: number
  cabang_berlaku: string[] | Array<{ id: string; nama?: string }>
  aktif: boolean
  dibuat_pada?: string
  jumlah_terbit?: number
  jumlah_terpakai?: number
  sisa_kuota?: number
  status_waktu?: 'akan_datang' | 'berjalan' | 'berakhir'
  pratinjau_aturan?: string
}

export interface CabangPilihan {
  id: string
  nama: string
}

export interface KampanyeProps {
  daftarKampanyeAwal?: DataKampanyeAdmin[]
  daftarCabang?: CabangPilihan[]
  onSimpan?: (
    data: Omit<DataKampanyeAdmin, 'id'> & { id?: string },
  ) => Promise<{ berhasil: boolean; pesan?: string }> | void
  onUbahStatus?: (
    id: string,
    aktif: boolean,
  ) => Promise<{ berhasil: boolean; pesan?: string }> | void
  onKembali?: () => void
}

const CABANG_DEFAULT: CabangPilihan[] = [
  { id: 'cabang-01', nama: 'Cabang Utama' },
  { id: 'cabang-02', nama: 'Cabang Asia Afrika' },
]

const KAMPANYE_DEFAULT: DataKampanyeAdmin[] = [
  {
    id: 'kmp-001',
    nama: 'Promo Makan Siang Hemat 20%',
    kode_kampanye: 'HEMAT20',
    jenis: 'persen',
    nilai: 20,
    min_belanja: 50000,
    maks_potongan: 20000,
    mulai: '2026-09-01T00:00:00Z',
    selesai: '2026-12-31T23:59:59Z',
    kuota: 200,
    anggaran_maks: 4000000,
    cabang_berlaku: [],
    aktif: true,
    jumlah_terbit: 45,
    jumlah_terpakai: 18,
    sisa_kuota: 155,
    status_waktu: 'berjalan',
  },
  {
    id: 'kmp-002',
    nama: 'Voucher Pelanggan Setia Rp25rb',
    kode_kampanye: 'SETIA25K',
    jenis: 'nominal',
    nilai: 25000,
    min_belanja: 75000,
    maks_potongan: null,
    mulai: '2026-09-15T00:00:00Z',
    selesai: '2026-10-31T23:59:59Z',
    kuota: 100,
    anggaran_maks: 2500000,
    cabang_berlaku: ['cabang-01'],
    aktif: true,
    jumlah_terbit: 80,
    jumlah_terpakai: 32,
    sisa_kuota: 20,
    status_waktu: 'berjalan',
  },
]

export function formatPratinjauAturan(k: {
  jenis: 'persen' | 'nominal'
  nilai: number
  min_belanja: number
  maks_potongan: number | null
  selesai?: string
  kuota?: number
  semuaCabang?: boolean
  jumlahCabang?: number
}): { kalimat: string; simulasi: string } {
  const diskonTeks =
    k.jenis === 'persen'
      ? `Diskon ${k.nilai}%${
          k.maks_potongan && k.maks_potongan > 0 ? ` (maksimal ${rupiah(k.maks_potongan)})` : ''
        }`
      : `Potongan langsung ${rupiah(k.nilai)}`

  const minTeks =
    k.min_belanja > 0
      ? `dengan belanja minimal ${rupiah(k.min_belanja)}`
      : 'tanpa syarat minimum belanja'

  const cabangTeks =
    k.semuaCabang || (k.jumlahCabang ?? 0) === 0
      ? 'di semua cabang'
      : `di ${k.jumlahCabang} cabang terpilih`

  const waktuTeks = k.selesai
    ? `berlaku hingga ${new Date(k.selesai).toLocaleDateString('id-ID', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
      })}`
    : 'tanpa batas waktu'

  const kuotaTeks = k.kuota ? `Kuota: ${k.kuota} voucher` : ''

  const kalimat = `${diskonTeks} ${minTeks}, ${cabangTeks}, ${waktuTeks}. ${kuotaTeks}.`

  // Contoh simulasi belanja
  let simulasi = ''
  if (k.jenis === 'persen') {
    const contohBelanja = Math.max(50000, k.min_belanja > 0 ? k.min_belanja * 1.5 : 50000)
    let potongan = Math.round((contohBelanja * k.nilai) / 100)
    let plafonKena = false
    if (k.maks_potongan && k.maks_potongan > 0 && potongan > k.maks_potongan) {
      potongan = k.maks_potongan
      plafonKena = true
    }
    const bayar = contohBelanja - potongan
    simulasi = `Contoh: Pelanggan belanja ${rupiah(contohBelanja)} → potongan ${rupiah(potongan)}${
      plafonKena ? ' (mencapai batas maksimal)' : ''
    }, total bayar ${rupiah(bayar)}.`
  } else {
    const contohBelanja = Math.max(50000, k.min_belanja > 0 ? k.min_belanja : 50000)
    const potongan = Math.min(contohBelanja, k.nilai)
    const bayar = contohBelanja - potongan
    simulasi = `Contoh: Pelanggan belanja ${rupiah(contohBelanja)} → potongan ${rupiah(
      potongan,
    )}, total bayar ${rupiah(bayar)}.`
  }

  return { kalimat, simulasi }
}

export function Kampanye({
  daftarKampanyeAwal = KAMPANYE_DEFAULT,
  daftarCabang = CABANG_DEFAULT,
  onSimpan,
  onUbahStatus,
  onKembali,
}: KampanyeProps) {
  const [daftarKampanye, setDaftarKampanye] = useState<DataKampanyeAdmin[]>(daftarKampanyeAwal)
  const [modalBuka, setModalBuka] = useState(false)
  const [sedangSimpan, setSedangSimpan] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [filterStatus, setFilterStatus] = useState<'semua' | 'aktif' | 'nonaktif'>('semua')

  // State Formulir
  const [editId, setEditId] = useState<string | null>(null)
  const [nama, setNama] = useState('')
  const [kodeKampanye, setKodeKampanye] = useState('')
  const [jenis, setJenis] = useState<'persen' | 'nominal'>('persen')
  const [nilai, setNilai] = useState<number>(10)
  const [minBelanja, setMinBelanja] = useState<number>(0)
  const [maksPotongan, setMaksPotongan] = useState<number | null>(20000)
  const [mulai, setMulai] = useState<string>(new Date().toISOString().slice(0, 10))
  const [selesai, setSelesai] = useState<string>(
    new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
  )
  const [kuota, setKuota] = useState<number>(100)
  const [anggaranMaks, setAnggaranMaks] = useState<number>(2000000)
  const [semuaCabang, setSemuaCabang] = useState<boolean>(true)
  const [cabangTerpilih, setCabangTerpilih] = useState<string[]>([])
  const [aktif, setAktif] = useState<boolean>(true)

  const bukaFormTambah = () => {
    setEditId(null)
    setNama('')
    setKodeKampanye('')
    setJenis('persen')
    setNilai(10)
    setMinBelanja(0)
    setMaksPotongan(20000)
    setMulai(new Date().toISOString().slice(0, 10))
    setSelesai(new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10))
    setKuota(100)
    setAnggaranMaks(2000000)
    setSemuaCabang(true)
    setCabangTerpilih([])
    setAktif(true)
    setPesanGalat(null)
    setModalBuka(true)
  }

  const bukaFormEdit = (kmp: DataKampanyeAdmin) => {
    setEditId(kmp.id)
    setNama(kmp.nama)
    setKodeKampanye(kmp.kode_kampanye)
    setJenis(kmp.jenis)
    setNilai(kmp.nilai)
    setMinBelanja(kmp.min_belanja)
    setMaksPotongan(kmp.maks_potongan)
    setMulai(kmp.mulai ? kmp.mulai.slice(0, 10) : new Date().toISOString().slice(0, 10))
    setSelesai(
      kmp.selesai
        ? kmp.selesai.slice(0, 10)
        : new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
    )
    setKuota(kmp.kuota)
    setAnggaranMaks(kmp.anggaran_maks)
    const cbg = Array.isArray(kmp.cabang_berlaku) ? kmp.cabang_berlaku : []
    const cbgIds = cbg.map((item) => (typeof item === 'string' ? item : item.id))
    setSemuaCabang(cbgIds.length === 0)
    setCabangTerpilih(cbgIds)
    setAktif(kmp.aktif)
    setPesanGalat(null)
    setModalBuka(true)
  }

  const tanganiToggleCabang = (id: string) => {
    setCabangTerpilih((prev) =>
      prev.includes(id) ? prev.filter((item) => item !== id) : [...prev, id],
    )
  }

  const tanganiSimpan = async () => {
    setPesanGalat(null)
    const namaBersih = nama.trim()
    const kodeBersih = kodeKampanye.trim().toUpperCase()

    // Validasi aturan mustahil
    if (!namaBersih) {
      setPesanGalat('Nama kampanye tidak boleh kosong.')
      return
    }

    if (!kodeBersih || kodeBersih.length < 3) {
      setPesanGalat('Kode kampanye minimal 3 karakter huruf/angka.')
      return
    }

    if (jenis === 'persen' && (nilai <= 0 || nilai > 100)) {
      setPesanGalat('Diskon persen harus antara 1% sampai 100%.')
      return
    }

    if (jenis === 'nominal' && nilai <= 0) {
      setPesanGalat('Nilai potongan nominal harus lebih besar dari Rp0.')
      return
    }

    if (minBelanja < 0) {
      setPesanGalat('Minimal belanja tidak boleh kurang dari Rp0.')
      return
    }

    if (jenis === 'persen' && maksPotongan !== null && maksPotongan <= 0) {
      setPesanGalat('Batas maksimal potongan untuk persen harus lebih besar dari Rp0.')
      return
    }

    if (!selesai || new Date(selesai) <= new Date(mulai)) {
      setPesanGalat('Tanggal selesai promo harus sesudah tanggal mulai.')
      return
    }

    if (kuota <= 0) {
      setPesanGalat('Kuota voucher harus lebih besar dari 0.')
      return
    }

    if (anggaranMaks <= 0) {
      setPesanGalat('Anggaran maksimal kampanye harus lebih besar dari Rp0.')
      return
    }

    if (jenis === 'nominal' && anggaranMaks < nilai) {
      setPesanGalat('Anggaran kampanye tidak boleh lebih kecil dari nilai voucher tunggal.')
      return
    }

    const payload: Omit<DataKampanyeAdmin, 'id'> & { id?: string } = {
      ...(editId ? { id: editId } : {}),
      nama: namaBersih,
      kode_kampanye: kodeBersih,
      jenis,
      nilai,
      min_belanja: minBelanja,
      maks_potongan: jenis === 'persen' ? maksPotongan : null,
      mulai: new Date(mulai).toISOString(),
      selesai: new Date(`${selesai}T23:59:59Z`).toISOString(),
      kuota,
      anggaran_maks: anggaranMaks,
      cabang_berlaku: semuaCabang ? [] : cabangTerpilih,
      aktif,
    }

    setSedangSimpan(true)
    try {
      const res = await onSimpan?.(payload)
      if (res && !res.berhasil) {
        setPesanGalat(res.pesan ?? 'Gagal menyimpan kampanye.')
        return
      }

      // Perbarui state lokal
      if (editId) {
        setDaftarKampanye((prev) =>
          prev.map((item) =>
            item.id === editId
              ? {
                  ...item,
                  ...payload,
                  pratinjau_aturan: formatPratinjauAturan({
                    jenis,
                    nilai,
                    min_belanja: minBelanja,
                    maks_potongan: jenis === 'persen' ? maksPotongan : null,
                    selesai,
                    kuota,
                    semuaCabang,
                    jumlahCabang: cabangTerpilih.length,
                  }).kalimat,
                }
              : item,
          ),
        )
        setPesanSukses(`Kampanye "${namaBersih}" berhasil diperbarui.`)
      } else {
        const itemBaru: DataKampanyeAdmin = {
          id: `kmp-${Date.now()}`,
          ...payload,
          dibuat_pada: new Date().toISOString(),
          jumlah_terbit: 0,
          jumlah_terpakai: 0,
          sisa_kuota: kuota,
          status_waktu: 'berjalan',
          pratinjau_aturan: formatPratinjauAturan({
            jenis,
            nilai,
            min_belanja: minBelanja,
            maks_potongan: jenis === 'persen' ? maksPotongan : null,
            selesai,
            kuota,
            semuaCabang,
            jumlahCabang: cabangTerpilih.length,
          }).kalimat,
        }
        setDaftarKampanye((prev) => [itemBaru, ...prev])
        setPesanSukses(`Kampanye baru "${namaBersih}" berhasil dibuat.`)
      }

      setModalBuka(false)
    } finally {
      setSedangSimpan(false)
    }
  }

  const tanganiUbahStatusAktif = async (kmp: DataKampanyeAdmin) => {
    const statusBaru = !kmp.aktif
    const res = await onUbahStatus?.(kmp.id, statusBaru)
    if (res && !res.berhasil) {
      setPesanGalat(res.pesan ?? 'Gagal mengubah status kampanye.')
      return
    }

    setDaftarKampanye((prev) =>
      prev.map((item) => (item.id === kmp.id ? { ...item, aktif: statusBaru } : item)),
    )
    setPesanSukses(
      `Kampanye "${kmp.nama}" ${statusBaru ? 'diaktifkan kembali.' : 'dinonaktifkan.'}`,
    )
  }

  // Hitung pratinjau reaktif formulir
  const pratinjau = formatPratinjauAturan({
    jenis,
    nilai,
    min_belanja: minBelanja,
    maks_potongan: jenis === 'persen' ? maksPotongan : null,
    selesai,
    kuota,
    semuaCabang,
    jumlahCabang: cabangTerpilih.length,
  })

  // Saring daftar kampanye
  const daftarTersaring = daftarKampanye.filter((item) => {
    if (filterStatus === 'aktif') return item.aktif
    if (filterStatus === 'nonaktif') return !item.aktif
    return true
  })

  return (
    <div className="pengaturan-kampanye" data-testid="pengaturan-kampanye">
      {/* Kepala Halaman */}
      <div className="pengaturan-kampanye__kepala">
        <div>
          <h2>🎟️ Pengaturan Kampanye Voucher</h2>
          <p className="small muted">
            Atur program promosi dan aturan diskon voucher pelanggan tanpa koding (PRD M10 & M2).
          </p>
        </div>
        <div style={{ display: 'flex', gap: 'var(--s-2)', alignItems: 'center' }}>
          {onKembali && (
            <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke menu pengaturan">
              ⬅️ Kembali
            </Tombol>
          )}
          <Tombol ragam="utama" onClick={bukaFormTambah} nama="Buat kampanye baru">
            ➕ Buat Kampanye Baru
          </Tombol>
        </div>
      </div>

      {/* Notifikasi Pesan Sukses / Galat */}
      {pesanSukses && (
        <div
          data-testid="notif-sukses"
          style={{
            padding: 'var(--s-2)',
            background: 'var(--surface-2)',
            border: '1px solid var(--success)',
            borderRadius: 'var(--radius)',
            color: 'var(--success)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span>{pesanSukses}</span>
          <Tombol ragam="kecil" onClick={() => setPesanSukses(null)} nama="Tutup pesan sukses">
            ✕
          </Tombol>
        </div>
      )}

      {/* Filter Status Kampanye */}
      <div style={{ display: 'flex', gap: 'var(--s-1)', alignItems: 'center' }}>
        <span className="small muted">Status:</span>
        <Tombol
          ragam={filterStatus === 'semua' ? 'utama' : 'kecil'}
          onClick={() => setFilterStatus('semua')}
          nama="Filter semua"
        >
          Semua ({daftarKampanye.length})
        </Tombol>
        <Tombol
          ragam={filterStatus === 'aktif' ? 'utama' : 'kecil'}
          onClick={() => setFilterStatus('aktif')}
          nama="Filter aktif"
        >
          Aktif ({daftarKampanye.filter((k) => k.aktif).length})
        </Tombol>
        <Tombol
          ragam={filterStatus === 'nonaktif' ? 'utama' : 'kecil'}
          onClick={() => setFilterStatus('nonaktif')}
          nama="Filter nonaktif"
        >
          Nonaktif ({daftarKampanye.filter((k) => !k.aktif).length})
        </Tombol>
      </div>

      {/* Daftar Kampanye */}
      <div className="pengaturan-kampanye__daftar" data-testid="daftar-kampanye">
        {daftarTersaring.length === 0 ? (
          <Kartu>
            <p className="muted" style={{ textAlign: 'center', padding: 'var(--s-4)' }}>
              Belum ada kampanye voucher pada kategori ini.
            </p>
          </Kartu>
        ) : (
          daftarTersaring.map((kmp) => (
            <div
              key={kmp.id}
              className="pengaturan-kampanye__kartu"
              data-testid={`kampanye-kartu-${kmp.kode_kampanye}`}
            >
              <div className="pengaturan-kampanye__kartu-kepala">
                <div>
                  <h3 style={{ margin: 0 }}>{kmp.nama}</h3>
                  <span
                    className="small"
                    style={{ fontFamily: 'var(--font-mono, monospace)', fontWeight: 600 }}
                  >
                    Kode: {kmp.kode_kampanye}
                  </span>
                </div>
                <div style={{ display: 'flex', gap: 'var(--s-1)', alignItems: 'center' }}>
                  <Lencana nada={kmp.aktif ? 'success' : 'danger'}>
                    {kmp.aktif ? 'Aktif' : 'Nonaktif'}
                  </Lencana>
                  <Lencana nada="info">
                    {kmp.jenis === 'persen' ? `Diskon ${kmp.nilai}%` : rupiah(kmp.nilai)}
                  </Lencana>
                </div>
              </div>

              {/* Pratinjau Kalimat Aturan Manusia */}
              <p
                className="small"
                data-testid={`pratinjau-${kmp.kode_kampanye}`}
                style={{ margin: 0, color: 'var(--text-muted)' }}
              >
                {kmp.pratinjau_aturan ||
                  formatPratinjauAturan({
                    jenis: kmp.jenis,
                    nilai: kmp.nilai,
                    min_belanja: kmp.min_belanja,
                    maks_potongan: kmp.maks_potongan,
                    selesai: kmp.selesai,
                    kuota: kmp.kuota,
                    semuaCabang:
                      !kmp.cabang_berlaku ||
                      (Array.isArray(kmp.cabang_berlaku) && kmp.cabang_berlaku.length === 0),
                    jumlahCabang: Array.isArray(kmp.cabang_berlaku) ? kmp.cabang_berlaku.length : 0,
                  }).kalimat}
              </p>

              {/* Rincian Statistik Serapan */}
              <div className="pengaturan-kampanye__kartu-statistik">
                <div>
                  <span className="small muted">Kuota:</span> <strong>{kmp.kuota} voucher</strong>
                </div>
                <div>
                  <span className="small muted">Terklaim:</span>{' '}
                  <strong>{kmp.jumlah_terbit ?? 0}</strong>
                </div>
                <div>
                  <span className="small muted">Terpakai:</span>{' '}
                  <strong>{kmp.jumlah_terpakai ?? 0}</strong>
                </div>
                <div>
                  <span className="small muted">Sisa Kuota:</span>{' '}
                  <strong>{kmp.sisa_kuota ?? kmp.kuota - (kmp.jumlah_terbit ?? 0)}</strong>
                </div>
              </div>

              {/* Tombol Aksi Kartu */}
              <div className="pengaturan-kampanye__kartu-aksi">
                <Tombol
                  ragam="kecil"
                  onClick={() => tanganiUbahStatusAktif(kmp)}
                  nama={`Ubah status ${kmp.kode_kampanye}`}
                >
                  {kmp.aktif ? '⏸️ Nonaktifkan' : '▶️ Aktifkan'}
                </Tombol>
                <Tombol
                  ragam="kecil"
                  onClick={() => bukaFormEdit(kmp)}
                  nama={`Edit kampanye ${kmp.kode_kampanye}`}
                >
                  ✏️ Edit Aturan
                </Tombol>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Modal Formulir Tambah / Edit Kampanye */}
      {modalBuka && (
        <Lapis
          buka={modalBuka}
          onTutup={() => setModalBuka(false)}
          judul={editId ? '✏️ Edit Kampanye Voucher' : '➕ Buat Kampanye Voucher Baru'}
        >
          <div className="pengaturan-kampanye__form" data-testid="form-kampanye">
            {/* Pesan Galat Validasi */}
            {pesanGalat && (
              <p
                className="small"
                data-testid="form-pesan-galat"
                style={{ color: 'var(--danger)', margin: 0 }}
              >
                {pesanGalat}
              </p>
            )}

            <KolomIsian
              label="Nama Kampanye"
              jenis="text"
              nilai={nama}
              onUbah={setNama}
              contoh="Mis. Promo Akhir Pekan Hemat 20%"
              wajib
            />

            <KolomIsian
              label="Kode Promo Pelanggan"
              jenis="text"
              nilai={kodeKampanye}
              onUbah={(val) => setKodeKampanye(val.toUpperCase())}
              contoh="Mis. HEMAT20 atau PROMO10K"
              wajib
              keterangan="Kode unik huruf besar/angka yang diketik atau dipindai pelanggan/kasir."
            />

            {/* Pilihan Jenis Diskon */}
            <div>
              <span className="label">Jenis Promo *</span>
              <div style={{ display: 'flex', gap: 'var(--s-2)', marginTop: 'var(--s-1)' }}>
                <Tombol
                  ragam={jenis === 'persen' ? 'utama' : 'biasa'}
                  onClick={() => {
                    setJenis('persen')
                    if (nilai > 100) setNilai(20)
                    if (maksPotongan === null) setMaksPotongan(20000)
                  }}
                  nama="Pilih jenis persen"
                >
                  % Persentase
                </Tombol>
                <Tombol
                  ragam={jenis === 'nominal' ? 'utama' : 'biasa'}
                  onClick={() => {
                    setJenis('nominal')
                    setMaksPotongan(null)
                    if (nilai <= 100) setNilai(20000)
                  }}
                  nama="Pilih jenis nominal"
                >
                  Rp Nominal Tunai
                </Tombol>
              </div>
            </div>

            {/* Nilai Diskon */}
            <KolomIsian
              label={jenis === 'persen' ? 'Besar Diskon (%)' : 'Besar Potongan (Rp)'}
              jenis="number"
              nilai={String(nilai)}
              onUbah={(val) => setNilai(Number(val) || 0)}
              contoh={jenis === 'persen' ? 'Mis. 20' : 'Mis. 25000'}
              wajib
              keterangan={
                jenis === 'persen'
                  ? 'Masukkan angka 1 sampai 100.'
                  : 'Masukkan nilai potongan dalam rupiah.'
              }
            />

            {/* Minimal Belanja */}
            <KolomIsian
              label="Syarat Minimal Belanja (Rp)"
              jenis="number"
              nilai={String(minBelanja)}
              onUbah={(val) => setMinBelanja(Number(val) || 0)}
              contoh="Mis. 50000 (isi 0 jika tanpa batas)"
              keterangan="Subtotal pesanan yang harus dicapai pelanggan untuk dapat menggunakan voucher."
            />

            {/* Plafon Maksimal Potongan (Hanya untuk Persen) */}
            {jenis === 'persen' && (
              <KolomIsian
                label="Batas Maksimal Potongan (Rp, opsional)"
                jenis="number"
                nilai={maksPotongan ? String(maksPotongan) : ''}
                onUbah={(val) => setMaksPotongan(val ? Number(val) : null)}
                contoh="Mis. 20000 (kosongkan jika tanpa batas maksimal)"
                keterangan="Plafon pengaman agar diskon persen pada tagihan besar tidak merugikan resto."
              />
            )}

            {/* Masa Berlaku (Mulai & Selesai) */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--s-2)' }}>
              <KolomIsian
                label="Tanggal Mulai"
                jenis="date"
                nilai={mulai}
                onUbah={setMulai}
                wajib
              />
              <KolomIsian
                label="Tanggal Selesai"
                jenis="date"
                nilai={selesai}
                onUbah={setSelesai}
                wajib
              />
            </div>

            {/* Kuota & Anggaran */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 'var(--s-2)' }}>
              <KolomIsian
                label="Kuota Voucher"
                jenis="number"
                nilai={String(kuota)}
                onUbah={(val) => setKuota(Number(val) || 0)}
                contoh="Mis. 100"
                wajib
                keterangan="Jumlah maksimal voucher yang dapat diklaim."
              />
              <KolomIsian
                label="Anggaran Maksimal (Rp)"
                jenis="number"
                nilai={String(anggaranMaks)}
                onUbah={(val) => setAnggaranMaks(Number(val) || 0)}
                contoh="Mis. 2000000"
                wajib
                keterangan="Total anggaran dana promo."
              />
            </div>

            {/* Pilihan Cabang Berlaku */}
            <div>
              <span className="label">Cabang Berlaku</span>
              <div style={{ display: 'flex', gap: 'var(--s-2)', marginTop: 'var(--s-1)' }}>
                <Tombol
                  ragam={semuaCabang ? 'utama' : 'kecil'}
                  onClick={() => {
                    setSemuaCabang(true)
                    setCabangTerpilih([])
                  }}
                  nama="Berlaku semua cabang"
                >
                  Semua Cabang
                </Tombol>
                <Tombol
                  ragam={!semuaCabang ? 'utama' : 'kecil'}
                  onClick={() => setSemuaCabang(false)}
                  nama="Pilih cabang spesifik"
                >
                  Pilih Cabang Tertentu
                </Tombol>
              </div>

              {!semuaCabang && (
                <div
                  style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 'var(--s-1)',
                    marginTop: 'var(--s-2)',
                    padding: 'var(--s-2)',
                    background: 'var(--surface-2)',
                    borderRadius: 'var(--radius-sm)',
                  }}
                >
                  {daftarCabang.map((cbg) => (
                    <label
                      key={cbg.id}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 'var(--s-2)',
                        cursor: 'pointer',
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={cabangTerpilih.includes(cbg.id)}
                        onChange={() => tanganiToggleCabang(cbg.id)}
                      />
                      <span>{cbg.nama}</span>
                    </label>
                  ))}
                </div>
              )}
            </div>

            {/* Kotak Pratinjau Aturan Bahasa Manusia Real-Time */}
            <div className="pengaturan-kampanye__pratinjau" data-testid="pratinjau-aturan-form">
              <span className="label" style={{ color: 'var(--accent)', fontWeight: 600 }}>
                📢 Pratinjau Aturan Bahasa Manusia:
              </span>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontWeight: 600,
                  fontSize: 'var(--t-2)',
                }}
              >
                {pratinjau.kalimat}
              </p>
              <p
                className="pengaturan-kampanye__pratinjau-simulasi small"
                style={{ color: 'var(--text-muted)' }}
              >
                {pratinjau.simulasi}
              </p>
            </div>

            {/* Tombol Aksi Bawah */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 'var(--s-2)' }}>
              <Tombol ragam="biasa" onClick={() => setModalBuka(false)} nama="Batal simpan">
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                onClick={tanganiSimpan}
                nonaktif={sedangSimpan}
                nama="Simpan aturan kampanye"
              >
                {sedangSimpan ? 'Menyimpan...' : editId ? 'Simpan Perubahan' : 'Buat Kampanye'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
