-- ============================================================================
-- UJI SQL: Peran berkuasa tidak mendaftarkan perangkat asing sendiri
--            (PMB1-F-036 · K-1 · keputusan Lee B 2026-09-30)
-- ============================================================================
-- Yang dijaga:
--   1. Bawaan saklar `izin_daftar_perangkat_bebas_peran_berkuasa` = MATI.
--   2. Dengan saklar mati: owner_pusat/pemilik_platform dari UUID perangkat yang
--      tidak dikenal DITOLAK (PERANGKAT_BELUM_DISETUJUI) dan TIDAK ada baris
--      perangkat baru yang tersimpan.
--   3. Dengan saklar HIDUP: perilaku lama pulih persis (auto-provisioning) —
--      ini yang dipakai Lee kalau memang ingin mendaftarkan perangkatnya sendiri.
--   4. Staf biasa pada penyewa tanpa perangkat aktif tetap boleh mendaftarkan
--      perangkat pertama (cara masuk kasir tidak berubah).
--   5. Perangkat yang sudah terdaftar tidakSage terpengaruh oleh saklar.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/daftar_perangkat_beru_peran_berkuasa.sql
-- Migrasi berlaku: 0090_saklar_daftar_perangkat_beru_peran_berkuasa.sql
-- ============================================================================

-- PIN owner & kasir dipasang sebagai pemilik tabel (klien tidak boleh menyentuh tabel ini).
delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000004', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

-- 1. Bawaan saklar harus MATI untuk setiap penyewa
select uji.harap(
  (select bool_and(not izin_daftar_perangkat_bebas_peran_berkuasa) from public.pengaturan),
  'F-036: saklar pendaftaran bebas peran berkuasa dibawa MATI di semua penyewa'
);

-- 1b. Prasyarat eksplisit PMB1-F-063: penyewa ini SUDAH punya perangkat aktif —
--     justru dalam keadaan begitu pendaftaran mandiri owner UUID asing ditolak.
select uji.harap(
  (select count(*) from public.perangkat
    where penyewa_id = '11111111-1111-1111-1111-111111111111' and aktif = true) >= 1,
  'F-063: penyewa sudah punya perangkat aktif — owner tetap tidak bisa mendaftarkan UUID asing (saklar mati)'
);

-- Seluruh panggilan berikutnya dari peran publik tanpa JWT (penyerang di peramban mana pun)
select uji.klaim(null);
set local role anon;

-- 2. Saklar mati: owner + PIN benar dari UUID asing -> DITOLAK, tidak didaftarkan
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'f0360000-0000-4000-8000-000000000001', 'Perangkat Penyerang', null
  )->>'kode') = 'PERANGKAT_BELUM_DISETUJUI',
  'F-036: peran berkuasa tidak boleh mendaftarkan UUID perangkat asing sendiri (saklar mati)'
);

reset role;
select uji.harap(
  (select count(*) from public.perangkat where id = 'f0360000-0000-4000-8000-000000000001') = 0,
  'F-036: UUID penyerang TIDAK tersimpan sebagai perangkat sah'
);

-- 2b. Kasir biasa pada penyewa yang sudah punya perangkat aktif juga tetap ditolak
--     (perilaku lama dipertahankan — saklar ini khusus peran berkuasa)
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test', '739205', 'f0360000-0000-4000-8000-000000000002', 'Asing-Kasir', null
  )->>'kode') = 'PERANGKAT_TIDAK_SAH',
  'F-036: kasir biasa dari perangkat asing tetap ditolak seperti sebelumnya'
);

-- 3. Saklar HIDUP -> perilaku lama pulih (kontrol: switch benar-benar mengendalikan)
reset role;
update public.pengaturan
   set izin_daftar_perangkat_bebas_peran_berkuasa = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null);
set local role anon;

select uji.harap(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'f0360000-0000-4000-8000-000000000003', 'Perangkat Owner Dipersetujui', null
  )->>'berhasil')::boolean,
  'F-036: saklar hidup -> owner boleh mendaftarkan perangkatnya sendiri seperti sebelumnya'
);
reset role;
select uji.harap(
  (select count(*) from public.perangkat where id = 'f0360000-0000-4000-8000-000000000003' and aktif) = 1,
  'F-036: perangkat pun benar-benar tersimpan saat saklar hidup'
);

-- 5. Perangkat yang SUDAH terdaftar tetap masuk tanpa hambatan baru (saklar dimatikan lagi)
update public.pengaturan
   set izin_daftar_perangkat_bebas_peran_berkuasa = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'f0360000-0000-4000-8000-000000000003', 'Perangkat Owner Dipersetujui', null
  )->>'kode') = 'LOGIN_SUKSES',
  'F-036: perangkat yang sudah terdaftar tetap bisa dipakai meski saklar mati'
);

-- 4. Staf biasa, penyewa tanpa perangkat aktif -> perangkat pertama tetap boleh didaftarkan
reset role;
insert into public.penyewa (id, nama, slug, zona_waktu)
values ('f0360000-0000-0000-0000-0000000bbbbb', 'Resto Uji F-036', 'uji-f036', 'Asia/Jakarta')
on conflict (id) do nothing;
insert into auth.users (id, email)
values ('f0360000-0000-0000-0000-0000000ccccc', 'kasir.uji.f036@contoh.test')
on conflict (id) do nothing;
insert into public.pengguna (id, penyewa_id, nama, email, peran)
values ('f0360000-0000-0000-0000-0000000ccccc', 'f0360000-0000-0000-0000-0000000bbbbb',
        'Kasir Uji', 'kasir.uji.f036@contoh.test', 'kasir')
on conflict (id) do nothing;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('f0360000-0000-0000-0000-0000000ccccc', crypt('739205', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;
insert into public.pengaturan (penyewa_id) values ('f0360000-0000-0000-0000-0000000bbbbb')
on conflict (penyewa_id) do nothing;

select uji.klaim(null);
set local role anon;
select uji.harap(
  (public.verifikasi_pin_perangkat(
    'kasir.uji.f036@contoh.test', '739205', 'f0360000-0000-4000-8000-000000000004', 'HP Kasir Pertama', null
  )->>'berhasil')::boolean,
  'F-036: kasir pada penyewa tanpa perangkat aktif tetap bisa mendaftarkan perangkat pertama'
);
