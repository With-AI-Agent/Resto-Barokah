-- Probe HAKIM H-F-03.4: jalur owner, PIN benar vs PIN salah dari UUID asing.
-- Hijau = kedua jawaban sama dan bukan login sukses (orakel tertutup).
-- Runner selalu ROLLBACK.

delete from public.percobaan_pin;
insert into public.kredensial_pin (pengguna_id, pin_hash)
values ('90000000-0000-0000-0000-000000000002', crypt('481516', gen_salt('bf')))
on conflict (pengguna_id) do update set pin_hash = excluded.pin_hash;

select uji.klaim(null);
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'f0390000-0000-4000-8000-0000000000aa', 'Asing-Owner-Benar', null
  )->>'kode'),
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '000000', 'f0390000-0000-4000-8000-0000000000bb', 'Asing-Owner-Salah', null
  )->>'kode'),
  'F-039 owner: PIN benar dan PIN salah dari UUID asing dijawab sama'
);
select uji.sama(
  (public.verifikasi_pin_perangkat(
    'owner.a@contoh.test', '481516', 'f0390000-0000-4000-8000-0000000000cc', 'Asing-Owner-Benar-2', null
  )->>'kode'),
  'PERANGKAT_BELUM_DISETUJUI',
  'F-036 owner: PIN benar dari UUID asing bukan login sukses'
);
