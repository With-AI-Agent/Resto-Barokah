-- Probe HAKIM H-F-03.4 (2026-10-02): apakah kunci HP F-038 menyamakan +62 dan 0?
-- Bukan uji resmi Pembangun. Hijau di sini = varian +62 MASIH lolos (celah sisa).
-- Runner selalu ROLLBACK. Tidak menyentuh produksi.

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000062',
  '11111111-1111-1111-1111-111111111111',
  'Probe +62 F-038', 'PLUS62', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 10, true
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000062',
       'Orang Pertama', null, '081234567890', null, true, 'kasir', 'hp-probe', '10.9.9.1'
     ) as hasil),
  'probe: HP 0812… pertama berhasil'
);

-- Varian yang komentar migrasi 0093 klaim sudah disatukan.
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000062',
       'Orang Kedua', null, '+62 812-3456-7890', null, true, 'kasir', 'hp-probe', '10.9.9.2'
     ) as hasil),
  'probe: +62 812… DITERIMA sebagai identitas kedua (celah bila hijau)'
);
