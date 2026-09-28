-- ============================================================================
-- UJI: urutan rantai audit (migrasi 0040) — regresi cacat urutan 0029
--
-- Cacat yang ditutup: `waktu` memakai now() = WAKTU MULAI TRANSAKSI, jadi dua
-- baris audit yang ditulis dalam SATU transaksi selalu seri waktunya dan urutan
-- rantai ditentukan oleh UUID acak. Kalau UUID baris kedua lebih kecil, pemeriksa
-- memulai dari baris yang hash_sebelumnya bukan GENESIS → rantai dilaporkan
-- PUTUS padahal tidak ada yang diubah. Peluangnya ~50% per pasangan baris, dan
-- jalur nyata yang menulis lebih dari satu baris per transaksi sudah ada:
-- `keluar_mode_dukungan` (0031) dan `bayar_pesanan` (0039).
--
-- Yang dibuktikan di sini:
--   1. banyak baris audit dalam SATU transaksi → rantai tetap utuh;
--   2. urutan diterbitkan peladen & monotonik (bukan jam, bukan kiriman klien);
--   3. `urutan` yang disebut klien DITIMPA (tidak bisa menyelip ke tengah rantai);
--   4. hash baris lama tetap sah (payload 0029 tidak diubah) — rantai tetap valid;
--   5. jejak yang benar-benar diubah orang tetap TERDETEKSI (pagar tidak tumpul).
-- ============================================================================

-- 1. Lima baris audit ditulis dalam SATU transaksi (jalur peladen, di luar RLS).
--    Semua mendapat `waktu` yang sama persis — persis kondisi yang dulu merusak.
insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, nilai_baru)
values ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000002', 'uji_urutan_1', 'uji', '{"n":1}'::jsonb),
       ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000002', 'uji_urutan_2', 'uji', '{"n":2}'::jsonb),
       ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000002', 'uji_urutan_3', 'uji', '{"n":3}'::jsonb),
       ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000002', 'uji_urutan_4', 'uji', '{"n":4}'::jsonb),
       ('11111111-1111-1111-1111-111111111111', '90000000-0000-0000-0000-000000000002', 'uji_urutan_5', 'uji', '{"n":5}'::jsonb);

-- 2. Semuanya benar-benar berbagi satu stempel waktu (bukti kondisinya tepat).
select uji.sama(
  (select count(distinct waktu) from public.catatan_audit where aksi like 'uji_urutan_%'),
  1::bigint, 'lima baris satu transaksi berbagi satu waktu (now() = waktu mulai transaksi)');

-- 3. Urutan diterbitkan peladen, monotonik, dan mengikuti urutan penulisan.
select uji.sama(
  (select count(*) from public.catatan_audit where aksi like 'uji_urutan_%' and urutan is null),
  0::bigint, 'tidak ada baris tanpa nomor urut');
select uji.sama(
  (select string_agg(aksi, ',' order by urutan) from public.catatan_audit where aksi like 'uji_urutan_%'),
  'uji_urutan_1,uji_urutan_2,uji_urutan_3,uji_urutan_4,uji_urutan_5',
  'urutan penelusuran = urutan penulisan (bukan urutan UUID acak)');
select uji.harap(
  (select count(*) = 5 from (
     select urutan, lag(urutan) over (order by urutan) as sebelum
       from public.catatan_audit where aksi like 'uji_urutan_%') x
    where sebelum is null or urutan > sebelum),
  'nomor urut selalu naik');

-- 4. `urutan` kiriman klien ditimpa peladen (tidak bisa menyelip ke tengah rantai).
insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, urutan, nilai_baru)
values ('11111111-1111-1111-1111-111111111111',
        '90000000-0000-0000-0000-000000000002', 'uji_urutan_selipan', 'uji', 1, '{"n":99}'::jsonb);
select uji.harap(
  (select urutan > (select max(urutan) from public.catatan_audit where aksi = 'uji_urutan_5')
     from public.catatan_audit where aksi = 'uji_urutan_selipan'),
  'urutan yang disebut klien diabaikan — baris baru tetap di ujung rantai');

-- 5. Rantai tetap utuh (inilah asersi yang dulu gagal ~50% tanpa 0040).
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner: boleh membaca audit
set local role authenticated;
select uji.sama(
  (select r.valid from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  true, 'rantai hash utuh walau enam baris berbagi satu stempel waktu');
select uji.sama(
  (select r.pesan from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  'Seluruh rantai audit valid dan tidak terputus.',
  'pemeriksa rantai tidak lagi salah lapor "tautan terputus"');
reset role;

-- 6. Pagar tidak tumpul: jejak yang diputus orang tetap TERDETEKSI. Pemicu 0029
--    menolak UPDATE mutlak, jadi manipulasi dilakukan dengan pemicu dinonaktifkan
--    sementara (pola yang sama dipakai supabase/tes/audit_rantai.sql) — yang diuji
--    di sini kemampuan PEMERIKSA menemukan perubahan, bukan kelemahan pemicunya.
set session_replication_role = 'replica';
update public.catatan_audit
   set hash_sebelumnya = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
       hash_baris      = encode(sha256('putusan-dibuat-untuk-uji'::bytea), 'hex')
 where aksi = 'uji_urutan_selipan';
set session_replication_role = 'origin';

select uji.sama(
  (select r.valid from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  false, 'pemutusan rantai tetap terdeteksi (pagar integritas tidak ikut tumpul)');
select uji.sama(
  (select r.baris_rusak_id from public.verifikasi_rantai_audit('11111111-1111-1111-1111-111111111111') r),
  (select id from public.catatan_audit where aksi = 'uji_urutan_selipan'),
  'pemeriksa menunjuk tepat baris yang diputus');
