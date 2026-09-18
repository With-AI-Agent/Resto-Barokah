# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang kerja terakhir:** `arena/01a0a8a2-resto-barokah`
- **Commit keadaan kerja:** `fc017f2c3850c79fdb7f715d0a178b715372f380`
- **Commit keadaan kerja:** `ffffffffffffffffffffffffffffffffffffffff`
- **PR:** PR #1 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** failure (run 35328530232, commit fc017f2c)
- **PERHATIAN:** CI terakhir BUKAN success — perbaiki CI lebih dulu sebelum pekerjaan baru.
- **Ditulis:** 2026-09-18 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **8** — T-019, T-018, T-002, T-003, T-010, T-011, T-015, T-016
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0a8a2-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

Keadaan keputusan Lee (2026-09-18, sesi ditutup karena berat): arah berikutnya **belum dipilih**.
Urutan yang disarankan agent, dan alasannya:

1. **Putaran verifikasi (disarankan lebih dulu, kecil).** Paket `AUD-3-2026-09-18-SIAP-TEMPEL.md`
   dan `PKT-2026-09-18-pr-01-putaran13-SIAP-TEMPEL.md` sudah disegarkan mesin ke commit keadaan ini.
   Lee tinggal menyalin **satu berkas per chat baru** (dua chat). Setelah laporan masuk:
   bantah-balik setiap temuan dengan probe sendiri (aturan tetap), tutup yang nyata, catat yang palsu.
   Bukti dari laporan putaran sebelumnya: dua putaran berturut-turut menemukan cacat nyata, dan dua
   cacat terakhir justru tertangkap CI — jadi verifikasi ini bukan formalitas.
2. **Lanjut kerja T1-24** (perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat) — menutup
   akar beberapa kelemahan (batas PIN per perangkat masih memakai nama perangkat kiriman klien).
   **PENTING (temuan baru):** ROADMAP T1-24 menyebut "Migrasi 0012", padahal 0012 **sudah terpakai**
   (penutup celah review) dan migrasi sudah mencapai `0014`. T1-24..T1-28 wajib memakai nomor
   berikutnya (0015 dst.) — perbarui ROADMAP + catat di `DECISIONS_LOG.md` saat dikerjakan.
3. **Lihat pratinjau** (10 tema, mode Nyaman/Padat) kalau Lee ingin menilai tampilan langsung.

Kalau Lee hanya menulis "lanjut" tanpa memilih: kerjakan **(1) penyiapan putaran verifikasi** sampai
tuntas (paket + arahan siap tempel), lalu tanyakan **satu** pertanyaan singkat: "verifikasi (jalankan
2 chat) atau langsung T1-24?" — jangan menebak di antara dua jalur besar yang tidak bisa dibatalkan.
