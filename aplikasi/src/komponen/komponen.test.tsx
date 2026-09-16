import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it, vi } from 'vitest'
import { Kartu } from './Kartu'
import { KolomIsian } from './KolomIsian'
import { Lapis } from './Lapis'
import { Lencana } from './Lencana'
import { Tabel, type KolomTabel } from './Tabel'
import { Toast } from './Toast'
import { Tombol } from './Tombol'
import { KeadaanGagal } from './KeadaanGagal'
import { KeadaanKosong } from './KeadaanKosong'
import { KeadaanMemuat } from './KeadaanMemuat'

describe('Tombol', () => {
  it('memakai kelas rancangan sesuai ragam', () => {
    expect(renderToStaticMarkup(<Tombol>Simpan</Tombol>)).toContain('class="btn btn-primary"')
    expect(renderToStaticMarkup(<Tombol ragam="bahaya">Hapus</Tombol>)).toContain(
      'class="btn btn-danger"',
    )
    expect(renderToStaticMarkup(<Tombol ragam="kecil">Kecil</Tombol>)).toContain(
      'class="btn btn-sm"',
    )
  })

  it('menghormati keadaan nonaktif dan lebar penuh', () => {
    const html = renderToStaticMarkup(
      <Tombol nonaktif lebar>
        Simpan
      </Tombol>,
    )
    expect(html).toContain('disabled')
    expect(html).toContain('btn btn-primary btn-lg')
  })

  it('memberi nama untuk pembaca layar bila isinya ikon', () => {
    expect(renderToStaticMarkup(<Tombol nama="Tambah pesanan">+</Tombol>)).toContain(
      'aria-label="Tambah pesanan"',
    )
  })
})

describe('Kartu', () => {
  it('tanpa judul hanya kotak isi', () => {
    const html = renderToStaticMarkup(<Kartu>isi</Kartu>)
    expect(html).toContain('class="card"')
    expect(html).not.toContain('card-head')
  })

  it('dengan judul memakai kepala kartu', () => {
    const html = renderToStaticMarkup(
      <Kartu judul="Transaksi" aksi={<span>aksi</span>}>
        isi
      </Kartu>,
    )
    expect(html).toContain('<h3>Transaksi</h3>')
    expect(html).toContain('class="card-head"')
  })
})

describe('Lencana', () => {
  it('memetakan nada ke kelas chip', () => {
    expect(renderToStaticMarkup(<Lencana nada="success">Lunas</Lencana>)).toContain(
      'class="chip chip-success"',
    )
    expect(renderToStaticMarkup(<Lencana>Netral</Lencana>)).toContain('class="chip"')
  })
})

describe('Lapis', () => {
  it('tidak merender apa pun saat tertutup', () => {
    expect(renderToStaticMarkup(<Lapis buka={false} judul="X" onTutup={() => undefined} />)).toBe(
      '',
    )
  })

  it('saat terbuka menjadi dialog yang bisa dibaca pembaca layar', () => {
    const html = renderToStaticMarkup(
      <Lapis buka judul="Konfirmasi bayar" onTutup={() => undefined} kaki={<Tombol>Ya</Tombol>}>
        <p>Yakin?</p>
      </Lapis>,
    )
    expect(html).toContain('role="dialog"')
    expect(html).toContain('aria-modal="true"')
    expect(html).toContain('aria-label="Konfirmasi bayar"')
    expect(html).toContain('lapis-kaki')
  })
})

describe('Toast', () => {
  it('dibacakan pembaca layar tanpa merebut fokus', () => {
    const html = renderToStaticMarkup(<Toast pesan="Tersimpan" nada="sukses" />)
    expect(html).toContain('role="status"')
    expect(html).toContain('aria-live="polite"')
    expect(html).toContain('toast toast-sukses')
  })

  it('punya ragam gagal dan info', () => {
    expect(renderToStaticMarkup(<Toast pesan="Gagal" nada="gagal" />)).toContain('toast-gagal')
    expect(renderToStaticMarkup(<Toast pesan="Info" />)).toContain('toast-info')
  })
})

describe('Tabel', () => {
  type Baris = { nama: string; harga: number }
  const kolom: readonly KolomTabel<Baris>[] = [
    { kunci: 'nama', judul: 'Menu' },
    { kunci: 'harga', judul: 'Harga', rata: 'kanan', nilai: (b) => `Rp${b.harga}` },
  ]

  it('menampilkan baris dan kolom', () => {
    const html = renderToStaticMarkup(
      <Tabel kolom={kolom} baris={[{ nama: 'Mie Ayam', harga: 18000 }]} />,
    )
    expect(html).toContain('class="table"')
    expect(html).toContain('<th scope="col">Menu</th>')
    expect(html).toContain('Rp18000')
    expect(html).toContain('class="right"')
  })

  it('tanpa data menampilkan penjelasan, bukan tabel kosong', () => {
    const html = renderToStaticMarkup(<Tabel kolom={kolom} baris={[]} judulKosong="Kosong" />)
    expect(html).toContain('keadaan-kosong')
    expect(html).not.toContain('<table')
  })
})

describe('KolomIsian', () => {
  it('menyambungkan label, keterangan, dan galat', () => {
    const html = renderToStaticMarkup(
      <KolomIsian
        label="Nama pelanggan"
        nilai="Budi"
        onUbah={() => undefined}
        keterangan="Boleh dikosongkan"
        galat="Nama terlalu pendek"
      />,
    )
    expect(html).toContain('class="input"')
    expect(html).toContain('aria-invalid="true"')
    expect(html).toContain('aria-describedby=')
    expect(html).toContain('galat-isian')
    expect(html).toContain('<label class="label"')
  })

  it('memanggil onUbah saat diisi', () => {
    const onUbah = vi.fn()
    const html = renderToStaticMarkup(<KolomIsian label="X" nilai="" onUbah={onUbah} />)
    expect(html).toContain('type="text"')
    expect(onUbah).not.toHaveBeenCalled()
  })
})

describe('Keadaan', () => {
  it('kosong: memberi penjelasan dan aksi', () => {
    const html = renderToStaticMarkup(
      <KeadaanKosong
        judul="Belum ada pesanan"
        keterangan="Tunggu kasir."
        aksi={<Tombol>Buat</Tombol>}
      />,
    )
    expect(html).toContain('keadaan-kosong')
    expect(html).toContain('Belum ada pesanan')
    expect(html).toContain('Buat')
  })

  it('memuat: batang hiasan disembunyikan dari pembaca layar', () => {
    const html = renderToStaticMarkup(<KeadaanMemuat judul="Memuat…" baris={2} />)
    expect(html).toContain('class="sr"')
    expect(html).toContain('aria-hidden="true"')
    expect(html.split('pemuat-batang').length - 1).toBe(2)
  })

  it('gagal: memakai role=alert dan tombol coba lagi', () => {
    const onCoba = vi.fn()
    const html = renderToStaticMarkup(<KeadaanGagal onCoba={onCoba} />)
    expect(html).toContain('role="alert"')
    expect(html).toContain('Coba lagi')
    expect(html).toContain('keadaan-gagal')
  })
})
