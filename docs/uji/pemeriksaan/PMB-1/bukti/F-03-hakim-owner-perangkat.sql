-- Probe HAKIM H-F-03 (baca-saja; PGlite lokal; runner selalu ROLLBACK; tidak menyentuh produksi).
-- Jalankan dari akar repo: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-03-hakim-owner-perangkat.sql
-- Sengaja menegaskan perilaku cacat (probe hijau = kelemahan masih ada), BUKAN uji regresi keamanan.
-- Prasyarat runner: fixture tenant Kedai Oasis di alat/sql/data-uji.sql; semua migrasi berlaku diterapkan.
--
-- Yang dibuktikan (dari peran PUBLIK tanpa JWT, seperti penyerang di browser mana pun):
--   A. F-036 — owner + PIN benar dari perangkat tak dikenal (UUID acak) DILAYANI dan perangkatnya
--      didaftarkan sendiri oleh RPC (0087 baris 172–174, 207–225).
--   B. F-039 — dari perangkat asing: PIN BENAR dijawab 'PERANGKAT_TIDAK_SAH' (JSON), sedangkan
--      PIN SALAH MELEDAK galat FK (percobaan_pin.perangkat_id) — dua jawaban berbeda = orakel PIN,
--      dan penolakan TIDAK LAGI SERAGAM seperti janji penutupan temuan lama K F-03 / B F-11.

-- 0. PIN owner & kasir dipasang sebagai pemilik tabel (klien tidak boleh menyentuh tabel ini).
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
select uji.harap(
  (select pin_hash ~ '^\$[a-z0-9]+\$' from public.kredensial_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000002'),
  'persiapan: hash PIN owner berbentuk bcrypt yang sah'
);

-- Seluruh panggilan berikut dari peran publik TANPA JWT.
select uji.klaim(null);
set local role anon;

-- A. F-036: owner + PIN benar dari perangkat tak dikenal → pemanggil dilayani?
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'deadbeef-0000-4000-8000-000000000001', 'Perangkat Penyerang', null
  )->>'berhasil')::boolean is true,
  'F-036: anon dari perangkat tak dikenal masuk sebagai OWNER (perangkat didaftarkan sendiri)'
);

-- B. F-039: resto kini punya perangkat aktif (dari langkah A) → kasir dari perangkat asing:
select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205', 'deadbeef-0000-4000-8000-000000000002', 'Asing-Satu', null
  )->>'kode'),
  'PERANGKAT_TIDAK_SAH',
  'F-039: PIN BENAR dari perangkat asing dijawab JSON PERANGKAT_TIDAK_SAH'
);
-- PIN SALAH dari perangkat asing: bukan jawaban seragam, melainkan galat basis data (FK percobaan_pin).
select uji.harap_gagal_sebab(
  $$select public.verifikasi_pin_perangkat(
      'kasir.a1@contoh.test', '000000', 'deadbeef-0000-4000-8000-000000000003', 'Asing-Dua', null)$$,
  'percobaan_pin',
  'F-039: PIN SALAH dari perangkat asing MELEMPAR galat FK (bukan KREDENSIAL_TIDAK_VALID) — jawaban berbeda dari PIN benar'
);

-- C. F-039 lanjutan: apakah batas 5×/akun masih bisa aktif bagi penyerang yang memutar UUID?
--    Enam percobaan PIN salah berturut-turut dari enam UUID perangkat berbeda.
do $$
declare
  i int;
  v_err int := 0;
begin
  for i in 1..6 loop
    begin
      perform public.verifikasi_pin_perangkat(
        'kasir.a1@contoh.test', '000000',
        ('deadbeef-0000-4000-8000-0000000002' || lpad(i::text, 2, '0'))::uuid,
        'Putar-' || i, null);
    exception when others then
      v_err := v_err + 1;
    end;
  end loop;
  perform uji.harap(v_err = 6,
    'F-039: 6 percobaan PIN salah dari 6 UUID berbeda SEMUANYA meledak galat — bukan jawaban AKUN_TERKUNCI');
end $$;

reset role;
select uji.harap(
  (select count(*) from public.percobaan_pin
    where pengguna_id = '90000000-0000-0000-0000-000000000004') = 0,
  'F-039: tidak satu pun percobaan gagal tercatat — batas 5×/akun tidak pernah bisa aktif bagi pola ini'
);
select uji.harap(
  (select count(*) from public.perangkat
    where id = 'deadbeef-0000-4000-8000-000000000001' and aktif) = 1,
  'F-036: perangkat penyerang benar-benar tersimpan AKTIF tanpa persetujuan pemilik'
);
