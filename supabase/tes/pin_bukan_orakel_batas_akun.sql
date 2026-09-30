-- ============================================================================
-- UJI SQL: PIN bukan orakel & batas percobaan per akun selalu hidup
--            (PMB1-F-039 · K-2)
-- ============================================================================
-- Yang dijaga:
--   1. Perangkat asing: PIN BENAR dan PIN SALAH mendapat jawaban yang SAMA
--      (tidak meledak galat FK, tidak membocorkan apakah PIN benar).
--   2. Setiap penolakan dicatat sebagai percobaan (dengan perangkat_id null bila
--      perangkat memang tidak ada) sehingga batas 5x/akun benar-benar menyala
--      walau penyerang memutar-mutar UUID.
--   3. Setelah batas terlampaui, jawabannya AKUN_TERKUNCI (bukan galat).
--   4. Perangkat yang sudah terdaftar & aktif tetap masuk seperti biasa.
--   5. Perangkat yang dicabut ditolak dengan jawaban yang sama apakah PIN-nya benar.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/pin_bukan_orakel_batas_akun.sql
-- Migrasi berlaku: 0091_pin_bukan_orakel_batas_akun.sql
-- ============================================================================

delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- Panggilan dari peran publik tanpa JWT (penyerang di peramban mana pun)
select uji.klaim(null);
set local role anon;

-- 1. PIN BENAR dari UUID asing
drop table if exists temp_orakel_benar;
create temporary table temp_orakel_benar as
select public.verifikasi_pin_perangkat(
  'kasir.a1@contoh.test', '739205', 'f0390000-0000-4000-8000-000000000001', 'Asing-Benar', null
) as res;

-- PIN SALAH dari UUID asing — TIDAK BOLEH meledak galat basis data
drop table if exists temp_orakel_salah;
create temporary table temp_orakel_salah as
select public.verifikasi_pin_perangkat(
  'kasir.a1@contoh.test', '000000', 'f0390000-0000-4000-8000-000000000002', 'Asing-Salah', null
) as res;

select uji.sama(
  (select res->>'kode' from temp_orakel_benar),
  (select res->>'kode' from temp_orakel_salah),
  'F-039: PIN benar dan PIN salah dari perangkat asing mendapat jawaban SERAGAM (bukan orakel PIN)'
);
select uji.sama(
  (select res->>'pesan' from temp_orakel_benar),
  (select res->>'pesan' from temp_orakel_salah),
  'F-039: pesan penolakan juga sama persis'
);
select uji.sama(
  (select res->>'berhasil' from temp_orakel_salah),
  'false',
  'F-039: penolakan PIN salah dari perangkat asing berupa JSON, bukan galat FK'
);

-- 2. Penolakan dari UUID asing TERCATAT (batas per akun jadi hidup)
reset role;
select uji.harap(
  (select count(*) from public.percobaan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000004' and not berhasil) = 2,
  'F-039: kedua penolakan tercatat sebagai percobaan gagal'
);
select uji.harap(
  (select count(*) from public.percobaan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000004'
      and not berhasil
      and perangkat_id is null) = 2,
  'F-039: UUID asing tidak dipaksakan ke kolom perangkat (dicecat null, bukan galat FK)'
);

-- 3. Batas 5x/akun: sudah ada 2 penolakan, lalu 4 percobaan lagi dari UUID berbeda
--    -> percobaan ke-6 harus sudah AKUN_TERKUNCI
select uji.klaim(null);
set local role anon;
do $$
declare
  i integer;
  v_kode text;
begin
  for i in 1..4 loop
    v_kode := public.verifikasi_pin_perangkat(
      'kasir.a1@contoh.test', '000000',
      ('f0390000-0000-4000-8000-00000000001' || i::text)::uuid,
      'Putar-' || i, null
    )->>'kode';
  end loop;

  perform uji.sama(
    v_kode, 'AKUN_TERKUNCI',
    'F-039: batas 5x/akun menyala untuk pola putar-UUID (tidak lagi lolos tanpa jejak)');
end $$;

-- 4. Perangkat terdaftar & aktif tetap bisa masuk
reset role;
delete from public.percobaan_pin;
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205', 'de000000-0000-0000-0000-000000000003', 'hp-kasir', null
  )->>'kode') = 'LOGIN_SUKSES',
  'F-039: perangkat kasir yang sah tetap bisa login dengan PIN benar'
);

-- 5. Perangkat dicabut: jawaban sama apakah PIN benar atau salah
reset role;
update public.perangkat set aktif = false where id = 'de000000-0000-0000-0000-000000000003';
delete from public.percobaan_pin;
select uji.klaim(null);
set local role anon;
select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205', 'de000000-0000-0000-0000-000000000003', 'hp-kasir', null
  )->>'kode'),
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '000000', 'de000000-0000-0000-0000-000000000003', 'hp-kasir', null
  )->>'kode'),
  'F-039: perangkat dicabut dijawab sama untuk PIN benar maupun PIN salah'
);
