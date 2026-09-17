# PROTOKOL_AUDIT_INDEPENDEN.md — Mekanisme Audit, Pemeriksaan & Review Independen

> **Status: BERLAKU sejak 2026-09-17** (permintaan pemilik: *"mekanisme audit, pemeriksaan, analisis dan review
> independen yang sangat teliti dan sangat cerdas… pastikan agent independen betul-betul jeli dan betul-betul
> menemukan masalah… Kalau ada skill yang bisa mendukung, pakai. Kalau perlu riset internet, lakukan."*)
>
> **Prinsip inti:** pembuat **tidak boleh** menjadi pemeriksa pekerjaannya sendiri. Model AI cenderung meloloskan
> karyanya sendiri walau diminta keras (riset 2026: bias "self-preference" bertahan walau diperintah kritis),
> sedangkan pemeriksa dari **sesi & model berbeda** menemukan cacat yang tak pernah terlihat pembuatnya.
> Karena itu audit **wajib** dijalankan di **sesi terpisah**, **model berbeda**, **hanya-baca**, dengan **paket** dan
> **format laporan yang divalidasi mesin**.

---

## 1. Kenapa mekanisme ini dibuat (masalah yang ditutup)

| Masalah nyata | Bukti dari riwayat proyek ini | Penutup dalam protokol ini |
|---|---|---|
| Pembuat menilai pekerjaannya sendiri | Sesi yang menulis RLS juga yang menguji RLS | §3 (sesi & model terpisah) + §5 (paket audit) |
| "Selesai" tanpa bukti | Dulu ada klaim jumlah tabel/tugas yang salah | §6 (kontrak bukti: setiap klaim wajib perintah + hasil) |
| Uji yang lulus karena **sebab yang salah** | T1-10: dua uji ditolak aturan lain, bukan aturan yang diuji | Lensa L4 + §7 (cacat tanaman kalibrasi) |
| "Teliti" tidak terukur | Tanpa ukuran, "BERSIH" hanya keyakinan | §7 (kalibrasi cacat tanaman: deteksi diukur) |
| Temuan tanpa bukti (kebisingan) | — | §6 (temuan wajib punya perintah/baris + skenario gagal) |
| Auditor ikut "memperbaiki" lalu kehilangan independensi | — | §3 larangan mengubah berkas + §6 butir 7 |
| Racun dokumen teater | — | §8 (pemeriksa laporan menolak laporan malas) |

---

## 2. Empat tingkat audit

| Tingkat | Kapan | Siapa | Keluaran wajib | Lama |
|---|---|---|---|---|
| **AUD-0 — Audit dampak** | Setiap kali sebuah **keputusan berubah** dan bisa membatalkan pekerjaan lama (mis. keamanan akun diperdalam) | Agent pembangun (boleh sesi yang sama) | `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` — daftar artefak yang bertentangan + tugas ulang | ≤ 1 jam |
| **AUD-1 — Periksa batch** | Setiap batch pekerjaan, sebelum laporan ke pemilik | Mesin (pemeriksa Python, uji SQL, vitest, CI) + agent | CI hijau + uji mutasi membuktikan gerbang bisa MERAH | otomatis |
| **AUD-2 — Review independen** | Akhir setiap **fase**, atau setiap perubahan yang menyentuh **uang/keamanan/data pelanggan** | **Sesi baru, model berbeda, hanya-baca** | Laporan dengan format §6, lolos `alat/audit-independen.py --periksa-laporan` | 1 sesi |
| **AUD-3 — Audit adversarial menyeluruh** | Sebelum pilot/produksi, sebelum Fase 11 ditutup, dan **kapan pun pemilik meminta** | **Sesi baru, model berbeda**, semua lensa + **kalibrasi cacat tanaman** | Laporan AUD-3 + hasil kalibrasi + verdict | 1–2 sesi |

**Aturan gerbang:** fase **tidak boleh** ditutup, dan pekerjaan bergelombang **tidak boleh** lanjut, selama masih ada temuan **K-1 (Kritis)** atau **K-2 (Tinggi)** berstatus TERVERIFIKASI. Temuan K-3/K-4 masuk daftar perbaikan fase (boleh ditunda dengan catatan).

---

## 3. Aturan independensi (wajib, tidak bisa ditawar)

1. **Sesi terpisah.** Auditor bekerja di **sesi/percakapan baru** — bukan sesi yang menulis kode itu.
2. **Model berbeda bila tersedia.** Bila platform memungkinkan memilih model lain (atau sub-agent dengan instruksi & konteks berbeda), gunakan. Bila tidak, wajib dicatat di laporan sebagai **keterbatasan** (jangan diklaim lebih kuat dari kenyataan).
3. **Hanya-baca.** Auditor **dilarang** mengubah, memperbaiki, atau menerapkan perbaikan apa pun — temuan ditulis, bukan dibetulkan. Perbaikan dilakukan pembangun **setelah** laporan selesai.
4. **Buta pada pembenaran.** Auditor menerima **paket audit** (§5) berisi klaim pembangun, tetapi tugasnya **membantah** klaim itu, bukan membaca lalu mempercayainya.
5. **Tidak boleh menjadi kepribadian "ramah".** Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan. Laporan yang tidak punya temuan **sah** — asalkan **angka usahanya** (jumlah artefak, serangan, klaim yang diuji) memenuhi minimum §6.
6. **Refutasi sebelum lapor.** Setiap calon temuan wajib diuji ulang di kode **sebagaimana adanya sekarang** (buka berkasnya, telusuri pemanggilnya, jalankan perintahnya). Kalau tidak bisa dibuktikan → tulis sebagai **DUGAAN**, bukan TERVERIFIKASI.

---

## 4. Lensa (Perspective-Based Reading) — dipakai sesuai tingkat

Riset *Perspective-Based Reading*: reviewer dengan **skenario tertentu** menemukan cacat jauh lebih banyak daripada reader "ad hoc"/daftar periksa biasa. Karena itu auditor **wajib** memakai lensa, dan setiap lensa punya pertanyaan pemicu.

| Lensa | Nama | Pertanyaan pemicu (wajib dijawab) |
|---|---|---|
| **L1** | Ancaman & Akses | Bisakah orang tanpa hak masuk/naik peran? Bisakah sesi/perangkat yang dicabut masih dipakai? Apakah ada fungsi istimewa (`security definer`) yang bisa dipanggil siapa saja? Apakah ada jalur yang membaca data penyewa lain? |
| **L2** | Uang & Jejak | Bisakah angka uang dibuat/ubah/hapus dari klien? Bisakah pembayaran dobel, void tanpa jejak, diskon lewat batas, kas tanpa shift? Apakah jejak audit benar-benar tak bisa diubah dan bisa mendeteksi penghapusan? |
| **L3** | Kesepakatan Dokumen | Setiap janji PRD/TECH_SPEC punya kode **dan** uji? Setiap klaim "Bukti" di ROADMAP **bisa direproduksi hari ini**? Ada syarat tanpa uji (orphan requirement) atau uji tanpa syarat (orphan test)? |
| **L4** | Mutu Uji | Ada uji yang lulus karena **sebab yang salah**? Negatif-test yang bisa ditolak banyak sebab? Uji yang tidak memeriksa apa pun? Gerbang yang belum pernah dibuktikan bisa MERAH? Ada bagian yang diuji dengan tiruan padahal bisa nyata? |
| **L5** | Lapangan & UI | Alur nyata di tablet kasir bisa selesai? Tujuh keadaan (kosong/memuat/gagal/antre/putus/tanpa-akses/berhasil) tertangani? Ada tombol yang tidak melakukan apa pun atau aksi tanpa tombol? Pesan galat bahasa manusia + kode? Target sentuh & kontras? Printer/offline? |
| **L6** | Privasi & Kepatuhan | Data pelanggan seminimal mungkin? Persetujuan sebelum simpan? Anonimisasi tanpa menghapus catatan keuangan? Jalur kebocoran 3×24 jam siap? Rahasia tidak pernah masuk repo/log? |

**Kombinasi minimum:** AUD-2 → **L1 + L3 + L4** (atau L2 menggantikan L3 bila lingkupnya uang). AUD-3 → **semua enam lensa**.

---

## 5. Paket audit (dibuat mesin, bukan diingat)

Perintah: `python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01..T1-10`
Keluaran: berkas paket di docs/uji/paket-audit/ berisi:

1. **Lingkup**: tugas/fase, commit, berkas yang diperiksa (dari atribut `File:` ROADMAP).
2. **Klaim pembangun yang harus dibantah**: seluruh teks `Bukti` pada tugas dalam lingkup + klaim jumlah/statistik.
3. **Lensa + skenario** yang wajib dijalankan (sesuai tingkat).
4. **Perintah bukti** yang disarankan (`node alat/uji-sql.mjs`, pemeriksa Python, `npm test`, dst.).
5. **Skill yang wajib dimuat** auditor (berkas nyata di repo — lihat §9).
6. **Format laporan** (salin dari §6) + aturan independensi (§3).
7. **Perintah validasi** laporannya sendiri: `python3 alat/audit-independen.py --periksa-laporan <berkas>`.

---

## 6. Kontrak laporan (divalidasi mesin — tanpa ini audit tidak diakui)

Judul & kepala laporan wajib memuat: Auditor · Tanggal · Tingkat audit · **Commit yang diaudit (SHA penuh)** ·
Paket audit · Verdict (`BERSIH` / `BERSIH-DENGAN-CATATAN` / `TIDAK-BERSIH`).

Tujuh bagian wajib, dengan nama **persis**:

1. `## 1. Cakupan` — tabel: artefak · diperiksa? · **bukti** (perintah/baris). Minimum 6 baris.
2. `## 2. Klaim pembangun yang saya coba falsifikasi` — tabel: klaim · cara uji · hasil. Minimum 5 baris.
3. `## 3. Serangan yang dijalankan (kill attempts)` — tabel skenario · cara · hasil. Minimum 5 (AUD-2) / 12 (AUD-3).
4. `## 4. Temuan` — tiap temuan berkepala `### [F-xx] Judul` dengan **delapan bidang**:
   `Tingkat` (K-1…K-4) · `Artefak` (berkas:baris) · `Klaim yang dilanggar` · `Bukti` (perintah → hasil nyata) ·
   `Skenario gagal` · `Dugaan penyebab` · `Cara membuktikan perbaikan` (perintah yang harus hijau) ·
   `Status verifikasi` (`TERVERIFIKASI` / `DUGAAN`). Bila tidak ada temuan → tulis `(tidak ada temuan)`.
5. `## 5. Kalibrasi cacat tanaman` — **wajib untuk AUD-3**: `Ditemukan: X dari Y`, daftar cacat yang ditemukan, dan jumlah temuan palsu.
6. `## 6. Yang tidak bisa saya verifikasi` — minimum 1 butir (jujur soal batas: tanpa akun Supabase, tanpa peramban, dsb.).
7. `## 7. Pernyataan tidak mengubah apa pun` — kalimat berisi "tidak mengubah" + bukti `git status --short` kosong.

**Aturan konsistensi yang ditegakkan mesin:**
- Ada temuan **K-1/K-2** berstatus TERVERIFIKASI → verdict **wajib** `TIDAK-BERSIH` (laporan "BERSIH" ditolak mesin).
- Verdict `BERSIH` pada AUD-3 hanya sah bila **semua cacat tanaman K-1/K-2 ditemukan** dan **≥70%** total ditemukan.
- Setiap temuan TERVERIFIKASI wajib punya perintah bukti; temuan K-1/K-2 wajib punya `Skenario gagal`.

---

## 7. Kalibrasi cacat tanaman (jantung kejujuran mekanisme ini)

Riset *defect injection*: kemampuan pemeriksa **diukur** dengan menyuntikkan cacat yang jawabannya sudah diketahui. Tanpa ini, "BERSIH" hanya keyakinan.

**Cara kerja (dijalankan pembangun, dinilai setelah audit):**

1. Pembangun menjalankan: `python3 alat/audit-independen.py --kalibrasi-siapkan`
   → menyalin HEAD ke `worktree` bersih, **menanam 6 cacat** dari katalog `alat/kalibrasi-cacat.json`
   (campuran K-1…K-4; ada yang seharusnya ketangkap mesin, ada yang hanya ketangkap penalaran),
   → menulis **kunci jawaban di luar repo** (`/tmp/...-kunci.md`, tidak boleh dibaca auditor).
2. Auditor memeriksa salinan itu **seperti kode sungguhan** (tanpa tahu kuncinya).
3. Setelah laporan masuk: `python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci>`
   → menghitung **tingkat deteksi** (per tingkat bahaya), **temuan palsu**, dan memutuskan
   `TERKALIBRASI` / `BELUM TERKALIBRASI`.
4. Hasil kalibrasi **dicatat permanen** di `docs/uji/AUDIT_RIWAYAT.md` (tren deteksi lintas audit).
5. Katalog cacat **tumbuh**: setiap cacat nyata baru yang lolos ke repo wajib ditambahkan sebagai butir kalibrasi baru (praktik *"defects → inspection scenarios"*).

---

## 8. Pemeriksa laporan (anti-teater)

`python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/LAPORAN_*.md` menolak laporan yang:
tidak punya bagian wajib · tidak punya SHA · bukti kosong · terlalu sedikit artefak/serangan/klaim · temuan tanpa
perintah bukti · verdict tidak konsisten dengan temuan · AUD-3 tanpa kalibrasi. Pemeriksa ini **sendiri diuji**
(`--uji-diri`) dengan laporan contoh bagus & tiga laporan sengaja buruk — kalau pemeriksa tidak bisa MERAH,
mekanismenya dianggap belum terpasang.

---

## 9. Skill & riset yang wajib dipakai auditor

Dimuat dari repo (berkas nyata, bukan ingatan):

| Skill | Berkas | Untuk lensa |
|---|---|---|
| Security review | `skills/security-review/SKILL.md` | L1, L6 |
| Systematic debugging | `skills/systematic-debugging/SKILL.md` | L4, akar masalah temuan |
| Verification before completion | `skills/verification-before-completion/SKILL.md` | §6 semua klaim bukti |
| Verification loop | `skills/verification-loop/SKILL.md` | urutan periksa (bangun → tipe → uji) |
| Test-driven development | `skills/test-driven-development/SKILL.md` | L4 |
| PRD/taskmaster | `skills/prd-taskmaster/SKILL.md` | L3 jejak syarat → tugas → uji |
| Supabase + Postgres best practices | `skills/supabase/SKILL.md`, `skills/supabase-postgres-best-practices/SKILL.md` | L1, L2 |
| UI/UX | `skills/ui-ux-pro-max/SKILL.md` | L5 |

Auditor **wajib**: (a) memuat skill di atas yang relevan dengan lensanya; (b) memakai `skills/find-skills` atau
`skills/agent-skills-hub` bila butuh skill tambahan; (c) **boleh & dianjurkan** mencari referensi internet
(dokumentasi resmi Supabase/PostgreSQL/OWASP, riset cacat perangkat lunak) dan **wajib mencantumkan tautannya**
di laporan untuk klaim yang bersandar pada perilaku sistem luar.

---

## 10. Alur lengkap (dari pemicu sampai tuntas)

```
PEMILIK/AGENT memutuskan audit (lihat §11)
   ↓
Agent pembangun: siapkan paket (--paket)  [AUD-3: + --kalibrasi-siapkan]
   ↓
PEMILIK membuka SESI BARU (model berbeda) & menempelkan PROMPT_AUDIT_INDEPENDEN (§12)
   ↓
Auditor: jalankan lensa → kumpulkan temuan → refutasi → tulis laporan (§6)   [hanya-baca]
   ↓
Mesin: --periksa-laporan (tolak bila malas/tidak konsisten)  [+ --kalibrasi-nilai untuk AUD-3]
   ↓
Agent pembangun: masukkan temuan ke ROADMAP sebagai tugas perbaikan (K-1/K-2 = menghentikan fase)
   ↓
Perbaikan → uji ulang → **auditor yang sama** (atau sesi independen baru) memverifikasi temuan tertutup
   ↓
Verdict & hasil kalibrasi dicatat di docs/uji/AUDIT_RIWAYAT.md; temuan K-1/K-2 wajib ditutup sebelum lanjut
```

**Batas putaran:** maksimum **2 putaran** audit-perbaikan untuk lingkup yang sama. Bila putaran ke-3 masih ada K-1/K-2,
pekerjaan **dihentikan** dan pemilik diberi penjelasan bahasa sederhana (3 pilihan + rekomendasi).

---

## 11. Kapan audit dijalankan (pemicu)

1. **Otomatis:** akhir setiap fase (AUD-2) · sebelum tugas bertanda uang/keamanan/data pelanggan di-`[x]` (AUD-2 pada perubahan itu) · sebelum pilot & sebelum Fase 11 ditutup (AUD-3).
2. **Saat keputusan berubah:** AUD-0 audit dampak (menghasilkan daftar pekerjaan ulang).
3. **Atas permintaan pemilik:** kalimat pemicu bebas, mis. **"Audit independen sekarang"** + lingkup (mis. "seluruh sistem", "keamanan akun", "Fase 1"). Agent **wajib**: menyiapkan paket dalam batch yang sama, menulis cara memulai sesi audit di `docs/PANDUAN_PEMILIK.md`, dan **tidak mengerjakan pekerjaan lain** sampai laporan masuk (kecuali tugas yang tidak menyentuh lingkup audit).

---

## 12. Prompt auditor (siap tempel)

Teks lengkap + cara pakai ada di `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`; versi terisi-otomatis untuk satu lingkup
tertentu ditulis di berkas paket (§5) sehingga pemilik cukup menyalin dari sana.

---

## 13. Riwayat & log keputusan dokumen ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Dokumen dibuat & BERLAKU; alat `alat/audit-independen.py` (paket · periksa laporan · kalibrasi · uji diri) + `alat/kalibrasi-cacat.json` + `docs/PANDUAN_PEMILIK.md` | Permintaan pemilik: menanam mekanisme audit/review independen yang matang, terukur, dan bisa ia picu sendiri; riset: maker–checker separation, Perspective-Based Reading, defect injection, refutation-before-report |

## 14. Risiko sisa yang diakui (jujur, bukan disembunyikan)

1. **Tidak ada jaminan 100%.** Studi inspeksi: tim PBR menemukan rata-rata ~58% cacat. Mekanisme ini **menaikkan & mengukur** deteksi, bukan menjanjikan kesempurnaan; karena itu ada lapis mesin (CI) + lapis auditor + lapis pemilik (uji terima).
2. **Auditor & pembangun bisa berbagi model yang sama.** Bila platform hanya menyediakan satu keluarga model, korelasi cacat tetap ada — dicatat di laporan sebagai keterbatasan, dan dikompensasi lensa + kalibrasi.
3. **Kunci jawaban kalibrasi ada di sistem berkas.** Auditor dilarang membacanya; pelanggaran hanya bisa dideteksi tidak langsung (temuan tanpa bukti → ditolak mesin). Ini kontrol proses, bukan kontrol teknis — dicatat terbuka.
4. **Audit tidak menggantikan uji terima manusia.** Keputusan akhir tetap di tangan pemilik.
