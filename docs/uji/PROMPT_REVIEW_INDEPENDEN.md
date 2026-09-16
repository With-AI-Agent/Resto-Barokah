# Prompt Review Independen — Proyek "Resto Barokah" / aplikasi "Sajian"

**Dibuat:** 2026-09-16 · **Revisi:** versi 3 (2026-09-16) — sesi reviewer **tidak perlu merge apa pun** dan **tidak perlu bergantung pada base branch**; kalau fondasi tidak terlihat di checkout-nya, ia mengambil sendiri dari cabang remote.
**Versi 2:** wajib base branch `arena/01a0a8a2-resto-barokah` → **gagal di percobaan pertama**: sesi reviewer ternyata mulai dari `main` (yang masih kosong), sehingga ia menilai "fondasi belum ada" dan putusannya `BELUM SIAP` (lihat `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md`). Versi 3 menutup celah itu.
**Untuk:** pemilik proyek (bukan untuk agent sesi pembangun)
**Tujuan:** memeriksa SELURUH fondasi, sistem kerja, dan panduan sebelum menulis satu baris kode aplikasi.

---

## Bagian A — Cara pakai (untuk pemilik)

1. **Jangan merge PR apa pun.** Sesi pembangun (yang sedang bersamamu) harus tetap terbuka agar temuan reviewer bisa langsung diserahkan ke sana.
2. Buka **sesi baru** untuk reviewer. **Kalau ada pilihan base branch saat membuat sesi, pilih `arena/01a0a8a2-resto-barokah`** — tapi kalau tidak ada/pilihan itu tidak bekerja, **tidak masalah**: prompt di bawah menyuruh reviewer mengambil sendiri fondasi dari cabang remote.
3. Salin **seluruh** teks antara penanda `▼ SALIN MULAI` dan `▲ SALIN SAMPAI`, tempel sebagai pesan pertama sesi reviewer.
4. Diamkan sampai selesai. Ia akan memberi **putusan + laporan 5 baris + nama cabangnya** (tidak merge apa pun).
5. Bawa hasil itu ke sesi pembangun (tempel apa adanya). Sesi pembangun yang mengambil laporan detail & menindaklanjuti.
6. Baru setelah semua temuan ditangani dan putusan terakhir bukan `BELUM SIAP`, coding Fase 0 dimulai.

**Batas satu putaran:** satu gelombang; bila ada temuan Kritis, boleh **satu putaran tambahan**. Tanpa batas ini, proyek berhenti selamanya di tahap memeriksa.

**Yang tidak bisa dijamin review ini:** kenyataan lapangan (merek printer T-002, daftar perangkat T-003); kode bebas cacat (kodenya belum ada); pengalaman nyata pelanggan.

---

▼ SALIN MULAI (salin dari baris ini ke bawah)

# TUGAS: REVIEW INDEPENDEN FONDASI — SEBELUM CODING DIMULAI

Halo. Kamu agent baru di repo ini, dan fondasi proyek ini **bukan hasil kerjamu** — jadi kamu tidak punya kepentingan untuk membelanya. Tugasmu satu: memeriksa semuanya dengan teliti sebelum proyek masuk tahap coding, lalu melaporkan hasilnya dengan jujur. Kalau ada masalah berat, mengatakan **"BELUM SIAP" adalah hasil yang berhasil**, bukan gagal.

## 0. Prasyarat: TEMUKAN DULU FONDASINYA (jangan berhenti hanya karena tidak terlihat)

Fondasi proyek ini bisa jadi **tidak berada di checkout-mu** (sesi baru kadang mulai dari `main` yang masih kosong). Jadi lakukan berurutan, dan **catat hasil tiap langkah di laporan**:

**A. Periksa checkout sendiri:**
```
git rev-parse --abbrev-ref HEAD
git log --oneline -3
ls docs/ROADMAP.md 2>/dev/null
grep -m1 '^STATUS:' PROJECT_STATE.md 2>/dev/null
```
Kalau `docs/ROADMAP.md` ada dan `PROJECT_STATE.md` memuat `STATUS: CODING_AKTIF` → **fondasi = checkout-mu**. Lanjut ke bagian 1.

**B. Kalau tidak ada → baru pakai rute ini (TANPA pindah cabang, TANPA merge):** Ambil sendiri dari cabang remote:
```
git ls-remote --heads origin | grep 'arena/'
git fetch origin <nama-cabang-arena>
git ls-tree --name-only FETCH_HEAD docs/ROADMAP.md      # cabang yang punya ini = cabang fondasi
git rev-parse FETCH_HEAD                                # catat commit-nya untuk laporan
mkdir -p /tmp/fondasi-review && git archive FETCH_HEAD | tar -x -C /tmp/fondasi-review
cd /tmp/fondasi-review && ls docs/ROADMAP.md PROJECT_STATE.md
```
Kalau ada beberapa cabang `arena/*`, pilih yang **memuat `docs/ROADMAP.md`** dan `PROJECT_STATE.md` berisi `STATUS: CODING_AKTIF`. Semua pembacaan & pemeriksa dijalankan dengan **cwd = `/tmp/fondasi-review`** (mis. `cd /tmp/fondasi-review && python3 _sistem/validate_system.py`). Di laporan tulis: **"Ditinjau: `<cabang>` @ `<commit>`"**.

**C. Kalau tidak ada satu pun cabang arena yang memuat fondasi** → **BERHENTI**. Laporkan: *"Fondasi tidak ditemukan di cabang mana pun; kemungkinan belum pernah di-push."* Jangan menebak, jangan menilai dari checkout kosong.

**Lalu (setelah fondasi ditemukan):**
- Baca aturan repo ini sendiri sesuai `START_DI_SINI.md` (jenis sesi: **Audit / Cross-Check**), termasuk `AGENT_SYSTEM.md` bagian "LANGKAH PERTAMA DI SETIAP SESI". Aturan repo tetap berlaku; instruksi di bawah menambah, bukan mengganti — kecuali pengecualian di bagian 6.
- Jalankan `python3 alat/mulai-sesi.py` (dari folder fondasi) dan catat apakah "DAFTAR TUNGGU" serta "KARTU SESI" tampil benar.
- Bahasa laporan ke pemilik: **Indonesia sederhana, tanpa jargon**.

## 1. Sikap kerja wajib (anti-laporan-palsu)

- Kamu **tidak** diminta menyetujui. Kamu diminta **mencoba mematahkan** fondasi ini.
- Dilarang menutup laporan dengan "semuanya sudah bagus" atau pujian tanpa daftar apa yang benar-benar diperiksa.
- Setiap temuan wajib punya: **lokasi berkas:baris**, **perintah persis**, **keluaran yang terlihat**, **dampak nyata** (pemilik, kas, pelanggan, keamanan), **usulan perbaikan**, **perkiraan besar pekerjaan**.
- Kalau satu area **tidak** menemukan temuan: tulis `0 temuan` + **3 hal tersulit yang kamu coba untuk mematahkannya**.
- Dilarang mengarang. Tidak bisa diverifikasi → tulis `TIDAK TERVERIFIKASI`, bukan `sepertinya benar`.
- Semua angka dari perintah yang kamu jalankan sendiri.

## 2. Larangan keras (pelanggaran = tugas gagal)

- **Jangan merge PR apa pun dan jangan tutup PR apa pun.** Merge/close bisa memutus akses sesi pembangun yang masih bekerja. Cukup commit + push ke cabangmu sendiri.
- Dilarang **melemahkan, melonggarkan, atau menghapus** pemeriksa (`_sistem/validate_system.py`, `alat/periksa-roadmap.py`, lainnya). Kalau pemeriksanya salah: tulis temuan + usulkan perbaikan.
- Dilarang menghapus berkas, `git reset --hard`, `git push --force`, atau mengubah riwayat Git.
- Dilarang **memulai coding aplikasi** (Fase 0 dst), membuat berkas di folder aplikasi, atau memasang paket aplikasi.
- Dilarang mengubah dokumen terkunci: `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md` → **usulkan**, jangan sunting.
- Dilarang mengubah keputusan pemilik (K1–K6, urutan hitung uang, PB1/service, peran & izin, alur pesanan). Perubahan = usulan + entri `docs/DECISIONS_LOG.md` bertanda **MENUNGGU PERSETUJUAN PEMILIK**.
- Dilarang menyentuh/menampilkan isi berkas rahasia (`.env`, kunci, token); laporkan keberadaannya saja.
- Dilarang mengeluarkan biaya atau mengusulkan langkah berbayar.
- Dilarang memperbaiki di luar temuan.

## 3. Wilayah pemeriksaan W1–W10 (semuanya, tanpa terkecuali)

Periksa kesepuluh wilayah ini; tiap wilayah hasilnya = temuan ber-bukti ATAU `0 temuan` + daftar uji.

- **W1 — Dokumen fondasi:** `docs/DISCOVERY.md`, `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/AGENT_OPERATING_GUIDE.md`, `docs/ROADMAP.md`, `docs/DECISIONS_LOG.md`, `docs/TERTANGGUH.md`, `docs/README.md`, `docs/teknis/*`, `docs/uji/*`, `docs/desain/*`. Uji: saling bertentangan? janji tanpa tugas / tugas tanpa janji? keputusan pemilik hilang atau berubah diam-diam? istilah konsisten?
- **W2 — Klaim vs bukti:** kumpulkan tiap klaim kuantitatif di dokumen/laporan (jumlah tugas, sebaran fase, jumlah tugas berisiko, jumlah entitas, jumlah RPC, jumlah temuan yang diklaim sudah diperbaiki) lalu **uji ulang sendiri**; nyatakan TERBUKTI / TIDAK TERBUKTI / TIDAK BISA DIVERIFIKASI.
- **W3 — Pemeriksa otomatis:** jalankan `python3 _sistem/validate_system.py` dan `python3 alat/periksa-roadmap.py`, catat keluaran persisnya. Lalu **tulis pemeriksa barumu sendiri** di `alat/periksa-fondasi-independen.py` (di checkout-mu) yang **tidak menyalin logika** pemeriksa lama dan **memakai sumber data berbeda** (mis. tarik daftar entitas/RPC langsung dari `docs/TECH_SPEC.md`, jangan pakai daftar tangan), dijalankan satu perintah, exit 0 bersih / 1 ada temuan, minimal memeriksa: 7 atribut lengkap & bukan pengisi kosong; tugas berisiko tinggi punya kewajiban DECISIONS_LOG; setiap `Ref` menunjuk bagian yang benar-benar ada; butir `T-xxx` yang dirujuk ada di TERTANGGUH (dan sebaliknya); M1–M12, entitas basis data, ART-1..ART-10 punya tugas; tidak ada nomor tugas ganda/fase terlewat. Sertakan hasil jalannya.
- **W4 — Mutu isi tugas (uji tangan):** ambil **minimal 15 tugas acak** (sebutkan cara mengacak; minimal 3 dari Fase 0) + periksa **seluruh Fase 0 (T0-01..T0-10)** satu per satu: tujuan masuk akal? berkas wajar? DoD bisa diuji? verifikasi bisa dijalankan? ada langkah tersembunyi? kalau dikerjakan persis, hasilnya benar?
- **W5 — Kesiapan Fase 0:** semua informasi ada (versi Node, paket, langkah Supabase, langkah Cloudflare, cara simpan rahasia, alamat deploy, urutan commit)? ada langkah mustahil tanpa akun/alat? urutan benar? **Uji khusus:** ada tugas membuat akun & proyek Supabase? ada tugas menjaga database gratis tetap hidup saat resto libur panjang (database gratis bisa "tertidur")?
- **W6 — Sistem kerja agent:** baca `_sistem/validate_system.py` (logikanya masuk akal? ada celah lolos? ada aturan bertabrakan?), `_sistem/templates/*`, `_sistem/AUDIT_*.md`, dan berkas akar `AGENT_SYSTEM.md`, `START_DI_SINI.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TESTS.md`, `ACCEPTANCE_TEST_LOG.md`, `REKAM-KLINIK.md`, `PROFIL_PENGGUNA.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `SYSTEM_MANIFEST.md`, `_Notes.md`, `_salinan-meta/`, `_log-sesi/*`. Masih cocok untuk proyek nyata? ada aturan bertabrakan? ada berkas berstatus lama yang menyesatkan? Jalankan uji penerimaan yang bisa dijalankan; tandai yang belum teruji.
- **W7 — Simulasi agent baru yang bodoh:** hanya dengan berkas wajib menurut aturan repo, apakah kamu tahu harus berbuat apa? tahu larangan? tahu apa yang menunggu keputusan pemilik? akan menanyakan hal yang sudah dijawab dokumen? Uji juga apakah `alat/mulai-sesi.py` benar-benar memuat buku tunggu dan cocok dengan `docs/TERTANGGUH.md`.
- **W8 — Jalur & panduan pemilik:** ikuti `PANDUAN_PENGGUNA.md` sebagai pemilik non-teknis (GitHub + sesi AI). Catat langkah yang tak bisa dijalankan, tak jelas, mengasumsikan hal yang tidak dimiliki pemilik, atau berbahaya (menghapus sesuatu, merge ke arah salah). Periksa juga `PANDUAN_PEMAKAIAN.md` benar-benar jelas berstatus arsip.
- **W9 — Operasional nyata & biaya nol:** (a) satu hari penuh (buka shift → pesan → dapur → bayar → tutup shift → laporan): tiap langkah punya tugas? (b) skenario gagal: internet putus, listrik mati, printer rusak, pesanan batal setelah dimasak, kas tidak cocok, voucher dicoba berulang, pegawai berhenti, dua orang mengubah pengaturan bersamaan — ada penanganannya? (c) biaya nol: ada langkah memaksa bayar / melanggar ketentuan gratis? batas gratis Cloudflare/Supabase/email + risikonya bila tembus? (d) data & keamanan: tugas membatasi akses data pelanggan, cadangan, pemulihan, uji izin?
- **W10 — Integritas repo & kerahasiaan:** `git ls-files`; berkas besar tidak perlu, berkas rahasia yang tidak sengaja masuk, sisa berkas sementara, berkas yang seharusnya di-ignore. Periksa ukuran `skills/` dan sampel isinya (wajar dibawa? ada isi sensitif?). Laporkan tanpa menampilkan isi rahasia.

## 4. Tabel cakupan berkas — WAJIB

Daftar **semua berkas yang dilacak Git** (dari `git ls-files`; isi `node_modules/` dan isi `skills/` diperiksa sebagai kebijakan), status per berkas: `DIPERIKSA MENDALAM` · `DIPERIKSA SEKILAS` · `TIDAK DIPERIKSA (alasan)`. Berkas "tidak relevan" tetap dicantumkan. Tujuannya: tidak ada yang terlewat tanpa alasan yang terlihat. Isi `skills/` (ribuan berkas vendor) **boleh diringkas menjadi satu baris kebijakan** — sebutkan jumlah berkas, ukuran, dan cara pemeriksaannya; tidak perlu satu baris per berkas.

## 5. Simulasi tiga sudut pandang (wajib)

1. **Agent baru yang bodoh** — apa yang paling mungkin dia salah pahami?
2. **Pemilik non-teknis** — langkah mana yang bikin tersesat/panik?
3. **Kedai Oasis, Sabtu malam penuh** — bagian rencana mana yang paling mungkin jebol lebih dulu?

Tiap sudut pandang: minimal 3 kelemahan konkret + sudah tertutup atau belum.

## 6. Aturan memperbaiki temuan

- **Boleh langsung diperbaiki** (catat di laporan): salah ketik, istilah tidak konsisten, rujukan berkas/bagian salah, informasi kurang di dokumen non-terkunci, tugas yang jelas kurang, penambahan butir buku tunggu, penambahan catatan/pemeriksa yang memperkuat.
- **Harus diusulkan:** `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md`, nilai uang/pajak/service, keputusan K1–K6, peran & izin, alur pesanan, apa pun yang membatalkan kesepakatan pemilik.
- **Pengecualian penting dari aturan repo (sengaja):** **jangan** mengubah `PROJECT_STATE.md`, `STATUS.md`, atau berkas di `_log-sesi/`. Alasan: cabangmu belum di-merge dan sesi pembangun bekerja di berkas yang sama; mengubahnya membuat penggabungan berantakan. Catat keadaan sesimu di bagian akhir laporanmu.
- Kalau memperbaiki sesuatu, jalankan pemeriksa barumu + pemeriksa lama dan tunjukkan hasilnya (lebih baik, bukan lebih longgar).
- Butir buku tunggu baru: `docs/TERTANGGUH.md` maksimal 12 terbuka, wajib ada tenggat + alasan.
- Perbaikan yang menyentuh area berisiko tinggi wajib punya entri `docs/DECISIONS_LOG.md`.
- Kalau fondasi kamu ambil ke `/tmp/fondasi-review` (rute B): tulis perbaikannya **di checkout cabangmu sendiri** (path sama), jangan di `/tmp` — supaya ikut ter-commit.

## 7. Keluaran (deliverable)

1. `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (di checkout cabangmu), urutan:
   1. Laporan 5 baris untuk pemilik.
   2. **Putusan:** `SIAP MULAI CODING` / `SIAP SETELAH PERBAIKAN` (sebutkan daftar) / `BELUM SIAP` (sebutkan penghalang). `SIAP MULAI CODING` hanya bila **0 Kritis dan 0 Mayor terbuka**. **Tafsir wajib:** temuan yang kamu perbaiki sendiri di cabangmu tetapi **belum digabung** ke cabang sesi pembangun dihitung **belum berlaku** → putusan paling hati-hati adalah `SIAP SETELAH PERBAIKAN`, dengan daftar apa yang harus digabung.
   3. **Apa yang ditinjau:** nama cabang + commit (dan rute A/B yang kamu pakai).
   4. Metode & perintah yang dijalankan (bisa diulang orang lain).
   5. Tabel cakupan berkas (bagian 4).
   6. Temuan W1–W10 format baku: tingkat (`KRITIS`/`MAYOR`/`MINOR`/`CATATAN`) · lokasi · bukti · dampak · perbaikan · status (`SUDAH DIPERBAIKI`/`DIUSULKAN`/`SENGAJA TIDAK DIUBAH` + alasan).
   7. Klaim vs bukti (W2).
   8. Hasil simulasi 3 sudut pandang (bagian 5).
   9. Risiko terbuka + pertanyaan yang hanya bisa dijawab pemilik (data lapangan).
   10. Batas cakupan: apa yang TIDAK bisa diperiksa dan kenapa (jujur).
   11. Rekomendasi langkah berikutnya (1 paragraf) + apakah aman memulai Fase 0.
   12. Catatan atas instruksi review ini sendiri: bagian mana yang salah/tidak bisa dijalankan.
   13. Keadaan sesi: dikerjakan, tertunda, berkas yang diubah.
2. `alat/periksa-fondasi-independen.py` (pemeriksa barumu; jalan; exit 0/1).
3. Perbaikan temuan + entri `docs/DECISIONS_LOG.md` bila perlu.
4. Satu commit deskriptif, **push ke cabangmu sendiri**.
5. Laporkan ke pemilik: **5 baris ringkasan** + **putusan** + **nama cabangmu** (`git rev-parse --abbrev-ref HEAD`) + commit yang ditinjau.
6. **BERHENTI.** Jangan mulai Fase 0, jangan coding, jangan menunggu instruksi tambahan.

## 8. Kriteria selesai (Definition of Done)

- W1–W10 semua punya hasil tertulis.
- Pemeriksa barumu jalan; pemeriksa lama `PASS`/`LOLOS` **atau** ada penjelasan jujur kenapa tidak.
- Tabel cakupan berkas lengkap; putusan akhir ada dengan alasan + bukti.
- Satu commit, sudah push, tidak merge/tutup PR apa pun.
- Laporan 5 baris + putusan + nama cabang dikirim ke pemilik.

## 9. Kalau kamu ragu

Gunakan `Stop Conditions` di `AGENT_SYSTEM.md`. Untuk tugas ini, berhenti dan tanya pemilik hanya bila: masalah keamanan/uang/data pelanggan tidak jelas; dua dokumen bertentangan yang tak bisa diputuskan; usulan menyentuh keputusan terkunci; atau butuh biaya. Selain itu: catat sebagai temuan, lanjutkan, selesaikan laporan.

▲ SALIN SAMPAI (salin sampai baris ini)

---

## Bagian C — Log keputusan

- 2026-09-16 — Berkas dibuat atas permintaan pemilik: *"aku mau lakukan review independen dulu... siapkan prompt untuk sesi baru agar sesi tersebut melakukan pemeriksaan mendalam terhadap semua ini."*
- 2026-09-16 (versi 2) — Permintaan pemilik: *"membuka sesi baru untuk reviewer independen tanpa menutup sesi ini"* → alur tanpa merge; base branch cabang arena; reviewer dilarang merge/close; hasil dibawa ke sesi pembangun; reviewer tidak menyentuh berkas keadaan/log.
- 2026-09-16 (versi 3) — **Percobaan pertama gagal**: sesi reviewer mulai dari `main` (fondasi tidak terlihat) sehingga putusannya `BELUM SIAP` untuk alasan yang salah (lihat `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md`). Versi 3 menghapus ketergantungan pada base branch: bagian 0 menyuruh reviewer **menemukan sendiri** cabang fondasi dari remote (`git ls-remote` → `git fetch` → `git archive` ke `/tmp/fondasi-review`), memakai checkout-nya bila sudah benar, dan **berhenti + melapor** bila fondasi tidak ada di mana pun. Ditambahkan juga kewajiban mencantumkan cabang + commit yang ditinjau.
- 2026-09-16 (versi 3, catatan hasil putaran 2) — Putaran 2 berhasil lewat rute A. Masukan reviewer yang diterapkan: (a) tafsir "perbaikan yang belum digabung = belum berlaku"; (b) tabel cakupan boleh meringkas `skills/` jadi satu baris kebijakan; (c) pemeriksa baru wajib memakai **sumber data berbeda** (tarik dari TECH_SPEC, bukan daftar tangan); (d) rute B ditegaskan sebagai cadangan, bukan jalan utama.
