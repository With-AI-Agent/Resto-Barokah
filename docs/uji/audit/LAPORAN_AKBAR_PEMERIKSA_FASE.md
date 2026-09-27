# PENUNJUK LAPORAN — PEMERIKSA RIWAYAT FASE (FASE 0 s/d FASE 10)

> **Baca ini dulu.** Peran "Pemeriksa Riwayat Fase" dikerjakan oleh **dua sesi pemeriksa yang berjalan paralel**, pada commit yang sama (`0fc63c7`). Keduanya menulis ke jalur yang sama sesuai naskah. Bentrok itu sudah terjadi dan **isi salah satunya sempat tertimpa** oleh gabungan commit `e05d4a4`.
>
> Supaya tidak ada lagi temuan yang hilang, **kedua laporan disimpan utuh di nama berbeda**. Berkas ini hanya penunjuk — bukan laporan.

| # | Laporan | Berkas | Temuan | Verdict |
|---|---|---|---|---|
| 1 | **Pemeriksa Fase — sesi `01a0e266`** (commit `8e1c427`) | [`LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-01a0e266.md`](./LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-01a0e266.md) | 1 K-1 · 4 K-2 · 4 K-3 · 7 K-4 | MEMERLUKAN PERBAIKAN |
| 2 | **Pemeriksa Fase — sesi `cf2f162`** (commit `cf2f162`, tingkat `AUD-2`) | [`LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-cf2f162.md`](./LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-cf2f162.md) | 2 K-1 · 5 K-2 · 1 K-3 | TIDAK-BERSIH |

**Keduanya sepakat pada kesimpulan utama: sistem BELUM SIAP ke Fase 11.** Keduanya juga menemukan TOTP sebagai temuan K-1 secara independen.

---

## Apa yang ditemukan masing-masing (silang-baca)

### Temuan yang ditemukan KEDUA laporan (saling menguatkan)
- **TOTP/MFA akun owner-admin tidak ada** di alur masuk yang aktif. Status: masih terbuka sejak temuan `L F-01` (2026-09-24).
- **Penyimpanan pesanan mem-bypass RPC `simpan_pesanan`** (`App.tsx`, `useAntrean.ts` menulis langsung ke tabel).
- **Cetak ulang struk belum punya jejak audit** dan printer belum siap operasional (T5-10, T6-06…T6-08).
- **Status roadmap & handoff tidak konsisten dengan bukti fase.**

### Temuan yang HANYA ada di laporan 1 (`01a0e266`)
- **19 berkas antarmuka (18 modul fitur) sudah dibangun & teruji tetapi tidak pernah terpasang** ke aplikasi berjalan — termasuk kunci otomatis, masuk owner/admin, pendaftaran perangkat (QR), pendaftaran tenant Lee, struk digital/WhatsApp, daftar pesanan, halaman kebijakan privasi.
- **Printer benar-benar tidak bisa dipakai**: `cetakBluetooth`, `cetakUsb`, `susunStruk`, `susunTiket` ada dan teruji, tetapi **tidak ada satu pun pemanggil di kode produksi**.
- **Data awal (seed) tidak ada** (`supabase/seed.sql`), padahal dibutuhkan sebelum pilot.
- **Fase 4 tertulis 0/10 padahal seluruh layar dapur sudah mendarat & terpasang** (utang catatan).
- **Satu tombol mati**: "Kebijakan Privasi" di tiga layar (prop tidak pernah diisi `App.tsx`).
- **Satu uji tidak stabil**: `TutupKas.test.tsx` gagal 1 dari 5 putaran penuh (balapan `waitFor`).

### Temuan yang HANYA ada di laporan 2 (`cf2f162`)
- **[F-02] Kirim ke Dapur memakai status `'antri'` yang tidak sah** — tabel `pesanan` (migrasi 0009) hanya menerima `draf/dikirim/dimasak/siap/lunas/batal`, dan transisi `draf → dikirim` wajib menyertakan `dikirim_ke_dapur_pada`. Jadi tombol "Kirim ke Dapur" berisiko ditolak database. **Ini cacat nyata yang luput dari laporan 1.**
- **[F-04] Sisa risiko integritas uang (I F-17 / T-025(a))** masih "DITUTUP sebagian · TERBUKA sisa".
- **[F-07] CI pada commit target ternyata MERAH** — lihat koreksi di bawah. **Ini juga luput dari laporan 1 dan penting.**

---

## Koreksi untuk laporan 1 (kejujuran)

Laporan 1 menyatakan "**126 gerbang CI utuh**". Itu benar untuk **pemeriksa gerbang** (`alat/periksa-gerbang-ci.py` membuktikan 126 gerbang masih tercantum dan tidak dilemahkan), tetapi **bukan** bukti bahwa CI pernah berhasil dijalankan. Fakta yang saya verifikasi sendiri:

| Perintah | Hasil |
|---|---|
| `gh run list --branch arena/01a0e266-resto-barokah --limit 1` | run `36314479079` → **failure** |
| langkah yang gagal | **#60 — "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras"** |
| `python3 _sistem/validate_system.py` (dijalankan lokal, hasil sama) | **GAGAL** dengan 3 pelanggaran |
| penyebab | 3 dari 5 laporan peran audit akbar **belum ada**: `LAPORAN_AKBAR_AUDITOR_UTAMA.md`, `LAPORAN_AKBAR_SPESIALIS_DATA.md`, `LAPORAN_AKBAR_SPESIALIS_FRONTEND.md` |

**Artinya: CI merah BUKAN karena cacat kode aplikasi.** Ia merah karena paket audit akbar baru 2 dari 5 laporan yang mendarat (Pemeriksa Fase dan Spesialis Infrastruktur). Begitu tiga laporan sisanya ditulis, pemeriksa ini seharusnya lolos.

---

## Aturan untuk sesi berikutnya (supaya bentrok tidak terulang)

1. **JANGAN menimpa laporan peran lain.** Jika peranmu sudah ada isinya di jalur wajib, **tambahkan berkas baru** dengan akhiran `__sesi-<id>` dan perbarui penunjuk ini.
2. **Jangan menghapus penunjuk ini** sebelum kelima laporan peran selesai dan Lee memutuskan penggabungannya.
3. Setiap laporan wajib mencantumkan **commit yang diaudit** dan **perintah yang bisa diulang**, supaya dua laporan bisa disilangkan tanpa saling meniadakan.

---

## Yang masih belum ada (untuk melengkapi matriks akbar)

- [ ] `docs/uji/audit/LAPORAN_AKBAR_AUDITOR_UTAMA.md` (Auditor Utama / holistik)
- [ ] `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_DATA.md` (Spesialis Basis Data & Keuangan)
- [ ] `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_FRONTEND.md` (Spesialis Frontend & Antarmuka)
- [x] `LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-01a0e266.md` dan `...__sesi-cf2f162.md` (Pemeriksa Riwayat Fase — dua sesi)
- [x] `docs/uji/audit/LAPORAN_AKBAR_SPESIALIS_INFRASTRUKTUR.md` (Spesialis Infrastruktur & SOP Bencana)

*Penunjuk ini dibuat 2026-09-27 untuk mencegah hilangnya temuan akibat bentrok penulisan antar sesi. Tidak ada isi laporan yang dibuang — keduanya tersimpan utuh di berkas berbeda.*
