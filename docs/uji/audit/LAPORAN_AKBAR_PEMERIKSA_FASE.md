# Laporan Akbar Pemeriksa Riwayat Fase 0–10

- **Auditor:** Agen pemeriksa fase pada sesi Arena — pemeriksaan hanya-baca untuk Lee
- **Tanggal:** 2026-09-27 (UTC)
- **Tingkat audit:** `AUD-2`
- **Mode cakupan:** `vertikal-fase-0-10` — pemeriksaan urut Fase 0 sampai Fase 10; ini bukan pengganti pemeriksaan horizontal atau holistik
- **Commit yang diaudit:** `0fc63c7e8d4007007380b8fcfc3b74a0d8010963`
- **Paket audit:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md`
- **Verdict:** `TIDAK-BERSIH`

## Ringkasan Eksekutif

Lee, pemeriksaan ini **tidak dapat menyatakan 11 fase tuntas tanpa utang teknis**. Ada bukti kuat untuk banyak bagian: 132/132 uji SQL lokal lulus, 123/123 berkas uji frontend dengan 1.013/1.013 tes lulus, 47/47 tabel memiliki RLS dan policy, 8/8 RPC penulisan terdaftar dengan kunci idempoten, serta pemeriksa roadmap, panduan, buku uji, rujukan, angka bukti, kontras, dan gerbang CI lulus.

Bukti hijau tersebut belum cukup untuk verdict bersih karena:

1. **Fase 2 memiliki celah K-1:** TOTP untuk owner/admin tidak ada pada alur login aktif. Komponen `MasukPengelola` hanya menguji callback dan tidak dirender oleh `App.tsx`; alur aktif masih login PIN.
2. **Fase 3 memiliki tombol utama yang gagal di database:** `App.tsx` mengirim status `antri`, padahal database hanya menerima `draf → dikirim` dengan `dikirim_ke_dapur_pada`.
3. **Jalur penyimpanan pesanan tidak memakai pintu atomik yang dijanjikan:** aplikasi daring dan replay luring melakukan `insert` langsung, bukan memanggil RPC `simpan_pesanan` dari migrasi 0080.
4. **Temuan keuangan dan keamanan yang sudah tercatat belum mendapat bukti penutupan independen yang cukup.** Pemeriksa temuan melaporkan 117 temuan terlacak, 108 ditutup, dan 5 masih terbuka/bersisa.
5. **Gerbang keseluruhan belum hijau:** CI remote pada commit ini gagal; validator sistem dan validator paket audit juga masih gagal dalam kondisi checkout ini.

Karena itu, **Fase 11 tidak boleh dianggap siap** dari hasil pemeriksaan ini.

## 1. Cakupan

Pemeriksaan dilakukan berurutan. Setiap fase dicocokkan dengan berkas implementasi dan berkas pengujian nyata berikut.

| Fase | Berkas implementasi yang diperiksa | Berkas/perintah pengujian yang diperiksa | Penilaian ringkas (bukti: `perintah`) |
|---|---|---|---|
| Fase 0 — Fondasi | `aplikasi/package.json`, `aplikasi/tsconfig*.json`, `.github/workflows/ci.yml`, `alat/periksa-gerbang-ci.py`, `_sistem/validate_system.py` | `aplikasi/src/uji/harness.test.tsx`, `npm run format:check`, `npm run lint`, `npm run typecheck`, `npm run build`, `python3 _sistem/validate_system.py` | Fondasi kode lulus, tetapi T0-12 masih terbuka dan validator sistem masih merah.  Buktinya: `python3 _sistem/validate_system.py` |
| Fase 1 — Database | `supabase/migrations/0001_penyewa.sql` sampai `0085_ringkasan_harian.sql`, terutama `0001`, `0004`, `0005`, `0018`, `0020`, `0029`, `0030`, `0057`, `0080` | `node alat/uji-sql.mjs`, `supabase/tes/rls_semua_tabel.sql`, `isolasi_lintas_penyewa.sql`, `matriks_izin_6_peran.sql`, `audit_rantai.sql`, `sesi_dan_perangkat.sql`, `idempoten.sql` | Bukti runtime lokal sangat luas dan hijau, tetapi banyak butir dasar T1 masih `[ ]` dan catatan audit keamanan belum seluruhnya ditutup.  Buktinya: `node alat/uji-sql.mjs` |
| Fase 2 — Autentikasi | `aplikasi/src/lib/auth.ts`, `aplikasi/src/hook/useSesi.ts`, `aplikasi/src/App.tsx`, `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`, `aplikasi/src/layar/masuk/MasukPengelola.tsx`, migrasi `0030`, `0058`, `0059`, `0061` | `MasukPengelola.test.tsx`, `LayarMasukPegawai.test.tsx`, `useSesi.test.tsx`, `supabase/tes/mfa.sql`, `verifikasi_pin_perangkat.sql`, `sesi_dan_perangkat.sql` | PIN, perangkat, sesi, dan pemulihan memiliki bukti; TOTP pada login aktif tidak terbukti dan T2-13 tetap terbuka.  Buktinya: `aplikasi/src/App.tsx:532` |
| Fase 3 — Kasir utama | `aplikasi/src/App.tsx`, `aplikasi/src/layar/kasir/LayarKasir.tsx`, `Keranjang.tsx`, `PemilihMeja.tsx`, `aplikasi/src/layar/pelayan/LayarPelayan.tsx`, migrasi `0008_meja.sql`, `0009_pesanan.sql`, `0080_kunci_idempoten_menyeluruh.sql` | `AlurKasirE2E.test.tsx`, `LayarKasir.test.tsx`, `Keranjang.test.tsx`, `PemilihMeja.test.tsx`, `supabase/tes/pesanan.sql`, `status_pesanan.sql`, `idempoten.sql` | Alur visual diuji, tetapi callback kirim di-mock. Payload aplikasi bertentangan dengan kontrak database; T3-05, T3-09, dan T3-13 masih terbuka.  Buktinya: `aplikasi/src/App.tsx:161–173` |
| Fase 4 — Dapur/KDS dan stok | `LayarDapur.tsx`, `LayarBar.tsx`, `KartuPesanan.tsx`, `TombolHabis.tsx`, `Stok.tsx`, `Opname.tsx`, `useTiketDapur.ts`, migrasi `0032`, `0033`, `0035`–`0038` | `LayarDapur.test.tsx`, `LayarBar.test.tsx`, `KartuPesanan.test.tsx`, `TombolHabis.test.tsx`, `Stok.test.tsx`, `Opname.test.tsx`, `useTiketDapur.test.tsx`, `status_item.sql`, `tujuan_item.sql`, `menu_habis_sumber.sql`, `set_stok.sql`, `opname_stok.sql` | Implementasi dan uji nyata ada, tetapi T4-01 sampai T4-10 masih bertanda `[ ]`; tidak boleh disebut tuntas hanya dari keberadaan komponen.  Buktinya: `aplikasi/src/layar/dapur/LayarDapur.test.tsx` |
| Fase 5 — Bayar dan void | `Bayar.tsx`, `DiskonManual.tsx`, `VoidItem.tsx`, `DaftarTransaksi.tsx`, `Struk.tsx`, migrasi `0039_bayar_pesanan.sql`, `0041_diskon_pin_atasan.sql`, `0042_bahan_terbuang_jujur.sql`, `0043_laporan_pembatalan.sql`, `0060_pembayaran_audit.sql` | `Bayar.test.tsx`, `LayarKasirBayar.test.tsx`, `DiskonManual.test.tsx`, `VoidItem.test.tsx`, `DaftarTransaksi.test.tsx`, `supabase/tes/pembayaran.sql`, `pembayaran_audit.sql`, `pembayaran_sebagian.sql`, `bahan_terbuang.sql` | Pembayaran, diskon, dan void memiliki bukti kuat. T5-10 untuk cari transaksi/cetak ulang tetap terbuka dan berhubungan dengan T-028.  Buktinya: `docs/ROADMAP.md:T5-10` |
| Fase 6 — Cetak | `aplikasi/src/lib/printer/struk.ts`, `tiket.ts`, `kirim.ts`, `expos.ts`, `profil.ts`, `aplikasi/src/layar/pengaturan/PasangPrinter.tsx`, `aplikasi/src/komponen/Struk.tsx` | `struk.test.ts`, `tiket.test.ts`, `kirim.test.ts`, `expos.test.ts`, `profil.test.ts`, `PasangPrinter.test.tsx`, `DaftarTransaksi.test.tsx` | Pembungkus printer, tiket, dan label SALINAN diuji; antrean cetak, printer per perangkat/cabang, dan uji nyata T6-06–T6-08 belum tertutup.  Buktinya: `docs/ROADMAP.md:T6-06` |
| Fase 7 — Kas dan shift | `BukaKas.tsx`, `TutupKas.tsx`, `KasKeluarMasuk.tsx`, `LaporanKas.tsx`, `LaporanPenjualan.tsx`, migrasi `0045`–`0054` | `BukaKas.test.tsx`, `TutupKas.test.tsx`, `KasKeluarMasuk.test.tsx`, `LaporanKas.test.tsx`, `LaporanPenjualan.test.tsx`, `supabase/tes/buka_shift.sql`, `tutup_shift.sql`, `kas_pergerakan.sql`, `golden_laporan.sql` | Bukti teknis fase ini lengkap pada runner lokal dan roadmap bertanda selesai; tetap ikut tertahan dari verdict keseluruhan karena gerbang dan temuan lintas fase belum bersih.  Buktinya: `supabase/tes/golden_laporan.sql` |
| Fase 8 — Voucher dan laporan | `aplikasi/src/layar/voucher/Daftar.tsx`, `Kampanye.tsx`, `KartuVoucher.tsx`, layar katalog publik, migrasi `0062`–`0069` | `Daftar.test.tsx`, `Kampanye.test.tsx`, `KartuVoucher.test.tsx`, `LaporanVoucher.test.tsx`, `Katalog.test.tsx`, `supabase/tes/voucher_aturan.sql`, `kasir_voucher.sql`, `laporan_voucher.sql`, `privasi.sql` | Bukti teknis dan uji lokal tersedia; belum menghapus temuan autentikasi, integritas pesanan, atau gerbang CI.  Buktinya: `supabase/tes/voucher_aturan.sql` |
| Fase 9 — Multi-cabang dan pengaturan | `LayarPengaturan.tsx`, `Identitas.tsx`, `Tampilan.tsx`, `Operasional.tsx`, `Meja.tsx`, `Menu.tsx`, `MenuCabang.tsx`, `MetodeBayar.tsx`, `Cabang.tsx`, `KelolaPegawai.tsx`, `Penyewa.tsx`, migrasi `0070`–`0079` | `LayarPengaturan.test.tsx`, `Identitas.test.tsx`, `Tampilan.test.tsx`, `Operasional.test.tsx`, `Meja.test.tsx`, `Menu.test.tsx`, `MenuCabang.test.tsx`, `MetodeBayar.test.tsx`, `Cabang.test.tsx`, `KelolaPegawai.test.tsx`, `Penyewa.test.tsx`, tes SQL pengaturan/cabang | Bukti teknis luas dan roadmap bertanda selesai; status fase tidak dinaikkan menjadi bersih karena audit ini menemukan penghambat lintas fase.  Buktinya: `supabase/tes/kelola_cabang.sql` |
| Fase 10 — Ketahanan dan bencana | `aplikasi/src/lib/antrean-lokal.ts`, `antrean-offline.ts`, `pemulihan-sesi.ts`, `aplikasi/src/hook/useAntrean.ts`, migrasi `0080`–`0085`, `alat/cadangan.sh`, `alat/eksekusi-cadangan.mjs`, `.github/workflows/ci.yml` | `antrean-lokal.test.ts`, `antrean-offline.test.ts`, `pemulihan-sesi.test.ts`, `uji/e2e/luring.spec.ts`, `mati-mendadak.spec.ts`, `supabase/tes/idempoten.sql`, `akhiri_sesi_perangkat_hilang.sql`, `denyut_pembersih.sql`, `pengaturan_bersamaan.sql`, `python3 alat/periksa-idempoten.py` | IndexedDB, backup, pemulihan, dan RPC idempoten memiliki bukti; jalur pesanan daring/luring masih bypass RPC `simpan_pesanan`, sehingga klaim T10-02 belum terbukti di batas aplikasi.  Buktinya: `python3 alat/periksa-idempoten.py` |

### Bukti mesin utama

- `python3 alat/periksa-roadmap.py` dan `--uji-diri`: LOLOS; 193 tugas roadmap dibaca, termasuk tugas yang masih terbuka.
- `python3 alat/periksa-panduan.py` dan `--uji-diri`: LOLOS; 799 baris, 16 alur, 30 perintah, 89 rujukan.
- `python3 alat/periksa-buku-uji.py` dan `--uji-diri`: LOLOS; setiap baris punya langkah, harapan, hasil, dan tugas.
- `python3 alat/periksa-rujukan.py` dan `--uji-diri`: LOLOS; 85 dokumen dan 3.919 rujukan diperiksa. Catatan rencana tetap dicetak sebagai catatan, bukan dihilangkan.
- `python3 alat/periksa-angka-bukti.py` dan `--uji-diri`: LOLOS.
- `node alat/uji-sql.mjs`: LOLOS; 82 migrasi diterapkan, 132 berkas uji lulus, 0 gagal.
- `npm test -- --run` dari `aplikasi/`: exit 0; 123 berkas dan 1.013 tes lulus. Ada stderr `Error: Not implemented: window.alert` dari jalur error `LayarKasir.tsx:445`; ini dicatat, bukan disamakan dengan output bersih.
- `python3 alat/periksa-sisir-rls.py`: LOLOS; 47/47 tabel RLS aktif dan 47/47 memiliki policy.
- `python3 alat/periksa-idempoten.py` dan `--uji-diri`: LOLOS; 8/8 RPC dan skema penyimpan kunci terdaftar.
- `python3 aplikasi/alat/uji-kontras.py`: LOLOS; 166 pemeriksaan, 0 gagal.
- `python3 alat/periksa-gerbang-ci.py`: LOLOS secara statis; 126 gerbang wajib terdeteksi. Ini tidak sama dengan CI remote hijau.
- `npm run format:check`, `npm run typecheck`, `npm run build`, `npm audit --audit-level=low`: format, tipe, build, dan audit dependensi exit 0. Lint exit 0 dengan 26 warning Fast Refresh; build mencetak peringatan chunk JavaScript lebih dari 500 kB.
- `python3 alat/periksa-temuan-audit.py` dan `--uji-diri`: LOLOS sebagai pemeriksa; 117 temuan terlacak, 108 ditutup, 5 terbuka/bersisa.
- `python3 _sistem/validate_system.py`: GAGAL karena lima laporan Akbar yang dirujuk prompt belum ada pada saat perintah dijalankan. Setelah laporan ini dibuat, empat laporan peran lain tetap bukan tanggung jawab pemeriksa fase.
- `python3 alat/periksa-paket.py`: GAGAL; 48 pelanggaran invariant paket/riwayat. Checkout ini dangkal sehingga sebagian kegagalan provenance tidak boleh dianggap sebagai 48 cacat produk.

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | Semua fase yang ditandai selesai benar-benar siap dilanjutkan ke Fase 11 (`docs/ROADMAP.md`, `docs/ops/SIAP-LANJUT.md`) | Cocokkan seluruh tugas T0–T10 dengan implementasi, uji, temuan audit, dan jalur aktif | **Terbantah:** T0-12, T2-13, T3-05/T3-09/T3-13, T4-01–T4-10, T5-10, T6-06–T6-08, dan sisa temuan audit masih menghalangi. |
| 2 | Login pengelola telah memiliki TOTP (`docs/ops/SIAP-LANJUT.md:1804–1819`, T2-13) | Telusuri render `App.tsx`, `useSesi.ts`, `auth.ts`, komponen `MasukPengelola`, serta pencarian TOTP/MFA | **Terbantah:** `App.tsx` merender `LayarMasukPegawai`; tidak ada implementasi TOTP aktif. |
| 3 | Tombol Kirim ke Dapur mengubah pesanan ke status yang sah | Bandingkan payload `App.tsx:161–173` dengan CHECK dan trigger `supabase/migrations/0009_pesanan.sql:155–170` | **Terbantah:** aplikasi mengirim `antri`; database tidak memiliki status itu dan mewajibkan timestamp untuk `dikirim`. |
| 4 | Semua penyimpanan pesanan menggunakan RPC idempoten | Cari semua pemanggilan `pesanan` dan `simpan_pesanan` di `App.tsx` dan `useAntrean.ts`; cocokkan dengan migrasi 0080 | **Terbantah:** jalur daring dan replay luring melakukan insert tabel langsung; RPC ada tetapi tidak dipanggil. |
| 5 | Uji alur kasir membuktikan kiriman database nyata | Baca `AlurKasirE2E.test.tsx` dan `App.test.tsx`, lalu cocokkan dengan handler aplikasi | **Terbantah:** E2E meng-mock `onKirimKeDapur`; `App.test.tsx` hanya menguji buka/tutup shift. |
| 6 | Jejak audit dan cetak ulang siap untuk pertanggungjawaban | Telusuri `DaftarTransaksi`, `Struk`, printer, `catatan_audit`, dan status T5-10/T6-06/T-028 | **Belum terbukti:** label SALINAN dan preview ada, tetapi status roadmap tetap terbuka dan tidak ditemukan pemanggilan audit untuk cetak ulang. |
| 7 | Seluruh pemeriksaan CI yang diwajibkan hijau | Jalankan pemeriksa lokal, lihat metadata CI remote, dan jalankan validator sistem/paket | **Terbantah:** `periksa-gerbang-ci.py` hijau secara struktur, tetapi run CI `36312424923` pada commit ini gagal pada langkah #60; validator sistem dan paket juga gagal. |
| 8 | Kunci uang dan audit yang masih tercatat terbuka sudah selesai hanya karena migrasi baru ada | Cocokkan `docs/uji/AUDIT_RIWAYAT.md` dengan `0015`, `0022`, `0024`, `0029`, `0057` dan uji yang tersedia | **Belum terbukti:** beberapa pagar memang ada dan uji lokal lulus, tetapi catatan `I F-17`, `F F-07`, `F F-08`, dan `A F-07` masih terbuka/bersisa; audit independen atau penyebaran nyata belum dibuktikan. |

## 3. Serangan yang dijalankan (kill attempts)

| # | Serangan | Target | Hasil |
|---|---|---|---|
| 1 | Cari status `antri` di UI, lalu cek apakah status itu ada di database | `App.tsx`, `0009_pesanan.sql` | Status UI ditemukan; status DB tidak ditemukan. |
| 2 | Hapus asumsi timestamp dan cocokkan transisi langsung terhadap trigger | `0009_pesanan.sql:155–170` | Trigger menolak status selain jalur resmi dan timestamp kirim wajib. |
| 3 | Cari RPC `simpan_pesanan` dan semua insert `pesanan` | `App.tsx`, `useAntrean.ts`, `0080_kunci_idempoten_menyeluruh.sql` | RPC ada, tetapi dua jalur aplikasi tidak memakainya. |
| 4 | Uji apakah uji E2E mengirim request Supabase nyata | `AlurKasirE2E.test.tsx`, `App.test.tsx` | Callback kirim di-mock; tidak ada kontrak payload ke Supabase. |
| 5 | Cari titik render TOTP dari entry point aplikasi | `App.tsx`, `MasukPengelola.tsx`, `useSesi.ts` | Entry point aktif tidak merender TOTP; hanya komponen terisolasi yang memiliki tipe/callback. |
| 6 | Cari migrasi atau kode TOTP/MFA aktif | `aplikasi/src`, `supabase/migrations` | Tidak ada hit TOTP/MFA pada jalur login; `supabase/tes/mfa.sql` menguji pemulihan perangkat, bukan TOTP. |
| 7 | Cocokkan semua status `[ ]` tugas T0–T10 dengan klaim handoff | `docs/ROADMAP.md`, `docs/ops/SIAP-LANJUT.md` | Tugas terbuka dan klaim “Fase 2 selesai penuh” bertentangan. |
| 8 | Jalankan seluruh suite SQL terhadap PostgreSQL lokal | `node alat/uji-sql.mjs` | 132/132 lulus; serangan ini tidak membuktikan jalur UI memakai semua RPC. |
| 9 | Jalankan suite frontend penuh dan simak stderr, bukan hanya exit code | `npm test -- --run` | 1.013/1.013 lulus, tetapi ada `window.alert` tidak tersedia dari jalur error kasir. |
| 10 | Jalankan RLS dan matriks izin fail-closed | `periksa-sisir-rls.py`, `periksa-matriks-izin.py` | 47/47 tabel dan matriks 6 peran lulus; tidak menghapus temuan alur kasir. |
| 11 | Jalankan pemeriksa idempotensi lalu bandingkan dengan pemanggil klien | `periksa-idempoten.py`, `App.tsx`, `useAntrean.ts` | 8/8 RPC terdaftar, tetapi caller pesanan bypass RPC; klaim “semua jalur” gagal. |
| 12 | Cari bukti audit untuk cetak ulang | `DaftarTransaksi.tsx`, `Struk.tsx`, `supabase/migrations`, `supabase/tes` | Label SALINAN ada; jejak audit cetak ulang dan T5-10/T6-06 belum terbukti selesai. |
| 13 | Jalankan pemeriksa temuan dan uji-dirinya | `alat/periksa-temuan-audit.py` | Pemeriksa hijau, tetapi hasilnya tetap 5 temuan terbuka/bersisa. |
| 14 | Jalankan validator paket pada checkout saat ini | `alat/periksa-paket.py` | 48 pelanggaran provenance/riwayat dilaporkan; diklasifikasikan sebagai masalah paket/riwayat, bukan otomatis cacat produk. |

## 4. Temuan

### [F-01] TOTP owner/admin tidak ada pada alur login aktif

- **Tingkat:** K-1
- **Artefak:** `aplikasi/src/App.tsx:9,532`, `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`, `aplikasi/src/layar/masuk/MasukPengelola.tsx`, `aplikasi/src/hook/useSesi.ts`, `aplikasi/src/lib/auth.ts`, `docs/ROADMAP.md:T2-13`, `docs/uji/AUDIT_RIWAYAT.md:L F-01`
- **Klaim yang dilanggar:** T2-13 dan klaim handoff bahwa Fase 2 telah selesai penuh dengan TOTP.
- **Bukti:** `find aplikasi/src -iname '*Totp*'` tidak menemukan komponen TOTP; `grep -rn 'butuhTotp' aplikasi/src` hanya menemukan tipe/panggilan mock di `MasukPengelola.tsx`; `App.tsx` merender `LayarMasukPegawai`; pencarian TOTP/MFA pada `supabase/migrations` dan `aplikasi/src/lib` tidak menemukan implementasi aktif.
- **Skenario gagal:** owner atau admin masuk melalui alur login aktif tanpa kode TOTP kedua, sehingga kompromi faktor login utama langsung membuka sesi berkuasa.
- **Dugaan penyebab:** pekerjaan T2-13 direpresentasikan oleh komponen/protokol terisolasi dan uji pemulihan, tetapi tidak dipasang pada entry point login dan tidak memiliki layanan TOTP peladen.
- **Cara membuktikan perbaikan:** buat verifikasi TOTP peladen yang nyata, pasang di `App.tsx`/alur sesi owner-admin, tetapkan perilaku bootstrap dan pemulihan, lalu tambahkan uji integrasi yang gagal bila TOTP dilewati.
- **Status verifikasi:** TERVERIFIKASI secara statis; uji login terhadap Supabase produksi belum dilakukan.

### [F-02] Kirim ke Dapur memakai status database yang tidak sah

- **Tingkat:** K-2
- **Artefak:** `aplikasi/src/App.tsx:161–173`, `aplikasi/src/layar/kasir/LayarKasir.tsx:426–451`, `supabase/migrations/0009_pesanan.sql:155–188`, `aplikasi/src/layar/kasir/AlurKasirE2E.test.tsx`
- **Klaim yang dilanggar:** T3-08 — kirim ke dapur mengubah status pesanan.
- **Bukti:** `App.tsx` memanggil `.update({ status: 'antri' })`; tabel `pesanan` pada migrasi 0009 hanya menerima `draf`, `dikirim`, `dimasak`, `siap`, `lunas`, dan `batal`; trigger hanya menerima `draf → dikirim` dan menolak bila `dikirim_ke_dapur_pada` kosong. Pemeriksaan statis berikut mereproduksi kontradiksi: `python3 - <<'PY' ... .update({ status: 'antri' }) ... old.status = 'draf' and new.status = 'dikirim' ... PY`.
- **Skenario gagal:** kasir membuat pesanan `draf`, menekan **Kirim ke Dapur** saat daring, lalu database menolak nilai status `antri` atau transaksi gagal sebelum pesanan masuk antrean dapur; layar hanya dapat menampilkan pesan gagal.
- **Dugaan penyebab:** istilah status UI lama tidak pernah diselaraskan dengan state machine database dan timestamp wajib tidak dikirim.
- **Cara membuktikan perbaikan:** ubah kontrak caller dan server secara teruji, tambahkan uji integrasi yang memanggil handler dengan Supabase/PostgreSQL nyata, dan pastikan transisi serta timestamp terlihat di KDS.
- **Status verifikasi:** TERVERIFIKASI dari kontrak kode/database; uji UI yang ada belum menangkap karena callback di-mock.

### [F-03] Penyimpanan pesanan aplikasi melewati RPC atomik/idempoten

- **Tingkat:** K-2
- **Artefak:** `aplikasi/src/App.tsx:70–123`, `aplikasi/src/hook/useAntrean.ts:93–158`, `supabase/migrations/0080_kunci_idempoten_menyeluruh.sql:47–57`, `supabase/tes/idempoten.sql`, `aplikasi/src/hook/useAntrean.test.tsx`
- **Klaim yang dilanggar:** T3-05 dan T10-02 — penyimpanan pesanan melewati pintu `simpan_pesanan` dan aman saat retry.
- **Bukti:** pencarian pemanggil menemukan `from('pesanan').insert(...)` di `App.tsx` dan `useAntrean.ts`, sedangkan `rpc('simpan_pesanan', ...)` tidak ditemukan pada caller tersebut. Handler daring memasukkan pesanan lalu item dalam dua operasi; replay luring melakukan pola yang sama. RPC 0080 justru menghitung salinan nama/harga dan mengembalikan balasan idempoten.
- **Skenario gagal:** insert pesanan berhasil tetapi insert item gagal atau koneksi putus di antaranya, sehingga tersisa pesanan `draf`; retry tidak memakai balasan rekaman lama dari RPC dan dapat mengembalikan error unique key atau meninggalkan data separuh jadi.
- **Dugaan penyebab:** migrasi dan uji RPC diselesaikan tanpa mengganti adapter aplikasi yang masih memakai jalur tabel lama.
- **Cara membuktikan perbaikan:** caller daring dan replay luring harus memanggil satu RPC atomik dengan payload yang sama; tambahkan uji kontrak aplikasi untuk retry, kegagalan antar-langkah, harga server, dan balasan idempoten.
- **Status verifikasi:** TERVERIFIKASI dari penelusuran statis; dampak pada deployment Supabase nyata belum dijalankan.

### [F-04] Sisa risiko integritas uang belum ditutup secara independen

- **Tingkat:** K-1
- **Artefak:** `docs/uji/AUDIT_RIWAYAT.md:I F-17`, `supabase/migrations/0022_beku_setelah_bayar.sql`, `supabase/migrations/0024_beku_satu_pernyataan.sql`, `supabase/tes/beku_setelah_bayar.sql`, `supabase/tes/beku_satu_pernyataan.sql`, `alat/uji-mutasi-0022.py`, `alat/uji-mutasi-0024.py`
- **Klaim yang dilanggar:** sisa I F-17/T-025(a) telah dapat dianggap tertutup hanya karena pagar migrasi baru mendarat.
- **Bukti:** `python3 alat/periksa-temuan-audit.py` melaporkan I F-17 sebagai “DITUTUP sebagian · TERBUKA sisa”; `docs/uji/AUDIT_RIWAYAT.md` menyebut jalur pembayaran sudah ada lalu item diturunkan masih memerlukan larangan/koreksi eksplisit dan audit/penyebaran nyata. Uji lokal dan mutasi penutupan memang ada serta lulus, sehingga temuan ini tidak menyatakan pagar tersebut tidak ada.
- **Skenario gagal:** setelah pembayaran sebagian/diterima, jumlah item diturunkan atau item dibatalkan tanpa rekonsiliasi koreksi/refund yang eksplisit; total dapat menjadi lebih kecil dari uang yang sudah diterima dan laporan tidak menjelaskan selisihnya.
- **Dugaan penyebab:** penutupan teknis dan keputusan larangan telah mendarat, tetapi bukti independen pada database tujuan serta jalur operasional koreksi belum tersedia.
- **Cara membuktikan perbaikan:** uji dua koneksi pada database tujuan untuk pembayaran parsial lalu perubahan item, buktikan semua jalur menolak atau membuat koreksi yang tercatat, dan lakukan penutupan formal I F-17/T-025(a) berdasarkan output runner baru.
- **Status verifikasi:** DUGAAN berisiko tinggi; sisa temuan dan kebutuhan bukti penutupan terverifikasi, tetapi skenario produksi belum dijalankan.

### [F-05] Kontrol keamanan dan catatan audit masih berstatus terbuka/bersisa

- **Tingkat:** K-2
- **Artefak:** `docs/uji/AUDIT_RIWAYAT.md:F F-07`, `docs/uji/AUDIT_RIWAYAT.md:F F-08`, `docs/uji/AUDIT_RIWAYAT.md:A F-07`, `supabase/migrations/0020_catatan_audit.sql`, `supabase/migrations/0029_audit_kekal_rantai.sql`, `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql`, `supabase/migrations/0057_truncate_audit_ditolak.sql`, `supabase/tes/catatan_audit.sql`, `supabase/tes/sesi_dan_perangkat.sql`
- **Klaim yang dilanggar:** kontrol wajib keamanan dan catatan audit sudah selesai/tersertifikasi hanya berdasarkan status roadmap.
- **Bukti:** pemeriksa temuan mencatat lima temuan terbuka/bersisa, termasuk F F-07, F F-08, dan A F-07. Kode saat ini memang memiliki tabel `catatan_audit`, trigger append-only/rantai, sesi, dan percobaan masuk; uji SQL juga lulus. Temuan ini secara sengaja menyatakan **status penutupan independen masih kurang**, bukan menyatakan tabel-tabel tersebut tidak ada.
- **Skenario gagal:** pemilik membaca status handoff sebagai jaminan bahwa seluruh kontrol keamanan sudah selesai, padahal residual sesi/percobaan/MFA, pengerasan rantai audit, dan pemeriksaan keamanan efektif masih menunjuk pekerjaan atau bukti tambahan; kontrol yang belum disertifikasi dapat lolos ke pilot.
- **Dugaan penyebab:** implementasi datang dalam beberapa migrasi sesudah catatan temuan, tetapi registri temuan dan bukti penutupan independen belum disegarkan secara konsisten.
- **Cara membuktikan perbaikan:** audit ulang setiap residual F F-07/F F-08/A F-07 dengan output runner dan deployment target, lalu tutup hanya baris yang memiliki bukti baru; khusus TOTP tetap mengikuti F-01.
- **Status verifikasi:** TERVERIFIKASI sebagai masalah status/bukti audit; keberadaan implementasi dasar diverifikasi dan tidak dipungkiri.

### [F-06] Cetak ulang belum memiliki bukti jejak audit dan kesiapan operasional lengkap

- **Tingkat:** K-2
- **Artefak:** `docs/ROADMAP.md:T5-10`, `docs/ROADMAP.md:T6-06–T6-08`, `docs/TERTANGGUH.md:T-028`, `aplikasi/src/layar/kasir/DaftarTransaksi.tsx`, `aplikasi/src/komponen/Struk.tsx`, `aplikasi/src/lib/printer/struk.ts`, `aplikasi/src/lib/printer/tiket.ts`
- **Klaim yang dilanggar:** pencarian transaksi, cetak ulang, antrean cetak, dan deteksi gagal siap untuk pilot.
- **Bukti:** `DaftarTransaksi` dan `Struk` memang memberi label `SALINAN — CETAK ULANG`, dan uji printer memastikan angka tidak dihitung ulang. Namun T5-10 dan T6-06–T6-08 masih `[ ]`/tertangguh; pencarian `cetak ulang`, `catat.*cetak`, dan `audit.*cetak` pada kode aplikasi, migrasi, dan uji tidak menemukan penulisan kejadian cetak ke `catatan_audit`.
- **Skenario gagal:** struk dicetak ulang beberapa kali atau printer gagal setelah sebagian byte terkirim, tetapi owner tidak memiliki jejak siapa/kapan/berapa kali dan tidak ada bukti printer perangkat/cabang nyata yang dapat diandalkan.
- **Dugaan penyebab:** implementasi preview dan formatter selesai lebih dahulu daripada antrean pekerjaan printer, penyimpanan per perangkat/cabang, dan uji lapangan.
- **Cara membuktikan perbaikan:** tetapkan event cetak/reprint yang tercatat, antrekan job secara idempoten dengan status gagal/retry, uji 58/80 mm serta Bluetooth/USB pada perangkat target, dan tutup T5-10/T6-06/T6-08 dengan bukti baru.
- **Status verifikasi:** TERVERIFIKASI untuk status tugas dan ketiadaan bukti audit yang dicari; uji perangkat fisik belum dilakukan.

### [F-07] Gerbang keseluruhan dan provenance paket audit belum hijau

- **Tingkat:** K-2
- **Artefak:** `.github/workflows/ci.yml`, `alat/periksa-gerbang-ci.py`, `_sistem/validate_system.py`, `alat/periksa-paket.py`, `docs/uji/paket-audit/`, metadata CI run `36312424923`
- **Klaim yang dilanggar:** pemeriksaan Akbar dan CI sudah dapat disebut hijau secara keseluruhan.
- **Bukti:** metadata GitHub untuk commit `0fc63c7e8d4007007380b8fcfc3b74a0d8010963` menunjukkan run `36312424923` **failure** pada langkah #60. `python3 _sistem/validate_system.py` gagal karena lima laporan peran yang dirujuk belum ada saat pemeriksaan dijalankan. `python3 alat/periksa-paket.py` gagal dengan 48 pelanggaran invariant paket/riwayat; repository ini juga merupakan klon dangkal. `python3 alat/periksa-gerbang-ci.py` hanya membuktikan 126 gerbang masih tercantum, bukan bahwa run remote berhasil.
- **Skenario gagal:** Lee menerima label “semua gerbang hijau” dari pemeriksa struktur, lalu menjalankan pilot sementara CI target atau provenance audit sebenarnya gagal dan laporan horizontal belum tersedia.
- **Dugaan penyebab:** status remote dan paket audit berkembang tidak serempak; riwayat lokal dangkal juga menghalangi pemeriksaan ancestry paket lama.
- **Cara membuktikan perbaikan:** jalankan CI pada commit target sampai hijau, ambil log langkah gagal, gunakan riwayat penuh untuk validator paket, lalu lengkapi dan validasi seluruh laporan peran Akbar.
- **Status verifikasi:** TERVERIFIKASI dari output lokal dan metadata remote; akar detail langkah #60 belum dapat diverifikasi karena `gh run view --log-failed` berakhir EOF dari Results Receiver.

### [F-08] Status roadmap dan handoff tidak konsisten dengan bukti fase

- **Tingkat:** K-3
- **Artefak:** `docs/ROADMAP.md:T0-12`, `T1-11`–`T1-22`, `T2-13`, `T3-05`, `T3-09`, `T3-13`, `T4-01`–`T4-10`, `T5-10`, `T6-06`–`T6-08`; `docs/ops/SIAP-LANJUT.md:1804–1819`
- **Klaim yang dilanggar:** pembaca dapat memakai handoff sebagai ringkasan status yang tunggal dan tidak bertentangan.
- **Bukti:** `python3 alat/periksa-roadmap.py` lulus sebagai pemeriksa format, tetapi roadmap masih memiliki tugas terbuka yang relevan; handoff pada bagian “Fase 2 selesai penuh” menyebut T2-13/TOTP sementara roadmap T2-13 masih `[ ]` dan entry point aktif tidak merendernya. Hal serupa terjadi ketika komponen Fase 4 ada tetapi seluruh T4 masih `[ ]`.
- **Skenario gagal:** pengambil keputusan membaca angka “fase selesai penuh” tanpa mencocokkan roadmap dan kode aktif, lalu menganggap pekerjaan yang belum diverifikasi sudah menjadi jaminan pilot.
- **Dugaan penyebab:** catatan handoff lama tidak diselaraskan setelah migrasi dan audit lanjutan mendarat.
- **Cara membuktikan perbaikan:** setelah bukti baru diterima, selaraskan handoff, roadmap, dan registri temuan melalui keputusan Lee; jangan mengubah tanda selesai sebagai bagian dari audit ini.
- **Status verifikasi:** TERVERIFIKASI sebagai ketidaksinkronan dokumentasi; laporan ini tidak mengubah dokumen sumber.

**Ringkasan tingkat temuan laporan ini:** 2 K-1, 5 K-2, 1 K-3, 0 K-4. Temuan F-04 dan sebagian F-05 sengaja diberi status DUGAAN bila bukti runtime/deployment akhir belum ada; status itu bukan izin untuk menganggapnya selesai.

## 5. Kalibrasi cacat tanaman

`Ditemukan: 0 dari 0 (tidak dijalankan sebagai kalibrasi AUD-3)`.

- Berkas kalibrasi mesin yang dirujuk, `/home/user/.kalibrasi/kalibrasi-cacat.json`, tidak tersedia pada sesi ini. Karena itu tidak ada skor AUD-3 yang boleh diklaim.
- Lima bahan internal dibaca sebagai kalibrasi manual arah serangan, bukan sebagai hasil kalibrasi resmi dan bukan sebagai angka tingkat deteksi.
- Tingkat laporan sengaja `AUD-2`, yaitu review vertikal independen dengan keterbatasan yang ditulis terang. Laporan ini **tidak menutup T0-12**, tidak mengeluarkan verdict paket horizontal/holistik, dan tidak menyatakan kalibrasi AUD-3 berhasil.

## 6. Yang tidak bisa saya verifikasi

- Tidak ada akses runtime ke proyek Supabase produksi/target deployment; uji SQL 132/132 berjalan pada PostgreSQL lokal di dalam runner.
- Tidak ada uji fisik Bluetooth, USB, printer 58/80 mm, atau uji Kedai Oasis; T6-08 tetap terbuka.
- Tidak ada uji browser end-to-end terhadap alur login dan kirim dapur dengan Supabase nyata. Uji frontend yang ada dapat lulus dengan mock.
- Akar detail CI langkah #60 tidak dapat dibaca karena `gh run view --log-failed` berakhir EOF dari Results Receiver; metadata run gagal tetap terlihat dan dicatat.
- `alat/periksa-paket.py` berjalan pada klon dangkal dengan dua batas ancestry; 48 pelanggaran dicatat sebagai masalah provenance/riwayat, bukan dihitung otomatis sebagai 48 cacat produk.
- Tidak tersedia sesi/model auditor kedua yang dapat dibandingkan dalam konteks ini. Independensi yang tersedia adalah mandat hanya-baca, penelusuran kontrak silang, dan runner mesin; ini bukan bukti dua penilai terpisah.
- Kalibrasi AUD-3 resmi tidak dapat dijalankan karena berkas kalibrasi tidak tersedia.

## 7. Pernyataan tidak mengubah apa pun

Saya melakukan pemeriksaan hanya-baca. Saya tidak mengubah roadmap, tanda `[x]`/`[ ]`, kode aplikasi, migrasi, uji, handoff, registri temuan, atau artefak proyek lain. **Satu-satunya berkas yang dibuat auditor adalah laporan ini:** `docs/uji/audit/LAPORAN_AKBAR_PEMERIKSA_FASE.md`.

Bukti status kerja setelah laporan dibuat harus menunjukkan hanya berkas laporan ini sebagai perubahan auditor; berkas build di folder yang diabaikan Git tidak dihitung sebagai artefak proyek yang diubah.

## 8. Temuan di luar cakupan

| # | Temuan | Mengapa di luar cakupan pemeriksa fase | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| L-01 | Audit horizontal Spesialis Data, Frontend, dan Infrastruktur belum digabungkan | Mandat ini hanya jejak fase vertikal, bukan pemeriksaan spesialis penuh | `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md:13–22` | Tunggu laporan peran masing-masing dan cocokkan silang pada commit yang sama. |
| L-02 | Kesetaraan deployment Supabase produksi dengan 82 migrasi lokal | Tidak ada akses deployment produksi dalam mandat hanya-baca ini | `node alat/uji-sql.mjs` hanya menjalankan PostgreSQL lokal | Auditor data/pemilik menjalankan pemeriksaan schema/deployment pada target resmi. |
| L-03 | Uji lapangan printer dan pilot kedai | Pemeriksa tidak memiliki perangkat fisik atau otorisasi pilot | `docs/ROADMAP.md:T6-08` | Tutup T6-08 dengan bukti perangkat dan keputusan Lee. |
| L-04 | Penyebab teknis rinci CI langkah #60 | Log Results Receiver tidak tersedia pada sesi ini | `gh run view 36312424923 --log-failed` berakhir EOF | Pemilik/integrator mengambil log dari GitHub lalu menjalankan ulang pada commit yang sama. |

## Kesimpulan dan Penutup Chat

**Posisi Sekarang:** Resto Barokah **TIDAK-BERSIH**. Fase 0–10 memiliki banyak implementasi nyata dan suite lokal yang hijau, tetapi belum terbukti bebas utang teknis. K-1 terpenting adalah TOTP aktif dan sisa integritas uang; K-2 terpenting adalah kirim dapur yang memakai status salah, bypass RPC pesanan, kontrol audit/keamanan yang belum ditutup, cetak ulang tanpa bukti audit lengkap, serta CI/provenance yang belum hijau.

**Rencana Selanjutnya:** Jangan mengubah roadmap sebagai bagian dari audit ini. Pemilik/integrator perlu menutup F-01 sampai F-08 dengan uji regresi dan bukti runtime/deployment baru, menyegarkan status temuan yang memang sudah terbukti tertutup, melengkapi laporan horizontal yang hilang, dan menjalankan CI target sampai hijau. Setelah itu lakukan pemeriksaan silang sebelum mempertimbangkan Fase 11.

**Langkah Lee:** Tinjau laporan ini, terutama F-01/F-02/F-03/F-04, lalu putuskan urutan perbaikan dan siapa yang diberi izin mengubah kode atau status roadmap. Jangan merge/close PR atau menyatakan siap pilot sebelum bukti penutupan baru diverifikasi.
