/**
 * Opname.tsx (T4-07) — opname berkala: isi jumlah NYATA, selisih tampil terbuka.
 * Koreksi tidak menghapus riwayat (buku besar hanya-tambah). Selisih nol tidak
 * dicatat — mengikuti penjaga buku besar ("Opname/koreksi dengan perubahan nol
 * tidak perlu dicatat.").
 */
import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import type { BarisBahan } from './Stok'

export function Opname({
  bahan,
  keadaan = 'siap',
  onSimpan,
  onKembali,
}: {
  bahan: BarisBahan[]
  keadaan?: 'memuat' | 'siap'
  onSimpan?: (bahanId: string, jumlahFisik: number, alasan: string) => void
  onKembali?: () => void
}) {
  const [dipilih, setDipilih] = useState<BarisBahan | null>(null)
  const [fisik, setFisik] = useState('')
  const [alasan, setAlasan] = useState('')

  const selisih =
    dipilih && fisik !== '' && !Number.isNaN(Number(fisik)) ? Number(fisik) - dipilih.jumlah : null

  return (
    <section
      data-testid="layar-opname"
      style={{ display: 'grid', gap: 'var(--s-4)', padding: 'var(--s-3)' }}
    >
      <header
        style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)', flexWrap: 'wrap' }}
      >
        <h2 style={{ margin: 0, fontSize: 'var(--t-6)' }}>Opname Stok</h2>
        <span className="small muted">Hitung fisik, selisih tampil apa adanya.</span>
        {onKembali ? (
          <Tombol ragam="biasa" onClick={onKembali}>
            <span data-testid="kembali-stok">Kembali ke Stok</span>
          </Tombol>
        ) : null}
      </header>

      {keadaan === 'memuat' ? <KeadaanMemuat judul="Memuat daftar bahan..." /> : null}
      {keadaan === 'siap' && bahan.length === 0 ? (
        <KeadaanKosong
          judul="Belum ada bahan untuk diopname."
          keterangan="Catat bahan di layar Stok lebih dulu."
        />
      ) : null}

      <ul style={{ listStyle: 'none', margin: 0, padding: 0, display: 'grid', gap: 'var(--s-2)' }}>
        {bahan.map((b) => (
          <li
            key={b.id}
            style={{ borderTop: '1px solid var(--b-netral)', paddingTop: 'var(--s-2)' }}
          >
            <span style={{ display: 'inline-flex', gap: 'var(--s-3)', alignItems: 'center' }}>
              <span style={{ fontWeight: 700 }}>{b.nama}</span>
              <span className="small muted">
                sistem: {b.jumlah} {b.satuan}
              </span>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setDipilih(b)
                  setFisik('')
                  setAlasan('')
                }}
              >
                <span data-testid={`hitung-${b.id}`}>Hitung</span>
              </Tombol>
            </span>
          </li>
        ))}
      </ul>

      {dipilih ? (
        <Kartu judul={`Hitung fisik: ${dipilih.nama}`}>
          <div style={{ display: 'grid', gap: 'var(--s-3)', maxWidth: '28rem' }}>
            <p style={{ margin: 0 }}>
              Jumlah sistem:{' '}
              <strong>
                {dipilih.jumlah} {dipilih.satuan}
              </strong>
            </p>
            <KolomIsian
              label="Jumlah fisik (hasil hitung)"
              jenis="number"
              nilai={fisik}
              onUbah={setFisik}
              wajib
            />
            {selisih !== null ? (
              <p data-testid="pratinjau-selisih" style={{ margin: 0 }}>
                Selisih:{' '}
                {selisih === 0 ? (
                  <Lencana nada="success">0 — cocok</Lencana>
                ) : (
                  <Lencana nada={selisih < 0 ? 'danger' : 'warn'}>
                    {selisih > 0 ? '+' : ''}
                    {selisih} {dipilih.satuan}
                  </Lencana>
                )}
              </p>
            ) : null}
            <KolomIsian
              label="Alasan / catatan opname"
              nilai={alasan}
              onUbah={setAlasan}
              keterangan="Wajib — misalnya: Hitung fisik gudang"
              wajib
            />
            <span style={{ display: 'inline-flex', gap: 'var(--s-2)' }}>
              <Tombol
                ragam="utama"
                nonaktif={selisih === 0 || selisih === null || !alasan.trim()}
                onClick={() => {
                  if (selisih === null || !alasan.trim() || !onSimpan) return
                  onSimpan(dipilih.id, Number(fisik), alasan.trim())
                  setDipilih(null)
                }}
              >
                <span data-testid="simpan-opname">Simpan Opname</span>
              </Tombol>
              <Tombol ragam="biasa" onClick={() => setDipilih(null)}>
                Batal
              </Tombol>
            </span>
            <span className="small muted">Selisih nol tidak dicatat (aturan buku besar).</span>
          </div>
        </Kartu>
      ) : null}
    </section>
  )
}
