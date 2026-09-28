/**
 * Stok.tsx (T4-06) — stok sederhana per bahan + riwayat perubahan.
 *
 * "Pencatatan sederhana, bukan resep otomatis (fase 2)" — keputusan rencana
 * stok bertahap di DECISIONS_LOG. Penambahan/pengurangan memakai delta (+/−)
 * dengan alasan wajib; buku besar `stok_pergerakan` mencatat siapa, kapan,
 * berapa, dan alasannya (RPC set_stok — TECH_SPEC §5 M9).
 */
import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { Tabel, type KolomTabel } from '../../komponen/Tabel'
import { Lencana } from '../../komponen/Lencana'
import { Tombol } from '../../komponen/Tombol'
import { KolomIsian } from '../../komponen/KolomIsian'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'

export interface BarisBahan {
  id: string
  nama: string
  satuan: string
  jumlah: number
  minimum: number
  dipantau: boolean
}

export interface BarisPergerakan {
  id: string
  bahanId: string
  namaBahan: string
  jenis: 'masuk' | 'keluar' | 'opname' | 'koreksi'
  jumlah: number
  alasan: string | null
  oleh: string | null
  waktu: string
}

export function Stok({
  bahan,
  riwayat,
  keadaan = 'siap',
  onSimpan,
  onKeOpname,
  onCoba,
}: {
  bahan: BarisBahan[]
  riwayat: BarisPergerakan[]
  keadaan?: 'memuat' | 'gagal' | 'siap'
  onSimpan?: (bahanId: string, delta: number, alasan: string) => void
  onKeOpname?: () => void
  onCoba?: () => void
}) {
  const [dipilih, setDipilih] = useState<{ id: string; nama: string; delta: number } | null>(null)
  const [jumlah, setJumlah] = useState('')
  const [alasan, setAlasan] = useState('')

  const kolom: readonly KolomTabel<BarisBahan>[] = [
    { kunci: 'nama', judul: 'Bahan' },
    { kunci: 'satuan', judul: 'Satuan' },
    { kunci: 'jumlah', judul: 'Jumlah', rata: 'kanan' },
    { kunci: 'minimum', judul: 'Minimum', rata: 'kanan' },
    {
      kunci: 'status',
      judul: 'Status',
      nilai: (b) =>
        b.dipantau && b.jumlah <= b.minimum ? (
          <Lencana nada="danger">Di bawah minimum</Lencana>
        ) : b.dipantau ? (
          <Lencana nada="success">Dipantau</Lencana>
        ) : (
          <Lencana nada="netral">Tidak dipantau</Lencana>
        ),
    },
    {
      kunci: 'aksi',
      judul: 'Aksi',
      nilai: (b) => (
        <span style={{ display: 'inline-flex', gap: 'var(--s-2)' }}>
          <Tombol
            ragam="utama"
            onClick={() => {
              setDipilih({ id: b.id, nama: b.nama, delta: 1 })
              setJumlah('')
              setAlasan('')
            }}
          >
            <span data-testid={`tambah-${b.id}`}>Tambah</span>
          </Tombol>
          <Tombol
            ragam="biasa"
            onClick={() => {
              setDipilih({ id: b.id, nama: b.nama, delta: -1 })
              setJumlah('')
              setAlasan('')
            }}
          >
            <span data-testid={`kurang-${b.id}`}>Kurang</span>
          </Tombol>
        </span>
      ),
    },
  ]

  const kolomRiwayat: readonly KolomTabel<BarisPergerakan>[] = [
    { kunci: 'waktu', judul: 'Waktu' },
    { kunci: 'namaBahan', judul: 'Bahan' },
    {
      kunci: 'jenis',
      judul: 'Jenis',
      nilai: (p) => (
        <Lencana nada={p.jenis === 'masuk' ? 'success' : p.jenis === 'keluar' ? 'warn' : 'info'}>
          {p.jenis}
        </Lencana>
      ),
    },
    { kunci: 'jumlah', judul: 'Perubahan', rata: 'kanan' },
    { kunci: 'alasan', judul: 'Alasan' },
    { kunci: 'oleh', judul: 'Oleh' },
  ]

  return (
    <section
      data-testid="layar-stok"
      style={{ display: 'grid', gap: 'var(--s-4)', padding: 'var(--s-3)' }}
    >
      <header
        style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)', flexWrap: 'wrap' }}
      >
        <h2 style={{ margin: 0, fontSize: 'var(--t-6)' }}>Stok Bahan</h2>
        <span className="small muted">Pencatatan sederhana — bukan resep otomatis.</span>
        {onKeOpname ? (
          <Tombol ragam="biasa" onClick={onKeOpname}>
            <span data-testid="ke-opname">Mulai Opname</span>
          </Tombol>
        ) : null}
      </header>

      {keadaan === 'memuat' ? <KeadaanMemuat judul="Memuat daftar bahan..." /> : null}
      {keadaan === 'gagal' ? (
        <KeadaanGagal
          judul="Gagal memuat stok"
          keterangan="Periksa sambungan lalu coba lagi."
          onCoba={onCoba}
        />
      ) : null}

      {keadaan === 'siap' && bahan.length === 0 ? (
        <KeadaanKosong
          judul="Belum ada bahan yang dicatat."
          keterangan="Tambahkan bahan (opsional) untuk mulai memantau persediaan."
        />
      ) : null}

      {bahan.length > 0 ? <Tabel kolom={kolom} baris={bahan} /> : null}

      {dipilih && onSimpan ? (
        <Kartu judul={`${dipilih.delta > 0 ? 'Tambah' : 'Kurang'} ${dipilih.nama}`}>
          <div style={{ display: 'grid', gap: 'var(--s-3)', maxWidth: '28rem' }}>
            <KolomIsian
              label="Jumlah"
              jenis="number"
              nilai={jumlah}
              onUbah={setJumlah}
              keterangan="Perubahan (delta), misalnya 5 atau 3.5"
              wajib
            />
            <KolomIsian
              label="Alasan"
              nilai={alasan}
              onUbah={setAlasan}
              keterangan="Wajib — contoh: Belanja pagi / Pemakaian dapur"
              wajib
            />
            <span style={{ display: 'inline-flex', gap: 'var(--s-2)' }}>
              <Tombol
                ragam="utama"
                onClick={() => {
                  const nilai = Number(jumlah)
                  if (!jumlah || Number.isNaN(nilai) || nilai <= 0 || !alasan.trim()) return
                  onSimpan(dipilih.id, dipilih.delta * nilai, alasan.trim())
                  setDipilih(null)
                }}
              >
                <span data-testid="simpan-perubahan">Simpan Perubahan</span>
              </Tombol>
              <Tombol ragam="biasa" onClick={() => setDipilih(null)}>
                Batal
              </Tombol>
            </span>
          </div>
        </Kartu>
      ) : null}

      <Kartu judul="Riwayat Perubahan">
        <Tabel
          kolom={kolomRiwayat}
          baris={riwayat}
          judulKosong="Belum ada perubahan tercatat."
          keteranganKosong="Setiap penambahan/pengurangan tercatat di buku besar."
        />
      </Kartu>
    </section>
  )
}
