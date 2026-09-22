# LAPORAN PEKERJA MARATON: T-01 (pekerja-1)

- **ID Tugas:** T-01
- **Pekerja:** pekerja-1
- **Cabang Sesi Pekerja:** `arena/01a0c1d7-resto-barokah`
- **Base Cabang Integrator:** `arena/01a0c1d1-resto-barokah`
- **Nomor Migrasi Cadangan:** `0020`
- **Tanggal:** 2026-09-21
- **Status Pekerjaan:** SELESAI

---

## 1. Yang Dikerjakan

Sesuai definisi tugas T-01 di `docs/ops/PAPAN_TUGAS.md` (menutup temuan audit F F-07 / ROADMAP T1-13):

1. **Migrasi `supabase/migrations/0020_catatan_audit.sql`:**
   - Membuat tabel `public.catatan_audit` dengan kolom:
     - `id uuid primary key default gen_random_uuid()`
     - `penyewa_id uuid not null references public.penyewa (id) on delete cascade`
     - `pelaku_id uuid references public.pengguna (id) on delete set null` (boleh `null` untuk peristiwa sistem)
     - `aksi text not null`
     - `entitas text not null`
     - `entitas_id uuid`
     - `nilai_lama jsonb`
     - `nilai_baru jsonb`
     - `waktu timestamptz not null default now()`
   - Membuat indeks: `catatan_audit_penyewa_waktu_idx on public.catatan_audit (penyewa_id, waktu desc)`.
   - Mengaktifkan Row Level Security (RLS) pada tabel `public.catatan_audit`.
   - Memberlakukan kebijakan RLS `catatan_audit_pilih`: hanya pengguna terautentikasi (`authenticated`) yang berada di penyewa yang sama dan memiliki izin `kelola_pegawai` (`penyewa_id = public.penyewa_saya() and public.boleh('kelola_pegawai')`) yang dapat membaca catatan audit.
   - Mengatur hak akses tabel:
     - Mencabut semua hak baku: `revoke all on table public.catatan_audit from public, anon, authenticated;`
     - Memberikan hak baca terkontrol: `grant select on table public.catatan_audit to authenticated;`
     - Memberikan hak penuh untuk jalur peladen/definer: `grant select, insert, update, delete on table public.catatan_audit to service_role;`
     - **TANPA** memberikan grant `insert`, `update`, atau `delete` ke klien (`anon` maupun `authenticated`).
   - Sesuai instruksi DoD: **TANPA trigger dulu** (pencatatan otomatis menyusul di panen berikutnya — tidak menyentuh fungsi lain).

2. **Suite Uji `supabase/tes/catatan_audit.sql`:**
   - Membuktikan insert, update, dan delete via peran klien (`authenticated`) ditolak secara langsung dengan `uji.harap_gagal_sebab` mematok pesan `permission denied.*catatan_audit`.
   - Membuktikan penulisan lewat jalur pemilik (peladen/superuser) berhasil menulis catatan audit, baik dengan `pelaku_id` pengguna maupun `pelaku_id IS NULL` (peristiwa otomatis sistem).
   - Membuktikan pembacaan oleh kasir dan pelayan (tanpa izin `kelola_pegawai`) menghasilkan 0 baris.
   - Membuktikan pembacaan oleh admin cabang dan owner pusat (dengan izin `kelola_pegawai`) berhasil melihat catatan audit resto miliknya.
   - Membuktikan isolasi multi-tenant (lintas penyewa menghasilkan 0 baris, baik dari resto A ke resto B maupun sebaliknya).
   - Membuktikan pengguna belum masuk (`anon`) ditolak membaca tabel secara langsung.

---

## 2. Bukti Pelaksanaan (Perintah + Hasil Nyata)

### A. Uji Lingkup Tugas (`supabase/tes/catatan_audit.sql`)

```
$ node alat/uji-sql.mjs supabase/tes/catatan_audit.sql

UJI SQL LOKAL (PostgreSQL di dalam Node — tanpa server, tanpa akun)
Menyiapkan peran, auth, dan alat bantu uji…
  OK    persiapan (peran/auth/alat uji)

Menerapkan 20 migrasi:
  OK    0001_penyewa_cabang.sql
  OK    0002_pengguna_izin_pengaturan.sql
  OK    0003_helper_identitas.sql
  OK    0004_pola_rls.sql
  OK    0005_izin_berjenjang.sql
  OK    0006_pin.sql
  OK    0007_katalog.sql
  OK    0008_meja.sql
  OK    0009_pesanan.sql
  OK    0010_pembayaran.sql
  OK    0011_peran_tunggal.sql
  OK    0012_penutup_celah_review.sql
  OK    0013_penutup_celah_putaran11.sql
  OK    0014_penutup_celah_putaran13.sql
  OK    0015_penutup_celah_putaran16.sql
  OK    0016_penutup_celah_pin_putaran18.sql
  OK    0017_pesanan_tertutup_beku.sql
  OK    0018_perangkat_terdaftar.sql
  OK    0019_pesan_diskon_jujur.sql
  OK    0020_catatan_audit.sql

Membuat data uji:
  OK    alat/sql/data-uji.sql

Menjalankan 1 berkas uji:
  LULUS supabase/tes/catatan_audit.sql

----------------------------------------------------------------------
uji: 1 LULUS · 0 GAGAL
HASIL: LOLOS
```

### B. Uji Seluruh Suite SQL (61 Berkas Uji)

```
$ node alat/uji-sql.mjs

... (menerapkan 20 migrasi) ...
Menjalankan 61 berkas uji:
  LULUS supabase/tes/cabang_sesi.sql
  LULUS supabase/tes/catatan_audit.sql
  LULUS supabase/tes/diskon_cap.sql
... (seluruh uji lainnya lolos) ...
  LULUS supabase/tes/rls_semua_tabel.sql
...
  LULUS supabase/tes/void_satu_item.sql

----------------------------------------------------------------------
uji: 61 LULUS · 0 GAGAL
HASIL: LOLOS
```
Catatan: `supabase/tes/rls_semua_tabel.sql` otomatis memverifikasi bahwa tabel `catatan_audit` mengaktifkan RLS, memiliki policy, dan mengikat `penyewa_saya()`.

---

## 3. Keterbatasan Jujur

1. **Pencatatan Otomatis Belum Dipasang:** Sesuai instruksi DoD tugas T-01 ("TANPA trigger dulu"), tabel `catatan_audit` baru disiapkan skema, indeks, izin hak akses, dan kebijakan RLS-nya. Pemicu otomatis (trigger) pada operasi sensitif (perubahan izin, diskon, PIN, dll.) direncanakan menyusul pada gelombang/panen berikutnya agar tidak menyentuh fungsi yang berada di luar lingkup eksklusif tugas T-01.
2. **Angka Jumlah Berkas Uji di Dokumen Induk:** Penambahan `supabase/tes/catatan_audit.sql` menaikkan jumlah berkas uji SQL dari 60 menjadi 61 berkas. Pemeriksa `alat/periksa-panduan.py` memantau klaim angka pada `PANDUAN_PENGGUNA.md` baris 66. Sesuai aturan maraton bahwa pekerja dilarang menyentuh berkas di luar lingkup eksklusif (menghindari tabrakan merge antar-pekerja maraton), pembaruan angka klaim pada `PANDUAN_PENGGUNA.md` tidak dilakukan oleh pekerja dan diserahkan kepada integrator saat panen.

---

## 4. Daftar Berkas yang Disentuh

Hanya 3 berkas (eksklusif dalam lingkup tugas T-01):
1. `supabase/migrations/0020_catatan_audit.sql` (baru)
2. `supabase/tes/catatan_audit.sql` (baru)
3. `docs/ops/maraton/LAPORAN-T-01.md` (baru)
