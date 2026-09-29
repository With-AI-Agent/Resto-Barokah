-- ============================================================================
-- PROBE HAKIM F-06 (2026-09-29) — temuan hakim baru: kendali "sesi terikat
-- perangkat + pencabutan seketika" (T1-25 / docs/KEAMANAN.md §4 butir 4 dan
-- baris matriks 195) TIDAK pernah ditegakkan pada permintaan mana pun.
--
-- ATURAN BACA HASIL: berkas ini LULUS = CACATNYA NYATA (konvensi probe PMB).
-- Kalau suatu hari jalur klien benar-benar mengikat sesi dan memakai klaim
-- sesuatu yang dibaca sesi_masih_aktif(), berkas ini WAJIB menjadi MERAH.
--
-- Empat asersi, semuanya dijalankan pada pohon hari ini:
--   A. Login staf berhasil dari kursi anon (klaim Rina x perangkat hp-atasan),
--      sesudahnya TIDAK ADA baris sesi_perangkat → klien tidak pernah mengikat
--      sesi (grep aplikasi/src untuk ikat_sesi_perangkat juga 0 baris).
--   B. RPC staf (bayar_pesanan, grant hanya ke `authenticated`) DITOLAK dari
--      kursi anon — kedudukan sebenarnya klien peramban sesudah login PIN.
--   C. sesi_masih_aktif() mengembalikan TRUE untuk pengguna terautentikasi yang
--      tokennya TIDAK membawa klaim session_id/perangkat_id — yaitu kedudukan
--      nyata setiap permintaan hari ini.
--   D. Kendali itu memang BISA menolak, tapi hanya bila klaimnya ada: klaim
--      session_id / perangkat_id yang tak dikenal → FALSE. Berkas uji menyuntikkan
--      klaim itu lewat uji.klaim(); produksi tidak punya penulis klaim
--      (tanpa [auth.hook] di supabase/config.toml, tanpa custom_access_token,
--      tanpa set_session/signInWithPassword di aplikasi/src).
--
-- Catatan urutan (pelajaran dari probe F-082): penyiapan tabel dijalankan
-- sebagai pemilik tabel SEBELUM `set local role anon`, dan pembacaan hitungan
-- dilakukan SESUDAH `reset role` karena anon tidak punya hak baca.
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel -------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- Owner memasang PIN 731904 untuk kasir Rina (pengguna 90000000-...-0004)
select public.simpan_pin(
  '731904',
  null,
  '90000000-0000-0000-0000-000000000004',
  'de000000-0000-0000-0000-000000000001',
  'kunci-uji-hp-owner-0123456789'
);

-- Pastikan perangkat hp-atasan (de...006) aktif & mengizinkan peran kasir
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur', 'admin_cabang', 'owner_pusat']::text[]
 where id = 'de000000-0000-0000-0000-000000000006';

-- Kosongkan sesi_perangkat penyewa A supaya hitungan di bawah benar-benar nol
delete from public.sesi_perangkat
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- --- A. login staf dari kursi anon (seperti klien, auth.ts:176) -----------
select uji.klaim(null);
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '731904',
    'de000000-0000-0000-0000-000000000006'::uuid,
    'HP Atasan',
    'kunci-uji-hp-atasan-0123456789'
  )->>'berhasil')::boolean,
  true,
  'A: login staf berhasil dari kursi anon (klien hanya memegang kunci anon)'
);

-- --- B. RPC staf dari kursi yang sama harus DITOLAK ----------------------
select uji.harap_gagal_sebab(
  'select public.bayar_pesanan(''e9000000-0000-0000-0000-000000000001''::uuid, ''e9000000-0000-0000-0000-000000000002''::uuid, 0, 0, ''tunai'', null)',
  'permission denied',
  'B: bayar_pesanan (grant hanya authenticated) DITOLAK dari kursi anon'
);

reset role;
select uji.klaim(null);

-- --- A(lanjutan): sesudah login TIDAK ada sesi_perangkat yang terikat -----
select uji.sama(
  (select count(*) from public.sesi_perangkat)::text,
  '0',
  'CACAT NYATA: sesudah login staf berhasil, sesi_perangkat tetap KOSONG (klien tidak pernah memanggil ikat_sesi_perangkat)'
);

-- --- C. kendali sesi per permintaan pada kedudukan nyata -----------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  true,
  'CACAT NYATA: token tanpa klaim session_id/perangkat_id (kedudukan nyata hari ini) diloloskan sesi_masih_aktif()'
);

-- --- D. kendali itu bisa menolak HANYA bila klaimnya disuntikkan ----------
select uji.klaim(
  '90000000-0000-0000-0000-000000000004',
  '{"session_id":"sess-hakim-tidak-ada-0001"}'::jsonb
);
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'D: dengan klaim session_id (seperti yang disuntikkan berkas uji) kendali menolak — jadi ia hanya hidup di uji'
);

select uji.klaim(
  '90000000-0000-0000-0000-000000000004',
  '{"perangkat_id":"de999999-0000-0000-0000-000000000009"}'::jsonb
);
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'D: dengan klaim perangkat_id asing kendali juga menolak — kedua jalur klaim tidak pernah terisi di produksi'
);

reset role;
select uji.klaim(null);
