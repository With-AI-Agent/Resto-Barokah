# DAFTAR_PEKERJAAN_ULANG.md — Pekerjaan Lama yang Harus Diulang Karena Perubahan Keamanan

> **Hasil AUD-0 (Audit Dampak) — 2026-09-17.** Dipicu permintaan pemilik: *"Bahkan sesi coding yang sebelumnya udh
> sempet kita mulai, klo itu perlu diulang karena berkaitan dengan perubahan ini, maka harus diulang."*
> Aturan: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2 (AUD-0).
>
> **Cara membaca:** baris yang bertanda **WAJIB** harus dikerjakan sebelum Fase 1B boleh dinyatakan selesai; yang
> bertanda **LENGKAP** sudah dikerjakan hari ini. Migrasi lama (0001–0010) **tidak boleh disunting** — perubahannya
> selalu lewat migrasi baru + `DECISIONS_LOG.md`.

## A. Ringkasan jujur

Perubahan keamanan 2026-09-17 **memang membatalkan sebagian pekerjaan Fase 1**. Yang dibatalkan terpusat pada satu
keputusan: **satu akun = satu peran** (ART-12) dan **perangkat terdaftar** (ART-11). Akibatnya:

| Bagian pekerjaan lama | Nasib |
|---|---|
| Skema penyewa/cabang/pengguna/izin/pengaturan (0002) | **Sebagian dibongkar**: `pengguna_cabang.peran` harus hilang |
| Mesin izin `izin_efektif()` (0005) | **Ditulis ulang** (ia membaca peran per cabang yang kini dilarang) |
| Uji izin per-cabang (tes/izin.sql §8) | **SELESAI 2026-09-17** — dibuang & diganti uji peran tunggal (`tes/izin.sql` §8 + `tes/peran_tunggal.sql`) |
| Fungsi identitas (0003) | **Ditambah** pemeriksaan sesi/perangkat |
| Pola RLS (0004) | **Diperketat** untuk tabel staf (perangkat sah) |
| PIN & percobaan (0006 + Edge Function) | **Digeser** ke perangkat terdaftar + percobaan masuk (kata sandi/MFA ikut dicatat) |
| Katalog, stok, meja, pesanan, pembayaran (0007–0010) | **Aman** — tidak bergantung peran per cabang; hanya policy-nya ikut diperketat (bagian B.6) |

## B. Daftar tindakan

| # | Artefak lama | Bertentangan dengan | Tindakan ulang | Tugas | Status |
|---|---|---|---|---|---|
| B.1 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql:54` — kolom `pengguna_cabang.peran` + komentar "peran berbeda per cabang" | `docs/KEAMANAN.md` §3 · ART-12 · PRD Aturan Bisnis 14 | Migrasi **0011** menghapus `pengguna_cabang.peran` (kolom & komentar lama dibiarkan apa adanya sebagai riwayat; migrasi baru yang membongkar) + pemicu penolak peran kedua per akun | **T1-23** | **LENGKAP 2026-09-17** — 0011 (`drop column`) + penjaga keanggotaan; uji `tes/peran_tunggal.sql`. Catatan jujur: pemicu tidak bisa mendeteksi kolom yang tidak ada, jadi penegakannya **struktural** (kolom hilang) + penjaga keanggotaan (satu resto, pemilik platform dilarang) |
| B.2 | `supabase/migrations/0005_izin_berjenjang.sql:185` — `izin_efektif()` membaca `pc.peran` (peran per cabang) | ART-12 (peran tunggal) | Tulis ulang `izin_efektif()` di migrasi **0011**: peran dari `pengguna.peran`, keanggotaan cabang dari `pengguna_cabang` (tanpa peran); uji ulang matriks 10 izin × 5 peran | **T1-23** | **LENGKAP 2026-09-17** — `tes/izin.sql` (matriks 10 izin × 5 peran tetap utuh) + `tes/peran_tunggal.sql` (peran akun = sumber tunggal; cabang asing tetap ditolak) |
| B.3 | `supabase/tes/izin.sql` §8 "pegawai merangkap dapat peran berbeda per cabang" | ART-12 | Buang bagian itu; ganti dengan uji **peran tunggal**: peran kedua ditolak, akun nonaktif ditolak, izin per cabang tetap berlaku lewat *izin centang*, bukan peran | **T1-23** | **LENGKAP 2026-09-17** — §8 diganti uji peran tunggal + berkas baru `tes/peran_tunggal.sql` (merangkap DUA CABANG tetap boleh; dua PERAN tidak) |
| B.4 | `supabase/migrations/0003_helper_identitas.sql` — `cabang_saya()` hanya memverifikasi ke `pengguna_cabang`, belum ke sesi/perangkat | ART-11 · KEAMANAN §7 (pencabutan seketika) | Tambah pemeriksaan sesi aktif + perangkat sah di migrasi **0012/0013**; uji: sesi dicabut → identitas kosong pada permintaan berikutnya | **T1-24/T1-25** | WAJIB |
| B.5 | `supabase/migrations/0004_pola_rls.sql` — policy tabel staf tanpa syarat perangkat | ART-11 | Policy baru (migrasi **0012**) memakai `(select public.perangkat_sah())` untuk tabel staf; uji dua arah (perangkat sah boleh · tidak sah ditolak) | **T1-24** | WAJIB |
| B.6 | `supabase/migrations/0006_pin.sql` — `percobaan_pin.perangkat` teks bebas; hanya PIN yang dicatat | ART-11/ART-12 · TECH_SPEC §4.6 (`percobaan_masuk`) | Migrasi **0014** membuat `percobaan_masuk` (FK perangkat + jenis percobaan: PIN/kata sandi/MFA); `percobaan_pin` **dihentikan** (drop, belum ada data produksi) dengan catatan di `DECISIONS_LOG.md`; `verifikasi_pin` menolak perangkat tak terdaftar | **T1-26** | WAJIB |
| B.7 | `supabase/functions/verifikasi_pin/index.ts` + `alat/periksa-fungsi-pin.py` | ART-11 (perangkat terdaftar) | Fungsi meneruskan bukti perangkat & memeriksa sesi; pemeriksa statis diperluas (tanpa `console.*`, tanpa `service_role`, POST saja) + uji negatif perangkat tak terdaftar | **T1-26** | WAJIB |
| B.8 | `supabase/tes/pin.sql` — batas perangkat diukur dari teks bebas | ART-11 | Uji dijalankan ulang memakai perangkat nyata dari fixture; tambah kasus: percobaan dari perangkat tak terdaftar ditolak **sebelum** PIN diperiksa | **T1-26** | WAJIB |
| B.9 | `alat/sql/data-uji.sql` — belum ada data perangkat | ART-11 | Tambah fixture: 2 perangkat terdaftar (kasir, dapur) + 1 kode pendaftaran + 1 perangkat dicabut; dipakai uji perangkat/sesi/percobaan | **T1-24/T1-26** | WAJIB |
| B.10 | `docs/ROADMAP.md` nomor migrasi & jumlah tugas | dokumentasi | **LENGKAP** — nomor lama digeser +7 (0011→0018 dst.), 3 tugas audit ditambahkan, jumlah diukur ulang | — | LENGKAP |
| B.11 | `docs/TECH_SPEC.md` §4.1/§4.6/§5/§8/§9/§11/§12/§13 | dokumentasi | **LENGKAP** — tabel/kolom baru, RPC baru, ART-11…ART-15, ringkasan §8 menunjuk `KEAMANAN.md` | — | LENGKAP |
| B.12 | `docs/PRD.md` M12 & aturan bisnis | dokumentasi | **LENGKAP** — M12 diperdalam, Aturan Bisnis 14–18, risiko #9–#11 | — | LENGKAP |

## C. Yang **tidak** perlu diulang (dinyatakan dengan bukti)

| Artefak | Alasan tidak perlu diulang | Bukti |
|---|---|---|
| `0001_penyewa_cabang.sql` | Tidak menyentuh peran/perangkat | `node alat/uji-sql.mjs` → `rls_penyewa.sql` LULUS |
| `0007_katalog.sql`, `0008_meja.sql`, `0009_pesanan.sql`, `0010_pembayaran.sql` | Logika harga/uang/salinan beku tidak bergantung pada cara orang masuk | Uji katalog/meja/pesanan/pembayaran LULUS; pagar uang diuji 13 mutasi |
| uji SQL yang sudah ada (12 berkas) | Tetap berlaku; hanya `tes/izin.sql` §8 & `tes/pin.sql` yang berubah (B.3, B.8) | Hasil uji terakhir: **21 berkas LULUS · 0 GAGAL** (2026-09-17, sesudah 0011) |
| Desain & komponen UI (`aplikasi/src/komponen/*`) | Belum ada layar fitur; kontrak UI baru menyentuh tugas UI ke depan | 7 berkas uji vitest LULUS (51 uji) |

## D. Aturan supaya ini tidak terulang

1. **Setiap keputusan yang menyentuh peran/keamanan wajib memicu AUD-0** (audit dampak) di hari yang sama — bukan ditemukan berbulan kemudian.
2. **Perubahan aturan wajib menyebut artefak lama yang dibatalkan**, seperti tabel di atas (di `DECISIONS_LOG.md`).
3. **Pekerjaan berisiko tidak boleh dinyatakan "selesai"** tanpa audit independen (AUD-2) — inilah alasan Fase 1 dijeda di T1-10, bukan diteruskan.
