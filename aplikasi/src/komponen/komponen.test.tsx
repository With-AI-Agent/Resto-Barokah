// @vitest-environment jsdom
// Lingkungan jsdom dipakai HANYA oleh uji yang benar-benar berinteraksi (audit I F-19:
// uji bernama "memanggil onUbah saat diisi" dulu cuma merender HTML, jadi handler yang
// tidak tersambung pun tetap hijau). Uji lain di berkas ini tetap memakai SSR.
import { renderToStaticMarkup } from 'react-dom/server'
import { cleanup, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
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

// Tanpa `globals`, pembersihan otomatis Testing Library tidak terdaftar — jadi dipanggil sendiri.
afterEach(cleanup)

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

  // F F-15 (2026-09-20): fokus keyboard dikunci di dalam lapis dan dipulihkan saat
  // ditutup. Uji ini BENAR-BENAR memindahkan fokus lewat kejadian keyboard (jsdom),
  // bukan sekadar merender — kelas cacat I F-19.
  it('memindahkan fokus ke dalam lapis saat terbuka', () => {
    const luar = document.createElement('button')
    luar.textContent = 'pemicu'
    document.body.appendChild(luar)
    luar.focus()
    const { rerender } = render(
      <Lapis buka judul="Kunci fokus" onTutup={() => undefined} kaki={<Tombol>Ya</Tombol>}>
        <p>Isi</p>
      </Lapis>,
    )
    // Fokus masuk: elemen interaktif pertama di dalam lapis = tombol Tutup.
    expect(document.activeElement?.textContent).toBe('Tutup')

    // Tab dari elemen TERAKHIR berputar ke elemen pertama (dikunci di dalam).
    const tombol = screen.getAllByRole('button')
    const terakhir = tombol[tombol.length - 1]
    terakhir.focus()
    fireEvent.keyDown(terakhir, { key: 'Tab' })
    expect(document.activeElement?.textContent).toBe('Tutup')

    // Shift-Tab dari elemen PERTAMA berputar ke elemen terakhir.
    const pertama = screen.getByRole('button', { name: 'Tutup' })
    pertama.focus()
    fireEvent.keyDown(pertama, { key: 'Tab', shiftKey: true })
    expect(document.activeElement).toBe(terakhir)

    // Ditutup: fokus pulang ke pemegang semula.
    rerender(
      <Lapis buka={false} judul="Kunci fokus" onTutup={() => undefined}>
        <p>Isi</p>
      </Lapis>,
    )
    expect(document.activeElement).toBe(luar)
    luar.remove()
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
    // Uji ini dulu hanya merender HTML lalu memastikan callback TIDAK terpanggil —
    // artinya handler `onChange` yang tidak tersambung pun akan lolos. Sekarang isian
    // benar-benar diisi dan nilainya diperiksa (bukti: audit I F-19).
    const onUbah = vi.fn()
    render(<KolomIsian label="Nama tamu" nilai="" onUbah={onUbah} />)
    const isian = screen.getByLabelText('Nama tamu')
    fireEvent.change(isian, { target: { value: 'Budi' } })
    expect(onUbah).toHaveBeenCalledTimes(1)
    expect(onUbah).toHaveBeenCalledWith('Budi')
  })

  it('menampilkan nilai terkendali dari pemanggil (tanpa mengubahnya sendiri)', () => {
    const onUbah = vi.fn()
    render(<KolomIsian label="Meja" nilai="12" onUbah={onUbah} />)
    expect((screen.getByLabelText('Meja') as HTMLInputElement).value).toBe('12')
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
