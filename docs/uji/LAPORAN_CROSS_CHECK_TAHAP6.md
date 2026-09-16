# Laporan Pemeriksaan Silang (Tahap 6) — Resto Barokah

> Peran: **reviewer independen**. Tanggal: 2026-09-16. Bahan yang diperiksa: `docs/DISCOVERY.md`,
> `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/AGENT_OPERATING_GUIDE.md`, `docs/ROADMAP.md`,
> `docs/TERTANGGUH.md`. Alat bantu: `python3 alat/periksa-roadmap.py`, `python3 _sistem/validate_system.py`.

## Ringkasan

**4 temuan** (1 Critical, 3 Minor). **Semuanya sudah diperbaiki** pada batch ini — tidak ada temuan yang dibiarkan.

| # | Tingkat | Temuan | Perbaikan |
|---|---|---|---|
| 1 | **Critical** | **Bentuk jawaban RPC berbeda antar dokumen.** `TECH_SPEC.md` §5 (dokumen terkunci) menetapkan `{ berhasil, kode, pesan, data }`, tetapi `AGENT_OPERATING_GUIDE.md` §6 (ditulis setelahnya) memakai `{ ok, data, kode, pesan }`. Bila dibiarkan, dua agent berbeda akan membangun dua bentuk berbeda → klien & uji saling tidak cocok. | Guide **disamakan** ke `TECH_SPEC.md` §5 (dokumen terkunci = sumber kebenaran). Dicatat di `DECISIONS_LOG.md`. |
| 2 | Minor | **Nama RPC resmi di `TECH_SPEC.md` §5 tidak muncul di `ROADMAP.md`.** Fungsinya ada dalam bentuk deskripsi tugas, tetapi nama resminya tidak dipetakan → agent coding bisa menamai sendiri dan menyimpang dari kontrak. | Ditambahkan bagian **"Peta nama RPC resmi → tugas"** di `ROADMAP.md` (jumlah resminya **33 RPC** — angka 26 pada versi awal laporan ini dikoreksi oleh review independen 2026-09-16). |
| 3 | Minor | **2 pertanyaan terbuka PRD belum masuk buku tunggu**: §10.4 (daftar pegawai dilatih & admin cabang) dan §10.7 (kebijakan privasi & persetujuan data pelanggan). Yang §10.7 justru wajib ada **sebelum** data pelanggan dikumpulkan (F8). | Ditambah **T-010** (pelatihan/admin cabang, tenggat F11) dan **T-011** (kebijakan privasi, tenggat sebelum F8) + rujukan ❓ di tugas terkait (T11-09, T8-07). |
| 4 | Minor | **Istilah peran tidak seragam**: "Dapur" vs "Dapur/Bar". | Disamakan: **satu peran "Dapur/Bar"**; layarnya dua (dapur & bar) seperti di ROADMAP T4-01/T4-02. |

## Yang diperiksa dan hasilnya (tidak ada temuan)

- **Fitur vs tugas:** semua Must Have M1–M12 punya tugas → diperiksa otomatis oleh `alat/periksa-roadmap.py` (**LOLOS**).
- **Entitas data model vs migrasi:** 30 entitas `TECH_SPEC.md` §4 semuanya punya tugas (pemeriksa menemukan 6 nama tabel yang hanya disebut lewat deskripsi → sudah ditutup).
- **API contract vs tugas:** 33 RPC + `hitung_total` terpetakan (temuan #2 sudah dibereskan).
- **Area Berisiko Tinggi vs penanganan:** ART-1…ART-10 semuanya punya tugas di Fase 1 atau fase terkait + tanda ⚠️ (jumlah tugas bertanda dihitung ulang oleh review independen: **66 tugas**).
- **Konsistensi istilah uang:** `harga_saat_itu`, "bilangan bulat rupiah", urutan "subtotal → diskon → PB1 → service → pembulatan" konsisten di PRD, TECH_SPEC, ROADMAP, PROMPT sesi.
- **Jejak keputusan:** keputusan K1–K6 (Tahap 3) & mode maraton (Tahap 4) muncul konsisten di TECH_SPEC §13, LOG_SESI, dan PROJECT_STATE.
- **Pertanyaan terbuka PRD yang TIDAK masuk G1 (bukan celah):** §10.6 (rencana penyewa kedua) dan §10.8 (mode luring untuk penyewa lain) memang **lingkup fase 2/3** — tidak perlu tugas di ROADMAP G1; keduanya sudah tercatat di PRD §5 (Fase 2 & 3).

## Pertanyaan terbuka PRD §10 — status penanganan

| PRD §10 | Status |
|---|---|
| 1. Nama produk | Ditutup 2026-09-16 → nama kerja **"Sajian"** (bisa diganti kapan saja) |
| 2. Nilai pajak & service nyata | Buku tunggu **T-005** (nilai awal 10% / 5%) — diisi saat penyiapan |
| 3. Jumlah shift & jam operasional | Buku tunggu **T-005** (nilai awal 1 shift) |
| 4. Daftar pegawai dilatih & admin cabang | Buku tunggu **T-010** (tenggat F11) |
| 5. Periode uji pilot | Sudah terjawab: metrik sukses = **1 bulan pemakaian harian penuh tanpa kertas** |
| 6. Rencana penyewa kedua | Fase 2 (bukan lingkup G1) |
| 7. Kebijakan privasi & persetujuan | Buku tunggu **T-011** (wajib sebelum F8) |
| 8. Mode luring penyewa lain | Fase 3 (bukan lingkup G1) |

## Bukti pemeriksaan (dapat diulang kapan saja)

```
python3 _sistem/validate_system.py     → PASS
python3 alat/periksa-roadmap.py        → LOLOS (jumlah tugas & tanda dihitung per tugas; lihat keluaran terkini)
```

**Kesimpulan:** dokumen fondasi konsisten; Area Berisiko Tinggi semuanya punya penanganan eksplisit;
satu temuan Critical (bentuk jawaban RPC) sudah dibereskan sebelum satu baris kode aplikasi ditulis.
Proyek siap masuk **CODING_AKTIF** mulai Fase 0.

---

## Addendum 2026-09-16 — koreksi dari review independen

Review independen (sesi `arena/01a0aac5-resto-barokah`, laporan penuh di `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md`) menemukan **dua angka di laporan ini yang salah**, dan keduanya sudah dikoreksi di atas maupun di dalam pemeriksa:

1. **"118 tugas bertanda ⚠️"** — angka itu menghitung **kemunculan lambang** (lambang muncul di judul tugas, di baris Risiko & mitigasi, dan di judul fase), bukan jumlah tugas. Jumlah tugas yang benar dihitung per blok tugas oleh `alat/periksa-roadmap.py` (sekarang mencetak angka yang benar, bukan kemunculan lambang).
2. **"26 RPC"** — jumlah nama RPC resmi di `TECH_SPEC.md` §5 adalah **33**; peta di `ROADMAP.md` kini memuat semuanya, dan nama RPC juga disisipkan ke blok tugas yang mengerjakannya.

Selain itu peta RPC sebelumnya memuat `lihat_laporan` yang **bukan** RPC melainkan **kode izin** (`TECH_SPEC.md` §4.3) — sudah dikeluarkan dari peta.
