# Bahan Diskusi Tahap 4 — Aturan Kerja Agent (AGENT_OPERATING_GUIDE)

> **Status: BAHAN DISKUSI — belum final.** Sesuai `AGENT_SYSTEM.md` Tahap 4, dokumen final
> (`docs/AGENT_OPERATING_GUIDE.md`) baru ditulis setelah pemilik bilang **"cukup, tulis drafnya"**.
>
> Ditulis: 2026-09-16 · Rujukan: `docs/TECH_SPEC.md` (dikunci), `docs/PRD.md` (dikunci), `_sistem/templates/AGENT_OPERATING_GUIDE.md`

---

## 0. Ringkasan bahasa manusia (baca ini saja kalau singkat)

Tahap 4 bukan tentang fitur, tapi tentang **aturan main agent** yang akan menulis kodenya nanti —
supaya hasilnya tetap rapi, aman, dan tidak "beda orang beda gaya" di sesi yang berbeda.

Cara berpikirnya seperti mempekerjakan tukang bangunan: kita perlu kesepakatan tertulis soal
**bahan yang dipakai** (gaya kode), **kapan dia boleh memutuskan sendiri**, **kapan dia wajib bertanya ke kamu**,
**cara dia memastikan pekerjaannya benar** (uji), dan **cara dia melaporkan pekerjaan** supaya tidak hilang saat ganti sesi.

Semua aturan ini gunanya satu: melindungi kamu — supaya **uang, data pelanggan, dan keputusanmu tidak berubah diam-diam**
dan supaya kalau ada masalah, ada jejak yang bisa dibaca.

**Ringkas 10 topik + usul agent:**

| # | Topik | Usul agent (ringkas) |
|---|---|---|
| 1 | Komunikasi ke kamu | Bahasa Indonesia sehari-hari, tanpa istilah teknis, tiap laporan ada "apa yang berubah + apa artinya untukmu" |
| 2 | Gaya menulis kode | Bahasa Indonesia untuk nama tabel & fitur; TypeScript mode ketat; aturan otomatis (ESLint + Prettier) wajib sebelum commit; warna/ukuran wajib pakai token desain v3 (tidak boleh karang sendiri) |
| 3 | Catatan pekerjaan (commit & branch) | Kerja hanya di branch sesi `arena/...`; jangan menyentuh `main`; commit kecil + pesan bahasa Indonesia rinci; push tiap selesai satu langkah |
| 4 | Uji sebagai pengaman | 4 lapis: uji database (isolasi data & uang), uji unit hitungan uang, uji tampilan statis, uji alur (Playwright) + "daftar uji terima" bahasa manusia untukmu |
| 5 | Kalau ada error | Pesan ke pengguna selalu bahasa Indonesia + langkah berikutnya + kode pendek; kejadian penting dicatat di tabel `catatan_kesalahan`; **tidak pernah** menulis sandi/PIN ke catatan |
| 6 | Arti "selesai" | 7 syarat tercentang (kode, uji, catatan, keputusan berisiko, commit, dokumen, laporan ke kamu) — tidak boleh diklaim selesai kalau ada yang kurang |
| 7 | Kerja lintas sesi (anti-lupa) | Setiap sesi mulai dari membaca posisi (PROJECT_STATE + STATUS + LOG_SESI), dan menutup dengan memperbarui ketiganya + commit — supaya sesi berikutnya tidak menebak |
| 8 | Buku keputusan berisiko (`DECISIONS_LOG.md`) | Mulai kosong; **wajib dibaca** sebelum menyentuh Area Berisiko Tinggi (mis. uang, izin, voucher); **wajib STOP & tanya** kalau mau mengubah keputusan yang sudah tercatat |
| 9 | Kalau rencana perlu berubah | Perubahan kecil-teknis boleh (dicatat); perubahan yang menyentuh janji ke kamu (fitur/biaya/waktu) **wajib tanya dulu**, baru dokumen diubah + dicatat |
| 10 | Kapan wajib berhenti & tanya | Menyentuh uang/keamanan/data pelanggan, ada biaya sekecil apa pun, dokumen saling bertentangan, tugas kurang jelas, atau ada keputusan fondasi yang mau diubah |

Kalau setuju semua, jawab saja **"cukup"** atau **"lanjut"** → agent menulis `docs/AGENT_OPERATING_GUIDE.md` yang rapi.
Kalau ada yang mau diubah, sebut nomornya (contoh: "nomor 3 jangan push tiap langkah").

---

## 1. Profil user & cara komunikasi

- Pemilik **tidak menulis kode** dan tidak memakai istilah teknis → semua laporan agent memakai bahasa sehari-hari,
  langkah bernomor, dan analogi bila perlu. Istilah teknis hanya boleh muncul di dalam dokumen teknis, dan selalu diberi arti singkat.
- Setiap laporan menjawab 4 hal: **apa yang dikerjakan · apa hasilnya (nyata, bisa dilihat) · apa artinya untukmu · apa yang dibutuhkan darimu**.
- Berita buruk tidak disembunyikan (uji gagal, batas gratis, temuan risiko) — disampaikan lebih dulu, dengan usul perbaikan.
- Kalau agent salah: akui, perbaiki, catat penyebabnya supaya tidak berulang.

## 2. Konvensi kode (gaya menulis kode)

- **Bahasa:** nama tabel, kolom, fitur, berkas layar, dan komponen memakai Bahasa Indonesia
  (`pesanan`, `catatan_audit`, `LayarKasir`). Nama bawaan alat (mis. `useState`, `map`) tetap seperti aslinya.
- **Ketat & aman:** TypeScript mode `strict`, dilarang `any` tanpa alasan tertulis, nilai kosong wajib ditangani.
  Semua operasi uang memakai **bilangan bulat rupiah** (tidak pernah pecahan/koma).
- **Aturan otomatis wajib sebelum commit:** ESLint + Prettier lulus (agent yang menjalankan, bukan pilihan).
- **Tampilan:** wajib memakai token desain v3 (`warna`, `jarak`, `huruf`, `bayangan`, `glow`, `kaca`).
  Dilarang menulis warna/ukuran mentah di luar token; tema baru = menambah token, bukan menempel `style` langsung.
- **Bentuk kode:** satu komponen satu berkas, fungsi pendek (±50 baris), nama jelas, komentar wajib untuk
  bagian rumit (hitungan uang, izin, voucher, cetak). Tidak ada kode mati/commented-out yang ditinggal.
- **Aliran data:** satu arah; klien **tidak pernah** menghitung uang sendiri — semua angka resmi dari peladen.
- **Folder:** mengikuti `TECH_SPEC.md §3` (aplikasi di `/aplikasi`, database di `/supabase`, alat di `/tools`).

## 3. Struktur commit & branch

- Kerja **hanya** di branch sesi `arena/...` (dibuat platform, tidak bisa diganti) → **tidak pernah** push ke `main`;
  PR dibuka **tanpa auto-merge** supaya pemilik selalu punya gerbang.
- Satu langkah kerja = satu commit; pesan commit Bahasa Indonesia yang **rinci** (apa + kenapa), karena
  deskripsi panjang tidak selalu bisa disimpan platform.
- **Push setiap langkah selesai** (bukan menumpuk di akhir) — supaya tidak ada pekerjaan yang hilang kalau sesi terputus.
- Commit wajib **bersih**: tidak menyertakan berkas rahasia (`.env`), berkas besar tak perlu, atau hasil percobaan.

## 4. Uji sebagai jaring pengaman (pengganti "review manusia")

1. **Uji database** — setiap migrasi wajib punya uji: isolasi data antar-resto & antar-cabang, ketepatan uang,
   voucher hanya sekali pakai, `catatan_audit` tidak bisa diubah/dihapus.
2. **Uji unit** — fungsi hitungan uang & format wajib 100% lulus (Vitest); angkanya diuji dengan kasus nyata
   (pajak, service, diskon, pembulatan, void).
3. **Uji tampilan statis** — memakai alat yang sudah ada (`uji-kontras.py`, `alat/periksa-halaman.py`), diperluas ke aplikasi.
4. **Uji alur (Playwright)** — 7 alur wajib: buka shift → pesan → kirim dapur → bayar → cetak → void berjenjang → tutup kas (+ voucher & katalog publik).
5. **Daftar uji terima bahasa manusia** untuk pemilik di akhir tiap gelombang (contoh: "Coba bayar tanpa memilih meja → harus muncul pesan jelas").
6. Aturan: **tidak ada naik gelombang sebelum semua uji hijau**; cacat yang ketemu → dicatat, diperbaiki, diuji ulang, dilaporkan.

## 5. Format pesan error & pencatatan masalah

- Pesan ke pengguna selalu: **(a) apa masalahnya dalam bahasa manusia · (b) apa yang bisa dilakukan sekarang · (c) kode pendek**.
  Contoh: *"Maaf, pesanan belum tersimpan karena koneksi terputus. Pesanan ada di antrean dan akan terkirim sendiri. Kode: PS-104."*
- Bentuk seragam dari peladen: `{ ok: true/false, data?, kode?, pesan? }` — klien menampilkan `pesan`, tidak pernah menebak sendiri.
- Setiap kejadian penting/gagal dicatat di tabel `catatan_kesalahan` (waktu, peran, kode, konteks) **tanpa** data sensitif.
- **Dilarang** menulis sandi, PIN, token, atau data pelanggan pribadi ke catatan mana pun.
- Tiga tingkat catatan: `info` (jejak biasa), `penting` (uang/izin/voucher), `gagal` (perlu diperiksa).

## 6. Definition of Done (arti "selesai")

Satu task hanya boleh ditandai `[x]` kalau **semua** tercentang:

- [ ] Kode sesuai `TECH_SPEC.md` & panduan ini, ada komentar di bagian rumit
- [ ] Uji otomatis yang relevan ada & lulus
- [ ] `ROADMAP.md` diperbarui (`[ ]` → `[x]`)
- [ ] `DECISIONS_LOG.md` diperbarui **bila menyentuh Area Berisiko Tinggi** (wajib)
- [ ] Dokumen terkait (TECH_SPEC/PRD) diperbarui bila ada detail baru yang mengikat
- [ ] Commit + push, repo bersih
- [ ] `PROJECT_STATE.md` + `STATUS.md` + `LOG_SESI` diperbarui (langkah terakhir)
- [ ] Laporan bahasa manusia ke pemilik: apa yang berubah, apa artinya, apa berikutnya

## 7. Cara kerja agent lintas sesi (anti-hilang konteks)

1. **Awal sesi:** baca `PROFIL_PENGGUNA.md` → `PROJECT_STATE.md` → `STATUS.md` → cari `_log-sesi/LOG_SESI_*.md` terbaru
   → cek branch & PR → **laporkan posisi ke pemilik** sebelum mulai kerja.
2. **Selama sesi:** setiap keputusan/koreksi/kendala/kalimat penting pemilik → langsung ditambahkan ke `LOG_SESI`
   (mendekati kata asli) + commit & push — mencatat lebih banyak jauh lebih murah daripada kehilangan konteks.
3. **Akhir sesi/checkpoint:** audit `ROADMAP` (`[x]` sinkron?), `DECISIONS_LOG` (ada yang terlewat?), repo bersih,
   lalu tutup dengan `PROJECT_STATE` + `STATUS` + `LOG_SESI` terbaru.
4. **Jangan mengulang tahap yang sudah dikunci** tanpa alasan sah (ada instruksi baru dari pemilik, atau ada bukti cacat).

## 8. Protokol `DECISIONS_LOG.md` (buku keputusan berisiko)

- Dokumen **mulai kosong dan diisi selama coding** (dibuat resmi pada Tahap 6 dari template).
- **Wajib dibaca lebih dulu** sebelum menyentuh Area Berisiko Tinggi (`TECH_SPEC.md` ART-1…ART-10) — bukan menebak dari kode.
- Kalau pendekatan yang sudah tercatat perlu diubah → **STOP, tanya pemilik dulu** (tidak boleh diam-diam).
- Setelah keputusan baru dibuat di area berisiko → **tulis entri baru sebelum lanjut task lain**.

Format entri (contoh nyata):

```markdown
### [Fase 1/2026-10-02] Uang dihitung di peladen, bukan di klien
- **Area:** Kalkulasi Keuangan (ART-3)
- **Keputusan:** seluruh total/pajak/service/diskon/kembalian dihitung oleh fungsi SQL tunggal `hitung_total()`;
  klien hanya menampilkan angka yang dikirim peladen.
- **Alasan:** mencegah manipulasi dari sisi perangkat & mencegah dua rumus berbeda (klien vs peladen) yang bisa berselisih.
- **File terkait:** `supabase/migrations/00X_hitung_total.sql`, `src/lib/format.ts`
- **Implikasi:** setiap fitur baru yang butuh angka uang WAJIB memanggil `hitung_total()` — dilarang menyalin rumusnya.
```

## 9. Kapan dokumen fondasi (`TECH_SPEC.md` / `PRD.md`) boleh berubah

- **Perubahan kecil-teknis** (nama kolom, urutan langkah internal, penamaan berkas) boleh langsung, tetapi **dicatat** di `DECISIONS_LOG.md` + dilaporkan ke pemilik.
- **Perubahan yang menyentuh janji ke pemilik** (fitur, tampilan, biaya, waktu, aturan bisnis) → **STOP**, tulis usulan
  2–3 pilihan + untung/rugi + rekomendasi, tunggu keputusan pemilik, **baru** ubah dokumen + catat tanggal & alasan di tabel riwayat.
- Dokumen yang sudah dikunci **tidak dihapus/ditimpa tanpa jejak**; riwayat perubahan selalu ditulis.

## 10. Kapan agent wajib berhenti & bertanya (Stop Conditions)

Wajib **STOP + tanya** bila terjadi salah satu:

1. Menyentuh **uang/kas**, **keamanan/izin/peran**, atau **data pelanggan** dan ada bagian yang belum jelas.
2. Muncul **biaya** — sekecil apa pun (batas gratis terlampaui, alat berbayar, domain, dsb).
3. Permintaan baru **bertentangan** dengan aturan/keputusan yang sudah dikunci.
4. Ada **dua dokumen yang saling bertentangan** (PRD vs TECH_SPEC vs ROADMAP).
5. Task di `ROADMAP.md` **kurang jelas / kurang DoD** → perbaiki ROADMAP dulu, jangan menebak.
6. Mau **mengubah keputusan** yang sudah tercatat di `DECISIONS_LOG.md`.
7. Butuh sesuatu yang hanya pemilik bisa beri (keputusan bisnis, data lapangan, kunci/akun layanan).

Bentuk pertanyaan yang benar: bahasa sederhana + 2–3 pilihan + rekomendasi agent + dampak tiap pilihan (kapan ada, kapan tidak).

---

## Struktur dokumen final `docs/AGENT_OPERATING_GUIDE.md` (yang akan ditulis setelah "cukup")

1. Profil User (non-teknis — cara komunikasi) · 2. Coding Conventions · 3. Struktur Commit & Branch ·
4. Testing · 5. Error Handling Format · 6. Definition of Done · 7. Cara Kerja Agent Lintas Sesi ·
8. Protokol `DECISIONS_LOG.md` (+ contoh entri) · 9. Protokol `PROJECT_STATE.md`/`STATUS.md` ·
10. Stop Conditions · 11. Log Keputusan (tabel riwayat perubahan dokumen ini).

## Pertanyaan penutup

- Sudah pas, atau ada nomor yang mau diubah? (sebut nomornya saja)
- Kalau setuju: **"cukup"** / **"lanjut"** → agent menulis `docs/AGENT_OPERATING_GUIDE.md`,
  lalu lanjut ke **Tahap 5: ROADMAP** (pecahan tugas G1, tiap task wajib punya 7 atribut lengkap).
