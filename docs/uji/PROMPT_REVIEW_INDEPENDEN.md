# Prompt Review Independen — Proyek "Resto Barokah" / aplikasi "Sajian"

**Dibuat:** 2026-09-16 · **Revisi:** 2026-09-16 (versi 2 — sesi pembangun TETAP TERBUKA, tidak perlu merge PR apa pun)
**Untuk:** pemilik proyek (bukan untuk agent sesi pembangun)
**Tujuan:** memeriksa SELURUH fondasi, sistem kerja, dan panduan sebelum menulis satu baris kode aplikasi.

---

## Bagian A — Cara pakai (untuk pemilik)

1. **Jangan merge PR apa pun dulu.** Sesi pembangun (yang sedang bersamamu sekarang) harus tetap terbuka, supaya temuan reviewer bisa langsung kamu serahkan ke sana.
2. Buka **sesi baru** untuk reviewer. Saat sesi baru dibuat, **atur base branch (cabang dasar) = `arena/01a0a8a2-resto-barokah`** — supaya reviewer bisa melihat seluruh hasil kerja fondasi.
3. Salin **seluruh** teks di antara penanda `▼ SALIN MULAI` dan `▲ SALIN SAMPAI` di bawah, tempel sebagai pesan pertama di sesi reviewer.
4. Diamkan sampai reviewer selesai. Ia akan memberi **laporan 5 baris + putusan + nama cabangnya** (tidak akan merge apa pun).
5. Bawa hasil itu ke sesi pembangun (tempel laporan + nama cabangnya). Sesi pembangun yang akan mengambil detail lengkap dan menindaklanjuti temuannya.
6. Setelah semua temuan ditangani dan putusan terakhir bukan `BELUM SIAP`, barulah coding Fase 0 dimulai.

**Batas satu putaran:** review ini **satu gelombang**; bila ada temuan Kritis, boleh **satu putaran tambahan** untuk memastikan perbaikannya benar. Tanpa batas ini, proyek bisa berhenti selamanya di tahap memeriksa.

**Yang tidak bisa dijamin review ini (biar harapan akurat):**
- Tidak bisa membuktikan kenyataan lapangan: merek printer (butir T-002) dan daftar perangkat (T-003) tetap harus diisi pemilik.
- Tidak bisa menjamin kode bebas cacat — kodenya belum ada. Nilainya = memastikan peta & aturan kerjanya benar sebelum berjalan jauh.
- Memeriksa dokumen dan sistem, bukan pengalaman makan di resto.

---

## Bagian B — Ringkasan tugas reviewer

Menjalankan semua pemeriksa otomatis + membuat pemeriksa barunya sendiri · memeriksa 10 wilayah · membuat tabel cakupan semua berkas · simulasi 3 sudut pandang · menguji kesiapan Fase 0 dan skenario nyata Kedai Oasis · menulis laporan ber-bukti · memperbaiki yang boleh · commit + push cabangnya sendiri · **tidak merge apa pun** · melaporkan 5 baris ke pemilik lalu berhenti.

---

▼ SALIN MULAI (salin dari baris ini ke bawah)

# TUGAS: REVIEW INDEPENDEN FONDASI — SEBELUM CODING DIMULAI

Halo. Kamu agent baru di repo ini, dan fondasi proyek ini **bukan hasil kerjamu** — jadi kamu tidak punya kepentingan untuk membelanya. Tugasmu satu: memeriksa semuanya dengan teliti sebelum proyek masuk tahap coding, lalu melaporkan hasilnya dengan jujur. Kalau ada masalah berat, mengatakan **"BELUM SIAP" adalah hasil yang berhasil**, bukan gagal.

## 0. Prasyarat & urutan awal (wajib, jangan dilewati)

Jalankan ini dulu dan tunjukkan hasilnya di laporan:

```
git rev-parse --abbrev-ref HEAD
git log --oneline -3
ls docs/ROADMAP.md docs/TERTANGGUH.md docs/DECISIONS_LOG.md
grep -m1 '^STATUS:' PROJECT_STATE.md
```

- Kamu harus mulai dari cabang **`arena/01a0a8a2-resto-barokah`** (pemilik memilihnya sebagai base branch sesimu), `docs/ROADMAP.md` harus ada, dan `PROJECT_STATE.md` harus berisi `STATUS: CODING_AKTIF`.
- **Kalau tidak sesuai:** BERHENTI. Jangan menebak, jangan mencari ke cabang lain. Laporkan ke pemilik: *"Sesi ini tidak dimulai dari fondasi — mohon buat sesi baru dengan base branch `arena/01a0a8a2-resto-barokah`, lalu jalankan lagi prompt ini."*
- Baca dulu aturan repo ini sendiri sesuai `START_DI_SINI.md` (jenis sesi: **Audit / Cross-Check**), termasuk `AGENT_SYSTEM.md` bagian "LANGKAH PERTAMA DI SETIAP SESI". Aturan repo tetap berlaku; instruksi di bawah menambah, bukan mengganti. Satu pengecualian penting ada di bagian 6 di bawah.
- Jalankan `python3 alat/mulai-sesi.py` dan catat apakah "DAFTAR TUNGGU" serta "KARTU SESI" tampil benar.
- Bahasa laporan ke pemilik: **Indonesia sederhana, tanpa jargon**, seperti menjelaskan ke pemilik warung yang tidak menulis kode.

## 1. Sikap kerja wajib (anti-laporan-palsu)

- Kamu **tidak** diminta menyetujui. Kamu diminta **mencoba mematahkan** fondasi ini.
- Dilarang menutup laporan dengan "semuanya sudah bagus" atau pujian tanpa daftar apa yang benar-benar diperiksa.
- Setiap temuan wajib punya: **lokasi berkas:baris**, **perintah persis yang dijalankan**, **keluaran yang terlihat**, **dampak nyata** (ke pemilik, ke kas, ke pelanggan, ke keamanan), **usulan perbaikan**, dan **perkiraan besar pekerjaan**.
- Kalau satu area **tidak** menemukan temuan: tulis `0 temuan`, lalu sebutkan **3 hal tersulit yang kamu coba untuk mematahkannya**.
- Dilarang mengarang. Kalau tidak bisa diverifikasi dari isi repo, tulis `TIDAK TERVERIFIKASI` — jangan `sepertinya benar`.
- Semua angka dikutip dari perintah yang kamu jalankan sendiri, bukan dari laporan lama.

## 2. Larangan keras (pelanggaran = tugas gagal)

- **Jangan merge PR apa pun dan jangan tutup PR apa pun.** Ada sesi pembangun lain yang sedang bekerja; merge/close bisa membuat sesi itu kehilangan akses dan pekerjaannya terputus. Cukup commit + push ke cabangmu sendiri.
- Dilarang **melemahkan, melonggarkan, atau menghapus** pemeriksa apa pun (`_sistem/validate_system.py`, `alat/periksa-roadmap.py`, atau lainnya). Kalau pemeriksanya sendiri salah: tulis temuan + usulkan perbaikan, jangan dilonggarkan supaya lolos.
- Dilarang menghapus berkas, `git reset --hard`, `git push --force`, atau mengubah riwayat Git.
- Dilarang **memulai coding aplikasi** (Fase 0 dan seterusnya), membuat berkas di folder aplikasi, atau menginstal paket aplikasi. Batch ini murni review + perbaikan temuan.
- Dilarang mengubah dokumen terkunci: `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md` → **usulkan di laporan**, jangan disunting sendiri.
- Dilarang mengubah keputusan pemilik (K1–K6, urutan perhitungan uang, PB1/service, peran & izin, alur pesanan) atas inisiatif sendiri. Perubahan seperti itu = usulan + entri `docs/DECISIONS_LOG.md` bertanda **MENUNGGU PERSETUJUAN PEMILIK**.
- Dilarang menyentuh atau menampilkan isi berkas rahasia (`.env`, kunci, token). Laporkan keberadaannya saja.
- Dilarang mengeluarkan biaya apa pun atau mengusulkan langkah yang memaksa pemilik membayar.
- Dilarang memperbaiki hal di luar temuan (jangan memperluas lingkup, jangan merapikan gaya tulisan yang tidak bermasalah).

## 3. Wilayah pemeriksaan (semuanya, tanpa terkecuali)

Periksa kesepuluh wilayah ini. Setiap wilayah hasilnya = temuan ber-bukti ATAU `0 temuan` + daftar uji yang dicoba.

- **W1 — Dokumen fondasi:** `docs/DISCOVERY.md`, `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/AGENT_OPERATING_GUIDE.md`, `docs/ROADMAP.md`, `docs/DECISIONS_LOG.md`, `docs/TERTANGGUH.md`, `docs/README.md`, `docs/teknisi/*`, `docs/uji/*`, `docs/desain/*`. Uji: ada yang saling bertentangan? Ada janji tanpa tugas, atau tugas tanpa janji? Ada keputusan pemilik yang hilang/berubah diam-diam? Istilah (peran, nama berkas, nama RPC, nama menu) konsisten?
- **W2 — Klaim vs bukti:** kumpulkan setiap klaim kuantitatif di laporan/dokumen (jumlah tugas, sebaran fase, jumlah tugas berisiko, jumlah entitas, jumlah RPC, jumlah temuan yang diklaim sudah diperbaiki) lalu **uji ulang sendiri**. Nyatakan tiap klaim TERBUKTI / TIDAK TERBUKTI / TIDAK BISA DIVERIFIKASI.
- **W3 — Pemeriksa otomatis (uji silang alat):** jalankan `python3 _sistem/validate_system.py` dan `python3 alat/periksa-roadmap.py`, catat keluaran persisnya. Lalu **tulis pemeriksa barumu sendiri** di `alat/periksa-fondasi-independen.py` yang **tidak menyalin logika** `alat/periksa-roadmap.py` (tulis ulang dari nol dari isi dokumen sumber), dijalankan satu perintah, keluar kode 0 bila bersih / 1 bila ada temuan, minimal memeriksa: 7 atribut lengkap tiap tugas dan isinya bukan pengisi kosong; tugas berisiko tinggi punya kewajiban DECISIONS_LOG; setiap `Ref` menunjuk bagian yang benar-benar ada; butir `T-xxx` yang dirujuk ada di TERTANGGUH (dan sebaliknya); modul wajib M1–M12, entitas basis data, dan ART-1..ART-10 punya tugas; tidak ada nomor tugas ganda atau fase terlewat. Sertakan hasil jalannya.
- **W4 — Mutu isi tugas (uji tangan):** ambil **minimal 15 tugas acak** (sebutkan caramu mengacak, minimal 3 dari Fase 0) dan periksa **seluruh Fase 0 (T0-01..T0-10)** satu per satu. Untuk tiap tugas: tujuan masuk akal? berkas yang disebut wajar? DoD bisa diuji? verifikasi bisa dijalankan? ada langkah tersembunyi yang tidak tertulis? kalau dikerjakan persis seperti tertulis, hasilnya benar?
- **W5 — Kesiapan Fase 0:** baca Fase 0 seperti kamu yang mengerjakannya. Semua informasi yang dibutuhkan ada (versi Node, nama paket, langkah Supabase, langkah Cloudflare, cara menyimpan rahasia, alamat deploy, urutan commit)? Ada langkah yang mustahil tanpa akun/alat yang belum disiapkan? Urutannya benar? **Uji khusus:** apakah ada tugas untuk membuat akun & proyek Supabase, dan apakah ada tugas menjaga basis data gratis tetap hidup saat resto libur panjang (database gratis bisa "tertidur")? Kalau tidak ada, itu temuan.
- **W6 — Sistem kerja agent:** periksa `_sistem/validate_system.py` (baca logikanya: aturannya masuk akal? ada celah lolos? ada aturan bertentangan?), `_sistem/templates/*`, `_sistem/AUDIT_*.md`, serta berkas akar `AGENT_SYSTEM.md`, `START_DI_SINI.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TESTS.md`, `ACCEPTANCE_TEST_LOG.md`, `REKAM-KLINIK.md`, `PROFIL_PENGGUNA.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `SYSTEM_MANIFEST.md`, `_Notes.md`, `_salinan-meta/`, `_log-sesi/*`. Uji: semuanya masih cocok untuk proyek nyata yang berjalan (bukan template kosong)? Ada aturan bertabrakan? Ada berkas berstatus lama yang menyesatkan? Jalankan uji penerimaan di `ACCEPTANCE_TESTS.md` sejauh bisa, tandai mana yang belum teruji.
- **W7 — Simulasi agent baru yang bodoh (uji terpenting):** bayangkan kamu agent baru yang tidak tahu apa pun dan **hanya** membaca berkas wajib menurut aturan repo. Apakah kamu tahu harus berbuat apa? Tahu batas larangan? Tahu apa yang menunggu keputusan pemilik? Apakah kamu akan menanyakan hal yang sebenarnya sudah dijawab di suatu dokumen? Tulis tiap celah sebagai temuan. Uji juga apakah `alat/mulai-sesi.py` benar-benar memuat buku tunggu dan cocok dengan `docs/TERTANGGUH.md` (hitung jumlah butir terbuka).
- **W8 — Jalur & panduan pemilik:** ikuti `PANDUAN_PENGGUNA.md` dari awal sampai akhir **sebagai pemilik non-teknis** yang memakai GitHub dan sesi AI. Catat setiap langkah yang tidak bisa dijalankan, tidak jelas, mengasumsikan hal yang tidak dimiliki pemilik, atau bisa membuat pemilik melakukan kesalahan berbahaya (mis. menghapus sesuatu, merge ke arah yang salah). Periksa juga bahwa berkas versi lama (`PANDUAN_PEMAKAIAN.md`) benar-benar jelas berstatus **arsip** dan tidak menyesatkan.
- **W9 — Operasional nyata & biaya nol:** (a) **Satu hari penuh** di Kedai Oasis: buka shift → pelanggan memesan → dapur memasak → bayar → tutup shift → laporan — apakah setiap langkah punya tugas di ROADMAP, ada lubang? (b) **Skenario gagal:** internet putus saat jam sibuk; listrik mati; printer rusak; pesanan batal setelah dimasak; kas tidak cocok; voucher dicoba berulang; pegawai berhenti (email & PIN); dua orang mengubah pengaturan bersamaan — adakah tugas/aturan penanganannya? (c) **Biaya nol:** adakah langkah yang menuntut pembayaran atau melanggar ketentuan layanan gratis? Periksa batas gratis layanan yang dipakai (Cloudflare, Supabase, pengirim email) dan tulis risikonya bila batas tembus (aplikasi berhenti, data tidur, email tidak terkirim). (d) **Data & keamanan:** adakah tugas membatasi akses data pelanggan, cadangan (backup), pemulihan, dan uji izin (siapa boleh lihat apa)?
- **W10 — Integritas repo & kerahasiaan:** periksa `git ls-files`. Cari berkas besar tidak perlu, berkas rahasia yang tidak sengaja masuk, sisa berkas sementara, dan berkas yang seharusnya diabaikan Git. Periksa ukuran folder `skills/` dan sampel isinya: wajar dibawa di repo ini? ada isi sensitif? Laporkan tanpa menampilkan isi rahasia.

## 4. Tabel cakupan berkas — WAJIB

Buat daftar **semua berkas yang dilacak Git** (dari `git ls-files`; isi `node_modules/` dan isi `skills/` diperiksa sebagai kebijakan), lalu beri status per berkas: `DIPERIKSA MENDALAM` · `DIPERIKSA SEKILAS` · `TIDAK DIPERIKSA (alasan)`. Berkas yang "tidak relevan" tetap dicantumkan. Tujuannya: pemilik minta "semuanya diperiksa tanpa terkecuali", jadi harus terlihat berkas mana yang tidak diperiksa dan kenapa.

## 5. Simulasi tiga sudut pandang (wajib, tulis hasilnya)

1. **Agent baru yang bodoh** — apa yang paling mungkin dia salah pahami, dan instruksi mana yang harus diperjelas?
2. **Pemilik non-teknis** — langkah mana yang bikin dia tersesat atau panik?
3. **Kedai Oasis, Sabtu malam penuh** — bagian rencana mana yang paling mungkin jebol lebih dulu?

Untuk tiap sudut pandang: minimal 3 kelemahan konkret, dan tentukan mana yang sudah tertutup fondasi, mana yang belum.

## 6. Aturan memperbaiki temuan

- **Boleh langsung diperbaiki** (catat di laporan): salah ketik, istilah tidak konsisten, rujukan berkas/bagian salah, informasi kurang di dokumen non-terkunci, tugas yang jelas-jelas kurang, penambahan butir buku tunggu, penambahan catatan/pemeriksa yang memperkuat.
- **Harus diusulkan, tidak boleh diubah sendiri:** `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md`, nilai uang/pajak/service, keputusan K1–K6, peran & izin, alur pesanan, dan apa pun yang membatalkan kesepakatan pemilik.
- **Pengecualian penting dari aturan repo (sengaja):** **jangan** mengubah `PROJECT_STATE.md`, `STATUS.md`, atau berkas di `_log-sesi/`. Alasan: cabangmu belum di-merge dan sesi pembangun sedang bekerja di berkas yang sama; mengubahnya membuat penggabungan berantakan. Catat keadaan sesimu (keadaan, apa yang dikerjakan, apa yang tertunda) di bagian akhir laporanmu saja.
- Setiap perbaikan harus bisa diuji ulang: setelah memperbaiki, jalankan pemeriksa barumu + pemeriksa lama dan tunjukkan hasilnya (harus lebih baik, bukan lebih longgar).
- Kalau menambah butir buku tunggu: `docs/TERTANGGUH.md` maksimal 12 butir terbuka, setiap butir punya tenggat dan alasan.
- Perbaikan apa pun yang menyentuh area berisiko tinggi wajib punya entri `docs/DECISIONS_LOG.md`.

## 7. Keluaran (deliverable)

1. `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md`, urutannya:
   1. Laporan 5 baris untuk pemilik.
   2. **Putusan:** `SIAP MULAI CODING` / `SIAP SETELAH PERBAIKAN` (sebutkan daftar perbaikannya) / `BELUM SIAP` (sebutkan penghalangnya). Aturan: `SIAP MULAI CODING` hanya bila **0 temuan Kritis dan 0 Mayor terbuka**.
   3. Metode & perintah yang dijalankan (bisa diulang orang lain).
   4. Tabel cakupan berkas (bagian 4).
   5. Temuan W1–W10 dengan format baku: tingkat (`KRITIS`/`MAYOR`/`MINOR`/`CATATAN`) · lokasi · bukti (perintah + keluaran) · dampak · perbaikan · status (`SUDAH DIPERBAIKI`/`DIUSULKAN`/`SENGAJA TIDAK DIUBAH` + alasan).
   6. Klaim vs bukti (W2).
   7. Hasil simulasi 3 sudut pandang (bagian 5).
   8. Risiko yang masih terbuka + pertanyaan yang hanya bisa dijawab pemilik (data lapangan).
   9. Batas cakupan: apa yang TIDAK bisa kamu periksa dan kenapa (jujur, jangan dibesar-besarkan).
   10. Rekomendasi langkah berikutnya (1 paragraf) + apakah aman memulai Fase 0.
   11. Catatan atas instruksi review ini sendiri: bagian mana yang tidak bisa dijalankan atau menurutmu salah.
   12. Keadaan sesi: apa yang dikerjakan, apa yang tertunda, berkas apa yang kamu ubah.
2. `alat/periksa-fondasi-independen.py` (pemeriksa barumu; jalan; kode keluar 0/1).
3. Perbaikan temuan yang boleh diperbaiki + entri `docs/DECISIONS_LOG.md` bila perlu.
4. Satu commit deskriptif, **push ke cabangmu sendiri**, lalu laporkan.

## 8. Kriteria selesai (Definition of Done)

- Semua wilayah W1–W10 punya hasil tertulis, tidak ada yang kosong.
- Pemeriksa barumu jalan dan hasilnya tercatat; pemeriksa lama masih `PASS`/`LOLOS` **atau** ada penjelasan jujur kenapa tidak.
- Tabel cakupan berkas lengkap.
- Putusan akhir ada, dengan alasan dan bukti.
- Perubahan tersimpan sebagai **satu commit**, sudah **push ke cabangmu** (jangan merge, jangan tutup PR).
- Laporkan ke pemilik: **5 baris ringkasan** (apa yang dikerjakan · apa yang ditemukan · apa yang sudah diperbaiki · apa yang menunggu keputusan pemilik · langkah berikutnya) + **putusan** + **nama cabangmu** (`git rev-parse --abbrev-ref HEAD`) supaya sesi pembangun bisa mengambil detailnya.
- Setelah itu **BERHENTI**. Jangan mulai Fase 0, jangan coding, jangan menunggu instruksi tambahan.

## 9. Kalau kamu ragu

Gunakan `Stop Conditions` di `AGENT_SYSTEM.md`. Untuk tugas ini, berhenti dan tanya pemilik hanya bila: ada masalah keamanan/uang/data pelanggan yang tidak jelas; ada dua dokumen bertentangan yang tidak bisa kamu putuskan; ada usulan yang menyentuh keputusan terkunci; atau ada hal yang butuh biaya. Selain itu: **catat sebagai temuan, lanjutkan pemeriksaan, selesaikan laporan.**

▲ SALIN SAMPAI (salin sampai baris ini)

---

## Bagian C — Log keputusan

- 2026-09-16 — Berkas dibuat menjelang penutupan sesi pembangunan fondasi, atas permintaan pemilik: *"Apakah menurut kamu ini udh bener-bener siap untuk mulai coding... aku mau lakukan review independen dulu. Aku mau kamu siapkan prompt untuk sesi baru agar sesi tersebut melakukan pemeriksaan mendalam terhadap semua ini, termasuk pada sistem nya, juga pada panduan penggunanya, dan lain nya."*
- 2026-09-16 (revisi versi 2) — Permintaan pemilik: *"aku mau membuka sesi baru untuk reviewer independen tanpa menutup sesi ini, sehingga klo ada temuan dari reviewer tersebut aku bisa kasih ke kamu"* → alur diubah: **tidak perlu merge PR #1 lebih dulu**; sesi reviewer dibuat dengan **base branch `arena/01a0a8a2-resto-barokah`**; reviewer **dilarang merge/menutup PR apa pun** (merge/close bisa memutus akses sesi pembangun yang masih hidup); reviewer melaporkan **putusan + 5 baris + nama cabangnya** kepada pemilik untuk diteruskan ke sesi pembangun; reviewer **tidak menyentuh** `PROJECT_STATE.md`, `STATUS.md`, dan `_log-sesi/*` agar penggabungan bersih.
