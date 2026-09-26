# PETA_UI.md — Peta Layar & Registri Aksi Resto Barokah

> **Pemberitahuan:** Berkas ini dihasilkan secara otomatis oleh `alat/peta-ui.py`.
> DILARANG menyunting berkas ini secara manual. Seluruh pembaruan wajib melalui
> `aplikasi/src/lib/layar.ts` dan `aplikasi/src/lib/aksi.ts`.

---

## 1. Ringkasan Eksekutif Antarmuka (G1)

- **Total Layar Terdaftar:** 11 layar
- **Total Aksi Terdaftar:** 48 aksi
  - Aksi Tulis / Transaksi: 33
  - Aksi Baca / Filter: 7
  - Aksi Navigasi / UI: 8
- **Aksi dengan Izin Spesifik:** 27 aksi
- **Aksi dengan Dialog Konfirmasi:** 16 aksi
- **Aksi Wajib Jejak Audit:** 25 aksi

---

## 2. Daftar Kontrak Layar

| ID Layar | Judul | Rute | Peran yang Berhak | Masuk Dari | Berkas Uji | Naskah Jalan |
|---|---|---|---|---|---|---|
| `bar` | Antrean Bar & Minuman | `/bar` | `owner_pusat`, `admin_cabang`, `kasir`, `dapur` | Tombol "Ke Layar Bar" di Antrean Dapur, Bilah navigasi Dapur | `src/layar/dapur/LayarBar.test.tsx` | `W-4-02` |
| `contoh` | Contoh Komponen & Tema | `/contoh` | `owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur`, `pemilik_platform`, `pelanggan` | Pengembang / Penguji, Bilah tema | `src/layar/contoh/LayarContoh.test.tsx` | `W-0-01` |
| `dapur` | Pesanan Dapur & Bar | `/dapur` | `owner_pusat`, `admin_cabang`, `kasir`, `dapur` | Bilah navigasi Dapur, Menu Utama | `src/layar/dapur/LayarDapur.test.tsx` | `W-4-01` |
| `kasir` | Kasir & Transaksi | `/kasir` | `owner_pusat`, `admin_cabang`, `kasir` | Bilah navigasi bawah Kasir, Setelah buka shift | `src/layar/kasir/LayarKasir.test.tsx` | `W-3-01` |
| `laporan` | Laporan Penjualan & Kas | `/laporan` | `owner_pusat`, `admin_cabang` | Bilah navigasi Laporan, Menu Pengelola | `src/layar/laporan/LayarLaporan.test.tsx` | `W-7-01` |
| `masuk` | Masuk Pegawai | `/masuk` | `pemilik_platform`, `owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur` | Awal aplikasi, Keluar sesi, Kunci otomatis | `src/layar/masuk/LayarMasuk.test.tsx` | `W-2-01` |
| `opname` | Opname Stok | `/opname` | `owner_pusat`, `admin_cabang`, `dapur` | Tombol "Ke Opname" di layar Stok | `src/layar/dapur/Opname.test.tsx` | `W-5-02` |
| `pelanggan-publik` | Katalog Menu Publik | `/menu` | `pelanggan`, `kasir`, `pelayan`, `admin_cabang`, `owner_pusat`, `pemilik_platform` | Tautan publik / QR Meja, Peramban pelanggan | `src/layar/pelanggan-publik/LayarPelangganPublik.test.tsx` | `W-8-02` |
| `pengaturan` | Pengaturan Resto | `/pengaturan` | `owner_pusat`, `admin_cabang` | Bilah navigasi Pengaturan, Menu Utama | `src/layar/pengaturan/LayarPengaturan.test.tsx` | `W-9-01` |
| `stok` | Stok Bahan | `/stok` | `owner_pusat`, `admin_cabang`, `dapur` | Menu Utama, Tombol "Ke Opname" di layar Stok | `src/layar/dapur/Stok.test.tsx` | `W-5-01` |
| `voucher` | Voucher & Diskon | `/voucher` | `owner_pusat`, `admin_cabang`, `kasir` | Panel Pembayaran Kasir, Menu Voucher | `src/layar/voucher/LayarVoucher.test.tsx` | `W-8-01` |

---

## 3. Matriks Jejak Fitur PRD M1–M12

| Kode PRD | Nama Fitur | Layar Terkait | Aksi Terkait |
|---|---|---|---|
| `M1` | Pemesanan Kasir Cepat | `kasir` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+5 lainnya) |
| `M2` | Papan Dapur & Bar Real-Time | `dapur` | `dapur.mulai_masak`, `dapur.selesai_masak`, `dapur.tandai_habis` |
| `M3` | Manajemen Meja & Status Layanan | `kasir`, `pengaturan` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+20 lainnya) |
| `M4` | Pembayaran Fleksibel & Multi-Metode | `kasir` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+5 lainnya) |
| `M5` | Laporan Penjualan & Rekonsiliasi Kas | `laporan` | `laporan.cetak_laporan`, `laporan.ekspor_data`, `laporan.filter_tanggal`, `laporan.pilih_cabang` |
| `M6` | Manajemen Pegawai & Hak Akses Berjenjang | `masuk`, `pengaturan` | `masuk.batal`, `masuk.ganti_pengguna`, `masuk.verifikasi_pin`, `pengaturan.hapus_kategori` (+14 lainnya) |
| `M7` | Katalog Menu & Kustomisasi Varian | `kasir`, `pelanggan-publik` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+7 lainnya) |
| `M8` | Voucher Diskon & Promosi | `kasir`, `voucher` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+8 lainnya) |
| `M9` | Manajemen Stok Bahan & Peringatan Habis | `dapur`, `pengaturan` | `dapur.mulai_masak`, `dapur.selesai_masak`, `dapur.tandai_habis`, `pengaturan.hapus_kategori` (+14 lainnya) |
| `M10` | Menu Digital Pelanggan (Self-Order QR) | `pelanggan-publik` | `pelanggan.cari_menu`, `pelanggan.filter_kategori` |
| `M11` | Dukungan Multi-Cabang Terpusat | `laporan`, `pengaturan` | `laporan.cetak_laporan`, `laporan.ekspor_data`, `laporan.filter_tanggal`, `laporan.pilih_cabang` (+15 lainnya) |
| `M12` | Audit Log & Keamanan Data Transaksi | `masuk`, `kasir`, `pengaturan` | `kasir.batal_item`, `kasir.beri_diskon`, `kasir.buka_shift`, `kasir.kas_pergerakan` (+23 lainnya) |

---

## 4. Registri Aksi Lengkap

| ID Aksi | Label | Layar | Peran | Izin | RPC | Jenis | Konfirmasi | Audit | Uji |
|---|---|---|---|---|---|---|---|---|---|
| `bar.mulai_buat` | Mulai Buat | `bar` | owner_pusat, admin_cabang, kasir, dapur | - | `set_status_item` | `tulis` | - | - | `uji_status_item_transisi` |
| `bar.selesai_buat` | Siap Saji | `bar` | owner_pusat, admin_cabang, kasir, dapur | - | `set_status_item` | `tulis` | - | - | `uji_status_item_transisi` |
| `contoh.ganti_kerapatan` | Ganti Kerapatan | `contoh` | owner_pusat, admin_cabang, kasir, pelayan, dapur, pemilik_platform, pelanggan | - | - | `navigasi` | - | - | `uji_contoh_ganti_kerapatan` |
| `contoh.ganti_tema` | Ganti Tema | `contoh` | owner_pusat, admin_cabang, kasir, pelayan, dapur, pemilik_platform, pelanggan | - | - | `navigasi` | - | - | `uji_contoh_ganti_tema` |
| `contoh.picu_toast` | Picu Toast Pemberitahuan | `contoh` | owner_pusat, admin_cabang, kasir, pelayan, dapur, pemilik_platform, pelanggan | - | - | `navigasi` | - | - | `uji_contoh_picu_toast` |
| `dapur.mulai_masak` | Mulai Masak | `dapur` | owner_pusat, admin_cabang, kasir, dapur | - | - | `tulis` | - | - | `uji_dapur_mulai_masak` |
| `dapur.selesai_masak` | Siap Saji | `dapur` | owner_pusat, admin_cabang, kasir, dapur | - | - | `tulis` | - | - | `uji_dapur_selesai_masak` |
| `dapur.tandai_habis` | Tandai Habis | `dapur` | owner_pusat, admin_cabang, dapur | `ubah_stok` | - | `tulis` | Ya | Ya | `uji_dapur_tandai_menu_habis` |
| `kasir.batal_item` | Batalkan Item | `kasir` | owner_pusat, admin_cabang, kasir | `void_sebelum_dapur` | `hitung_total` | `tulis` | Ya | Ya | `uji_kasir_batal_item_pra_dapur` |
| `kasir.beri_diskon` | Beri Diskon | `kasir` | owner_pusat, admin_cabang, kasir | `beri_diskon` | - | `tulis` | Ya | Ya | `uji_kasir_diskon_transaksi` |
| `kasir.buka_shift` | Buka Shift | `kasir` | owner_pusat, admin_cabang, kasir | - | `buka_shift` | `tulis` | - | Ya | `uji_kasir_buka_shift`, `src/layar/kasir/BukaKas.test.tsx` |
| `kasir.kas_pergerakan` | Catat Kas Masuk/Keluar | `kasir` | owner_pusat, admin_cabang, kasir | `tutup_kas` | `kas_pergerakan` | `tulis` | Ya | Ya | `uji_kasir_kas_pergerakan`, `src/layar/kasir/KasKeluarMasuk.test.tsx` |
| `kasir.kirim_dapur` | Kirim ke Dapur | `kasir` | owner_pusat, admin_cabang, kasir | - | `hitung_total` | `tulis` | - | - | `uji_kirim_tiket_dapur` |
| `kasir.kurang_item` | Kurangi Item | `kasir` | owner_pusat, admin_cabang, kasir | - | `hitung_total` | `tulis` | - | - | `uji_kasir_kurang_item` |
| `kasir.proses_bayar` | Bayar Pesanan | `kasir` | owner_pusat, admin_cabang, kasir | - | `bayar_pesanan` | `tulis` | Ya | Ya | `uji_kasir_bayar_tunai_lunas`, `src/hook/useBayar.test.tsx`, `src/layar/kasir/Bayar.test.tsx` |
| `kasir.tambah_item` | Tambah Item | `kasir` | owner_pusat, admin_cabang, kasir | - | `hitung_total` | `tulis` | - | - | `uji_kasir_tambah_item` |
| `kasir.tutup_shift` | Tutup Shift | `kasir` | owner_pusat, admin_cabang, kasir | `tutup_kas` | `tutup_shift` | `tulis` | Ya | Ya | `uji_kasir_tutup_shift`, `src/layar/kasir/TutupKas.test.tsx` |
| `laporan.cetak_laporan` | Cetak Laporan | `laporan` | owner_pusat, admin_cabang | `lihat_laporan` | - | `baca` | - | - | `uji_laporan_cetak` |
| `laporan.ekspor_data` | Ekspor Ringkasan | `laporan` | owner_pusat, admin_cabang | `lihat_laporan` | - | `baca` | - | - | `uji_laporan_ekspor` |
| `laporan.filter_tanggal` | Filter Tanggal | `laporan` | owner_pusat, admin_cabang | `lihat_laporan` | - | `baca` | - | - | `uji_laporan_filter_tanggal` |
| `laporan.pilih_cabang` | Pilih Cabang | `laporan` | owner_pusat, admin_cabang | `lihat_laporan` | - | `baca` | - | - | `uji_laporan_pilih_cabang` |
| `masuk.batal` | Batal | `masuk` | pemilik_platform, owner_pusat, admin_cabang, kasir, pelayan, dapur | - | - | `navigasi` | - | - | `uji_batal_masuk` |
| `masuk.ganti_pengguna` | Ganti Pegawai | `masuk` | pemilik_platform, owner_pusat, admin_cabang, kasir, pelayan, dapur | - | - | `navigasi` | - | - | `uji_navigasi_ganti_pegawai` |
| `masuk.verifikasi_pin` | Masuk | `masuk` | pemilik_platform, owner_pusat, admin_cabang, kasir, pelayan, dapur | - | `verifikasi_pin` | `tulis` | - | - | `uji_masuk_pin_sah`, `uji_masuk_pin_salah` |
| `opname.catat_fisik` | Catat Jumlah Fisik | `opname` | owner_pusat, admin_cabang, dapur | `ubah_stok` | `opname_stok` | `tulis` | Ya | Ya | `uji_opname_stok` |
| `opname.kembali_stok` | Kembali ke Stok | `opname` | owner_pusat, admin_cabang, dapur | - | - | `navigasi` | - | - | `uji_opname_stok` |
| `pelanggan.cari_menu` | Cari Menu | `pelanggan-publik` | pelanggan, kasir, pelayan, admin_cabang, owner_pusat, pemilik_platform | - | - | `baca` | - | - | `uji_pelanggan_cari_menu` |
| `pelanggan.filter_kategori` | Pilih Kategori | `pelanggan-publik` | pelanggan, kasir, pelayan, admin_cabang, owner_pusat, pemilik_platform | - | - | `baca` | - | - | `uji_pelanggan_filter_kategori` |
| `pengaturan.hapus_kategori` | Hapus Kategori Menu | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `hapus_kategori_menu` | `tulis` | Ya | Ya | `uji_pengaturan_hapus_kategori` |
| `pengaturan.hapus_meja` | Hapus Meja | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `hapus_meja` | `tulis` | Ya | Ya | `uji_pengaturan_hapus_meja` |
| `pengaturan.hapus_menu` | Hapus Menu | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `hapus_menu` | `tulis` | Ya | Ya | `uji_pengaturan_hapus_menu` |
| `pengaturan.hapus_metode_bayar` | Hapus Metode Pembayaran | `pengaturan` | owner_pusat | `atur_pengaturan` | `hapus_metode_bayar` | `tulis` | Ya | Ya | `uji_pengaturan_hapus_metode_bayar` |
| `pengaturan.salin_harga_cabang` | Salin Menu Cabang | `pengaturan` | owner_pusat | `atur_pengaturan` | `salin_harga_cabang` | `tulis` | Ya | Ya | `uji_pengaturan_salin_harga_cabang` |
| `pengaturan.simpan_aturan_tip` | Simpan Aturan Tip | `pengaturan` | owner_pusat | `atur_pengaturan` | `simpan_aturan_tip` | `tulis` | - | Ya | `uji_pengaturan_simpan_aturan_tip` |
| `pengaturan.simpan_kategori` | Simpan Kategori Menu | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_kategori_menu` | `tulis` | - | Ya | `uji_pengaturan_simpan_kategori` |
| `pengaturan.simpan_menu` | Simpan Menu | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_menu` | `tulis` | - | Ya | `uji_pengaturan_simpan_menu` |
| `pengaturan.simpan_menu_cabang` | Simpan Menu Cabang | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_menu_cabang` | `tulis` | - | Ya | `uji_pengaturan_simpan_menu_cabang` |
| `pengaturan.simpan_metode_bayar` | Simpan Metode Pembayaran | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_metode_bayar` | `tulis` | - | Ya | `uji_pengaturan_simpan_metode_bayar` |
| `pengaturan.simpan_pajak` | Simpan Pajak & Service | `pengaturan` | owner_pusat | `atur_pengaturan` | `simpan_operasional` | `tulis` | Ya | Ya | `uji_pengaturan_pajak`, `uji_pengaturan_operasional` |
| `pengaturan.simpan_tema` | Terapkan Tema | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_tema` | `tulis` | - | Ya | `uji_pengaturan_tema` |
| `pengaturan.tambah_meja` | Tambah Meja | `pengaturan` | owner_pusat, admin_cabang | `atur_pengaturan` | `simpan_meja` | `tulis` | - | Ya | `uji_pengaturan_tambah_meja` |
| `pengaturan.tambah_pegawai` | Tambah Pegawai | `pengaturan` | owner_pusat, admin_cabang | `kelola_pegawai` | `simpan_pin` | `tulis` | - | Ya | `uji_pengaturan_tambah_pegawai` |
| `pengaturan.ubah_izin` | Ubah Izin Peran | `pengaturan` | owner_pusat | `kelola_pegawai` | - | `tulis` | Ya | Ya | `uji_pengaturan_ubah_izin` |
| `stok.catat_perubahan` | Catat Perubahan Stok | `stok` | owner_pusat, admin_cabang, dapur | `ubah_stok` | `set_stok` | `tulis` | Ya | Ya | `uji_set_stok` |
| `stok.ke_opname` | Ke Opname | `stok` | owner_pusat, admin_cabang, dapur | - | - | `navigasi` | - | - | `uji_opname_stok` |
| `voucher.batal` | Tutup | `voucher` | owner_pusat, admin_cabang, kasir | - | - | `navigasi` | - | - | `uji_voucher_batal` |
| `voucher.cek_kode` | Periksa Voucher | `voucher` | owner_pusat, admin_cabang, kasir | - | - | `baca` | - | - | `uji_voucher_cek_kode` |
| `voucher.klaim_diskon` | Terapkan Voucher | `voucher` | owner_pusat, admin_cabang, kasir | `pakai_voucher` | `hitung_total` | `tulis` | Ya | Ya | `uji_voucher_klaim_diskon` |

