# AGENT_OPERATING_GUIDE.md — Aturan Kerja Agent (Resto Barokah)

> **Status: DISETUJUI & BERLAKU — 2026-09-16** (pemilik: *"Cukup, lanjut."* atas bahan diskusi
> `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md`). Dokumen ini **dibaca ulang setiap sesi kerja**
> (bersama `TECH_SPEC.md`), karena setiap sesi bisa memakai model AI yang berbeda dan tidak punya ingatan.
>
> Ditulis untuk: **AI agent** yang melanjutkan proyek ini lintas sesi — bukan developer manusia.
> Rujukan: `docs/PRD.md` (dikunci) · `docs/TECH_SPEC.md` (dikunci) · `AGENT_SYSTEM.md` · `PROFIL_PENGGUNA.md`

---

## 0. Fakta platform yang membentuk SEMUA aturan di bawah (wajib dipahami lebih dulu)

Proyek ini dikerjakan lewat sesi agent di **lmarena**. Kenyataan platform yang tidak bisa diubah:

1. **Model AI tiap sesi bisa berbeda** — sesi baru tidak mewarisi "cara berpikir", ingatan, atau asumsi sesi sebelumnya.
   → **Satu-satunya memori proyek adalah berkas di repo ini.** Kalau tidak ditulis, hilang.
2. **Branch dibuat otomatis** (`arena/<id>-...`), tidak bisa diganti namanya. **Base branch dipilih di awal sesi**
   (rekomendasi: `main`). Agent **tidak boleh** pindah/ membuat branch lain.
3. **Setelah PR di-merge atau di-close, akses sesi itu hilang** (branch sudah tidak bisa di-push lagi).
   → Semua pekerjaan **WAJIB sudah di-commit & push** sebelum meminta merge. Sesi berikutnya dibuka dari `main`.
4. **Chat lama tidak bisa dibaca sesi baru.** Karena itu ada tiga penanda yang saling menutupi:
   `PROJECT_STATE.md` (posisi), `STATUS.md` (field pasti), `_log-sesi/LOG_SESI_*.md` (kronologi mendekati kata asli).
5. **PR tanpa auto-merge** — pemilik selalu punya gerbang terakhir.

**Konsekuensi operasional (tidak bisa ditawar):** commit + push setiap langkah selesai · tutup sesi dengan
memperbarui ketiga penanda · jangan menumpuk pekerjaan lama tanpa push · sesi baru mulai dengan membaca fondasi.

### Gerbang pindah sesi (WAJIB dicek sebelum membuka sesi baru)

> **Dikoreksi 2026-09-20 (temuan audit I F-12).** Versi lama bagian ini mewajibkan **merge PR ke `main`**
> sebelum sesi baru; `PROMPT_SESI_BARU.md` di sisi lain melarang merge hanya untuk melihat pekerjaan.
> Dua-duanya dokumen aktif, jadi agent terjepit. Aturan tunggal yang berlaku sekarang:

**Melihat & melanjutkan pekerjaan TIDAK perlu merge.** Cukup susul cabang sesinya (tanpa mengubah `main`):

```
git fetch origin <CABANG-SESI>:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
```

- Sesi baru tetap boleh dibuka dari basis `main`; langkah di atas menyusulkan pekerjaan terakhir ke
  ruang kerja sesi baru itu. Branch sesi lama tidak dipakai ulang — tapi **isinya** tetap bisa dibaca
  siapa pun lewat GitHub selama branch itu ada.
- **Merge PR ke `main` adalah keputusan pemilik (Lee)** — bukan syarat untuk bekerja atau meninjau.
  PR #1 misalnya sengaja dibiarkan **tidak di-merge**.
- Setelah PR di-merge/di-close: branch sesi itu **selesai** — jangan push lagi ke sana.
- Kalau `docs/ops/SIAP-LANJUT.md` menyebut cabang yang berbeda dari baris `SESI YANG AKU LANJUT` di
  `PROMPT_SESI_BARU.md`: **baris pilihan Lee yang menang**; laporkan bedanya lalu rapikan handoff.

### Kalau ruang kerja dinyalakan ulang (pulih cepat — pelajaran 2026-09-16)

Ruang kerja bisa restart di tengah proyek. Dua hal yang biasa rusak **bukan karena kode kita**:

| Gejala | Sebab | Pemulihan |
|---|---|---|
| Pratinjau mati, pesan `vite: not found` | `node_modules` hilang (sengaja tidak disimpan) | `bash aplikasi/alat/pratinjau.sh` (memasang pustaka ±3 detik lalu menyalakan pratinjau) |
| Riwayat Git lokal mundur (HEAD kembali ke `main`, berkas kerja hilang) | salinan Git lokal ter-reset; pekerjaan terbaru hanya ada di GitHub | `bash alat/pulihkan-git.sh` (memeriksa) → `bash alat/pulihkan-git.sh --perbaiki` (memulihkan) |

Aturan yang tidak boleh dilanggar saat memulihkan:

- **Jangan menulis ulang berkas dari ingatan.** Ambil dari GitHub (`git fetch` lalu `git restore --source=origin/<cabang>`); ingatan model bukan sumber kebenaran.
- **Jangan pernah** `git reset --hard`, `git push --force`, atau menghapus branch. Pemulihan resmi = `git reset --soft` + `git restore --source=…` (lihat `alat/pulihkan-git.sh`).
- Kalau ada perubahan belum di-commit, **berhenti**: periksa dulu (`git status`), commit/simpan, baru pulihkan. Pemulih sengaja menolak jalan pada ruang kerja kotor.
- Setelah pulih: jalankan `bash aplikasi/alat/periksa-semua.sh`, lalu **commit + push lagi** — supaya kejadian yang sama tidak mengulang.

---

## 1. Profil User (pemilik non-teknis)

- Pemilik **tidak menulis kode** dan tidak memakai istilah teknis → semua laporan dalam **bahasa Indonesia sehari-hari**,
  langkah bernomor, analogi bila perlu. Istilah teknis hanya di dalam dokumen teknis, selalu diberi arti singkat.
- Setiap laporan menjawab 4 hal: **apa yang dikerjakan · hasil nyata (bisa dilihat/dicoba) · artinya untuk pemilik · apa yang dibutuhkan dari pemilik**.
- Berita buruk (uji gagal, batas gratis, risiko) disampaikan **lebih dulu**, disertai usul perbaikan.
- Keputusan yang diminta kepada pemilik selalu berbentuk: **2–3 pilihan + untung/rugi singkat + rekomendasi agent + dampaknya**.
- Pemilik kadang menjawab singkat (`"lanjut"`, `"terserah"`) atau melewati formulir pilihan → itu **persetujuan resmi**:
  agent memutuskan sesuai rekomendasinya sendiri dan **mencatatnya sebagai keputusan resmi** (tidak ada asumsi diam-diam).
- Salah → akui, perbaiki, catat penyebabnya agar tidak terulang. Jangan pernah menutupi kegagalan.

## 2. Pemasangan Skill Otomatis — wajib di awal SETIAP sesi

Skill yang tersedia **sudah tersimpan lokal** di `skills/` (56 folder, 87 berkas SKILL.md, ±26 MB) — tidak perlu internet,
tidak perlu memasang ulang. Yang perlu dilakukan sesi baru: **memuatnya ke "diri" sendiri dengan cara membacanya**.

**Protokol (urutan wajib):**

1. Jalankan: `python3 alat/mulai-sesi.py` → mencetak **KARTU SESI** (posisi proyek, branch/PR, log sesi terbaru,
   **daftar skill yang wajib dibaca untuk fase sekarang**, dan berkas fondasi yang wajib dibaca).
2. **Baca sungguhan** setiap berkas skill yang tercantum (SKILL.md beserta referensi yang ditunjuknya bila relevan).
   Jangan hanya menyebutnya. Jangan lewati.
3. Baca berkas fondasi yang ditandai `[ADA]` di KARTU SESI (utamanya `docs/TECH_SPEC.md` bagian relevan +
   dokumen ini + `docs/PRD.md` fitur terkait).
4. Laporkan **KARTU SESI terisi** ke pemilik (termasuk jumlah skill yang dibaca) **sebelum** mulai bekerja.
5. Kalau ada skill yang dibutuhkan fase ini tapi tidak ada di repo → **laporkan**. Boleh mengusulkan pemasangan
   (`npx skills add`), tetapi **jangan memasang apa pun tanpa izin pemilik** (aturan biaya nol + keamanan).
6. Kalau `alat/mulai-sesi.py` gagal dijalankan → pakai jalur cadangan: ikuti tabel fase → skill di bawah, dan catat kegagalannya.

**Jalur cadangan: peta fase → skill wajib** (kalau script tidak tersedia):

| Fase (STATUS) | Skill wajib dibaca |
|---|---|
| FONDASI_TAHAP_1 | `skills/product-discovery/discovery-interview-prep` · `skills/product-management` · `skills/brainstorming` |
| FONDASI_TAHAP_2 | `skills/product-management/prd-development` · `skills/product-management/prioritization-advisor` · `skills/prd-taskmaster` |
| FONDASI_TAHAP_3 | `skills/supabase` · `skills/supabase-postgres-best-practices` · `skills/cloudflare` · `skills/wrangler` · `skills/security-review` |
| FONDASI_TAHAP_4 | `skills/ai-agent-skills/skills/best-practices` · `skills/tdd-workflow` · `skills/verification-loop` · `skills/security-review` |
| FONDASI_TAHAP_5 | `skills/product-discovery/roadmap-planning` · `skills/product-management/prioritization-advisor` · `skills/writing-plans` |
| FONDASI_TAHAP_6 | `skills/verification-loop` · `skills/verification-before-completion` · `skills/systematic-debugging` |
| CODING_AKTIF | `skills/vercel-react-best-practices` · `skills/building-components` · `skills/supabase-postgres-best-practices` · `skills/cloudflare` · `skills/tdd-workflow` · `skills/systematic-debugging` · `skills/agent-browser` · `skills/security-review` |
| Sesi desain | `skills/ui-ux-pro-max` · `skills/design-system` · `skills/ui-styling` · `skills/brand` · `skills/banner-design` |

Semua fase juga membaca `skills/find-skills` (untuk mencari skill yang belum terpasang).

## 3. Coding Conventions

- **Bahasa:** nama tabel, kolom, fitur, berkas layar, komponen → Bahasa Indonesia (`pesanan`, `catatan_audit`, `LayarKasir`).
  Nama bawaan alat (`useState`, `map`) tetap. Komentar menjelaskan **kenapa**, bukan sekadar mengulang kode.
- **Ketat & aman:** TypeScript mode `strict`; `any` dilarang kecuali ada alasan tertulis; nilai kosong wajib ditangani.
  **Uang selalu bilangan bulat rupiah** — tidak pernah pecahan/koma.
- **Alat wajib sebelum commit:** ESLint + Prettier lulus; `npx tsc --noEmit` bersih. Agent yang menjalankannya — bukan pilihan.
- **Tampilan:** wajib memakai token desain v3 (`prototipe/css/tokens.css` → dipindah ke aplikasi).
  Dilarang menulis warna/ukuran bayangan mentah di luar token. Tema baru = token baru, bukan `style` langsung.
- **Bentuk:** satu komponen satu berkas; fungsi ±50 baris; tidak ada kode mati; folder mengikuti `docs/TECH_SPEC.md` §3.
- **Aliran data:** satu arah; **klien tidak pernah menghitung uang** — semua angka resmi dari peladen (`hitung_total()`).
- **Aksesibilitas dasar:** target sentuh ≥44 px, kontras memenuhi pemeriksa, fokus keyboard terlihat,
  label pembaca layar pada tombol ikon.

## 4. Struktur Commit & Branch

- Kerja **hanya** di branch sesi (`arena/...`); **tidak pernah** push ke `main`; PR dibuka tanpa auto-merge.
- Awali sesi dengan `git branch --show-current` + `gh pr list --state all`; bila PR branch ini sudah MERGED/CLOSED →
  sesi tidak bisa push lagi → laporkan, jangan memaksa.
- **Satu langkah kerja = satu commit**, pesan Bahasa Indonesia **rinci** (apa + kenapa + berkas penting) karena
  deskripsi panjang tidak selalu bisa disimpan platform.
- **Push setiap langkah selesai.** Jangan menumpuk. Kalau sesi mati sebelum push, pekerjaan hilang permanen.
- Commit wajib bersih: tanpa berkas rahasia (`.env*`), tanpa berkas besar tak perlu, tanpa hasil percobaan.
- Sebelum minta merge: pastikan `ROADMAP.md` `[x]` sinkron, `DECISIONS_LOG.md` terisi bila menyentuh area berisiko,
  dan ketiga penanda sesi sudah diperbarui.

## 5. Testing (jaring pengaman pengganti review manusia)

1. **Uji database (SQL)** — setiap migrasi: isolasi data antar-resto/antar-cabang (RLS), ketepatan uang,
   voucher hanya sekali pakai, `catatan_audit` tidak bisa diubah/dihapus.
2. **Uji unit (Vitest)** — fungsi hitungan uang & format wajib lulus 100%, diuji dengan kasus nyata
   (pajak, service, diskon, pembulatan, void, uang pas/kurang).
3. **Uji tampilan statis** — `prototipe/uji-kontras.py` + `prototipe/alat/periksa-halaman.py` (diperluas ke aplikasi):
   kontras, aturan desain, target sentuh, struktur halaman.
4. **Uji alur (Playwright, di CI/lingkungan pengembangan)** — 7 alur wajib: buka shift → pesan → kirim dapur → bayar →
   cetak → void berjenjang → tutup kas, ditambah alur voucher & katalog publik. **Catatan 2026-09-17:** Chromium
   **tidak bisa diunduh di ruang kerja agent** (sudah dicoba, gagal) → uji peramban **hanya jalan di CI**; jaring lokal
   penggantinya = uji SQL + uji komponen (jsdom) + pemeriksa statis. Dilarang mengklaim "teruji di peramban" bila
   uji itu belum jalan di CI.
4b. **Uji komponen per layar (WAJIB sejak 2026-09-17, rincian `docs/SPESIFIKASI_UI.md` §6):** tiap aksi di Registri Aksi
   dibuktikan memanggil RPC yang benar untuk peran yang berizin, dan **tidak ada** untuk peran terlarang; ketujuh keadaan
   (kosong/memuat/gagal/menunggu terkirim/tanpa akses/data sebagian/berhasil) punya ujinya sendiri.
4c. **Uji keamanan akun & perangkat (WAJIB, `docs/KEAMANAN.md` §14):** peran × aksi · perangkat tidak terdaftar ·
   pencabutan seketika · sesi lewat umur · kunci percobaan masuk · PIN lemah/kembar · rantai audit · mode dukungan.
4e. **Audit independen (WAJIB sejak 2026-09-17 — `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`):**
   **AUD-0** audit dampak saat keputusan berubah · **AUD-1** periksa batch (CI, otomatis) · **AUD-2** review independen
   akhir fase/perubahan berisiko oleh **sesi baru + model berbeda, hanya-baca**, laporan **wajib lolos**
   `python3 alat/audit-independen.py --periksa-laporan <berkas>` · **AUD-3** audit adversarial 6 lensa + **kalibrasi
   cacat tanaman** sebelum pilot/atas permintaan pemilik. Temuan **K-1/K-2 TERVERIFIKASI = fase tidak boleh ditutup**.
   Mekanismenya sendiri wajib teruji: `python3 alat/audit-independen.py --uji-diri` (ikut CI).
4f. **Buku pedoman induk = bagian dari kode (WAJIB sejak 2026-09-17):** setiap kali menambah/mengubah **mekanisme** (audit, keamanan, biaya, uji, laporan, alur kerja baru) atau menambah **prompt** untuk pemilik, batch yang sama **wajib** memperbarui bagian terkait di `PANDUAN_PENGGUNA.md` (Bagian B alur · Bagian C prompt · Bagian D mekanisme · Bagian E perintah · Bagian G masalah · Bagian H peta berkas). Pemeriksa `alat/periksa-panduan.py` (ikut CI) menahan CI bila buku menyusut, kehilangan topik wajib, kehilangan mekanisme, blok promptnya tidak lagi identik dengan sumbernya, atau menunjuk berkas yang tidak ada. Alasan: mekanisme yang tidak bisa dipakai pemilik = mekanisme yang tidak ada; buku basi = cacat K-2/K-3 yang paling lama tersembunyi.
4g. **Review PR independen (WAJIB sejak 2026-09-17 — `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`):** sebelum meminta Lee menekan merge, setiap PR wajib: (a) CI **hijau pada commit PR terakhir**; (b) paket review dibuat mesin (`python3 alat/review-pr.py --siapkan`) dan dijalankan **sesi peninjau independen**; (c) laporan peninjau **lolos** `--periksa-laporan`; (d) temuan **K-1/K-2 tertutup** (gerbang `tahan_semua`); (e) untuk **Jalur Merah** (migrasi, izin/RLS, uang, data pelanggan, alat pemeriksa CI) laporan wajib memuat bukti uji mutasi + rencana pemulihan; (f) Lee menerima **Kartu Keputusan** (`--kartu-keputusan`). Agent **tidak pernah** meminta merge tanpa keenam hal itu, dan **tidak pernah** menekan merge sendiri. Cek cepat: `python3 alat/review-pr.py --kesiapan`.


4d. **Uji pemanggilan RPC langsung:** penolakan **tidak boleh** hanya di layar — peran tanpa izin yang memanggil RPC
   langsung (tanpa lewat UI) wajib ditolak database; ini yang membedakan "disembunyikan" dari "diamankan".
5. **Uji mesin/nyata** — cetak struk di printer Kedai Oasis (risiko #1 PRD) sebelum gelombang berikutnya dimulai.
6. **Daftar uji terima bahasa manusia** ditulis di akhir tiap gelombang untuk pemilik (contoh:
   *"Coba bayar tanpa memilih meja → harus muncul pesan jelas"*).
7. **Aturan gelombang:** tidak ada naik gelombang sebelum semua uji hijau. Cacat yang ditemukan → dicatat,
   diperbaiki, diuji ulang, dilaporkan — bukan didiamkan.

## 6. Error Handling Format

- **Pesan ke pengguna:** (a) masalahnya dalam bahasa manusia · (b) yang bisa dilakukan sekarang · (c) kode pendek.
  Contoh: *"Maaf, pesanan belum tersimpan karena koneksi terputus. Pesanan ada di antrean dan akan terkirim sendiri. Kode: PS-104."*
- **Bentuk seragam dari peladen:** `{ berhasil: bool, kode: teks, pesan: teks, data: … }` (mengikuti `TECH_SPEC.md` §5 — sumber kebenaran). Klien hanya menampilkan `pesan`, tidak menebak.
- **Kode error** berkelompok: `PS-1xx` pesanan · `BY-2xx` pembayaran · `VC-3xx` voucher · `KS-4xx` kas/shift ·
  `PR-5xx` printer · `AK-6xx` akun/izin · `UM-9xx` umum. Kode ditulis di tabel rujukan saat dibuat.
- **Catatan masalah:** tabel `catatan_kesalahan` (waktu, peran, kode, konteks, tanpa data sensitif).
  Tiga tingkat: `info` · `penting` (uang/izin/voucher) · `gagal`. Dibaca agent sebelum bertanya ke pemilik.
- **DILARANG** menulis sandi, PIN, token, atau data pribadi pelanggan ke catatan mana pun (termasuk pesan error & commit).

## 7. Definition of Done (arti "selesai")

Sebuah task hanya boleh ditandai `[x]` bila **semua** tercentang:

- [ ] Kode sesuai `docs/TECH_SPEC.md` & dokumen ini; komentar di bagian rumit
- [ ] Uji otomatis yang relevan ada & lulus (dan buktinya dilaporkan)
- [ ] `docs/ROADMAP.md`: task `[ ]` → `[x]`
- [ ] `docs/DECISIONS_LOG.md` diperbarui **bila menyentuh Area Berisiko Tinggi** (wajib, sebelum task lain)
- [ ] Dokumen fondasi diperbarui bila ada detail baru yang mengikat (lihat §11)
- [ ] Commit + push; repo bersih
- [ ] `PROJECT_STATE.md` + `STATUS.md` + LOG_SESI diperbarui (langkah terakhir)
- [ ] Laporan bahasa manusia ke pemilik: apa yang berubah · artinya · apa berikutnya
- [ ] **Buku pedoman induk** (`PANDUAN_PENGGUNA.md`) diperbarui bila batch menyentuh mekanisme/prompt/berkas untuk pengguna — dibuktikan `python3 alat/periksa-panduan.py` LOLOS
- [ ] **Bila batch membuka/menyentuh PR:** review PR independen selesai + `python3 alat/review-pr.py --kesiapan` SIAP + Kartu Keputusan di tangan Lee (atau PR belum dimintakan merge)
- [ ] **Bila menyentuh uang/keamanan/data pelanggan:** AUD-2 (audit independen) sudah dijalankan & laporannya LOLOS kontrak, dan **tidak ada** temuan K-1/K-2 terbuka

**Tambahan untuk tugas UI (DoD v2 — 2026-09-17; rincian `docs/SPESIFIKASI_UI.md` §6):**

- [ ] Kontrak layar ditulis lengkap (tujuan · peran · jalan masuk · data · aksi · **7 keadaan** · bukti)
- [ ] Semua aksi layar ada di **Registri Aksi** (`aplikasi/src/lib/aksi.ts`) dengan izin/RPC/pesan/uji
- [ ] Tombol dirender lewat `TombolAksi` (tombol mentah dilarang di folder `layar/`)
- [ ] Uji komponen per peran lulus (aksi berizin memanggil RPC benar; aksi terlarang tidak tampil)
- [ ] Pemeriksa `python3 alat/peta-ui.py --periksa` lulus + `docs/PETA_UI.md` sudah diperbarui (hasil generate)
- [ ] Naskah jalan bernomor `W-<fase>-<nomor>` ditulis & **dijalankan** di pratinjau; hasil dicatat di blok Bukti ROADMAP
- [ ] Izin ditegakkan di database (dibuktikan uji SQL), bukan hanya disembunyikan di layar

## 8. Cara Kerja Agent Lintas Sesi

1. **Awal sesi:** `PROFIL_PENGGUNA.md` → `alat/mulai-sesi.py` (KARTU SESI) → baca skill & fondasi yang ditandai →
   laporkan posisi + KARTU SESI ke pemilik → tunggu konfirmasi tujuan.
2. **Selama sesi:** setiap keputusan/koreksi/kendala/kalimat penting pemilik → langsung ditambahkan ke
   `LOG_SESI_*.md` (mendekati kata asli) + commit & push. Mencatat berlebihan = rugi detik; lupa mencatat = rugi jam.
3. **Akhir sesi/checkpoint:** audit `ROADMAP` (`[x]` sinkron?) · `DECISIONS_LOG` (ada yang terlewat?) · repo bersih ·
   `PROJECT_STATE` + `STATUS` + `LOG_SESI` diperbarui · **commit & push** · baru nyatakan aman ditutup.
4. **Jangan mengulang tahap yang sudah dikunci** tanpa alasan sah (instruksi baru pemilik / bukti cacat ber-rujukan).

## 9. Protokol DECISIONS_LOG.md

- Dokumen ini **mulai kosong dan diisi selama coding** (dibuat resmi pada Tahap 6 dari template).
- **Wajib dibaca lebih dulu** sebelum menyentuh Area Berisiko Tinggi (`TECH_SPEC.md` ART-1…ART-10) —
  bukan menebak dari kode yang ada.
- Kalau pendekatan yang **sudah tercatat** perlu diubah → **STOP, tanya pemilik dulu**. Dilarang mengganti diam-diam.
- Setelah keputusan baru di area berisiko → **tulis entri sebelum lanjut task lain**.

Contoh 1 (sudah menjadi keputusan fondasi — dipakai saat coding dimulai):

```markdown
### [Fase 1/2026-10-02] Uang dihitung di peladen, bukan di klien
- **Area:** Kalkulasi Keuangan (ART-3)
- **Keputusan:** seluruh total/pajak/service/diskon/kembalian dihitung fungsi SQL tunggal `hitung_total()`;
  klien hanya menampilkan angka dari peladen.
- **Alasan:** mencegah manipulasi dari perangkat & mencegah dua rumus berbeda yang bisa berselisih.
- **File terkait:** `supabase/migrations/00X_hitung_total.sql`, `src/lib/format.ts`
- **Implikasi:** fitur apa pun yang butuh angka uang WAJIB memanggil `hitung_total()` — dilarang menyalin rumusnya.
```

Contoh 2:

```markdown
### [Fase 1/2026-10-05] Pola RLS: penyewa + cabang di setiap policy
- **Area:** RLS & Isolasi Penyewa (ART-1)
- **Keputusan:** setiap tabel ber-`penyewa_id` memakai policy `USING (penyewa_id = auth.penyewa_id())`;
  tabel ber-cabang menambah `AND cabang_id IN (SELECT cabang_id FROM pengguna_cabang WHERE pengguna_id = auth.uid())`.
- **Alasan:** satu pola seragam mengurangi peluang satu tabel lupa dikunci.
- **File terkait:** `supabase/migrations/*`, `supabase/tes/rls_*.sql`
- **Implikasi:** tabel baru wajib menyalin pola ini + uji RLS-nya; jangan membuat pengecualian tanpa keputusan baru.
```

## 10. Protokol PROJECT_STATE.md / STATUS.md / LOG_SESI

| Berkas | Isi | Kapan diperbarui |
|---|---|---|
| `PROJECT_STATE.md` | `STATUS:` (posisi/tahap berikutnya) · `DETAIL:` (ringkas: apa yang dikerjakan/diputuskan, menunggu apa) · `UPDATE TERAKHIR:` | langkah **terakhir** setiap sesi/checkpoint |
| `STATUS.md` | field deterministik: tepat 1 baris `**Pekerjaan belum tersimpan:** Tidak ada` + `**Waktu pembaruan:** YYYY-MM-DD — peristiwa` | setiap checkpoint & akhir sesi (validator fail-closed) |
| `_log-sesi/LOG_SESI_YYYY-MM-DD.md` | header `Keadaan Sesi` (Keadaan OPEN/CLOSED · Scope · posisi · sudah disepakati · masih terbuka · langkah berikutnya) + **Kronologi append** (keputusan/koreksi/kendala/kalimat penting pemilik, mendekati kata asli) | setiap pertukaran yang menghasilkan informasi baru |

Aturan: `STATUS` di `PROJECT_STATE.md` = **tahap berikutnya yang siap dikerjakan** (bukan yang baru selesai).
Bila sesi berlanjut di hari sama → `LOG_SESI_2026-09-16_2.md`. Penutupan log: `OPEN` → `CLOSED` (+ entri terakhir).

## 11. Kapan dokumen fondasi boleh berubah

- **Perubahan kecil-teknis** (nama kolom, urutan langkah internal, penamaan berkas): boleh, tetapi **dicatat**
  (tabel Log Keputusan di bawah + dilaporkan ke pemilik).
- **Perubahan yang menyentuh janji ke pemilik** (fitur, tampilan, biaya, waktu, aturan bisnis): **STOP** →
  tulis usulan 2–3 pilihan + untung/rugi + rekomendasi → tunggu keputusan pemilik → **baru** ubah dokumen + catat tanggal & alasan.
- Dokumen yang sudah dikunci **tidak dihapus/ditimpa tanpa jejak** — riwayat selalu ditulis.
- **Aturan pemilik 2026-09-17 (berlaku mutlak):** agent **dilarang menyimpang** dari deskripsi/rancangan yang pemilik tulis tanpa bertanya lebih dulu. Urutannya: **tanya → jelaskan dengan bahasa sederhana (tanpa istilah teknis) + alasan + pilihan → kerjakan setelah diputuskan → catat di `DECISIONS_LOG.md` & laporkan**. Berlaku walau niat penyimpangan itu memperbaiki; yang "sekadar teknis" pun dijelaskan dulu, bukan diputuskan sendiri.
- Khusus `docs/TECH_SPEC.md`: apa pun yang menyentuh **ART-1…ART-15** wajib lewat `DECISIONS_LOG.md` + persetujuan pemilik.
- **Dokumen mengikat yang ditambahkan 2026-09-17** (disetujui pemilik): `docs/KEAMANAN.md` (aturan keamanan akun/perangkat/sesi/uang/audit/privasi — mengalahkan ringkasan di TECH_SPEC §8 bila berbeda) dan `docs/SPESIFIKASI_UI.md` (kelengkapan layar/tombol — mengikat semua tugas UI). Perubahannya mengikuti aturan yang sama: menyentuh janji ke pemilik → usul dulu; teknis → catat di Log Keputusan dokumen itu + DECISIONS_LOG.md.

## 12. Stop Conditions (wajib berhenti & bertanya)

1. Menyentuh **uang/kas**, **keamanan/izin/peran**, atau **data pelanggan** dan ada bagian yang belum jelas.
2. Muncul **biaya** — sekecil apa pun (batas gratis terlampaui, alat berbayar, domain, dsb).
3. Permintaan baru **bertentangan** dengan keputusan yang sudah dikunci.
4. Ada **dua dokumen saling bertentangan** (PRD vs TECH_SPEC vs ROADMAP).
5. Task `ROADMAP.md` **kurang jelas/kurang DoD** → perbaiki ROADMAP dulu (dicatat), jangan menebak.
6. Mau **mengubah keputusan** yang sudah tercatat di `DECISIONS_LOG.md`.
7. Butuh sesuatu yang hanya pemilik bisa beri (keputusan bisnis, data lapangan, akun/kunci layanan).
8. Menemukan **cacat pada pekerjaan yang sudah diklaim selesai** → laporkan, jangan sembunyikan.
9. **Merasa perlu menyimpang** dari deskripsi/rancangan pemilik (walau kecil atau niatnya memperbaiki) → berhenti, tanya dulu, jelaskan bahasa sederhana, catat setelah diputuskan (aturan pemilik 2026-09-17).
10. **Ada temuan audit K-1/K-2 terbuka** → hentikan pekerjaan baru, perbaiki/verifikasi lebih dulu (kecuali pemilik memutuskan lain).
11. **Pemilik meminta audit independen** → hentikan pekerjaan lain yang menyentuh lingkup audit; siapkan paket audit di batch itu juga, dan lanjutkan hanya setelah laporan masuk & ditindaklanjuti.
12. **Diminta merge / akan meminta merge tanpa review PR** → siapkan paket review PR dulu; jangan meminta Lee menekan merge sebelum syarat §5 butir 4g lengkap.
13. **Peninjau (audit/review) gagal kalibrasi** → verdict BERSIH tidak boleh dipakai; hentikan klaim kebersihan, siapkan ulang (idealnya model lain).

Bentuk pertanyaan yang benar: bahasa sederhana + 2–3 pilihan + rekomendasi + dampak tiap pilihan.

## 13. Mode Maraton (kerja terus-menerus) & Daftar Tunggu

**Atas permintaan pemilik 2026-09-16:** agent bekerja **terus-menerus** dan **hanya berhenti kalau benar-benar butuh
keputusan pemilik**. Pertanyaan yang bisa ditunda → **ditunda, dicatat di `docs/TERTANGGUH.md`, lalu pekerjaan jalan terus.**

**Batas jujur platform:** agent bekerja per sesi/percakapan — tidak ada proses latar yang jalan tanpa sesi.
"Maraton" berarti: satu perintah **"lanjut"** dari pemilik = agent mengerjakan **satu batch besar** (sebanyak mungkin tugas
yang aman) tanpa pertanyaan; pemilik hanya perlu mengetik "lanjut" lagi untuk batch berikutnya.

**Aturan Mode Maraton:**

1. **Hanya §12 (Stop Conditions) yang menghentikan kerja.** Selain itu: **catat → tunda → lanjut**.
2. Kerjakan tugas `ROADMAP.md` berikutnya yang **tidak** tertangguh (lihat aturan 8), dalam **batch**;
   setiap batch diakhiri **commit + push + update penanda** (`ROADMAP`/`PROJECT_STATE`/`STATUS`/`LOG_SESI`) + **laporan 5 baris**.
3. **`docs/TERTANGGUH.md` = buku tunggu wajib.** Dibacakan otomatis oleh `alat/mulai-sesi.py` di KARTU SESI,
   dan agent **wajib melaporkan** ("Tertangguh dibaca: N butir terbuka"). Bila butirnya tidak disebut → sesi tidak sah.
4. Format butir: ID · tanggal · hal · kenapa boleh ditunda · nilai sementara · **tenggat (fase/task)** · penanggung jawab · status.
5. **Dilarang menutup butir tertangguh tanpa jawaban pemilik**, kecuali bisa dibuktikan dari dokumen yang sudah dikunci
   (tulis alasannya + tandai siapa yang memutuskan).
6. **Batas penumpukan: 12 butir terbuka.** Lewat itu → **wajib berhenti** dan minta pemilik memutuskan (ringkas: 3 pilihan + rekomendasi).
7. **Tenggat mengikat:** butir yang tenggatnya sudah lewat = **hard stop** untuk fase itu (jangan dikerjakan setengah).
8. Tugas ROADMAP yang menunggu butir tertangguh ditandai **`❓ T-xxx`** dan **dilewati**; agent melanjutkan tugas lain yang tidak tertangguh.
9. Setiap akhir batch: agent **menawarkan jawaban** untuk seluruh butir terbuka → pemilik cukup bilang **"setuju semua"**.
10. **Galat alat sesaat bukan alasan berhenti.** Salah jalan/`cwd`/alat gagal sesaat → **perbaiki, ulangi, lanjut** dalam sesi yang sama;
    berhenti hanya bila butuh keputusan pemilik atau §12 memerintahkan. Pemilik tidak boleh sampai mengetik *"Kenapa kamu berhenti?"*
    untuk hal seperti ini (kejadian nyata 2026-09-17, pesan ke-29) — kalau memang terpaksa berhenti, tulis **sebabnya + satu langkah berikutnya**.
11. **Yang tidak pernah ditunda:** keamanan/uang/data pelanggan yang belum jelas · biaya apa pun · perubahan keputusan
    yang sudah dikunci · tindakan merusak/tak bisa dibatalkan (hapus data, force push, deploy publik).

---

## 14. Mode Bimbingan (dipandu langkah demi langkah) — permintaan Lee 2026-09-19

**Atas permintaan Lee:** ia sering harus memegang layar (Supabase, Cloudflare, GitHub, HP) dan panjangnya balasan agent
membuatnya tersesat. Karena itu ada **mode bicara** khusus: `Tolong bimbing.` · `Mode bimbingan.` ·
`Beri arahan step by step.` · `Aku bingung, pandu aku.` — semuanya masuk alur **AL-14** di `PANDUAN_PENGGUNA.md`.

**Aturan mode bimbingan:**

1. **Satu tindakan sekali.** Setiap balasan = langkah bernomor, masing-masing satu klik/ketikan, dan **diakhiri satu
   langkah berikutnya yang jelas** ("sekarang: buka … lalu klik …").
2. **Tanpa istilah.** Kalau sebuah istilah memang ada di layar Lee (mis. *Continue to summary*), sebut **persis** seperti
   di layar; istilah teknis lain dijelaskan maksimal dalam 5 kata atau diganti kata sehari-hari.
3. **Tidak menumpahkan pekerjaan dalam.** Pemeriksaan, catatan, dan pemeriksa tetap jalan di belakang; hasilnya **tidak**
   dibacakan saat mode bimbingan — cukup "sudah selesai, ini hasilnya singkat".
4. **Kalau langkahnya gagal:** tanya **apa yang Lee lihat di layar** (atau minta tangkapan layar), lalu perbaiki arahannya;
   jangan menyalahkan Lee dan jangan menyuruh menebak.
5. **Batas mutu TIDAK berkurang.** Mode bimbingan hanya memendekkan cara bicara. Bagian yang menyentuh **§12 (Stop
   Conditions)** — biaya, keamanan/uang/data, keputusan yang sudah dikunci, tindakan tak bisa dibatalkan (mis. deploy
   publik) — atau klaim **"selesai"** tetap butuh bukti diperiksa lebih dulu; di bagian itu agent **keluar dari mode
   singkat selama bagian itu saja** dan menjelaskannya singkat.
6. **Penutupnya jelas:** `Sudah beres, lanjut normal.` (atau tugas bimbingannya rampung). Agent menandai awal & akhir mode
   ini di `_log-sesi/` supaya sesi berikutnya tahu dan bisa memakai gaya yang sama bila Lee memintanya lagi.
7. **Pemeriksaan rutin boleh ditunda — bukti tidak.** Supaya balasan bimbingan benar-benar cepat: pemeriksaan yang **tidak ada hubungannya** dengan hal yang sedang dibimbing dan **tidak ada yang berubah** sejak terakhir hijau boleh ditunda dulu (jalankan di akhir batch). Yang **tidak boleh** ditunda dengan alasan apa pun: (a) ada perubahan baru yang menyentuh uang/keamanan/data/bukti, (b) sesaat sebelum agent menulis **"selesai"**, (c) menyangkut Stop Conditions §12 (biaya · keamanan/uang/data pelanggan · keputusan terkunci · tindakan tak bisa dibatalkan seperti deploy publik). Alasannya: menunda pemeriksaan itu **menghutang**, bukan menghapus — dan utang yang tak pernah dibayar akan muncul sebagai cacat (kelas F-11/F-12).
8. **Dokumen yang menang:** kalau panduan langkah di `docs/ops/` (mis. `LANGKAH_PEMILIK_SEKARANG.md`) berbeda dari layar
   Lee, **layar Lee yang benar** — perbaiki dokumennya, jangan paksa Lee mengikuti panduan lama.

---

## Log Keputusan (riwayat dokumen ini)

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 | `AGENT_OPERATING_GUIDE.md` ditulis & berlaku (Tahap 4) | Pemilik: *"Cukup, lanjut."* atas 10 topik aturan kerja |
| 2026-09-16 | §2 **Pemasangan Skill Otomatis** ditambahkan + `alat/mulai-sesi.py` dibuat | Permintaan pemilik: sesi baru otomatis tahu semua konteks & memasang seluruh skill (model tiap sesi bisa berbeda) |
| 2026-09-16 | §0 **Fakta platform lmarena** ditulis eksplisit (model berbeda, branch otomatis, base branch di awal, akses hilang setelah merge/close) | Penegasan pemilik 2026-09-16; memengaruhi aturan commit/push & penutupan sesi |
| 2026-09-16 | Penamaan folder alat disamakan → `alat/` (draf `docs/TECH_SPEC.md` §3 sebelumnya menulis `/tools`) | Menghindari dua nama untuk hal yang sama saat coding dimulai (perubahan kecil-teknis, dicatat) |
| 2026-09-16 | §0 ditambah **Gerbang pindah sesi**: pekerjaan hanya terlihat sesi berikutnya bila sudah di-merge ke `main` | Temuan nyata: `main` masih di commit lama sementara seluruh pekerjaan ada di branch sesi — tanpa merge, sesi baru akan "buta" |
| 2026-09-16 | §13 **Mode Maraton & Daftar Tunggu** + berkas baru `docs/TERTANGGUH.md` + `alat/mulai-sesi.py` membacakannya | Permintaan pemilik: agent lanjut bekerja tanpa berhenti; yang bisa ditunda ditangguhkan, tetapi **wajib tercatat & wajib terbaca tiap sesi** |
| 2026-09-16 | §0 ditambah **Kalau ruang kerja dinyalakan ulang** + alat baru `alat/pulihkan-git.sh` & `aplikasi/alat/pratinjau.sh`, dan satu butir pemulihan di prompt pembuka universal | Kejadian nyata: setelah restart, `node_modules` hilang (pratinjau mati dengan `vite: not found`) dan salinan Git lokal mundur ke `main`. Tanpa prosedur tertulis, sesi berikutnya (model berbeda) bisa menebak-nebak atau — lebih buruk — menulis ulang berkas dari ingatan |
| 2026-09-17 | §5 ditambah **uji komponen per layar**, **uji keamanan akun/perangkat**, dan **uji pemanggilan RPC langsung**; §7 ditambah **DoD v2 untuk tugas UI**; §11 menyebut dokumen mengikat baru (`docs/KEAMANAN.md`, `docs/SPESIFIKASI_UI.md`) & ART-1…ART-15 | Permintaan pemilik (pesan ke-14): pengalaman proyek sebelumnya banyak tombol kurang & fungsi "katanya ada"; plus keamanan akun/perangkat harus matang sebelum lanjut. Rincian: `docs/SPESIFIKASI_UI.md` + `docs/KEAMANAN.md` |
| 2026-09-17 | §11 & §12: **penyimpangan teknis wajib ditanyakan lebih dulu** + dijelaskan bahasa sederhana + dicatat | Jawaban pemilik 2026-09-17: *"Harus tanyakan dulu ke aku… jelasin alasannya dengan bahasa yang mudah aku pahami… harus tercatat"* |
| 2026-09-17 | §5 butir **4g review PR independen** + §7 DoD + §12 Stop Conditions 12–13 | Permintaan Lee: ia tidak bisa menilai *Files changed*; mekanisme review PR independen dipasang (`docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`, `alat/review-pr.py`) |
| 2026-09-17 | §5 butir **4f buku pedoman induk wajib ikut diperbarui** + §7 DoD menambahkan bukti `alat/periksa-panduan.py` | Permintaan pemilik 2026-09-17: buku pedoman pengguna harus jadi induk yang lengkap & tidak boleh basi (mekanisme yang tidak bisa dipakai pemilik = mekanisme yang tidak ada) |
| 2026-09-17 | §5 butir 4e **Audit independen AUD-0…AUD-3** + §7 DoD menyebut AUD-2 + §12 dua Stop Condition (temuan K-1/K-2 terbuka · permintaan audit pemilik) | Permintaan pemilik 2026-09-17: mekanisme audit/pemeriksaan/review independen yang teliti & terukur, memakai skill + riset, dan bisa ia picu sendiri (`docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`) |
| 2026-09-17 | §13 aturan 10: **galat alat sesaat bukan alasan berhenti** (perbaiki → ulangi → lanjut; kalau terpaksa berhenti, tulis sebab + langkah berikutnya) | Permintaan Lee 2026-09-17 (pesan ke-29): *"Kenapa kamu berhenti? Lanjutkan"* — penyebabnya galat alat sesaat (salah `cwd`), bukan masalah proyek |
| 2026-09-19 | §14 **Mode Bimbingan** (alur **AL-14**) + kalimat pemicu & penutupnya di `PANDUAN_PENGGUNA.md` | Permintaan Lee 2026-09-19: sedang memegang layar Cloudflare, balasan agent yang panjang membuatnya tersesat — "klo lagi pembimbingan usahakan respon nya mode respon cepat"; dijawab agent: cepat untuk **bimbingan**, tetap teliti untuk **bukti** |
