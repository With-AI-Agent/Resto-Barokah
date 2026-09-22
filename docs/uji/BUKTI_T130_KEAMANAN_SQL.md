# T1-30 — keamanan SQL efektif (Batch-5)

Tanggal 2026-09-21. **Parsial; T1-30 belum selesai. Bukan AUD-2 independen.**

## Sudah diterapkan

- `supabase/tes/keamanan_fungsi.sql`: setiap SECURITY DEFINER aplikasi di schema
  public wajib path terkunci; ACL efektif tidak mengandung EXECUTE PUBLIC;
  pemicu berhak pemilik tidak diiklankan sebagai RPC anon/authenticated.
- `alat/periksa-keamanan-sql.py` menjalankan migrasi di DB sementara dan membaca
  katalog, bersama `rls_semua_tabel.sql` (RLS, policy, isolasi, rantai helper).
  Definisi awal yang ditimpa, ACL default NULL, GRANT sesudah REVOKE, dan komentar
  tidak dapat membuat pemeriksa mengesahkan keadaan palsu.
- `supabase/migrations/0023_acl_fungsi_pemicu.sql`: daftar eksplisit 20 pemicu
  dicabut hak PUBLIC/anon/authenticated-nya. Service role tetap; fungsi trigger
  tidak dapat dipanggil sebagai RPC biasa, dan eksekusi trigger terpasang tidak
  memerlukan EXECUTE pemanggil. Ini higiene hak, bukan perubahan izin bisnis.
- Mesin dan uji-diri tercatat di CI, gerbang dua arah, dan periksa-semua.

## Bukti lokal

Sebelum 0023: uji baru gagal tepat **T130-public**. Sesudahnya:
`node alat/uji-sql.mjs` → **65/65 hijau**; operasi staf/trigger lama tetap diuji.
`python3 alat/periksa-keamanan-sql.py --uji-diri` → **9 mutasi** ditolak dengan
asersi, kontrol awal/akhir hijau, salinan sintaks rusak **bukan** bukti.

Mutasi: path dihapus; path memakai schema pengguna; PUBLIC dibuka ulang;
fungsi baru mewarisi ACL PUBLIC; komentar REVOKE palsu; trigger dibuka ke
anon/authenticated (2); RLS dimatikan; policy terakhir tabel dihapus.
Pengujian ini tidak memanggil produksi. Migrasi 0001–0016 tetap utuh.

## Yang belum — milik agent T1-30, sebelum DoD dicentang

1. **Sesudah AUD-2 atas 0022/0023**, buat analisis AST/statis panggilan helper
   policy; jangan memakai syarat "ada SELECT di mana saja" atau mencocokkan
   definisi pertama. Inventaris awal katalog: 55 policy; **minimal 38** memanggil
   salah satu `penyewa_saya()`, `cabang_saya()`, `peran_saya()` tanpa SELECT.
   Angka ini diagnostik awal, bukan audit AST seluruh ekspresi.
2. Tutup utang initplan menggunakan migrasi **baru**, bukan menyunting migrasi
   beku; pertahankan predicate, peran, USING/WITH CHECK, isolasi, dan perilaku
   subquery berkorelasi. Jangan membuat pengecualian hanya supaya CI hijau.
3. Kalibrasi minimal: helper langsung; SELECT palsu di komentar; satu helper
   terbungkus dan satu masih langsung dalam policy sama; pemanggilan baru/
   overload; predicate tenant/cabang terlepas; policy WITH CHECK terlewat.
   Uji RLS/matriks harus tetap hijau sebelum dan sesudah perubahan.
4. Rahasia dan npm audit tetap gerbang terpisah. Pemeriksa saat ini bukan
   pengganti analisis semua schema/fungsi penyedia Supabase, audit independen,
   atau pengujian pada Supabase asli. Skema aplikasi sekarang berada di public.
5. **Pemilik gerbang eksternal: Lee + agent audit/deploy.** Jangan sebar 0023
   tanpa izin terpisah. Minta peninjau independen menilai ACL minimum dan
   kepekaan harness; paket hanya boleh mengacu commit CI-hijau.

Rencana ini juga melekat pada T1-30 di `docs/ROADMAP.md`, A F-07 di
`docs/uji/AUDIT_RIWAYAT.md`, dan `docs/ops/SIAP-LANJUT.md` §3 — bukan catatan
sementara yang boleh hilang saat ganti sesi.
