-- ============================================================================
-- PROBE HAKIM P-1B-00 (2026-10-07) — reproduksi MANDIRI temuan PMB1-F-095
-- pada pohon hari ini (105 migrasi).
--
-- Latar: probe asli `bukti/H-F-06-sesi-perangkat-mati.sql` (hakim H-F-06.2,
-- 2026-09-29) hari ini GAGAL di asersi A, bukan karena cacatnya hilang,
-- melainkan karena penyiapannya basi: ia memakai perangkat `hp-atasan`
-- (de…006) yang TIDAK punya baris `persetujuan_perangkat` untuk Rina
-- (pengguna …0004), sehingga migrasi 0101 menolak login lebih dulu
-- (PERANGKAT_BELUM_DISETUJUI). Probe ini memakai `hp-kasir` (de…003) yang
-- persetujuannya ADA di `alat/sql/data-uji.sql:161`, lalu mengukur inti
-- temuannya: apakah kendali "sesi terikat perangkat + pencabutan seketika"
-- (T1-25 / docs/KEAMANAN.md §4 butir 4 & baris matriks 195) benar-benar
-- ditegakkan pada permintaan nyata.
--
-- ATURAN BACA HASIL: berkas ini LULUS = CACATNYA NYATA (konvensi probe PMB).
-- Bila kelak klien mengikat sesi dan mengirim klaim/header yang dibaca
-- sesi_masih_aktif(), berkas ini WAJIB menjadi MERAH.
-- ============================================================================

-- --- penyiapan sebagai pemilik tabel -------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');

-- Owner memasang PIN 731904 untuk kasir Rina (pengguna …0004)
select public.simpan_pin(
  '731904',
  null,
  '90000000-0000-0000-0000-000000000004',
  'de000000-0000-0000-0000-000000000001',
  'kunci-uji-hp-owner-0123456789'
);

-- hp-kasir (de…003) aktif & mengizinkan peran kasir
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur', 'admin_cabang', 'owner_pusat']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

-- Kosongkan sesi_perangkat penyewa A supaya hitungan benar-benar nol
delete from public.sesi_perangkat
 where penyewa_id = '11111111-1111-1111-1111-111111111111';

-- --- A. login staf dari kursi anon (seperti klien, auth.ts) --------------
select uji.klaim(null);
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '731904',
    'de000000-0000-0000-0000-000000000003'::uuid,
    'HP Kasir',
    'kunci-uji-hp-kasir-0123456789'
  )->>'berhasil')::boolean,
  true,
  'A: login staf berhasil dari kursi anon (penyiapan sah: persetujuan_perangkat ADA di data-uji.sql:161)'
);

-- --- B. RPC staf dari kursi yang sama harus DITOLAK (kendali) ------------
select uji.harap_gagal_sebab(
  'select public.bayar_pesanan(''e9000000-0000-0000-0000-000000000001''::uuid, ''e9000000-0000-0000-0000-000000000002''::uuid, 0, 0, ''tunai'', null)',
  'permission denied',
  'B (kendali): bayar_pesanan (grant hanya authenticated) DITOLAK dari kursi anon — penolakan karena peran, bukan karena fungsi rusak'
);

reset role;
select uji.klaim(null);

-- --- C. CACAT: sesudah login berhasil, sesi_perangkat tetap KOSONG -------
select uji.sama(
  (select count(*) from public.sesi_perangkat
    where penyewa_id = '11111111-1111-1111-1111-111111111111')::text,
  '0',
  'CACAT NYATA 1: sesudah login staf berhasil, sesi_perangkat tetap KOSONG — klien tidak pernah memanggil ikat_sesi_perangkat'
);

-- --- D. CACAT: kendali sesi per permintaan lolos pada kedudukan nyata ----
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  public.sesi_masih_aktif(),
  true,
  'CACAT NYATA 2: token tanpa klaim session_id/perangkat_id (kedudukan nyata tiap permintaan hari ini) diloloskan sesi_masih_aktif()'
);

select uji.sama(
  public.penyewa_saya(),
  '11111111-1111-1111-1111-111111111111'::uuid,
  'CACAT NYATA 3 (dampak): penyewa_saya() tetap mengembalikan penyewa walau tidak ada sesi terikat sama sekali'
);

reset role;
select uji.klaim(null);

-- --- E. KENDALI NEGATIF 1: klaim asing → kendali menolak ----------------
select uji.klaim(
  '90000000-0000-0000-0000-000000000004',
  '{"session_id":"sess-hakim-tidak-ada-0001"}'::jsonb
);
set local role authenticated;
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'KENDALI NEGATIF 1: dengan klaim session_id yang tidak ada di sesi_perangkat, kendali menolak → fungsi tidak rusak, hanya tidak pernah dipakai'
);
reset role;
select uji.klaim(null);

-- --- F. KENDALI NEGATIF 2: sesi diikat lalu DICABUT → ditolak -----------
-- Bukti bahwa mesin penolakannya nyata: bila sesi benar-benar diikat dan
-- kemudian dicabut, sesi_masih_aktif() menolak. Jadi yang hilang bukan
-- fungsinya, melainkan pemanggilnya (klien) dan penulis klaimnya.
select uji.klaim('90000000-0000-0000-0000-000000000004');
select uji.sama(
  (select (public.ikat_sesi_perangkat(
    'sess-hakim-p1b00-0001',
    'de000000-0000-0000-0000-000000000003'::uuid,
    'kunci-uji-hp-kasir-0123456789',
    '90000000-0000-0000-0000-000000000004'::uuid
  )->>'berhasil')::boolean),
  true,
  'KENDALI NEGATIF 2a: ikat_sesi_perangkat bekerja bila dipanggil (membuktikan RPC-nya hidup)'
);

update public.sesi_perangkat
   set status = 'dicabut'
 where session_id = 'sess-hakim-p1b00-0001';

select uji.klaim(
  '90000000-0000-0000-0000-000000000004',
  '{"session_id":"sess-hakim-p1b00-0001"}'::jsonb
);
set local role authenticated;
select uji.sama(
  public.sesi_masih_aktif(),
  false,
  'KENDALI NEGATIF 2b: sesi yang dicabut DITOLAK — pencabutan seketika hanya berlaku bagi pemanggil yang membawa session_id, dan tidak ada satu pun klien yang melakukannya'
);
reset role;
select uji.klaim(null);
