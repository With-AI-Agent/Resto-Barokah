/**
 * KasKeluarMasuk — Modal Pencatatan Kas Masuk, Kas Keluar, Setoran, dan Koreksi (T7-03).
 *
 * Mengikuti aturan PRD M7 dan TECH_SPEC §4.3 & §9 ART-6:
 *  - Mencatat uang tunai masuk (tambahan modal/receh) dan uang tunai keluar
 *    (belanja mendadak, es batu, kasbon, setoran ke brankas/bank).
 *  - Alasan wajib diisi (bukan string kosong).
 *  - Jumlah uang wajib positif (> 0).
 *  - Pergerakan kas kekal dan masuk ke perhitungan uang seharusnya saat tutup shift.
 *  - Komponen murni antarmuka: bebas tombol liar (peta-ui.py Aturan 7).
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import { useBahasa } from '../../bahasa'

export type JenisPergerakanKas = 'masuk' | 'keluar' | 'setoran' | 'koreksi'

export interface KasPergerakanInput {
  jenis: JenisPergerakanKas
  jumlah: number
  alasan: string
  shiftId?: string
  cabangId?: string
  disetujuiOleh?: string
  kunciIdempoten?: string
}

export interface HasilKasPergerakan {
  sukses: boolean
  pesan?: string
  data?: {
    id: string
    shiftId: string
    cabangId: string
    jenis: JenisPergerakanKas
    jumlah: number
    alasan: string
    pelakuId: string
    disetujuiOleh?: string | null
    dibuatPada: string
  }
}

export interface KasKeluarMasukProps {
  shiftId?: string
  cabangId?: string
  namaCabang?: string
  namaKasir?: string
  onSimpan: (data: KasPergerakanInput) => Promise<HasilKasPergerakan> | HasilKasPergerakan
  onBatal?: () => void
  onTutup?: () => void
}

const SARAN_ALASAN: Record<JenisPergerakanKas, string[]> = {
  keluar: [
    'Beli es batu kristal',
    'Beli gas LPG mendadak',
    'Belanja bumbu / sayur segar',
    'Kasbon staf disetujui',
    'Biaya darurat operasional',
  ],
  masuk: ['Tambah uang kembalian / receh', 'Tambah modal laci kasir', 'Pengembalian sisa belanja'],
  setoran: ['Setoran berkala ke brankas owner', 'Setoran tunai ke bank'],
  koreksi: ['Koreksi uang receh terselip pasca-tutup', 'Koreksi pembulatan / hitung fisik'],
}

const NOMINAL_CEPAT = [10000, 20000, 50000, 100000, 500000]

export function KasKeluarMasuk({
  shiftId,
  cabangId,
  namaCabang,
  namaKasir,
  onSimpan,
  onBatal,
  onTutup,
}: KasKeluarMasukProps) {
  const { t } = useBahasa()

  const [jenis, setJenis] = useState<JenisPergerakanKas>('keluar')
  const [jumlah, setJumlah] = useState<number>(0)
  const [alasan, setAlasan] = useState<string>('')
  const [disetujuiOleh, setDisetujuiOleh] = useState<string>('')
  const [memproses, setMemproses] = useState(false)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [suksesData, setSuksesData] = useState<HasilKasPergerakan['data'] | null>(null)

  const tanganiUbahJumlah = (val: string) => {
    const angka = parseInt(val.replace(/\D/g, ''), 10)
    setJumlah(isNaN(angka) ? 0 : angka)
    setPesanGalat(null)
  }

  const tambahNominalCepat = (tambah: number) => {
    setJumlah((prev) => prev + tambah)
    setPesanGalat(null)
  }

  const pilihSaranAlasan = (saran: string) => {
    setAlasan(saran)
    setPesanGalat(null)
  }

  const tanganiKirim = async (e: React.FormEvent) => {
    e.preventDefault()

    if (jumlah <= 0) {
      setPesanGalat('Jumlah uang wajib lebih besar dari Rp0.')
      return
    }

    if (!alasan.trim()) {
      setPesanGalat(t('kasir.alasan_kas') + ' tidak boleh kosong.')
      return
    }

    setMemproses(true)
    setPesanGalat(null)

    try {
      const kunciIdempoten = `kp-${shiftId || 'global'}-${Date.now()}`
      const hasil = await onSimpan({
        jenis,
        jumlah,
        alasan: alasan.trim(),
        shiftId,
        cabangId,
        disetujuiOleh: disetujuiOleh.trim() || undefined,
        kunciIdempoten,
      })

      if (hasil.sukses) {
        setSuksesData(
          hasil.data || {
            id: 'kp-' + Date.now(),
            shiftId: shiftId || '',
            cabangId: cabangId || '',
            jenis,
            jumlah,
            alasan: alasan.trim(),
            pelakuId: '',
            dibuatPada: new Date().toISOString(),
          },
        )
      } else {
        setPesanGalat(hasil.pesan || t('umum.gagal'))
      }
    } catch (err: unknown) {
      const pesan = err instanceof Error ? err.message : t('umum.gagal')
      setPesanGalat(pesan)
    } finally {
      setMemproses(false)
    }
  }

  // Tampilan bila berhasil dicatat
  if (suksesData) {
    return (
      <div className="kas-pergerakan-wadah" data-testid="layar-kas-pergerakan-sukses">
        <div style={{ textAlign: 'center', padding: 'var(--s-4) 0' }}>
          <div style={{ fontSize: '3rem', marginBottom: 'var(--s-2)' }}>✅</div>
          <h2 style={{ margin: 0, color: 'var(--text-prim)', fontSize: 'var(--teks-xl)' }}>
            {t('kasir.sukses_kas_pergerakan')}
          </h2>
          <p
            style={{
              color: 'var(--text-sec)',
              fontSize: 'var(--teks-sm)',
              marginTop: 'var(--s-1)',
            }}
          >
            Transaksi pergerakan kas telah diverifikasi dan masuk ke dalam audit keuangan.
          </p>
        </div>

        <div className="kotak-rincian-kas">
          <div className="baris-rincian">
            <span className="label-rincian">{t('kasir.jenis_kas')}</span>
            <span
              className="nilai-rincian"
              style={{ fontWeight: 700, textTransform: 'capitalize' }}
            >
              {suksesData.jenis === 'keluar' && '🔴 ' + t('kasir.kas_keluar')}
              {suksesData.jenis === 'masuk' && '🟢 ' + t('kasir.kas_masuk')}
              {suksesData.jenis === 'setoran' && '🏦 ' + t('kasir.kas_setoran')}
              {suksesData.jenis === 'koreksi' && '⚖️ ' + t('kasir.kas_koreksi')}
            </span>
          </div>

          <div className="baris-rincian">
            <span className="label-rincian">{t('kasir.nominal_kas')}</span>
            <span
              className="nilai-rincian"
              style={{
                fontSize: 'var(--teks-lg)',
                fontWeight: 800,
                color: suksesData.jenis === 'masuk' ? 'var(--success)' : 'var(--warn)',
              }}
            >
              {suksesData.jenis === 'masuk' ? '+' : '-'} {rupiah(suksesData.jumlah)}
            </span>
          </div>

          <div className="baris-rincian">
            <span className="label-rincian">{t('kasir.alasan_kas')}</span>
            <span className="nilai-rincian" style={{ fontStyle: 'italic' }}>
              &ldquo;{suksesData.alasan}&rdquo;
            </span>
          </div>

          {namaCabang && (
            <div className="baris-rincian">
              <span className="label-rincian">Cabang</span>
              <span className="nilai-rincian">{namaCabang}</span>
            </div>
          )}

          {namaKasir && (
            <div className="baris-rincian">
              <span className="label-rincian">Pencatat</span>
              <span className="nilai-rincian">{namaKasir}</span>
            </div>
          )}
        </div>

        <div style={{ marginTop: 'var(--s-4)', display: 'flex', gap: 'var(--s-2)' }}>
          <Tombol jenis="button" ragam="utama" lebar onClick={onTutup || onBatal}>
            {t('umum.selesai')}
          </Tombol>
        </div>
      </div>
    )
  }

  return (
    <div className="kas-pergerakan-wadah" data-testid="layar-kas-pergerakan">
      {/* Kepala Modal */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h2
            style={{
              margin: 0,
              fontSize: 'var(--teks-lg)',
              fontWeight: 700,
              color: 'var(--text-prim)',
            }}
          >
            💸 {t('kasir.kas_pergerakan_judul')}
          </h2>
          <p
            style={{
              margin: 'var(--s-1) 0 0',
              fontSize: 'var(--teks-xs)',
              color: 'var(--text-sec)',
            }}
          >
            {t('kasir.kas_pergerakan_petunjuk')}
          </p>
        </div>
        {(onTutup || onBatal) && (
          <div
            role="button"
            tabIndex={0}
            onClick={onTutup || onBatal}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                ;(onTutup || onBatal)?.()
              }
            }}
            aria-label={t('umum.tutup')}
            style={{
              cursor: 'pointer',
              padding: 'var(--s-1) var(--s-2)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--teks-sm)',
              color: 'var(--text-ter)',
            }}
          >
            ✕
          </div>
        )}
      </div>

      <form
        onSubmit={tanganiKirim}
        style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-4)' }}
      >
        {/* Pilihan Jenis Pergerakan */}
        <div>
          <label
            style={{
              display: 'block',
              fontSize: 'var(--teks-xs)',
              fontWeight: 600,
              color: 'var(--text-sec)',
              marginBottom: 'var(--s-2)',
            }}
          >
            {t('kasir.jenis_kas')}
          </label>
          <div className="opsi-jenis-grid">
            <div
              role="button"
              tabIndex={0}
              className={`opsi-jenis-btn ${jenis === 'keluar' ? 'opsi-jenis-btn--aktif' : ''}`}
              onClick={() => {
                setJenis('keluar')
                setPesanGalat(null)
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') setJenis('keluar')
              }}
              data-testid="pilih-jenis-keluar"
            >
              <span>🔴 Kas Keluar</span>
              <span style={{ fontSize: 'var(--teks-xs)', fontWeight: 400, opacity: 0.8 }}>
                Operasional / Belanja
              </span>
            </div>

            <div
              role="button"
              tabIndex={0}
              className={`opsi-jenis-btn ${jenis === 'masuk' ? 'opsi-jenis-btn--aktif' : ''}`}
              onClick={() => {
                setJenis('masuk')
                setPesanGalat(null)
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') setJenis('masuk')
              }}
              data-testid="pilih-jenis-masuk"
            >
              <span>🟢 Kas Masuk</span>
              <span style={{ fontSize: 'var(--teks-xs)', fontWeight: 400, opacity: 0.8 }}>
                Tambah Modal / Receh
              </span>
            </div>

            <div
              role="button"
              tabIndex={0}
              className={`opsi-jenis-btn ${jenis === 'setoran' ? 'opsi-jenis-btn--aktif' : ''}`}
              onClick={() => {
                setJenis('setoran')
                setPesanGalat(null)
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') setJenis('setoran')
              }}
              data-testid="pilih-jenis-setoran"
            >
              <span>🏦 Setoran</span>
              <span style={{ fontSize: 'var(--teks-xs)', fontWeight: 400, opacity: 0.8 }}>
                Ke Brankas / Bank
              </span>
            </div>

            <div
              role="button"
              tabIndex={0}
              className={`opsi-jenis-btn ${jenis === 'koreksi' ? 'opsi-jenis-btn--aktif' : ''}`}
              onClick={() => {
                setJenis('koreksi')
                setPesanGalat(null)
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') setJenis('koreksi')
              }}
              data-testid="pilih-jenis-koreksi"
            >
              <span>⚖️ Koreksi</span>
              <span style={{ fontSize: 'var(--teks-xs)', fontWeight: 400, opacity: 0.8 }}>
                Pasca-Tutup Kasir
              </span>
            </div>
          </div>
        </div>

        {/* Kolom Isian Jumlah */}
        <div>
          <KolomIsian
            label={t('kasir.nominal_kas')}
            nilai={jumlah > 0 ? rupiah(jumlah) : ''}
            contoh="Rp0"
            onUbah={tanganiUbahJumlah}
            wajib
          />

          {/* Tombol Nominal Cepat */}
          <div
            style={{
              display: 'flex',
              gap: 'var(--s-1)',
              flexWrap: 'wrap',
              marginTop: 'var(--s-2)',
            }}
          >
            {NOMINAL_CEPAT.map((nominal) => (
              <div
                key={nominal}
                role="button"
                tabIndex={0}
                onClick={() => tambahNominalCepat(nominal)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') tambahNominalCepat(nominal)
                }}
                style={{
                  cursor: 'pointer',
                  padding: 'var(--s-1) var(--s-2)',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px solid var(--border)',
                  background: 'var(--surface-alt)',
                  color: 'var(--text-sec)',
                  fontSize: 'var(--teks-xs)',
                  fontWeight: 600,
                }}
              >
                +{rupiah(nominal)}
              </div>
            ))}
            <div
              role="button"
              tabIndex={0}
              onClick={() => setJumlah(0)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') setJumlah(0)
              }}
              style={{
                cursor: 'pointer',
                padding: 'var(--s-1) var(--s-2)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
                background: 'var(--surface-alt)',
                color: 'var(--warn)',
                fontSize: 'var(--teks-xs)',
                fontWeight: 600,
              }}
            >
              Reset
            </div>
          </div>
        </div>

        {/* Kolom Alasan Wajib */}
        <div>
          <KolomIsian
            label={t('kasir.alasan_kas')}
            nilai={alasan}
            contoh={t('kasir.alasan_kas_placeholder')}
            onUbah={(val) => {
              setAlasan(val)
              setPesanGalat(null)
            }}
            wajib
          />

          {/* Saran Alasan Cepat */}
          <div
            style={{
              display: 'flex',
              gap: 'var(--s-1)',
              flexWrap: 'wrap',
              marginTop: 'var(--s-2)',
            }}
          >
            {SARAN_ALASAN[jenis].map((saran) => (
              <div
                key={saran}
                role="button"
                tabIndex={0}
                onClick={() => pilihSaranAlasan(saran)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') pilihSaranAlasan(saran)
                }}
                style={{
                  cursor: 'pointer',
                  padding: 'var(--s-1) var(--s-2)',
                  borderRadius: 'var(--radius-sm)',
                  border: '1px dashed var(--border)',
                  background: 'var(--surface-alt)',
                  color: 'var(--text-sec)',
                  fontSize: 'var(--teks-xs)',
                }}
              >
                {saran}
              </div>
            ))}
          </div>
        </div>

        {/* Kolom Disetujui Oleh (Opsional) */}
        <KolomIsian
          label={t('kasir.disetujui_oleh_label')}
          nilai={disetujuiOleh}
          contoh="Nama atasan / supervisor yang memberi izin..."
          onUbah={(val) => setDisetujuiOleh(val)}
        />

        {/* Pesan Kesalahan */}
        {pesanGalat && (
          <div role="alert" className="kotak-galat">
            ⚠️ {pesanGalat}
          </div>
        )}

        {/* Tombol Aksi */}
        <div style={{ display: 'flex', gap: 'var(--s-2)', marginTop: 'var(--s-2)' }}>
          {onBatal && (
            <Tombol jenis="button" ragam="biasa" onClick={onBatal} nonaktif={memproses}>
              {t('umum.batal')}
            </Tombol>
          )}
          <Tombol
            jenis="submit"
            ragam="utama"
            lebar
            nonaktif={memproses || jumlah <= 0 || !alasan.trim()}
          >
            {memproses ? t('umum.memproses') : t('kasir.simpan_kas')}
          </Tombol>
        </div>
      </form>
    </div>
  )
}
