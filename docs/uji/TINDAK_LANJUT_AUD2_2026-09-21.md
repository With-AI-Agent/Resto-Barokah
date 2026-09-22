# Panen dua laporan AUD-2 — target 09bcb89, belum menutup gerbang

**Status:** dua laporan selesai menurut Lee; sesi ketiga error, **abaikan**. Tidak
meminta audit ulang. Integrator memvalidasi **format**, belum mereproduksi/membantah
klaim teknis di bawah. T1-30/T1-45 tetap `[ ]`, tidak ada izin merge/deploy atau
perluasan fitur. Pemilik seluruh tindak lanjut: **agent integrator T1-45**, dengan
agent T1-30 untuk katalog/gerbang. Ini pekerjaan teknis, bukan keputusan Lee yang
baru; lanjutkan reproduksi K-2 dulu pada pekerjaan audit berikutnya.

## Penugasan G3 yang disetujui Lee (2026-09-21)

**Hasil panen 2026-09-22:** T-04/A-F01+A-F03, T-05/A-F02, dan T-06/B-F01..B-F09
sudah diterima dari tiga cabang pekerja dan disalin apa adanya ke cabang integrator;
provenance ada di `docs/ops/PAPAN_TUGAS.md`. Ini bantah-balik, bukan audit AUD-2
pengganti; sesi ketiga lama tetap diabaikan. Target kerja G3 tetap
**e50bac4d897ca65b37dde9e64dbd246a3891b041** (CI 35600019563 SUCCESS), dibandingkan
09bcb89 historis. Paket terbit pada `598e40ca4e873ccea719cfb281e072a4e723a5ff`.
Integrator mengulang bukti dan telah menanam batch perbaikan 0024–0026 serta
penguatan alat/CI di working tree; status substantif baru dinyatakan tertutup
setelah hosted CI batch ini hijau. A-F04/A-F05/A-F06/B-F10 tetap dilacak; A-F04
sudah punya regresi dua-koneksi lokal, A-F05 dokumentasi angka sedang direkonsiliasi,
dan A-F06 punya uji keterpanggilan trigger.

## Provenance dan akar kegagalan push

Repo `With-AI-Agent/Resto-Barokah`, cabang auditor
`arena/01a0c39d-resto-barokah`, folder asal keduanya `docs/uji/audit/`,
nama asal `LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.md`
(provenance pada cabang remote, bukan nama berkas arsip lokal).

| Asal | Commit penuh | Salinan tak diubah |
|---|---|---|
| A, TIDAK-BERSIH, 6 temuan (2 K-2) | `5529eae99fbd6f369b41ef599919418a3719adee` | `docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.dari-5529eae.md` |
| B, BERSIH-DENGAN-CATATAN, 10 K-3 | `b8290b3d125df3971dcaab974c96586c11f0976a` | `docs/uji/audit/LAPORAN_AUD-2_2026-09-21_terarah__01a0c39d.dari-b8290b3.md` |

Kedua commit saudara berinduk `253d1297a3b81433d7f5809afd257d8a1b40958f`.
B berkembang ke `7ad811211d1ff1b4cf0f0a4ca4c1da8b84e07f06`; merge
`b68490ed7cdbe52175e546c2df0bd0454418bb13` menggabungkannya dengan A. Tip yang
Lee kirim `7eb30341442bb1676d298d6d72ff33075886061f` memiliki **satu berkas**,
A ditaruh dalam lampiran; bukan dua arsip terpisah. A tetap tersedia dalam riwayat.
Integrator mengambil **dua versi asal** lewat `git show <commit>:<path>`;
tidak merge cabang/kode auditor dan tidak menggabungkan verdict. Banding byte/blob
salinan dengan objek Git asal sebelum commit. Ini juga membuktikan penanda cabang
bukan ID sesi unik; penolakan non-fast-forward melindungi riwayat.

Target keduanya `09bcb89fc139b3be32ab874e7a004f0a3b0480ee`; paket tetap diterbitkan
pada `742518cc09b2cb8ae2ee5e8568344e297e8ca0c9`, tidak disunting. Laporan B tidak
berhasil menjalankan SQL/concurrency; tidak boleh membatalkan K-2 A. Klaim model
berbeda **belum bisa dibuktikan**, dan cabang sama tidak membuktikan identitas
sesi; jangan menyatakan persyaratan independensi model sudah terpenuhi.

## Pemeriksaan penerimaan yang sudah dilakukan

- Kedua salinan byte-identik dengan objek asal (Git blob hash).
- `alat/audit-independen.py --periksa-laporan <salinan>` dalam klon bersih
  branch integrator pada 5d3b449: **exit 0 keduanya**. A: 32 artefak, 7 klaim,
  22 serangan, 6 temuan. B: 81 artefak, 13 klaim, 41 serangan, 10 temuan.
- Pemeriksa di checkout implementasi menolak karena perubahan alat nonlaporan;
  tidak membersihkan perubahan untuk memaksanya lolos. Klon terisolasi memisahkan
  validasi format dari pekerjaan integrator. Exit 0 bukan pembuktian klaim teknis.

## Antrean wajib dan syarat penutupan

Semua baris **TERBUKA — belum dibantah-balik integrator**. ID A/B adalah asal laporan,
bukan auditor/model baru. Bukti/perintah lengkap ada pada F-xx laporan bersangkutan.

| ID | Klaim / prioritas | Langkah berikut dan bukti penutup wajib |
|---|---|---|
| A-F01 | K-2, CTE pembayaran + perubahan jejak satu statement melewati 0022 | **TERVERIFIKASI perilaku pada PG/PGlite; pagar lokal ditanam, CI belum dicatat.** Integrator menambah migrasi baru `0024_beku_satu_pernyataan.sql`, regresi `supabase/tes/beku_satu_pernyataan.sql`, dan mutasi `alat/uji-mutasi-0024.py`; jangan ubah migrasi beku. Keterjangkauan klien tetap batas jujur pekerja. |
| A-F02 | K-2, authenticated tanpa sub melewati isolasi RPC | **TERVERIFIKASI perilaku; pagar lokal ditanam, CI belum dicatat.** Migrasi baru `0025_isolasi_identitas_null.sql` mensyaratkan role sesi + klaim JWT `service_role` yang cocok (serta tetap mengizinkan pemicu internal), dengan regresi `supabase/tes/isolasi_null_identitas.sql` + `alat/uji-mutasi-0025.py`. Keterjangkauan PostgREST produksi tetap BELUM-TERVERIFIKASI; akses SQL superuser langsung adalah batas ancaman yang dicatat. |
| A-F03 | K-3, tes/mutasi satu statement belum ada | **DITANGANI lokal, menunggu CI:** regresi CTE + kontrol sebelum bayar hijau; pagar dilepas → `MERAH-PAGAR`; SQL rusak → `RUSAK`. Harness 0024 terdaftar di CI/gerbang/paritas. |
| A-F04 | K-3, deadlock multi-parent edit item | Reproduksi PG dua koneksi; bedakan cacat lama dan janji urutan kunci 0022, bukti jadwal/SQLSTATE dan rollback atomik. |
| A-F05 | K-4, angka bukti basi | Banding angka pada target dan saat ini, perbaiki sumber/penjaga dengan mutasi; jangan mengubah arsip menjadi klaim baru. |
| A-F06 | K-4, 11 trigger non-definer EXECUTE terbuka | Baca katalog efektif + keterpanggilan RPC nyata; risiko belum terbukti. Uji pencabutan tidak merusak trigger sebelum keputusan. |
| B-F01 | K-3, classifier runtime+asersi campuran | Jalankan R0/R1 §3.3, seluruh sebab runtime wajib ditolak meski ada asersi; buktikan caller T1-30. |
| B-F02 | K-3, kalibrasi concurrency semua False | R0/R2; bedakan pelanggaran tersimpan vs koneksi/deadlock/timing, kontrol negatif nyata. |
| B-F03 | K-3, mutan progres 0022 merusak dua pagar | R0/R3; isolasikan satu pagar per mutan, kontrol positif status masak tetap sah. |
| B-F04 | K-3, ekspresi CI/shell melemahkan guard | R0/R4; fixture continue-on-error ekspresi dan shell yang tidak menjalankan tes harus merah. |
| B-F05 | K-3, daftar lokal vs CI beda | Daftar dalam §3 laporan; rekonsiliasi perintah/pengecualian eksplisit, mutasi kehilangan satu perintah wajib ditolak. |
| B-F06 | K-3, PIN log/body/alias lolos | R0/R5 + N1; spy sink log dan sentinel PIN di handler asli, jangan klaim baseline sudah bocor. |
| B-F07 | K-3, scanner secret key format baru | R0/R6; fixture sintetis secret vs publishable (tanpa token nyata), uji negatif. |
| B-F08 | K-3, workflow bukan CI dianggap bukti | R0/R7; fixture CI gagal + deploy sukses harus ditolak; bukan tuduhan CI target asli palsu. |
| B-F09 | K-3, SHA baris CI beda target | R0/R7; tolak mismatch sebelum API, tetap terima kontrol SHA benar. |
| B-F10 | K-3, status duplikat basi | R0/R8; bedakan sejarah/status aktif, tautkan penutup kanonik tanpa mencentang sisa T1-24. |

**Status integrator G3 setelah panen (2026-09-22, sebelum hosted CI batch):**

| Kelompok | Status bukti | Perubahan lokal / batas |
|---|---|---|
| A-F01/A-F03 | perilaku terverifikasi; penutupan kode menunggu CI | migrasi/regresi/mutasi 0024 |
| A-F02 | perilaku terverifikasi; penutupan kode menunggu CI; keterjangkauan produksi belum terverifikasi | migrasi/regresi/mutasi 0025 |
| B-F01 | diperbaiki lokal + uji-diri campuran runtime/asersi | classifier fail-closed + `periksa-keamanan-sql` |
| B-F02 | diperbaiki lokal + uji-diri enam kasus | kalibrasi concurrency menerima bukti spesifik saja |
| B-F03 | diperbaiki lokal | mutasi BEFORE/AFTER 0022 tepat satu pagar |
| B-F04 | diperbaiki lokal | guard ekspresi `continue-on-error` + `shell: cat` |
| B-F05 | diperbaiki lokal | paritas 83 perintah CI vs skrip lokal + mutasi hapus |
| B-F06 | diperbaiki lokal + runtime log spy | checker PIN lebih sempit + E18 mutant log |
| B-F07 | diperbaiki lokal + fixture sintetis | scanner `sb_secret_` |
| B-F08 | diperbaiki lokal + fixture workflow | `ci_target` wajib path CI + SHA tepat |
| B-F09 | diperbaiki lokal + uji-diri | SHA baris CI harus sama dengan target |
| A-F04 | terverifikasi deadlock lama; dipagari lokal, CI menunggu | migrasi 0026 + uji dua koneksi/mutasi |
| A-F05/A-F06/B-F10 | ditangani dokumentasi/kontrol lokal, belum penutupan final | angka/status canon tetap wajib disegarkan dan diverifikasi |

**Urutan:** A-F01/A-F02 → A-F03/A-F04 → B-F01..B-F09 (gerbang pembuktian) →
A-F05/A-F06/B-F10. Setiap penutup perlu hasil mentah kontrol/cacat/pulih, SHA perbaikan
serta CI commit itu; jangan menutup seluruh tugas dari laporan format-hijau.
Tidak ada merge/deploy; verifikasi/sebar Supabase tetap perlu izin Lee.

## Catatan mekanisme ditemukan saat persiapan G3 (belum ditutup)

Pemilik integrator T1-44, sesudah panen penghalang K-2: pemeriksa paket AUD lama
masih mencari teks checkout--detach di pembuka, sedangkan generator/prompt baru
mengutamakan salinan terisolasi tanpa checkout bersama. **DUGAAN ketidakselarasan
kontrak**, belum menjalankan fixture end-to-end paket AUD baru untuk menutupnya.
Langkah berikut: buat paket AUD baru di salinan → jalankan periksa-paket → buktikan
kontrol lama/baru dan mutan bootstrap hilang, lalu selaraskan tanpa melonggarkan
pin target/CI atau menyunting paket beku. G3 adalah kontrak tugas reproduksi di
folder maraton, bukan audit AUD dengan klaim lulus validator AUD; jangan memakai
G3 sebagai alasan menghindari gerbang itu ketika menerbitkan audit penuh kelak.
