-- Probe HAKIM H-F-03.5 (2026-10-02) — PMB1-F-038 SESUDAH migrasi 0095 (perbaikan 18bd3a7, kartu B-F-03.2).
-- PERTANYAAN : apakah SATU nomor HP yang ditulis dengan cara lain masih melahirkan pelanggan KEDUA
--              (dan voucher kedua) pada kampanye yang sama?
-- CARA BACA  : konvensi PMB — HIJAU (LULUS) = celah HIDUP. Sesudah perbaikan yang benar berkas ini GAGAL
--              pada pasangan CELAH pertama yang sudah tertutup (RPC melempar galat kunci unik, bukan lagi
--              menerbitkan voucher kedua). Matriks lengkap: H-F-03.5-matriks-varian-nomor.sql.
-- KONTROL    : positif  = nomor dasar sah diterima;
--              negatif  = bentuk yang DICAKUP 0095 (+62, 62, tanpa nol) memang ditolak kunci unik,
--                         jadi probe ini memanggil pagar 0095 yang asli dan bukan data uji yang rusak.
-- KURSI      : kasir Rina (90000000-0000-0000-0000-000000000004) lewat RPC asli public.daftar_voucher.
-- Runner selalu ROLLBACK. Tidak menyentuh produksi. Bukan uji resmi Pembangun.

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000501',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye probe H-F-03.5', 'PROBE5', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 100, true
);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- KONTROL POSITIF: nomor dasar yang sah diterima
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000501',
       'Orang Dasar', null, '0812-3456-7890', null, true, 'kasir', 'hp-probe', '10.5.0.1'
     ) as hasil),
  'kontrol positif: nomor 0812-3456-7890 diterima'
);

-- KONTROL NEGATIF: tiga bentuk yang DICAKUP 0095 ditolak kunci unik (pagar hidup)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000501',
       'Kembar +62', null, '+62 812-3456-7890', null, true, 'kasir', 'hp-probe', '10.5.0.2')$$,
  'pelanggan_penyewa_telepon_unik',
  'kontrol negatif: +62 812-3456-7890 ditolak'
);
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000501',
       'Kembar 62', null, '62 812 3456 7890', null, true, 'kasir', 'hp-probe', '10.5.0.3')$$,
  'pelanggan_penyewa_telepon_unik',
  'kontrol negatif: 62 812 3456 7890 ditolak'
);
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000501',
       'Kembar 8', null, '812 3456 7890', null, true, 'kasir', 'hp-probe', '10.5.0.4')$$,
  'pelanggan_penyewa_telepon_unik',
  'kontrol negatif: 812 3456 7890 ditolak'
);

-- CELAH: tiap pasangan memakai nomor dasar SENDIRI (agar tidak saling bertabrakan).
-- Dasar diterima (kontrol), lalu penulisan lain dari nomor yang SAMA juga diterima (celah).
do $$
declare
  r record;
  v_dasar boolean;
  v_kembar boolean;
begin
  for r in
    select * from (values
      (1, '0811-1111-0001', '+62 (0)811-1111-0001', 'kurung-nol: +62 (0)…'),
      (2, '0811-1111-0002', '+62 0811 1111 0002',   'nol dipertahankan sesudah +62'),
      (3, '0811-1111-0003', '0062 811 1111 0003',   'awalan internasional 00: 0062 …'),
      (4, '0811-1111-0004', '0062-0811-1111-0004',  '0062 dengan nol dipertahankan'),
      (5, '021-5790-1230',  '+62 (0)21 5790 1230',  'telepon rumah: kurung-nol'),
      (6, '021-5790-1231',  '21 5790 1231',         'telepon rumah tanpa nol di depan')
    ) as t(no, dasar, kembar, label)
  loop
    select (hasil->>'berhasil')::boolean into v_dasar
      from public.daftar_voucher(
        '11111111-1111-1111-1111-111111111111',
        'c3000000-0000-0000-0000-000000000501',
        'Dasar ' || r.no, null, r.dasar, null, true, 'kasir', 'hp-probe', ('10.5.1.' || r.no)
      ) as hasil;
    perform uji.harap(v_dasar, 'kontrol positif ' || r.no || ': nomor dasar ' || r.dasar || ' diterima');

    select (hasil->>'berhasil')::boolean into v_kembar
      from public.daftar_voucher(
        '11111111-1111-1111-1111-111111111111',
        'c3000000-0000-0000-0000-000000000501',
        'Kembaran ' || r.no, null, r.kembar, null, true, 'kasir', 'hp-probe', ('10.5.2.' || r.no)
      ) as hasil;
    perform uji.harap(v_kembar, 'CELAH ' || r.no || ': ' || r.label || ' diterima sebagai identitas kedua');
  end loop;
end $$;

-- AKIBAT: 1 (dasar kontrol) + 6 x 2 = 13 voucher untuk hanya 7 nomor yang berbeda.
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000501') = 13,
  'akibat: kampanye mengeluarkan 13 voucher untuk 7 nomor (6 nomor mendapat DUA voucher)'
);
