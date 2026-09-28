# T1-30 — keamanan SQL efektif (Batch-5)

Tanggal 2026-09-22. **Selesai lokal (DoD terpenuhi); menunggu verifikasi CI hosted.**

## Sudah diterapkan

- `supabase/tes/keamanan_fungsi.sql`: setiap SECURITY DEFINER aplikasi di schema
  public wajib path terkunci (`public, pg_temp`); ACL efektif tidak mengandung
  EXECUTE PUBLIC; pemicu berhak pemilik tidak diiklankan sebagai RPC anon/authenticated;
  keterpanggilan trigger non-definer ditolak sebagai RPC klien (A-F06); seluruh
  pemanggilan helper bebas korelasi pada policy RLS wajib dibungkus `(SELECT ...)`
  untuk optimasi InitPlan.
- `alat/periksa-keamanan-sql.py` menjalankan migrasi di DB sementara dan membaca
  katalog asli, bersama `rls_semua_tabel.sql` (RLS, policy, isolasi, rantai helper).
  Definisi awal yang ditimpa, ACL default NULL, GRANT sesudah REVOKE, dan komentar
  tidak dapat membuat pemeriksa mengesahkan keadaan palsu.
- `supabase/migrations/0023_acl_fungsi_pemicu.sql`: daftar eksplisit 20 pemicu
  dicabut hak PUBLIC/anon/authenticated-nya. Service role tetap; fungsi trigger
  tidak dapat dipanggil sebagai RPC biasa, dan eksekusi trigger terpasang tidak
  memerlukan EXECUTE pemanggil.
- `supabase/migrations/0027_initplan_policy_rls.sql`: seluruh 43 policy RLS yang
  sebelumnya memanggil helper identitas/peran/izin (`penyewa_saya`, `peran_saya`,
  `cabang_saya`, `auth.uid`, `boleh`) secara langsung diperbarui dengan pembungkus
  `(SELECT ...)` subquery agar PostgreSQL mengevaluasinya sekali per query (InitPlan),
  bukan per baris tabel. RLS permissive, using/with-check, dan rantai jangkar tetap utuh.
- Mesin dan uji-diri tercatat di CI, gerbang dua arah, dan periksa-semua.

## Bukti lokal

- `node alat/uji-sql.mjs` → **67/67 hijau**; seluruh operasi staf/trigger/RLS teruji.
- `python3 alat/periksa-keamanan-sql.py --uji-diri` → **13 mutasi** ditolak dengan
  asersi, kontrol awal/akhir hijau, salinan sintaks rusak **bukan** bukti.

Mutasi:
1. path dihapus dari fungsi helper
2. path memakai schema pengguna
3. EXECUTE PUBLIC dibuka ulang
4. fungsi baru mewarisi ACL PUBLIC
5. komentar REVOKE palsu
6. trigger dibuka ke authenticated
7. trigger dibuka ke anon
8. helper `penyewa_saya()` dipanggil langsung tanpa SELECT
9. helper campuran: satu SELECT dan satu `peran_saya()` langsung
10. WITH CHECK helper `boleh()` langsung tanpa SELECT
11. SELECT palsu dalam komentar tidak mengelabui InitPlan
12. RLS tabel dimatikan
13. policy terakhir tabel dihapus

Pengujian ini tidak memanggil produksi. Migrasi beku 0001–0016 tetap utuh.

## Batasan jujur & tindak lanjut

1. Rahasia dan npm audit tetap gerbang terpisah (`alat/periksa-rahasia.py`, `npm audit`).
2. Peninjauan independen: pemilik gerbang eksternal adalah Lee + agent audit/deploy.
   Penyebaran ke Supabase nyata memerlukan izin eksplisit dari Lee.
