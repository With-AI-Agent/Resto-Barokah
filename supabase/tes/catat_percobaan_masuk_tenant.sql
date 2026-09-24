-- ============================================================================
-- UJI: catat_percobaan_masuk() divalidasi tenant (N F-05 audit 2026-09-24)
-- ============================================================================

-- 1. service_role: p_penyewa_id bebas → BOLEH
select set_config('request.jwt.claim.role', 'service_role', false);
select public.catat_percobaan_masuk(
  '11111111-1111-1111-1111-111111111111'::uuid,
  null, null, false, 'uji service_role'
);

select uji.harap(
  (select count(*)::integer from public.percobaan_masuk
   where sebab = 'uji service_role') >= 1,
  'service_role boleh catat percobaan_masuk lintas tenant'
);

delete from public.percobaan_masuk where sebab = 'uji service_role';

-- Setup pengguna uji
do $$
declare
  v_pengguna_id uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
begin
  insert into auth.users (id, email) values
    (v_pengguna_id, 'kasir-uji@uji.local')
  on conflict do nothing;

  insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif)
  values (v_pengguna_id, '11111111-1111-1111-1111-111111111111',
          'Kasir Uji', 'kasir-uji@uji.local', 'kasir', true)
  on conflict do nothing;

  insert into public.kredensial_pin (pengguna_id, pin_hash)
  values (v_pengguna_id, '$tiruan$10$abc')
  on conflict do nothing;
end $$;

-- 2. authenticated dengan p_penyewa_id cocok → BOLEH
select set_config('request.jwt.claim.sub',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', false);
select set_config('request.jwt.claim.role', 'authenticated', false);

select public.catat_percobaan_masuk(
  '11111111-1111-1111-1111-111111111111'::uuid,
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid,
  null, true, 'uji authenticated cocok'
);

select uji.harap(
  (select count(*)::integer from public.percobaan_masuk
   where sebab = 'uji authenticated cocok') >= 1,
  'authenticated dengan p_penyewa_id cocok: BOLEH'
);

delete from public.percobaan_masuk where sebab = 'uji authenticated cocok';

-- 3. authenticated lintas tenant → DITOLAK
select uji.harap_gagal_sebab(
  $$ select public.catat_percobaan_masuk(
       '99999999-9999-9999-9999-999999999999'::uuid,
       null, null, false, 'uji lintas tenant'
     ) $$,
  'lintas-tenant',
  'authenticated dengan p_penyewa_id lintas tenant: DITOLAK'
);

-- 4. authenticated p_penyewa_id NULL → DITOLAK
select uji.harap_gagal_sebab(
  $$ select public.catat_percobaan_masuk(
       null, null, null, false, 'uji null tenant'
     ) $$,
  'p_penyewa_id wajib diisi',
  'authenticated dengan p_penyewa_id NULL: DITOLAK'
);
