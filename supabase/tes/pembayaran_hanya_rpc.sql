-- UJI: INSERT ke public.pembayaran HANYA lewat RPC (M F-01 audit 2026-09-24)
select uji.harap(
  not exists(select 1 from pg_policies
             where schemaname = 'public'
               and tablename = 'pembayaran'
               and policyname = 'pembayaran_tambah'),
  'Policy pembayaran_tambah sudah dihapus dari tabel pembayaran'
);

select uji.harap(
  exists(select 1 from pg_trigger
         where tgname = 'aa_pembayaran_cegah_insert_langsung'),
  'Trigger aa_pembayaran_cegah_insert_langsung aktif pada pembayaran'
);

select set_config('request.jwt.claim.role', 'anon', false);
select set_config('request.jwt.claim.sub', '', false);

select uji.harap_gagal_sebab(
  $$ insert into public.pembayaran
       (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah)
     values ('00000000-0000-0000-0000-000000000000',
             '00000000-0000-0000-0000-000000000000',
             'Tunai', 'tunai', 1000) $$,
  'Pesanan tidak ditemukan|Metode bayar|INSERT langsung|permission denied',
  'INSERT langsung sebagai anon: DITOLAK'
);

do $$
declare
  v_pengguna_id uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_cabang_id uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  v_pesanan_id uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';
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

  insert into public.cabang (id, penyewa_id, nama) values
    (v_cabang_id, '11111111-1111-1111-1111-111111111111', 'Cabang Uji')
  on conflict do nothing;

  insert into public.pengguna_cabang (pengguna_id, cabang_id)
  values (v_pengguna_id, v_cabang_id)
  on conflict do nothing;

  insert into public.metode_bayar (id, penyewa_id, nama, jenis, aktif, urutan)
  values ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
          '11111111-1111-1111-1111-111111111111',
          'Tunai', 'tunai', true, 1)
  on conflict do nothing;

  insert into public.pesanan (id, penyewa_id, cabang_id, nomor,
                              pelayan_id, kasir_id, status, total,
                              kunci_idempoten, dibuat_pada)
  values (v_pesanan_id, '11111111-1111-1111-1111-111111111111',
          v_cabang_id, 60000,
          v_pengguna_id, v_pengguna_id, 'draf', 10000,
          'kunci-uji-0060-' || v_pesanan_id::text, now())
  on conflict do nothing;
end $$;

select set_config('request.jwt.claim.sub',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', false);
select set_config('request.jwt.claim.role', 'authenticated', false);

select uji.harap_gagal_sebab(
  $$ insert into public.pembayaran
       (pesanan_id, metode_id, metode_nama_saat_itu, jenis_saat_itu, jumlah, kasir_id)
     values ('dddddddd-dddd-dddd-dddd-dddddddddddd',
             'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
             'Tunai', 'tunai', 10000,
             'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') $$,
  'Pesanan tidak ditemukan|Metode bayar|INSERT langsung',
  'INSERT langsung sebagai authenticated: DITOLAK'
);
