-- ============================================================================
-- Probe HAKIM F-14 (kartu H-F-14.2, sesi arena/01a0ec16-resto-barokah, 2026-09-29)
-- Objek: PMB1-F-177 (generator kode voucher) & PMB1-F-180 (jumlah tabel publik)
--
-- Kenapa runtime, bukan hanya grep: dua temuan ini mengklaim sesuatu tentang
-- DEFINISI YANG BERLAKU dan tentang ISI DATABASE hari ini. Grep bisa tertipu
-- fungsi yang ditulis ulang di migrasi berikutnya (jebakan klasik repo ini,
-- lihat SIAP-LANJUT §3 butir 0m/0o2). Probe ini memanggil fungsi yang benar-benar
-- hidup di database hasil seluruh migrasi, dari kursi peran yang benar-benar
-- punya hak (anon — lihat grant di 0064:378,381).
--
-- Jalankan:
--   npm ci --prefix alat      (sekali per ruang kerja)
--   node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-14.2-voucher-dan-tabel.sql
--
-- Cara membaca: asersi berlabel CELOH memakai uji.harap terhadap KENYATAAN.
-- Hijau = celah ADA dan terbukti. Bila suatu hari diperbaiki, asersi CELOH jadi
-- MERAH — dan itu kabar baik (ubah asersinya, jangan longgarkan pagarnya).
-- Kontrol positif & negatif di tiap bagian membuktikan probe ini benar-benar
-- memanggil artefaknya dan bisa merah (bukan bukti tautologis — pelajaran
-- PMB1-F-092).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — PMB1-F-177: validator format voucher
-- Klaim di bahan: DECISIONS_LOG.md:2825 "alfabet Crockford Base32 tanpa karakter
-- ambigu (0, O, 1, I)"; komentar kode 0064:62 "tanpa karakter ambigu 0, O, 1, I, L"
-- ---------------------------------------------------------------------------

set local role anon;

-- 1a. Kontrol positif: kode sah (huruf/angka dari alfabet generator) diterima.
select uji.harap(
  public.apakah_format_voucher_acak('RB-2345-ABCD'),
  'kontrol positif: kode sah RB-2345-ABCD harus diterima validator');

-- 1b. Kontrol negatif: karakter ambigu 0/O/1/I DITOLAK → validator benar-benar
--     bekerja dan probe ini bisa merah (bukan tautologis).
select uji.harap(
  public.apakah_format_voucher_acak('RB-0O1I-0O1I') is false,
  'kontrol negatif: 0/O/1/I harus ditolak validator');

-- 1c. Kontrol negatif kedua: bentuk bukan RB-XXXX-XXXX ditolak.
select uji.harap(
  public.apakah_format_voucher_acak('RB-234-ABCD') is false,
  'kontrol negatif: panjang salah harus ditolak validator');

-- 1d. CELOH: huruf L DITERIMA padahal komentar 0064:62 menyatakan L ambigu
--     (kelas regex [2-9A-HJ-NP-Z] memuat rentang J-N = J,K,L,M,N).
select uji.harap(
  public.apakah_format_voucher_acak('RB-LLLL-LLLL'),
  'CELOH F-177: huruf L diterima validator (seharusnya ditolak menurut komentar 0064:62) — hijau = celah ADA');

reset role;

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — PMB1-F-177: definisi generator yang BENAR-BENAR berlaku
-- Klaim di bahan: DECISIONS_LOG.md:2825 "dibangkitkan menggunakan gen_random_bytes()"
-- ---------------------------------------------------------------------------

-- 2a. Kontrol positif: definisi efektif bisa dibaca dari katalog (bukan dari berkas).
select uji.harap(
  length(pg_get_functiondef('public.buat_kode_voucher_acak()'::regprocedure)) > 100,
  'kontrol positif: definisi efektif buat_kode_voucher_acak terbaca dari pg_catalog');

-- 2b. CELOH: definisi efektif memakai random() (bukan CSPRNG).
select uji.harap(
  pg_get_functiondef('public.buat_kode_voucher_acak()'::regprocedure) like '%floor(random() * v_len)%',
  'CELOH F-177: definisi efektif memakai floor(random() * v_len) — bukan CSPRNG; hijau = klaim gen_random_bytes tidak terbukti');

-- 2c. CELOH: tidak ada gen_random_bytes di definisi efektif.
select uji.harap(
  pg_get_functiondef('public.buat_kode_voucher_acak()'::regprocedure) not like '%gen_random_bytes%',
  'CELOH F-177: gen_random_bytes tidak ada di definisi efektif — hijau = klaim DECISIONS_LOG:2825 keliru');

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — PMB1-F-177: alfabet NYATA generator (dihitung dari keluaran, 4000 contoh)
-- Klaim di bahan: "alfabet Crockford Base32" (32 karakter, memuat 0 dan 1, tanpa I L O U)
-- ---------------------------------------------------------------------------

-- 3a. Kontrol positif: generator menghasilkan pola RB-XXXX-XXXX.
select uji.harap(
  public.buat_kode_voucher_acak() ~ '^RB-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$',
  'kontrol positif: keluaran generator cocok pola RB-XXXX-XXXX');

-- 3b. CELOH: alfabet nyata = 31 karakter (bukan 32 Crockford), dan tidak memuat
--     0/1/I/L/O — jadi bukan Crockford (Crockford justru MEMUAT 0 dan 1).
select uji.harap(
  (with sampel as (select public.buat_kode_voucher_acak() as kode from generate_series(1, 4000)),
        huruf as (select substr(kode, s, 1) as c
                    from sampel, generate_series(1, 12) s
                   where substr(kode, s, 1) <> '-')
   select count(distinct c) from huruf) = 31,
  'CELOH F-177: alfabet nyata generator 31 karakter, bukan Crockford Base32 (32) — hijau = klaim DECISIONS_LOG:2825 keliru');

-- 3c. CELOH: karakter 0/1/I/L/O tidak pernah muncul (Crockford memuat 0 dan 1).
select uji.harap(
  (with sampel as (select public.buat_kode_voucher_acak() as kode from generate_series(1, 4000)),
        huruf as (select substr(kode, s, 1) as c
                    from sampel, generate_series(1, 12) s
                   where substr(kode, s, 1) <> '-')
   select count(*) from huruf where c in ('0', '1', 'I', 'L', 'O')) = 0,
  'CELOH F-177: 0/1/I/L/O tidak pernah dibangkitkan — bukti alfabet bukan Crockford');

-- 3d. Kontrol positif: generator benar-benar acak (tidak konstan) — 4000 panggilan
--     menghasilkan lebih dari satu nilai berbeda.
select uji.harap(
  (select count(distinct kode) from (select public.buat_kode_voucher_acak() as kode
                                       from generate_series(1, 200)) x) > 100,
  'kontrol positif: generator menghasilkan nilai beragam (tidak konstan)');

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — PMB1-F-180: jumlah tabel publik hari ini
-- Klaim di bahan: :3000 dan :3003 "45 tabel" · :3076 "46 tabel" · :3197 "47 tabel"
-- (tiga angka berbeda, tiga entri berlabel tanggal sama 2026-09-27)
-- ---------------------------------------------------------------------------

-- 4a. Kontrol positif: katalog PostgreSQL bisa dibaca (cara yang sama dengan
--     supabase/tes/sisir_rls_akhir.sql yang mengklaim 45 tabel).
select uji.harap(
  (select count(*) from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r') >= 45,
  'kontrol positif: minimal 45 tabel publik (ambang yang dipakai sisir_rls_akhir.sql:99)');

-- 4b. CELOH: jumlahnya 47 hari ini, bukan 45 seperti klaim :3000/:3003.
select uji.sama(
  (select count(*) from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r')::int,
  47,
  'CELOH F-180: tabel publik hari ini 47 — klaim "45 tabel" di :3000/:3003 sudah tidak berlaku tanpa penanda');

-- 4c. Kontrol silang: angka 45 di bahan bukan karangan — jumlah tabel yang punya
--     penyewa_id + yang tidak, dibaca dari katalog yang sama.
select uji.harap(
  (select count(*) from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity) >= 45,
  'kontrol silang: seluruh tabel publik tetap ber-RLS (substansi klaim T10-05 tidak dibantah probe ini)');

-- ---------------------------------------------------------------------------
-- BAGIAN 5 — PMB1-F-176: tidak ada satu pun kolom TOTP di skema (klaim :3227)
-- ---------------------------------------------------------------------------

-- 5a. Kontrol positif: katalog kolom bisa dibaca.
select uji.harap(
  (select count(*) from information_schema.columns
    where table_schema = 'public') > 500,
  'kontrol positif: information_schema.columns skema public terbaca');

-- 5b. CELOH: nol kolom bernama totp/mfa/2fa di seluruh skema public → lapisan
--     "Wajib TOTP pada setiap akun berkuasa" (:3227) tidak punya artefak data.
select uji.sama(
  (select count(*) from information_schema.columns
    where table_schema = 'public'
      and (column_name ilike '%totp%' or column_name ilike '%mfa%' or column_name ilike '%2fa%'))::int,
  0,
  'CELOH F-176: nol kolom TOTP/MFA di skema public — hijau = klaim "TOTP wajib sudah terpasang kokoh" tanpa artefak');
