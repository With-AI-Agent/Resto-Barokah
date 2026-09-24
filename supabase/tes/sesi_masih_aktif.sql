-- ============================================================================
-- UJI: sesi_masih_aktif() + periksa_sesi_aman() (N F-03 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-03: pencabutan sesi tidak阻断 permintaan
--     berikutnya. Migrasi 0058 menambah helper & RPC publik.
-- ============================================================================

-- 1. session_id kosong → FALSE.
select uji.harap(
  public.sesi_masih_aktif('') is false,
  'sesi_masih_aktif(""): FALSE'
);

select uji.harap(
  public.sesi_masih_aktif(null::text) is false,
  'sesi_masih_aktif(null): FALSE'
);

-- 2. session_id tidak ada di tabel → FALSE.
select uji.harap(
  public.sesi_masih_aktif('session-tidak-ada') is false,
  'sesi_masih_aktif(session tak dikenal): FALSE'
);

-- 3. Buat sesi aktif (peran kasir → umur 12 jam).
--    Cabang & pengguna harus lebih dulu agar FK perangkat terpenuhi.
--    auth.users juga harus ada karena public.pengguna.id REFERENCES auth.users.id.
do $$
declare
  v_pengguna_id uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_cabang_id uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
begin
  -- auth.users dummy
  insert into auth.users (id, email) values
    (v_pengguna_id, 'kasir-uji@uji.local')
  on conflict do nothing;

  insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif)
  values (v_pengguna_id, '11111111-1111-1111-1111-111111111111',
          'Kasir Uji', 'kasir-uji@uji.local', 'kasir', true)
  on conflict do nothing;

  insert into public.cabang (id, penyewa_id, nama)
  values (v_cabang_id, '11111111-1111-1111-1111-111111111111', 'Cabang Uji')
  on conflict do nothing;

  insert into public.kredensial_pin (pengguna_id, pin_hash)
  values (v_pengguna_id, '$tiruan$10$abc')
  on conflict do nothing;
end $$;

insert into public.perangkat (id, penyewa_id, cabang_id, nama, peran_diizinkan, aktif, didaftarkan_oleh)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'Perangkat Uji 1', array['kasir']::text[], true,
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');

insert into public.sesi_perangkat (
  session_id, penyewa_id, perangkat_id, pengguna_id, cabang_id, mulai, berakhir_pada, status
) values (
  'session-uji-aktif-1',
  '11111111-1111-1111-1111-111111111111',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'cccccccc-cccc-cccc-cccc-cccccccccccc',
  now(),
  now() + interval '12 hours',
  'aktif'
);

select uji.harap(
  public.sesi_masih_aktif('session-uji-aktif-1') is true,
  'sesi_masih_aktif(session aktif): TRUE'
);

-- 4. RPC periksa_sesi_aman untuk sesi aktif → aktif=TRUE.
select uji.harap(
  (public.periksa_sesi_aman('session-uji-aktif-1')->>'aktif')::boolean = true,
  'periksa_sesi_aman(session aktif): aktif=true'
);

-- 5. Sesi dicabut → FALSE.
update public.sesi_perangkat
   set status = 'dicabut'
 where session_id = 'session-uji-aktif-1';

select uji.harap(
  public.sesi_masih_aktif('session-uji-aktif-1') is false,
  'sesi_masih_aktif(session dicabut): FALSE'
);

select uji.harap(
  (public.periksa_sesi_aman('session-uji-aktif-1')->>'aktif')::boolean = false,
  'periksa_sesi_aman(session dicabut): aktif=false'
);

select uji.harap(
  (public.periksa_sesi_aman('session-uji-aktif-1')->>'kode') = 'SESI_DICABUT',
  'periksa_sesi_aman(session dicabut): kode=SESI_DICABUT'
);

-- 6. Sesi kedaluwarsa → FALSE.
update public.sesi_perangkat
   set status = 'aktif',
       berakhir_pada = now() - interval '1 minute'
 where session_id = 'session-uji-aktif-1';

select uji.harap(
  public.sesi_masih_aktif('session-uji-aktif-1') is false,
  'sesi_masih_aktif(session kedaluwarsa): FALSE'
);

select uji.harap(
  (public.periksa_sesi_aman('session-uji-aktif-1')->>'kode') = 'SESI_KEDALUWARSA',
  'periksa_sesi_aman(session kedaluwarsa): kode=SESI_KEDALUWARSA'
);

-- 7. periksa_sesi_aman() tanpa argumen, dengan session_id dari klaim JWT.
--    Di PGlite, klaim kosong → "SESI_TIDAK_ADA".
select set_config('request.jwt.claim.session_id', '', true);

select uji.harap(
  (public.periksa_sesi_aman()->>'kode') = 'SESI_TIDAK_ADA',
  'periksa_sesi_aman() tanpa argumen & klaim kosong: kode=SESI_TIDAK_ADA'
);

-- 8. periksa_sesi_aman() dengan klaim JWT valid.
select set_config('request.jwt.claim.session_id', 'session-uji-aktif-1', true);

select uji.harap(
  (public.periksa_sesi_aman()->>'kode') in ('SESI_AKTIF', 'SESI_DICABUT', 'SESI_KEDALUWARSA'),
  'periksa_sesi_aman() dengan klaim: kode sesi'
);

-- Cleanup
delete from public.sesi_perangkat where session_id = 'session-uji-aktif-1';
delete from public.perangkat where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
