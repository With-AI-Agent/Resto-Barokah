# Probe verifikasi putaran 16 — 2026-09-19 (bukti sesi kerja)

Berkas di folder ini adalah **probe milik sesi kerja** (bukan milik peninjau) yang dipakai untuk
**membantah-balik setiap temuan** dua laporan peninjau pada putaran verifikasi 2026-09-19
(laporan audit `01a0b85b` + laporan review PR putaran16 `01a0b85b`).

Aturan yang dipegang: temuan peninjau **tidak dipercaya sebelum diuji ulang** dengan probe sendiri
(`docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §6a). Hasil: **25/25 temuan NYATA, 0 temuan palsu**.

Cara menjalankan satu probe (butuh `npm ci --prefix alat` sekali):

```
node alat/uji-sql.mjs docs/uji/audit/probe-2026-09-19/pr01-penanda-palsu.sql
```

Arti hasil: probe **LULUS** berarti perilaku yang diduga cacat MEMANG terjadi (probe menyatakan
harapan "celah ada" dan harapan itu terpenuhi). Probe ini **bukan uji regresi** — uji regresi
permanen (yang harus MERAH saat penjaga diperbaiki) dibuat di tugas penutup **T1-45**.

| Berkas probe | Temuan | Yang dibuktikan |
|---|---|---|
| `pr01-penanda-palsu.sql` | review PR-01 (**K-1**) | Penanda `resto.pembatalan_pesanan` bisa dipasang kasir (`set_config`) → item sesudah dapur dibatalkan tanpa PIN & tanpa baris jejak; kontrol tanpa penanda tetap DITOLAK |
| `pr02-void-satu-item.sql` | review PR-02 (K-2) | Void SATU item ikut membatalkan seluruh pesanan; pembayaran item yang masih hidup ditolak |
| `pr03-bocor-nomor.sql` | review PR-03 (K-2) | Kasir resto B membaca hitungan pesanan cabang resto A lewat `nomor_pesanan_berikutnya()` |
| `pr04-oracle-pin.sql` | review PR-04 (K-2) | Jawaban "PIN sudah dipakai pegawai lain" memastikan sebuah angka = PIN aktif kolega |
| `pr05-pra-dapur.sql` | review PR-05 (K-3) | Pelayan (tanpa izin void) membatalkan item pra-dapur tanpa satu pun baris jejak |
| `pr06-jejak-hierarki.sql` | review PR-06 (K-3) | Penolakan "PIN atasan lebih tinggi" tidak meninggalkan jejak (log ikut ter-rollback) |
| `pr07-kupon-tanpa-pesanan.sql` | review PR-07 (K-3) / audit F-02 | Kupon persetujuan tanpa ikatan pesanan bisa DIBUAT tetapi mustahil DIPAKAI (jalur Edge buntu) |
| `pr08-saldo-tanpa-buku.sql` | review PR-08 (K-3) | Saldo awal stok 500 kg masuk tanpa satu pun baris buku besar |
| `pr09-pin-warisan.sql` | review PR-09 (K-3) | PIN warisan 4 angka tak bisa diverifikasi & tak bisa naik kelas swadaya |
| `pr14-hak-fungsi.sql` | review PR-14 (K-4) | `service_role` ditolak 3 fungsi 0014; `peringkat_peran` bisa dipanggil `anon` |
| `pr15-meja-terputus.sql` | review PR-15 (K-4) | Hapus meja memutus tautan pesanan lunas (`meja_id` → NULL) |
| `audit-f01-diskon-sesudah-lunas.sql` | audit F-01 (K-2) | Diskon pada pesanan `lunas` mengubah `total` SETELAH uang tercatat |
| `audit-f10-pesan-diskon.sql` | audit F-10 (K-4) | Kasir yang melewati batasnya tetap ditolak walau atasan berizin ada (pesan galat menunjuk alur yang tidak ada) |

Bukti mekanisme (bukan SQL) dijalankan di `/tmp` pada saat verifikasi dan tercatat di
`docs/uji/AUDIT_RIWAYAT.md` §"2026-09-19": gerbang CI gagal-terbuka (`/tmp/gc`), generator paket
memancing temuan palsu, label gema `12/12` vs nyata `16/16`, dan klaim luar-cakupan yang **tidak
dapat direproduksi** (`--siapkan` exit 0 → diuji ulang exit **1**).
