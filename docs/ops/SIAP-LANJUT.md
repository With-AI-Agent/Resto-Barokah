# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang kerja terakhir:** `arena/01a0b4c3-resto-barokah`
- **Commit keadaan kerja:** `51feb34d1fe23bebeecf42b29b2f2e9ec4902c64`
- **PR:** PR #1 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** success (run 35353489997, commit 869b2a18)
- **Ditulis:** 2026-09-18 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **9** — T-019, T-018, T-002, T-003, T-010, T-011, T-015, T-016, T-020
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0b4c3-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

Keadaan keputusan Lee (2026-09-18, sesi `01a0b4c3`): Lee memilih **"nyalakan pratinjau dulu"** +
mode **maraton**. Pratinjau sudah dibuktikan hidup (Vite `5173` layar contoh 10 tema & Nyaman/Padat;
`prototipe/` di `8080` lima halaman mockup; kontras 166 lolos · `periksa-halaman` 183/183).
**Arah besar masih belum dipilih** — ini pertanyaan yang harus diajukan lebih dulu di sesi baru,
jangan dijawab sendiri:

1. **Putaran verifikasi** (rekomendasi sesi-sesi sebelumnya). Paket `AUD-3-2026-09-18-SIAP-TEMPEL.md`
   dan `PKT-2026-09-18-pr-01-putaran14-SIAP-TEMPEL.md` menunjuk `cdd80b6` = **12 commit di bawah tip**.
   Sudah diukur: `git diff --name-only cdd80b6..HEAD -- aplikasi/ supabase/ prototipe/` hanya
   `aplikasi/alat/periksa-semua.sh` → **temuan auditor tetap sah untuk kode**, tetapi `.github/workflows/ci.yml`
   berubah sejak itu (+3 langkah: uji-diri `mulai-sesi.py` & `periksa-roadmap.py`, gerbang 18 → 20), jadi untuk
   menilai **gerbang CI** buat dulu paket di tip: `python3 alat/review-pr.py --siapkan --dasar origin/main --nama pr-01`
   dan `python3 alat/audit-independen.py --paket AUD-3 --semua`. Setelah laporan masuk: bantah-balik tiap temuan
   dengan probe sendiri, tutup yang nyata, catat yang palsu (dua putaran terakhir menemukan cacat nyata → bukan formalitas).
2. **Lanjut kerja T1-24** (perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat) — menutup
   `percobaan_pin_perangkat.sql` (F-11) dan baris temuannya di `docs/uji/AUDIT_RIWAYAT.md` §1b.
   **Nomor migrasi SUDAH dibetulkan 2026-09-18** (lihat `docs/DECISIONS_LOG.md` «Nomor migrasi rencana
   dikoreksi»): T1-24→**0015** · T1-25→0016 · T1-26→0017 · T1-27→0018 · T1-28→0019 · T1-36→0020;
   rantai lama T1-11→0021 dst. Nomor di ROADMAP kini resmi **perkiraan** — ambil nomor bebas pertama saat
   mengerjakan, tulis di baris **Bukti**, dan biarkan butir 8 `alat/periksa-roadmap.py` yang menjaga.
3. **Sebelum T1-27:** jawab dulu **T-020** (tabel `catatan_audit` dibuat di T1-13 tetapi dijangkarkan di
   T1-27 — usulan agent: T1-27 yang membuat tabelnya langsung dalam bentuk jadi). Tandai `❓ T-020` hilang
   dari T1-27 hanya kalau jawaban Lee sudah tercatat di `docs/TERTANGGUH.md`.
4. **Buku tunggu = 9 butir terbuka** (batas 12): T-019 · T-018 · T-002 · T-003 · T-010 · T-011 · T-015 ·
   T-016 · T-020. Tawarkan jawaban sekaligus di akhir batch — Lee cukup bilang "setuju semua".
5. **PR #1: JANGAN MERGE** (keputusan Lee; masih terbuka).

Kalau Lee hanya menulis "lanjut" tanpa memilih: kerjakan **(1) penyiapan putaran verifikasi** sampai tuntas
(paket di tip + arahan siap tempel), lalu tanyakan **satu** pertanyaan singkat: "verifikasi (jalankan 2 chat)
atau langsung T1-24?" — jangan menebak di antara dua jalur besar yang tidak bisa dibatalkan.
