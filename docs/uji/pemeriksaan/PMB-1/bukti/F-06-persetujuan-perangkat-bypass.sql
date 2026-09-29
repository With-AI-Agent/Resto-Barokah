-- Uji coba independen F-06: Membuktikan RPC verifikasi_pin_perangkat tidak memeriksa persetujuan_perangkat
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-06-persetujuan-perangkat-bypass.sql

-- Owner memasang PIN '516372' untuk kasir Rina
select uji.klaim('90000000-0000-0000-0000-000000000002');
select public.simpan_pin(
  '516372',
  null,
  '90000000-0000-0000-0000-000000000004',
  'de000000-0000-0000-0000-000000000001',
  'kunci-uji-hp-owner-0123456789'
);

-- Pastikan perangkat kasir aktif
update public.perangkat
   set aktif = true,
       status = 'aktif',
       peran_diizinkan = array['kasir', 'pelayan', 'dapur']::text[]
 where id = 'de000000-0000-0000-0000-000000000003';

-- Pastikan tabel persetujuan_perangkat kosong untuk Kasir Rina dan Perangkat Kasir ini
delete from public.persetujuan_perangkat
 where pengguna_id = '90000000-0000-0000-0000-000000000004'
   and perangkat_id = 'de000000-0000-0000-0000-000000000003';

-- Panggil verifikasi_pin_perangkat sebagai anon (sebagaimana klien memanggilnya saat login staf)
select uji.klaim(null);
set local role anon;

select uji.sama(
  (public.verifikasi_pin_perangkat(
    'kasir.a1@contoh.test',
    '516372',
    'de000000-0000-0000-0000-000000000003'::uuid,
    'Tablet Kasir',
    'kunci-uji-hp-kasir-0123456789'
  )->>'berhasil')::boolean,
  true,
  'Terbukti: Staf berhasil masuk tanpa persetujuan_perangkat (bypass)'
);
