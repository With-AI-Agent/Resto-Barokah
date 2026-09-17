-- ============================================================================
-- 0004 — Pola RLS seragam (satu pola untuk semua tabel)
--
-- Pola yang dipakai — dan WAJIB dipakai tabel mana pun yang menyusul:
--   * Setiap tabel: RLS aktif + minimal satu policy (deny by default).
--   * Policy memakai fungsi identitas dari 0003 (penyewa_saya, cabang_saya,
--     cabang_ids_saya, peran_saya, sepenyewa) sebagai alat utama.
--     PENYIMPANGAN YANG DISENGAJA & SATU-SATUNYA (lihat `pengguna_pilih` di bawah):
--     keanggotaan cabang diperiksa dengan subquery langsung ke `pengguna_cabang`,
--     bukan lewat fungsi identitas. Alasannya: `pengguna_cabang` sendiri ber-RLS,
--     jadi membungkusnya jadi fungsi SECURITY DEFINER justru menambah permukaan hak
--     istimewa tanpa manfaat. Komentar lama berbunyi "TIDAK ada subquery langsung ke
--     tabel lain" — itu **tidak lagi benar** dan sudah dikoreksi (temuan review RV-2
--     putaran8 PR-19); tabel LAIN di luar jati diri tetap wajib lewat fungsi identitas.
--   * Tabel yang punya `penyewa_id` → policy-nya WAJIB menyebut `penyewa_saya()`.
--   * Menulis (insert/update) dibuka seperlunya dan tetap dibatasi di policy
--     `with check`; perubahan izin/uang tetap lewat RPC (Fase berikutnya).
--
-- Uji otomatis "tabel tanpa policy = gagal" ada di supabase/tes/rls_semua_tabel.sql
-- dan dijalankan setiap kali ada kiriman kode (CI).
-- ============================================================================

-- Hak tingkat tabel untuk peran yang memang boleh menulis (batasannya tetap
-- di policy). Supabase memberi hak ini lewat default privileges; ditulis
-- eksplisit supaya perilaku lokal = produksi.
grant insert, update on public.cabang to authenticated;

-- ------------------------------------------------------------------ penyewa
create policy penyewa_pilih on public.penyewa
  for select to authenticated
  using (id = public.penyewa_saya());

-- ------------------------------------------------------------------- cabang
create policy cabang_pilih on public.cabang
  for select to authenticated
  using (penyewa_id = public.penyewa_saya());

create policy cabang_tambah on public.cabang
  for insert to authenticated
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat');

create policy cabang_ubah on public.cabang
  for update to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat')
  with check (penyewa_id = public.penyewa_saya());

-- ----------------------------------------------------------------- pengguna
-- Setiap orang melihat dirinya sendiri; owner pusat melihat seluruh pegawai
-- di restonya; admin cabang hanya melihat pegawai yang bertugas di cabangnya.
create policy pengguna_pilih on public.pengguna
  for select to authenticated
  using (
    id = auth.uid()
    or (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat')
    or (
      penyewa_id = public.penyewa_saya()
      and public.peran_saya() = 'admin_cabang'
      and exists (
        select 1
          from public.pengguna_cabang pc
         where pc.pengguna_id = public.pengguna.id
           and pc.cabang_id = public.cabang_saya()
      )
    )
  );

-- ---------------------------------------------------------- pengguna_cabang
create policy pengguna_cabang_pilih on public.pengguna_cabang
  for select to authenticated
  using (pengguna_id = auth.uid() or cabang_id in (select public.cabang_ids_saya()));

-- ------------------------------------------------------------------- izin
-- Pegawai melihat izinnya sendiri; owner pusat & admin cabang melihat izin
-- pegawai di lingkupnya (dipakai layar centang izin, M3).
create policy izin_pilih on public.izin
  for select to authenticated
  using (
    pengguna_id = auth.uid()
    or (public.peran_saya() in ('owner_pusat', 'admin_cabang') and public.sepenyewa(pengguna_id))
  );

-- -------------------------------------------------------------- pengaturan
create policy pengaturan_pilih on public.pengaturan
  for select to authenticated
  using (penyewa_id = public.penyewa_saya());

create policy pengaturan_ubah on public.pengaturan
  for update to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() = 'owner_pusat')
  with check (penyewa_id = public.penyewa_saya());

-- Catatan: tidak ada policy untuk peran `anon` di tabel mana pun. Artinya
-- pengunjung yang belum masuk melihat NOL baris — bukan error, bukan bocor.
