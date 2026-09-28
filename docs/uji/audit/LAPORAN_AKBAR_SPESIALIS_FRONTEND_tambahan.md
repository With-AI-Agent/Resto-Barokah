# Laporan Tambahan Audit Akbar — Spesialis Frontend & Kasir Lapangan (Pelengkap)

- **Auditor:** agen pemeriksa sesi `arena/01a0e267-resto-barokah` (putaran kedua, hanya-baca).
- **Tanggal:** 2026-09-27 UTC
- **Tingkat audit:** AUD-2 (pemeriksaan spesialis horizontal Fase 0–10) — **pelengkap**, bukan pengganti.
- **Commit yang diaudit:** `0fc63c7e8d4007007380b8fcfc3b74a0d8010963`
- **Paket audit:** `docs/uji/PAKET_PEMERIKSAAN_AKBAR_F0_F10.md` dan `docs/uji/PROMPT_AKBAR_SPESIALIS_FRONTEND.md`.
- **Alasan commit berbeda:** HEAD berisi laporan/laporan audit lain (`docs(audit): …`) yang ditulis sesi lain; pohon **kerja** yang saya periksa adalah commit `0fc63c7e`, dan tidak satu pun berkas `aplikasi/src/` di pohon itu berubah sejak pengauditan (dicek dengan `git diff 0fc63c7e HEAD -- aplikasi/src docs/PETA_UI.md` → kosong).
- **Hubungan dengan laporan lain:** laporan peran ini sudah ada di cabang ini sebagai `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md` (SIA-01). Laporan ini **tidak menimpa** berkas itu; ia memuat temuan yang **belum ada di sana**, semuanya masih terbuka pada commit di atas. Rujukan silang ditambahkan di berkas SIA-01.
- **Verdict:** TIDAK-BERSIH — MEMERLUKAN PERBAIKAN sebelum Fase 11 (menambah 3 temuan terbuka pada SIA-01: 1 K-2, 2 K-3).

## Ringkasan eksekutif

Mesin sudah hijau dan fitur inti yang Lee minta (keyboard PIN, anti-intipan, IndexedDB, sanitasi) sudah dibuktikan pada SIA-01. Yang saya tambahkan adalah tiga celah yang **tidak tercakup SIA-01**, dan dua di antaranya saya buktikan dengan menjalankan pengujian nyata:

1. **Pesanan yang tampak "sudah masuk" belum tentu sampai ke dapur.** Saat internet putus di tengah alur kasir, pesanan memang masuk antrean, tetapi perintah "Kirim ke Dapur" sesudahnya tidak ikut diantrekan. Setelah jaringan pulih, pesanan tersimpan tanpa pernah berpindah ke antrean dapur.
2. **Layar pelayan bisa menyatakan "✅ Pesanan berhasil dikirim ke dapur!" padahal tidak ada pengiriman sama sekali.** Ini saya buktikan dengan menjalankan layarnya tanpa penangan pengiriman — persis kondisi yang dipasang `App.tsx`.
3. **Percobaan ulang setelah kegagalan sebagian dapat menandai pesanan "terkirim" tanpa melengkapi itemnya**, karena bentrok kunci/ID apa pun diperlakukan sebagai duplikat yang aman.

## Tabel bukti pengujian

| # | Bukti | Hasil |
|---|---|---|
| 1 | Laporan SIA-01 (`git show FETCH_HEAD:docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md`) | Dibaca penuh lebih dulu; F-01…F-13 dipetakan agar tidak ada duplikasi. Hasil: tiga temuan di bawah **belum ada** di sana |
| 2 | Uji nyata di `aplikasi/alat/uji-sementara-pelayan.test.tsx` (berkas sementara, **sudah dihapus** setelah bukti diambil) | `render(<LayarPelayan namaPelayan="Pelayan Uji" />)` + klik "+ Tambah" + klik Kirim → `TEXT_HALAMAN` memuat `"✅ Pesanan berhasil dikirim ke dapur!"`; hasil uji `1 passed` |
| 3 | `nl -ba aplikasi/src/App.tsx \| sed -n '120,175p'` | `onSimpanPesanan` mengantrekan saat gagal (baris 124-147); `onKirimKeDapur` (161-173) **tidak** punya jalur antre, hanya kembalikan `sukses:false` |
| 4 | `rg -n 'tambahKeAntrean\|tambahAntrean\(' aplikasi/src --glob '!*.test.*'` | Pemanggil produksi hanya `App.tsx:127` untuk `simpan_pesanan`; tidak ada untuk status dapur/pembayaran |
| 5 | `nl -ba aplikasi/src/hook/useAntrean.ts \| sed -n '112,154p'` | Jalur duplikat `23505`/`kunci_idempoten` → `return { sukses: true }` (baris 123-127) **sebelum** insert item (131-145) |
| 6 | `nl -ba aplikasi/src/layar/kasir/LayarKasir.tsx \| sed -n '426,452p'` | Rantai `onSimpanPesanan` → `onKirimKeDapur`; kegagalan tahap kedua hanya `alert()` |
| 7 | `cd aplikasi && npm test -- --run` (satu perintah wajib; diulang) | 123 berkas / 1013 uji lolos — **tidak ada** uji yang menangkap ketiga temuan ini |

## 1. Cakupan

| # | Artefak | Diperiksa? | Bukti |
|---|---|---|---|
| 1 | Laporan SIA-01 (agar tidak duplikat) | Ya, baca penuh | `git show FETCH_HEAD:docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md` |
| 2 | Alur kasir: simpan → kirim dapur | Ya, telusur + jalankan | `nl -ba aplikasi/src/App.tsx \| sed -n '120,175p'`; `nl -ba aplikasi/src/layar/kasir/LayarKasir.tsx \| sed -n '426,452p'` |
| 3 | Layar pelayan + pemasangan prop dari App | Ya, dijalankan nyata | `nl -ba aplikasi/src/App.tsx \| sed -n '460,470p'`; `nl -ba aplikasi/src/layar/pelayan/LayarPelayan.tsx \| sed -n '47,60p;117,133p'` |
| 4 | Penangan default antrean (duplikat) | Ya, baca baris | `nl -ba aplikasi/src/hook/useAntrean.ts \| sed -n '112,154p'` |
| 5 | Pemanggil produksi `tambahKeAntrean` | Ya, pencarian kode | `rg -n 'tambahKeAntrean\|tambahAntrean\(' aplikasi/src --glob '!*.test.*'` |
| 6 | Jaring uji yang seharusnya menangkap ini | Ya, dijalankan ulang | `cd aplikasi && npm test -- --run` → 123/123 |

## 2. Klaim pembangun yang saya coba falsifikasi

| Klaim | Cara uji | Hasil |
|---|---|---|
| "Pesanan tersimpan di antrean luring (akan dikirim saat kembali daring)" menyelesaikan seluruh alur | Telusur pesan sukses App ke aksi dapur sesudahnya | Pesan itu benar untuk **penyimpanan**, tetapi tiket dapur tidak ikut dipulihkan (F-14) |
| Layar pelayan sudah terhubung ke peladen | Jalankan `LayarPelayan` tanpa prop, seperti App memasangnya | Pesan sukses muncul tanpa satu pun pengiriman (F-15) |
| Pengiriman ulang aman dari pesanan ganda | Baca jalur `23505` dan urutan insert | Aman dari dobel, tetapi bisa **sukses palsu** saat item tertinggal (F-16) |
| SIA-01 sudah menyeluruh | Baca seluruh 13 temuan SIA-01 | Tidak ada yang membahas jalur pengiriman dapur, prop pelayan, atau sukses-palsu duplikat |
| Uji hijau = alur lapangan aman | Jalankan seluruh suite | 1013 uji lolos tanpa menangkap F-14/F-15/F-16 |

## 3. Serangan yang dijalankan (kill attempts)

| Skenario | Cara | Hasil |
|---|---|---|
| Internet putus tepat setelah pesanan tersimpan | Telusur `App.tsx:124-147` → `:161-173` | Simpan masuk antrean; kirim dapur gagal tanpa antre ulang (F-14) |
| Jaringan pulih, kasir berharap dapur menerima tiket | Baca penangan default `useAntrean.ts:112-154` | Hanya insert pesanan+item; status dapur tidak pernah diubah (F-14) |
| Render layar pelayan persis seperti di produksi | Uji nyata jsdom di salinan sementara | Muncul "✅ Pesanan berhasil dikirim ke dapur!" tanpa pengiriman (F-15) |
| Klik kirim dua kali di layar pelayan | Baca `LayarPelayan.tsx:117-133` | Sukses palsu berulang; keranjang dikosongkan sehingga item hilang dari pandangan (F-15) |
| Perangkat dimatikan setelah induk pesanan tersimpan, sebelum item | Baca urutan insert `useAntrean.ts:112-145` | Percobaan ulang bertemu `23505` → dilaporkan sukses sebelum item diinsert (F-16) |
| Pelayan buka Menu Utama yang tidak punya case | `rg -n "case '" aplikasi/src/App.tsx` | Beberapa ID jatuh ke `LayarContoh` (sudah dicatat sebagai bagian F-15) |

## 4. Temuan

### [F-14] Tiket dapur tidak dipulihkan setelah pesanan luring terkirim
- **Tingkat:** K-2 (Tinggi) — menyentuh alur nyata kasir ke dapur saat jaringan kedai buruk.
- **Artefak:** `aplikasi/src/App.tsx:124-147` (jalur antre) dan `aplikasi/src/App.tsx:161-173` (`onKirimKeDapur`); `aplikasi/src/layar/kasir/LayarKasir.tsx:426-452`; `aplikasi/src/hook/useAntrean.ts:112-154`.
- **Klaim yang dilanggar:** janji "simpan saat putus → kirim otomatis saat online" untuk seluruh alur kasir, bukan hanya penyimpanan.
- **Bukti:** `nl -ba aplikasi/src/App.tsx | sed -n '120,175p'` → `onSimpanPesanan` memanggil `tambahKeAntrean` di `catch`, sedangkan `onKirimKeDapur` hanya `update({ status: 'antri' })` dan `return { sukses: false, pesan: error.message }` tanpa antre. `rg -n 'tambahKeAntrean|tambahAntrean\(' aplikasi/src --glob '!*.test.*'` → hanya satu pemanggil produksi (`App.tsx:127`). Penangan sinkronisasi `useAntrean.ts:112-154` hanya insert pesanan dan item; tidak ada perubahan status ke `antri`.
- **Skenario gagal:** kasir menekan "Kirim ke Dapur" saat internet mati → pesan simpan sukses, kirim gagal, keranjang tetap ada. Saat jaringan pulih, pesanan masuk peladen **tanpa** pernah masuk antrean dapur; dapur tidak memasak pesanan itu kecuali kasir mengulanginya manual.
- **Dugaan penyebab:** alur dua tahap (simpan lalu kirim) diantrekan hanya pada tahap pertama; status dapur dianggap aksi layar yang harus online.
- **Cara membuktikan perbaikan:** uji integrasi di mana tahap simpan luring lalu `onKirimKeDapur` gagal, kemudian online → harus menghasilkan tepat satu pesanan berstatus `antri` dan satu tiket dapur; bila status dapur tidak bisa diantrekan, pesan kasir harus jujur "belum masuk dapur" (bukan "berhasil"). `cd aplikasi && npm test -- --run` tetap hijau.
- **Status verifikasi:** TERVERIFIKASI secara jalur kode; belum diuji di peladen nyata.

### [F-15] Layar pelayan melaporkan sukses kirim tanpa pengiriman apa pun
- **Tingkat:** K-3 (Sedang; naik ke K-2 bila peran pelayan diaktifkan di pilot).
- **Artefak:** `aplikasi/src/App.tsx:465-470`; `aplikasi/src/layar/pelayan/LayarPelayan.tsx:47-60,117-133,136`.
- **Klaim yang dilanggar:** aksi tulis pada layar hidup harus benar-benar menulis; pesan sukses harus berdasarkan bukti peladen.
- **Bukti:** uji nyata (berkas sementara `aplikasi/alat/uji-sementara-pelayan.test.tsx`, sudah dihapus) → `render(<LayarPelayan namaPelayan="Pelayan Uji" />)`, klik "+ Tambah", klik "Kirim": keluaran `TEXT_HALAMAN` memuat `"✅ Pesanan berhasil dikirim ke dapur!"`; vitest `1 passed`. Kode `LayarPelayan.tsx:122-125` hanya memanggil `onKirimPesanan` **bila ada**, lalu tanpa syarat menampilkan sukses dan mengosongkan keranjang. `App.tsx:465-470` merender `<LayarPelayan namaPelayan={…} />` **tanpa** prop itu.
- **Skenario gagal:** pelayan mencatat pesanan meja, melihat konfirmasi hijau, keranjang kosong — dan pesanan tidak pernah ada di peladen maupun dapur. Pihak dapur tidak pernah tahu; pelanggan menunggu.
- **Dugaan penyebab:** komponen demonstrasi dipasang sebagai layar hidup tanpa adaptor tulis, dan pesan sukses bergantung pada keberadaan prop, bukan pada hasil pengiriman.
- **Cara membuktikan perbaikan:** bila `onKirimPesanan` tidak ada, layar wajib menampilkan pesan gagal/“belum tersedia” dan **tidak** mengosongkan keranjang; atau App memasang pengiriman sungguhan. Uji: `expect(teks).not.toContain('berhasil dikirim')` ketika prop absen, dan satu pesanan/tiket muncul ketika prop ada.
- **Status verifikasi:** TERVERIFIKASI (dijalankan, bukan dugaan).

### [F-16] Duplikat `23505` dapat menandai sukses padahal item belum lengkap
- **Tingkat:** K-3 (Sedang).
- **Artefak:** `aplikasi/src/hook/useAntrean.ts:112-154`.
- **Klaim yang dilanggar:** "tersinkronisasi tanpa dobel pencatatan" sekaligus jujur soal status terkirim.
- **Bukti:** `nl -ba aplikasi/src/hook/useAntrean.ts | sed -n '112,154p'` → insert induk (113-121); bila `errPesanan` memuat `kunci_idempoten` **atau kode apa pun** `23505`, fungsi langsung `return { sukses: true }` (123-127) **sebelum** insert item (131-145). Tidak ada pemeriksaan apakah item sudah ada.
- **Skenario gagal:** sesi sebelumnya menyimpan induk pesanan lalu mati sebelum item tersimpan; percobaan ulang menganggap semuanya beres → pesanan tampil terkirim tetapi tanpa item/harga, dapur menerima tiket kosong.
- **Dugaan penyebab:** jalur idempoten "sudah pernah dikirim" disamakan dengan "sudah lengkap"; dua insert tidak atomik.
- **Cara membuktikan perbaikan:** saat bertemu duplikat, verifikasi keberadaan item (atau pakai satu RPC atomik) sebelum menyatakan sukses; uji harus memaksa insert item gagal setelah induk berhasil → setelah retry status harus tetap gagal/`menunggu`, bukan sukses. `cd aplikasi && npm test -- --run` tetap hijau.
- **Status verifikasi:** TERVERIFIKASI secara urutan kode; dampak nyata bergantung perilaku kendala peladen (belum direproduksi terhadap Supabase).

## 5. Kalibrasi cacat tanaman

Tidak dijalankan. Mandat ini bukan paket AUD-3 kalibrasi dan tidak menyediakan bahan cacat tanaman; kunci jawaban tidak dibuka. Uji mutasi aplikasi (81 mutasi) sudah dijalankan pada tabel bukti SIA-01.

## 6. Yang tidak bisa saya verifikasi

- Tidak menjalankan Supabase nyata: dampak F-14/F-16 terhadap data sungguhan belum diukur; keduanya saya buktikan dari urutan kode.
- Tidak menguji di peramban/tablet fisik: F-15 dibuktikan di jsdom, bukan perangkat.
- Tidak mengaudit berkas SQL, CI, dan SOP bencana (di luar peran spesialis frontend).
- Tidak bisa memastikan sesi ini memakai model berbeda dari pembangun; dicatat sebagai keterbatasan independensi.

## 7. Pernyataan tidak mengubah apa pun

Saya **tidak mengubah** kode aplikasi, CSS, atau pengujian. Berkas uji sementara untuk F-15 dibuat di `aplikasi/alat/uji-sementara-pelayan.test.tsx` lalu **dihapus kembali**; `git status --short` setelahnya kosong sebelum laporan ini dibuat. Satu-satunya berkas yang saya buat adalah laporan ini, ditambah **penambahan tautan** (bukan pengubahan isi/verdict) di berkas laporan SIA-01 agar temuan ini mudah ditemukan. Bukti: `git status --short` menampilkan hanya berkas laporan ini dan berkas SIA-01 yang saya beri tautan.

## 8. Temuan di luar cakupan (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | Kewajiban idempotensi/atomisitas pada sisi basis data (kunci unik, RPC transaksional) | Milik Spesialis Data & Keuangan, bukan frontend | `nl -ba aplikasi/src/hook/useAntrean.ts \| sed -n '112,154p'` | Audit data menilai apakah RPC/transaksi peladen dapat menutup F-16 tanpa perubahan klien |
| 2 | SOP kasir saat internet mati (kapan menolak melayani, cara mengulang kirim) | Kebijakan operasional milik Lee | `nl -ba aplikasi/src/App.tsx \| sed -n '120,175p'` | Keputusan Lee, lalu ditulis di SOP & panduan pengguna |
