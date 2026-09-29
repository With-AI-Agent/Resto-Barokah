import { describe, expect, it } from 'vitest'
import { petaKatalogKasir, type DataKatalogKasir } from './useKatalogKasir'

describe('petaKatalogKasir', () => {
  it('memakai data menu dan harga/status cabang, termasuk varian dan tambahan aktif', () => {
    const data: DataKatalogKasir = {
      kategori: [
        { id: 'kategori-2', nama: 'Minuman', urutan: 2 },
        { id: 'kategori-1', nama: 'Makanan', urutan: 1 },
      ],
      menu: [
        {
          id: 'menu-1', kategori_id: 'kategori-1', nama: 'Nasi Uji', deskripsi: null,
          harga: 25000, foto_path: null, unggulan: true, jenis: 'makanan', aktif: true, urutan: 1,
        },
        {
          id: 'menu-2', kategori_id: 'kategori-1', nama: 'Menu disembunyikan', deskripsi: null,
          harga: 10000, foto_path: null, unggulan: false, jenis: 'makanan', aktif: true, urutan: 2,
        },
        {
          id: 'menu-3', kategori_id: 'kategori-1', nama: 'Menu nonaktif', deskripsi: null,
          harga: 10000, foto_path: null, unggulan: false, jenis: 'makanan', aktif: false, urutan: 3,
        },
      ],
      menuCabang: [
        { menu_item_id: 'menu-1', harga: 0, aktif: true, habis: true },
        { menu_item_id: 'menu-2', harga: null, aktif: false, habis: false },
      ],
      varian: [
        { menu_item_id: 'menu-1', nama: 'Jumbo', tambahan_harga: 5000 },
        { menu_item_id: 'menu-2', nama: 'Tidak dipakai', tambahan_harga: 0 },
      ],
      tambahan: [
        { id: 'tambahan-umum', menu_item_id: null, nama: 'Sambal', harga: 0 },
        { id: 'tambahan-khusus', menu_item_id: 'menu-1', nama: 'Telur', harga: 4000 },
        { id: 'tambahan-lain', menu_item_id: 'menu-2', nama: 'Tidak dipakai', harga: 1000 },
      ],
    }

    const hasil = petaKatalogKasir(data)

    expect(hasil.kategori.map((kategori) => kategori.nama)).toEqual(['Makanan', 'Minuman'])
    expect(hasil.menu).toHaveLength(1)
    expect(hasil.menu[0]).toMatchObject({
      id: 'menu-1',
      harga: 0,
      habis: true,
      daftarVarian: [{ nama: 'Jumbo', tambahanHarga: 5000 }],
      daftarTambahan: [
        { id: 'tambahan-umum', nama: 'Sambal', harga: 0 },
        { id: 'tambahan-khusus', nama: 'Telur', harga: 4000 },
      ],
    })
  })
})
