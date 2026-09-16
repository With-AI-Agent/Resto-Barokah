# Bahan Diskusi Tahap 5 — ROADMAP (Pecahan Tugas G1)

> **Status: BAHAN DISKUSI — belum final.** Sesuai `AGENT_SYSTEM.md` Tahap 5, dokumen final
> (`docs/ROADMAP.md`) baru ditulis setelah pemilik bilang **"cukup, tulis drafnya"**.
>
> Ditulis: 2026-09-16 · Skill yang dipakai: `skills/product-discovery/roadmap-planning` (urutan & dependensi) ·
> `skills/product-management/prioritization-advisor` (MoSCoW: Must = M1–M12) · `skills/writing-plans` (task kecil, TDD, commit sering)
> Rujukan: `docs/PRD.md` (dikunci) · `docs/TECH_SPEC.md` (dikunci) · `docs/AGENT_OPERATING_GUIDE.md` (berlaku)

---

## 0. Ringkasan bahasa manusia

**Apa itu ROADMAP?** Daftar pekerjaan yang sangat rinci — seperti buku resep langkah demi langkah untuk agent.
Satu pekerjaan = **1 tujuan yang bisa diuji**, cukup kecil untuk satu sesi kerja. Kalau tidak tertulis di daftar ini,
agent **tidak akan mengerjakannya**. Jadi daftar ini harus lengkap dari hal sekecil "buat berkas contoh rahasia" sampai "deploy ke internet".

**Aturan tiap pekerjaan (7 keterangan wajib):** Tujuan · Rujukan (bagian PRD/TECH_SPEC) · Berkas yang disentuh ·
Kriteria selesai (bisa diuji) · Kompleksitas (kecil/sedang/besar + jam) · Risiko & penanganannya · Cara verifikasi.

**Prinsip urutannya (kenapa begini):**
1. **Hal paling berisiko dikerjakan paling awal** — karena jadi fondasi semua fitur. Kalau salah sejak awal, semua di atasnya ikut salah.
   Yang paling berisiko di proyek ini: **pemisahan data antar-resto (RLS)**, **peran & izin**, dan **hitungan uang**.
2. **Yang lain menunggu fondasi** — layar kasir tidak bisa dibangun sebelum tabel pesanan & hitungan uang ada dan terbukti benar.
3. **Tiap fase diakhiri bukti** (uji otomatis + daftar uji terima bahasa manusia) sebelum fase berikutnya dimulai.
4. **Gelombang tetap dihormati:** G1 = yang dipakai harian di Kedai Oasis; G2 & G3 menyusul (tidak dicampur ke daftar ini).

---

## 1. Usulan urutan fase (11 fase, ± 136 pekerjaan)

| Fase | Nama | Isi utama | Perkiraan jumlah pekerjaan |
|---|---|---|---|
| **F0** | Persiapan & rangka kerja | Repo aplikasi (`/aplikasi`), React+TS+Vite+PWA, token desain v3 dipindah, ESLint/Prettier/tsc, Vitest, struktur folder, `.env.example`, README, GitHub Actions (lint+unit), proyek Supabase + Cloudflare dibuat, **halaman kosong ter-deploy ke internet** | 10 |
| **F1** | **Database, keamanan & uang** ⚠️ | Semua migrasi tabel (penyewa→cabang→pengguna→izin→pengaturan; katalog; pesanan; pembayaran; kas; voucher; audit), **pola RLS + helper izin**, **PIN (hash) & pembatasan percobaan**, **`hitung_total()` + uji uang**, penomoran pesanan harian (zona waktu), `catatan_audit` hanya-tambah, seluruh **uji SQL** | 22 |
| **F2** | Masuk & kerangka aplikasi | Supabase Auth: pegawai (email+PIN) & pelanggan (Google utama + email), layar masuk, navigasi per peran, pemilih cabang, halaman "belum punya akses", sesi berakhir otomatis, kerangka PWA (manifest + service worker dasar) | 12 |
| **F3** | Pesanan & kasir (M4) | Layar kasir: katalog, keranjang, pilih meja/jenis pesanan, catatan khusus per item, **tagihan terbuka**, ubah/pindah meja, status meja, `simpan_pesanan` + uji, kunci menu habis di kasir | 16 |
| **F4** | Dapur/KDS & stok dasar (M5, M9) | Layar dapur & bar (pemisahan makanan/minuman), urutan FIFO, tanda jenis pesanan, instruksi mencolok, ubah status, **tombol menu habis** yang mengunci kasir + katalog, stok sederhana + opname + riwayat | 10 |
| **F5** | Pembayaran & pembatalan (M6) | `bayar_pesanan` (tunai + kembalian, QRIS/transfer/e-wallet/kartu sebagai pencatatan), pajak & service terpisah di struk, diskon (bawaan satu, opsi tumpuk + batas), **void bertingkat** (sebelum/sesudah dapur) + PIN + alasan + bahan terbuang, struk digital/cadangan | 12 |
| **F6** | Cetak termal (ESC/POS) | Web Bluetooth + WebUSB, tiket dapur, struk, cetak ulang, pemasangan printer per perangkat, **cadangan digital wajib**, pesan jelas saat printer mati | 8 |
| **F7** | Kas & shift + laporan harian (M7, M8) | Buka/tutup kas, modal awal, uang seharusnya vs hasil hitung, alasan selisih, pengingat shift belum ditutup, `buka_shift`/`tutup_shift` + uji, **Laporan A (kas harian per shift)** + laporan penjualan dasar, filter per cabang sesuai peran | 12 |
| **F8** | Katalog pelanggan & voucher (M10) | Halaman publik per resto (merek, warna, banner), menu + foto, menu habis otomatis tertutup, daftar pelanggan (Google/email), kampanye voucher oleh admin, barcode/kode, **`cek_voucher` (baca saja)** & **`pakai_voucher` (sekali pakai + PIN)**, scan kamera + ketik manual, 10 pengaman anti-kecurangan, laporan percobaan | 14 |
| **F9** | Pengaturan tanpa koding & multi-cabang (M2, M11) | Layar pengaturan: identitas & tampilan (nama, logo, warna/tema, banner), pajak/service/pembulatan, cara pesan, meja & area, metode bayar, header/footer struk, tambah cabang + printer per cabang, harga/menu beda per cabang, izin pegawai dicentang owner | 12 |
| **F10** | Ketahanan & keamanan lanjutan (M12, K4) | Antrean offline (IndexedDB) + kunci idempoten di semua penulisan, pemulihan gagal kirim, batas percobaan masuk/PIN, normalisasi email (anti email sekali-pakai), sesi berakhir otomatis, **penyisiran ulang seluruh RLS** + uji | 8 |
| **F11** | Uji terima, deploy produksi, audit | 7 alur Playwright, **uji cetak nyata di Kedai Oasis**, daftar uji terima bahasa manusia, audit keamanan, audit tampilan (kontras/a11y/responsif), loading & empty state, favicon, halaman error, deploy produksi + domain, **peringatan 70%/90% batas gratis (K6)**, panduan singkat pemakaian untuk pegawai | 10 |

**Catatan jujur:** jumlah di atas perkiraan (± 136 pekerjaan). Angka pasti & isi tiap pekerjaan akan ditulis satu per satu
di `docs/ROADMAP.md`. Estimasi waktu keseluruhan G1 tetap **10–14 minggu kerja agent** (seperti tercatat di `TECH_SPEC.md` §0).

---

## 2. Checklist kelengkapan (dari `AGENT_SYSTEM.md` Tahap 5) — cara memenuhinya

| Syarat | Cara dipenuhi | Status usulan |
|---|---|---|
| Semua fitur **Must Have** M1–M12 punya minimal 1 task | M1→F1+F9 · M2→F9 · M3→F1+F9 · M4→F3 · M5→F4 · M6→F5 · M7→F7 · M8→F7 · M9→F4 · M10→F8 · M11→F9 · M12→F1+F10 | ✅ rencana |
| Semua **entitas Data Model** punya migrasi (+ seed) | F1 memuat seluruh tabel dari `TECH_SPEC.md` §4 (penyewa…catatan_kesalahan) + `seed.sql` (penyewa contoh, metode bayar, meja) | ✅ rencana |
| Semua **API/RPC** punya task + uji | F1 (fungsi SQL inti) + F3/F5/F7/F8 (RPC per fitur) — tiap RPC = 1 task kode + 1 task uji | ✅ rencana |
| Semua **Area Berisiko Tinggi** (ART-1…ART-10) di **Fase 1** + tanda ⚠️ DECISIONS_LOG | ART-1…ART-3, ART-5, ART-6, ART-9 di F1; ART-4 di F3/F5; ART-7 di F6; ART-8 di F10; ART-10 di F1/F2/F8 — semuanya bertanda ⚠️ | ✅ rencana |
| Setup repo, env, lint, uji, CI, deploy | F0 (repo/lint/uji/CI/env) + F11 (deploy produksi) | ✅ rencana |
| Integrasi pihak ketiga punya task setup + uji | Supabase (F0/F1), Google Sign-In (F2), Resend email (F2/F8), Cloudflare+Wrangler (F0/F11), pg_cron (F1/F11) | ✅ rencana |
| Hal kecil tidak terlupakan | README/.env.example/favicon/error page/loading/empty/a11y/responsif masuk F0 & F11 (plus di setiap layar) | ✅ rencana |

---

## 3. Yang masih ❓ AMBIGU — butuh jawaban pemilik / data lapangan

| # | Hal | Cara menangani di ROADMAP |
|---|---|---|
| 1 | Merek & tipe **printer** Kedai Oasis + cara sambung | Task F6 ditulis lengkap, tetapi ada 1 anak-task bertanda **❓ AMBIGU** ("sesuaikan protokol per merek printer") yang tidak dieksekusi sebelum jawaban ada. Kalau belum ada saat F6 dimulai → agent STOP & tanya (aturan `AGENT_OPERATING_GUIDE.md` §12) |
| 2 | **Daftar perangkat** (Android/iPhone/komputer) | Tidak menghambat: jalur cadangan digital & cetak PDF sudah wajib. Task iPhone dicatat sebagai "uji perangkat kedua" di F11 |
| 3 | **Nama produk platform** | Tidak menghambat coding. Dipakai di judul aplikasi, manifest PWA, domain. Task penamaan ada di F0 dengan **nilai sementara** "Sajian" (bisa diganti 1 baris) + tanda ❓ |
| 4 | Apakah semua **pegawai punya email aktif** | F2 memakai email+PIN. Bila ada pegawai tanpa email → dicatat di F2 sebagai opsi "dibuatkan email oleh admin" (keputusan kecil saat itu) |
| 5 | Nilai **pajak/service** & jam operasional/jumlah shift nyata | Tidak menghambat: semuanya pengaturan (bawaan PB1 10% & service 5%, bisa diubah tanpa koding). Diisi saat penyiapan Kedai Oasis (F11) |

---

## 4. Bentuk satu pekerjaan (contoh nyata, 7 keterangan)

```markdown
- [ ] Task 34 — RPC hitung_total() + uji uang (pajak, service, diskon, pembulatan)
  - **Tujuan:** satu-satunya tempat menghitung uang, supaya tidak ada dua rumus yang bisa berselisih.
  - **Ref:** TECH_SPEC §5 (API) & §9 ART-3 (rantai hitungan uang); PRD § M6 (pajak & service terpisah di struk)
  - **File:** `supabase/migrations/0012_hitung_total.sql`, `supabase/tes/uang_*.sql`
  - **DoD:** fungsi mengembalikan rincian {subtotal, diskon, pb1, service, pembulatan, total}; 12 kasus uji lulus
    (termasuk pajak 0%, service 0%, diskon penuh, pembulatan .01, dan total bernilai bulat rupiah);
    tidak ada satu pun `float`/`numeric` pecahan untuk nominal.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update DECISIONS_LOG.md — Area: Kalkulasi Keuangan (ART-3);
    risikonya dua rumus berbeda → mitigasi: klien DILARANG menghitung, semua pemanggilan lewat RPC ini.
  - **Verifikasi:** `supabase test` (12 kasus) hijau + pemeriksaan manual hasil struk contoh cocok dengan kalkulator.
```

---

## 5. Pertanyaan penutup

- Urutan fasenya sudah masuk akal? (sebut nomor fase kalau ada yang mau dipindah/digabung)
- Ada pekerjaan yang menurutmu kurang/berlebihan di daftar fase di atas?
- Kalau setuju: jawab **"cukup"** → agent menulis `docs/ROADMAP.md` lengkap (± 136 pekerjaan, masing-masing 7 keterangan),
  lalu checkpoint: **Tahap 6 (pemeriksaan silang seluruh dokumen)** → baru coding G1 dimulai.
