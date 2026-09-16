# Folder layar (`src/layar/`)

Satu folder = satu layar. Folder-folder ini sudah disiapkan sejak Fase 0 supaya
nama dan susunannya tidak berubah lagi di tengah jalan (sesuai `docs/TECH_SPEC.md`
bagian 3), tetapi isinya masih kosong sampai fasa masing-masing dikerjakan:

| Folder              | Layar                                               | Dikerjakan mulai           |
| ------------------- | --------------------------------------------------- | -------------------------- |
| `kasir/`            | kasir (POS): pilih menu, keranjang, bayar           | Fase 3                     |
| `dapur/`            | papan pesanan dapur/bar                             | Fase 4                     |
| `laporan/`          | laporan harian & rekap                              | Fase 5                     |
| `pengaturan/`       | pengaturan resto, menu, pegawai, meja, voucher      | Fase 7                     |
| `pelanggan-publik/` | katalog publik & pesan-sendiri pelanggan            | Fase 8                     |
| `voucher/`          | voucher undang-teman: buat, cek (hanya baca), pakai | Fase 9                     |
| `masuk/`            | masuk pegawai (email + PIN) & pelanggan (Google)    | Fase 2                     |
| `contoh/`           | **bukan layar produksi** — layar bukti Fase 0       | Fase 0 (dihapus di Fase 2) |

Folder kosong tidak ikut tersimpan di Git, karena itu setiap folder wajib punya
berkas penanda `.gitkeep`. Aturan ini diperiksa otomatis oleh
`aplikasi/alat/periksa-struktur.py` (bagian "terlacak Git").
