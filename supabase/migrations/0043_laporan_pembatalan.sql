-- ============================================================================
-- 0043 — Laporan pembatalan (T5-12): siapa, nilai, alasan, jenis
--
-- PRD M8 menuntut laporan memuat "daftar pembatalan (siapa, nilai, alasan)",
-- dan PRD M6 butir 4 menegaskan "tidak ada pembatalan yang tidak terlihat".
-- Migrasi ini menyediakan bacaannya — DAN menutup satu celah nyata yang
-- ditemukan saat menyiapkannya.
--
-- ---------------------------------------------------------------------------
-- CACAT NYATA YANG DITUTUP DI SINI (ditemukan 2026-09-23 dengan menjalankannya,
-- bukan dengan membaca kode):
--
--   Policy `pembatalan_pilih` (migrasi 0010) berbunyi:
--       for select to authenticated using (public.pesanan_sepenyewa(pesanan_id))
--
--   Artinya SIAPA PUN yang masuk — termasuk PELAYAN dan DAPUR — bisa membaca
--   SELURUH baris pembatalan restonya: siapa yang membatalkan, berapa nilai
--   kerugiannya, dan alasannya. Padahal izin `lihat_laporan` (0005) hanya
--   diberikan kepada owner_pusat dan admin_cabang; kasir, pelayan, dan dapur
--   tegas-tegas `false`.
--
--   Dibuktikan sebelum diperbaiki: sebagai Dedi (pelayan, `boleh('lihat_laporan')`
--   = false), `select count(*) from public.pembatalan` mengembalikan **1**, bukan 0.
--
--   Kenapa ini serius: daftar pembatalan adalah data ketenagakerjaan yang
--   sensitif. Ia memperlihatkan pegawai mana yang paling sering membatalkan dan
--   berapa kerugian yang ia timbulkan. Rekan kerja tidak berhak membacanya, dan
--   pegawai yang tahu rekannya bisa membaca justru terdorong menutupi kesalahan
--   alih-alih mencatatnya jujur — persis kebalikan dari tujuan tabel ini.
--
--   Yang TIDAK diubah: hak MENULIS. Kasir dan pelayan tetap boleh mencatat
--   pembatalan (itu pekerjaan mereka). Yang dipersempit hanya hak MEMBACA
--   kembali daftarnya.
-- ---------------------------------------------------------------------------
--
-- Tidak ada RPC baru di sini. `docs/TECH_SPEC.md` §5 tidak memuat RPC laporan
-- pembatalan tersendiri (yang ada `laporan_shift` & `laporan_harian`, dikerjakan
-- di Fase 7), dan menambah nama di luar daftar itu adalah keputusan pemilik.
-- Jadi laporan ini disediakan sebagai VIEW yang tunduk pada RLS tabelnya —
-- bacaan biasa, bukan pintu baru.
-- ============================================================================

-- ------------------------------------------------- 1. tutup celah baca (RLS)
drop policy if exists pembatalan_pilih on public.pembatalan;

create policy pembatalan_pilih on public.pembatalan
  for select to authenticated
  using (
    public.pesanan_sepenyewa(pesanan_id)
    -- Dibungkus (select ...) dengan sengaja: tanpa itu PostgreSQL memanggil
    -- `boleh()` SEKALI PER BARIS, bukan sekali per perintah. Pada laporan
    -- sebulan yang berisi ratusan baris, bedanya nyata — dan penjaga
    -- `supabase/tes/keamanan_fungsi.sql` (T130-initplan) memang menolak bentuk
    -- yang tidak dibungkus.
    and (select public.boleh('lihat_laporan'))
  );

comment on policy pembatalan_pilih on public.pembatalan is
  'T5-12: daftar pembatalan hanya boleh DIBACA pemegang izin lihat_laporan (owner/admin). Mencatat pembatalan tetap boleh bagi kasir & pelayan — yang dipersempit hanya hak membaca kembali, karena daftar ini memperlihatkan pegawai mana yang paling sering membatalkan dan berapa kerugiannya.';

-- ------------------------------------------- 2. bacaan laporan (siapa/nilai/alasan)
--
-- Nama pelaku & penyetuju disalin lewat join ke `pengguna`, bukan disimpan ulang:
-- pembatalan tidak butuh salinan beku seperti harga (ART-3) karena yang dilaporkan
-- adalah ORANGNYA, dan nama orang yang berubah memang harus ikut berubah di laporan.
--
-- `security_invoker` WAJIB: tanpa itu view berjalan sebagai pemiliknya dan RLS di
-- atas akan terlewati — celah yang baru saja ditutup akan terbuka lagi lewat pintu
-- lain.
create or replace view public.laporan_pembatalan
with (security_invoker = true) as
  select
    b.id,
    p.penyewa_id,
    p.cabang_id,
    p.tanggal,
    p.nomor                       as nomor_pesanan,
    b.waktu,
    b.tahap,                                   -- 'sebelum_dapur' | 'sesudah_dapur'
    b.alasan,
    b.nilai_kerugian,
    b.bahan_terbuang,
    b.pelaku_id,
    pel.nama                      as pelaku_nama,
    b.disetujui_oleh,
    stj.nama                      as penyetuju_nama,
    b.pesanan_item_id,
    pi.nama_saat_itu              as item_nama,
    pi.qty                        as item_qty
  from public.pembatalan b
  join public.pesanan p            on p.id = b.pesanan_id
  left join public.pengguna pel    on pel.id = b.pelaku_id
  left join public.pengguna stj    on stj.id = b.disetujui_oleh
  left join public.pesanan_item pi on pi.id = b.pesanan_item_id;

comment on view public.laporan_pembatalan is
  'T5-12: daftar pembatalan siap laporan (siapa, nilai, alasan, jenis pra/pasca dapur) per hari & cabang. security_invoker: tunduk pada RLS pembatalan — hanya pemegang lihat_laporan yang melihat isinya.';

revoke all on public.laporan_pembatalan from public, anon;
grant select on public.laporan_pembatalan to authenticated;
