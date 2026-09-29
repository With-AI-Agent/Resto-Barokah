import type { KategoriData, MenuItemData } from '../../layar/kasir/Katalog'

export const KATEGORI_KASIR_UJI: KategoriData[] = [
  { id: 'kat-0', nama: 'Semua Menu', urutan: 0 },
  { id: 'kat-1', nama: 'Makanan', urutan: 1 },
  { id: 'kat-2', nama: 'Minuman', urutan: 2 },
  { id: 'kat-3', nama: 'Camilan', urutan: 3 },
]

export const MENU_KASIR_UJI: MenuItemData[] = [
  {
    id: 'menu-01', kategoriId: 'kat-1', nama: 'Nasi Goreng Spesial Barokah',
    deskripsi: 'Nasi goreng dengan ayam dan telur.', harga: 28000, unggulan: true,
    jenis: 'makanan', aktif: true, habis: false,
    daftarVarian: [
      { nama: 'Porsi Sedang', tambahanHarga: 0 },
      { nama: 'Porsi Jumbo', tambahanHarga: 7000 },
    ],
    daftarTambahan: [
      { id: 'tbh-1', nama: 'Tambah Telur Dadar', harga: 5000 },
      { id: 'tbh-2', nama: 'Ekstra Kerupuk Kaleng', harga: 2000 },
    ],
  },
  {
    id: 'menu-02', kategoriId: 'kat-1', nama: 'Ayam Bakar Madu Pedas', harga: 32000,
    jenis: 'makanan', aktif: true,
    daftarVarian: [{ nama: 'Paha', tambahanHarga: 0 }, { nama: 'Dada', tambahanHarga: 2000 }],
  },
  {
    id: 'menu-03', kategoriId: 'kat-2', nama: 'Es Teh Manis Melati', harga: 6000,
    jenis: 'minuman', aktif: true, habis: false,
    daftarVarian: [
      { nama: 'Manis Sedang', tambahanHarga: 0 },
      { nama: 'Kurang Gula', tambahanHarga: 0 },
      { nama: 'Tawar Dingin', tambahanHarga: 0 },
    ],
  },
  {
    id: 'menu-04', kategoriId: 'kat-2', nama: 'Kopi Susu Gula Aren Barokah', harga: 18000,
    jenis: 'minuman', aktif: true, habis: true,
  },
  {
    id: 'menu-05', kategoriId: 'kat-3', nama: 'Tahu Tempe Goreng Lengkuas', harga: 12000,
    jenis: 'makanan', aktif: true,
  },
  {
    id: 'menu-07', kategoriId: 'kat-2', nama: 'Es Jeruk Nipis', harga: 8000,
    jenis: 'minuman', aktif: true,
  },
]
