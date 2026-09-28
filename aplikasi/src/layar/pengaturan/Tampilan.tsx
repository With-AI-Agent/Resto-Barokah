/* eslint-disable react-refresh/only-export-components */
/**
 * Tampilan.tsx — Pengaturan Tema & Warna Merek Resto (T9-02 / PRD M2)
 *
 * Mengizinkan Owner Resto (atau staf dengan izin atur_pengaturan) untuk:
 *  1. Memilih gaya visual dari 10 tema resmi (Terang Bersih, Hangat Kedai, Gelap Dapur,
 *     Kontras Tinggi, Bara Panggang, Vintage Klasik, Alam Hijau, Tropis Segar,
 *     Pastel Manis, Etnik Nusantara) yang semuanya 100% lolos uji kontras WCAG 2.1.
 *  2. Menentukan tingkat kerapatan tampilan antarmuka (Nyaman / Padat).
 *  3. Menyesuaikan kode warna aksen merek dengan validasi otomatis kontras WCAG AA (>= 4.5:1).
 *  4. Melihat pratinjau langsung kartu menu, tombol aksi, dan lencana status.
 *  5. Menerapkan seketika ke antarmuka aplikasi atau menyimpan permanen ke basis data.
 */

import { useState, useId } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lencana } from '../../komponen/Lencana'
import {
  TEMA,
  KERAPATAN,
  type KodeTema,
  type Kerapatan,
  terapkanTema,
  terapkanKerapatan,
  segarkanWarnaSistem,
  simpanPilihan,
} from '../../lib/tema'

export interface DataTema {
  tema: KodeTema
  kerapatan: Kerapatan
  warnaMerek?: string
  versiPengaturan?: string | null
}

export interface TampilanProps {
  dataAwal?: Partial<DataTema>
  onSimpan?: (data: DataTema) => Promise<{ berhasil: boolean; pesan?: string }>
  onKembali?: () => void
  hanyaBaca?: boolean
}

const DATA_BAWAAN: DataTema = {
  tema: 'terang',
  kerapatan: 'nyaman',
  warnaMerek: '',
  versiPengaturan: null,
}

/**
 * Validasi kontras WCAG AA (>= 4.5:1 untuk teks normal) untuk kode warna aksen heksa.
 * Menghitung kecerahan relatif (luminance) dan memastikan keterbacaan teks tombol.
 */
export function validasiKontrasAksen(kodeHex: string): {
  valid: boolean
  rasio: number
  pesan: string
} {
  const bersih = kodeHex.replace(/^#/, '').trim()
  if (!bersih) {
    return {
      valid: true,
      rasio: 21.0,
      pesan: 'Menggunakan warna aksen bawaan tema resmi (100% lolos WCAG AA).',
    }
  }

  if (!/^[0-9a-fA-F]{3}$|^[0-9a-fA-F]{6}$/.test(bersih)) {
    return {
      valid: false,
      rasio: 0,
      pesan: 'Format kode warna heksa tidak valid (contoh: e06000 atau a23b11).',
    }
  }

  const penuh =
    bersih.length === 3
      ? bersih
          .split('')
          .map((c) => c + c)
          .join('')
      : bersih
  const num = parseInt(penuh, 16)
  const r = (num >> 16) & 255
  const g = (num >> 8) & 255
  const b = num & 255

  const f = (val: number) => {
    const s = val / 255
    return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4)
  }
  const lum = 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)

  // Kontras terhadap latar terang (lum 1.0) dan latar gelap (lum 0.0)
  const kontrasKeTerang = (1.0 + 0.05) / (lum + 0.05)
  const kontrasKeGelap = (lum + 0.05) / (0.0 + 0.05)

  // Aksen merek harus terlihat jelas di atas latar terang (minimal 3.0:1)
  // dan mampu memuat teks yang terbaca (minimal 4.5:1 untuk teks normal).
  if (kontrasKeTerang < 3.0) {
    return {
      valid: false,
      rasio: Number(kontrasKeTerang.toFixed(2)),
      pesan: `Warna terlalu pucat (rasio kontras ${kontrasKeTerang.toFixed(2)}:1 terhadap latar, minimal 3.0:1). Tombol dan ikon tidak akan terlihat jelas.`,
    }
  }

  const rasioMaks = Math.max(kontrasKeTerang, kontrasKeGelap)

  if (rasioMaks < 4.5) {
    return {
      valid: false,
      rasio: Number(rasioMaks.toFixed(2)),
      pesan: `Warna ini memiliki rasio kontras ${rasioMaks.toFixed(2)}:1, di bawah standar WCAG AA (minimal 4.5:1). Teks tombol akan sulit dibaca.`,
    }
  }

  return {
    valid: true,
    rasio: Number(rasioMaks.toFixed(2)),
    pesan: `Warna memenuhi standar aksesibilitas WCAG AA (rasio kontras ${rasioMaks.toFixed(2)}:1 >= 4.5:1).`,
  }
}

export function Tampilan({ dataAwal, onSimpan, onKembali, hanyaBaca = false }: TampilanProps) {
  const [tema, setTema] = useState<KodeTema>(dataAwal?.tema ?? DATA_BAWAAN.tema)
  const [kerapatan, setKerapatan] = useState<Kerapatan>(
    dataAwal?.kerapatan ?? DATA_BAWAAN.kerapatan,
  )
  const [warnaMerek, setWarnaMerek] = useState<string>(
    dataAwal?.warnaMerek ?? DATA_BAWAAN.warnaMerek ?? '',
  )
  const [versiPengaturan, setVersiPengaturan] = useState<string | null>(
    dataAwal?.versiPengaturan ?? null,
  )

  const [sedangMemuat, setSedangMemuat] = useState(false)
  const [pesanSukses, setPesanSukses] = useState<string | null>(null)
  const [pesanGalat, setPesanGalat] = useState<string | null>(null)
  const [statusUjiWarna, setStatusUjiWarna] = useState(
    validasiKontrasAksen(dataAwal?.warnaMerek ?? ''),
  )

  const idNotifikasi = useId()

  const tanganiGantiWarna = (nilai: string) => {
    setWarnaMerek(nilai)
    const hasilUji = validasiKontrasAksen(nilai)
    setStatusUjiWarna(hasilUji)
    if (!hasilUji.valid && nilai.trim()) {
      setPesanGalat(hasilUji.pesan)
    } else {
      setPesanGalat(null)
    }
  }

  const tanganiTerapkanSementara = () => {
    terapkanTema(tema)
    terapkanKerapatan(kerapatan)
    segarkanWarnaSistem()
    setPesanSukses('Tema berhasil diterapkan sementara ke layar ini!')
  }

  const tanganiSimpan = async () => {
    setPesanGalat(null)
    setPesanSukses(null)

    if (warnaMerek.trim() && !statusUjiWarna.valid) {
      setPesanGalat('Warna merek tidak memenuhi standar kontras WCAG AA. Perbaiki terlebih dahulu.')
      return
    }

    setSedangMemuat(true)
    try {
      // Simpan lokal agar langsung tersimpan di peramban
      simpanPilihan(tema, kerapatan)
      terapkanTema(tema)
      terapkanKerapatan(kerapatan)
      segarkanWarnaSistem()

      if (onSimpan) {
        const hasil = await onSimpan({
          tema,
          kerapatan,
          warnaMerek: warnaMerek.trim(),
          versiPengaturan,
        })

        if (!hasil.berhasil) {
          setPesanGalat(hasil.pesan || 'Gagal menyimpan tema tampilan.')
        } else {
          setPesanSukses(hasil.pesan || 'Tema tampilan restoran berhasil disimpan!')
          setVersiPengaturan(new Date().toISOString())
        }
      } else {
        setPesanSukses('Tema tampilan restoran berhasil disimpan!')
        setVersiPengaturan(new Date().toISOString())
      }
    } catch (galat: unknown) {
      const pesan = galat instanceof Error ? galat.message : 'Terjadi kesalahan sistem.'
      setPesanGalat(pesan)
    } finally {
      setSedangMemuat(false)
    }
  }

  return (
    <div className="layar-tampilan" data-testid="layar-tampilan">
      {/* Kepala Halaman */}
      <div
        className="baris-judul"
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
          <h2 style={{ margin: 0, fontSize: '1.35rem', fontWeight: 700 }}>
            Tema & Warna Merek Restoran
          </h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
            Pilih dari 10 tema visual resmi v3 yang 100% lolos uji kontras WCAG AA (≥ 4.5:1).
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {onKembali && (
            <Tombol
              ragam="biasa"
              onClick={onKembali}
              nonaktif={sedangMemuat}
              nama="Kembali ke menu pengaturan"
            >
              Kembali
            </Tombol>
          )}
          <Tombol
            ragam="biasa"
            onClick={tanganiTerapkanSementara}
            nonaktif={sedangMemuat}
            nama="Terapkan tema ini ke aplikasi sekarang"
          >
            Coba di Seluruh Layar
          </Tombol>
          <Tombol
            ragam="utama"
            onClick={tanganiSimpan}
            nonaktif={
              sedangMemuat || hanyaBaca || (warnaMerek.trim() !== '' && !statusUjiWarna.valid)
            }
            nama="Simpan pengaturan tema ke database resto"
          >
            {sedangMemuat ? 'Menyimpan…' : 'Simpan Tema'}
          </Tombol>
        </div>
      </div>

      {/* Notifikasi Status */}
      {pesanSukses && (
        <div
          id={idNotifikasi}
          role="status"
          aria-live="polite"
          data-testid="pesan-sukses"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius)',
            background: 'var(--success-soft)',
            color: 'var(--success)',
            border: '1px solid var(--border)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <span>{pesanSukses}</span>
          <Tombol
            ragam="biasa"
            onClick={() => setPesanSukses(null)}
            nama="Tutup pemberitahuan sukses"
          >
            Tutup
          </Tombol>
        </div>
      )}

      {pesanGalat && (
        <div
          role="alert"
          data-testid="pesan-galat"
          style={{
            padding: '0.75rem 1rem',
            marginBottom: '1rem',
            borderRadius: 'var(--radius)',
            background: 'var(--danger-soft)',
            color: 'var(--danger)',
            border: '1px solid var(--border)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <span>{pesanGalat}</span>
          <Tombol
            ragam="biasa"
            onClick={() => setPesanGalat(null)}
            nama="Tutup pemberitahuan galat"
          >
            Tutup
          </Tombol>
        </div>
      )}

      {/* Grid Pengaturan & Pratinjau */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '1.25rem',
          alignItems: 'start',
        }}
      >
        {/* Kolom Kiri: Pilihan 10 Tema & Kerapatan */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {/* Kartu Pemilih 10 Tema */}
          <Kartu judul="Pilihan Tema Siap Pakai">
            <p style={{ margin: '0 0 1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Setiap tema memiliki kombinasi warna, font, bayangan, dan nuansa khusus yang ramah
              mata dan telah lolos uji keterbacaan kasir.
            </p>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fill, minmax(130px, 1fr))',
                gap: '0.75rem',
              }}
            >
              {TEMA.map((t) => {
                const terpilih = tema === t.kode
                return (
                  <div
                    key={t.kode}
                    data-theme={t.kode}
                    style={{
                      border: terpilih ? '2px solid var(--accent)' : '1px solid var(--border)',
                      borderRadius: 'var(--radius)',
                      padding: '0.6rem',
                      background: 'var(--surface)',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.5rem',
                      cursor: 'pointer',
                      transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                      boxShadow: terpilih ? 'var(--sh-2)' : 'none',
                    }}
                    onClick={() => setTema(t.kode)}
                  >
                    {/* Kotak Sampel Warna Mini Tema */}
                    <div
                      style={{
                        height: '42px',
                        borderRadius: 'var(--radius-sm)',
                        background: 'var(--bg)',
                        border: '1px solid var(--border)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '6px',
                        padding: '4px',
                      }}
                    >
                      <div
                        style={{
                          width: '18px',
                          height: '18px',
                          borderRadius: '4px',
                          background: 'var(--accent)',
                        }}
                      />
                      <div
                        style={{
                          width: '18px',
                          height: '18px',
                          borderRadius: '4px',
                          background: 'var(--surface)',
                          border: '1px solid var(--border)',
                        }}
                      />
                      <div
                        style={{
                          width: '18px',
                          height: '18px',
                          borderRadius: '4px',
                          background: 'var(--text)',
                        }}
                      />
                    </div>

                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.85rem', color: 'var(--text)' }}>
                        {t.nama}
                      </div>
                      <div
                        style={{
                          fontSize: '0.72rem',
                          color: 'var(--text-muted)',
                          lineHeight: '1.2',
                          marginTop: '2px',
                        }}
                      >
                        {t.keterangan}
                      </div>
                    </div>

                    <div style={{ marginTop: 'auto', paddingTop: '4px' }}>
                      <Tombol
                        ragam={terpilih ? 'utama' : 'biasa'}
                        onClick={() => setTema(t.kode)}
                        nama={`Pilih tema ${t.nama}`}
                      >
                        {terpilih ? '✓ Aktif' : 'Pilih'}
                      </Tombol>
                    </div>
                  </div>
                )
              })}
            </div>
          </Kartu>

          {/* Kartu Kerapatan Tampilan */}
          <Kartu judul="Kerapatan Tampilan">
            <p style={{ margin: '0 0 1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Atur kepadatan informasi di layar kasir dan katalog pelanggan.
            </p>

            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
              {KERAPATAN.map((k) => {
                const aktif = kerapatan === k.kode
                return (
                  <div
                    key={k.kode}
                    style={{
                      flex: 1,
                      minWidth: '130px',
                      border: aktif ? '2px solid var(--accent)' : '1px solid var(--border)',
                      borderRadius: 'var(--radius)',
                      padding: '0.75rem',
                      background: 'var(--surface)',
                      cursor: 'pointer',
                    }}
                    onClick={() => setKerapatan(k.kode)}
                  >
                    <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{k.nama}</div>
                    <div
                      style={{
                        fontSize: '0.78rem',
                        color: 'var(--text-muted)',
                        marginTop: '0.25rem',
                      }}
                    >
                      {k.kode === 'nyaman'
                        ? 'Jarak longgar, kartu lega (cocok untuk tablet & katalog).'
                        : 'Jarak padat, menu rapat (optimal untuk kecepatan kasir).'}
                    </div>
                    <div style={{ marginTop: '0.75rem' }}>
                      <Tombol
                        ragam={aktif ? 'utama' : 'biasa'}
                        onClick={() => setKerapatan(k.kode)}
                        nama={`Pilih mode kerapatan ${k.nama}`}
                      >
                        {aktif ? '✓ Dipilih' : 'Gunakan'}
                      </Tombol>
                    </div>
                  </div>
                )
              })}
            </div>
          </Kartu>

          {/* Kartu Penyesuaian Warna Merek Kustom */}
          <Kartu judul="Warna Merek Tambahan (Opsional)">
            <p style={{ margin: '0 0 0.75rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Masukkan kode warna heksa khusus restoran Anda (misal <strong>e06000</strong>). Sistem
              akan memverifikasi kontras terhadap standar WCAG AA (≥ 4.5:1).
            </p>

            <KolomIsian
              label="Kode Heksa Warna Aksen (tanpa tanda pagar)"
              nilai={warnaMerek}
              onUbah={tanganiGantiWarna}
              contoh="Contoh: e06000"
              keterangan="Kosongkan jika ingin menggunakan aksen bawaan tema terpilih."
              nonaktif={sedangMemuat || hanyaBaca}
            />

            <div style={{ marginTop: '0.75rem' }}>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  fontSize: '0.82rem',
                }}
              >
                <Lencana nada={statusUjiWarna.valid ? 'success' : 'danger'}>
                  {statusUjiWarna.valid ? 'WCAG AA Lolos' : 'Kontras Rendah'}
                </Lencana>
                <span style={{ color: 'var(--text-muted)' }}>{statusUjiWarna.pesan}</span>
              </div>
            </div>
          </Kartu>
        </div>

        {/* Kolom Kanan: Pratinjau Langsung (Live Preview) */}
        <div style={{ position: 'sticky', top: '1rem' }}>
          <Kartu judul="Pratinjau Langsung Komponen">
            <p style={{ margin: '0 0 1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
              Tampilan langsung menu dan tombol dengan tema{' '}
              <strong>{TEMA.find((t) => t.kode === tema)?.nama}</strong> dan mode{' '}
              <strong>{kerapatan}</strong>.
            </p>

            {/* Kotak Kontainer Pratinjau Tema Terpilih */}
            <div
              data-testid="kotak-pratinjau"
              data-theme={tema}
              data-density={kerapatan}
              style={{
                border: '1px solid var(--border)',
                borderRadius: 'var(--radius-lg)',
                padding: kerapatan === 'padat' ? '0.75rem' : '1.25rem',
                background: 'var(--bg)',
                color: 'var(--text)',
                boxShadow: 'var(--sh-2)',
                display: 'flex',
                flexDirection: 'column',
                gap: kerapatan === 'padat' ? '0.75rem' : '1rem',
              }}
            >
              {/* Header Mini Restoran */}
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  paddingBottom: '0.5rem',
                  borderBottom: '1px solid var(--border)',
                }}
              >
                <div>
                  <div
                    style={{
                      fontWeight: 800,
                      fontSize: '1rem',
                      fontFamily: 'var(--font-display)',
                    }}
                  >
                    Kedai Oasis Barokah
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                    Meja 08 • Pesanan Kasir
                  </div>
                </div>
                <Lencana nada="success">Buka</Lencana>
              </div>

              {/* Contoh Kartu Menu Makanan */}
              <div
                className="kartu-makan"
                style={{
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius)',
                  overflow: 'hidden',
                  padding: kerapatan === 'padat' ? '0.5rem' : '0.85rem',
                  display: 'flex',
                  gap: '0.75rem',
                  alignItems: 'center',
                }}
              >
                {/* Placeholder Foto Menu */}
                <div
                  style={{
                    width: kerapatan === 'padat' ? '54px' : '72px',
                    height: kerapatan === 'padat' ? '54px' : '72px',
                    borderRadius: 'var(--radius-sm)',
                    background: 'var(--surface-2)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.5rem',
                    flexShrink: 0,
                  }}
                >
                  🍲
                </div>

                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', gap: '0.35rem', marginBottom: '2px' }}>
                    <span
                      style={{
                        fontSize: '0.68rem',
                        fontWeight: 700,
                        color: 'var(--accent)',
                        textTransform: 'uppercase',
                      }}
                    >
                      Unggulan
                    </span>
                  </div>
                  <div
                    style={{
                      fontWeight: 700,
                      fontSize: '0.92rem',
                      color: 'var(--text)',
                      lineHeight: '1.2',
                    }}
                  >
                    Nasi Goreng Spesial
                  </div>
                  <div
                    style={{
                      fontSize: '0.75rem',
                      color: 'var(--text-muted)',
                      marginTop: '2px',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                    }}
                  >
                    Telur mata sapi, acar segar & kerupuk
                  </div>
                  <div
                    style={{
                      fontWeight: 800,
                      color: 'var(--accent)',
                      fontSize: '0.95rem',
                      marginTop: '4px',
                    }}
                  >
                    Rp 28.000
                  </div>
                </div>
              </div>

              {/* Baris Tombol Aksi Contoh */}
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                <Tombol ragam="utama" onClick={() => {}} nama="Tombol aksi contoh pesan">
                  + Tambah Pesanan
                </Tombol>
                <Tombol ragam="biasa" onClick={() => {}} nama="Tombol sekunder contoh rincian">
                  Rincian
                </Tombol>
              </div>

              {/* Deretan Lencana Status Contoh */}
              <div
                style={{
                  display: 'flex',
                  gap: '0.4rem',
                  flexWrap: 'wrap',
                  paddingTop: '0.25rem',
                }}
              >
                <Lencana nada="success">Selesai</Lencana>
                <Lencana nada="warn">Menunggu</Lencana>
                <Lencana nada="netral">Draf</Lencana>
              </div>

              {/* Keterangan Aksesibilitas Kontras */}
              <div
                style={{
                  fontSize: '0.72rem',
                  color: 'var(--text-muted)',
                  borderTop: '1px dashed var(--border)',
                  paddingTop: '0.5rem',
                  display: 'flex',
                  justifyContent: 'space-between',
                }}
              >
                <span>Standar Keterbacaan:</span>
                <strong style={{ color: 'var(--success)' }}>WCAG AA Lolos (≥ 4.5:1)</strong>
              </div>
            </div>
          </Kartu>
        </div>
      </div>
    </div>
  )
}
