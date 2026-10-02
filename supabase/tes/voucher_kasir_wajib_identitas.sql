-- ============================================================================
-- UJI SQL: Pelanggan jalur kasir wajib kunci identitas (PMB1-F-038 · K-2)
-- ============================================================================
-- Yang dijaga:
--   1. Pelanggan jalur `kasir` TANPA email dan TANPA nomor HP DITOLAK (RPC maupun
--      INSERT langsung) — tidak ada lagi identitas tanpa kunci.
--   2. Nomor HP yang sama pada satu penyewa hanya bisa menjadi SATU identitas —
--      nama fiktif kedua dengan HP yang sama tidak menghasilkan voucher kedua.
--   3. Nomor HP disimpan dinormalisasi (digit saja).
--   4. Kontrol positif: kasir + HP unik tetap bisa mendaftarkan pelanggan.
-- Jalankan: node alat/uji-sql.mjs supabase/tes/voucher_kasir_wajib_identitas.sql
-- Migrasi berlaku: 0093_pelanggan_kasir_wajib_identitas.sql
-- ============================================================================

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000038',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye uji kasir F-038', 'KASIRF38', 'nominal', 20000, 50000,
  now() - interval '1 hour', now() + interval '1 day', 10, true
);

-- Kasir Rina yang sedang masuk mencatat pelanggan
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 1. Jalur kasir TANPA email & TANPA nomor HP -> DITOLAK
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Pelanggan Tanpa Identitas', null, null, null, true, 'kasir', 'hp-kasir-rina', '10.9.1.1')$$,
  'IDENTITAS_WAJIB',
  'F-038: klaim voucher lewat kasir tanpa email dan tanpa nomor HP ditolak'
);

-- 2. Kontrol positif: kasir + nomor HP unik -> SUKSES, HP tersimpan sebagai digit
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Pelanggan Sah Kasir', null, '0812-3456-7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.2'
     ) as hasil),
  'F-038: kasir + nomor HP unik tetap bisa mendaftarkan pelanggan'
);
select uji.harap(
  (select telepon from public.pelanggan where telepon = '081234567890') = '081234567890',
  'F-038: nomor HP tersimpan dinormalisasi (digit saja)'
);

-- 3. Nama fiktif BERBEDA dengan nomor HP yang SAMA -> ditolak kunci unik
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Nama Fiktif Kedua', null, '0812.3456.7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.3')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038: identitas kedua dengan nomor HP yang sama tidak bisa lahir'
);
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000038') = 1,
  'F-038: kampanye hanya mengeluarkan satu voucher untuk satu identitas'
);

-- 4. INSERT langsung tanpa jalur apa pun juga tertolak (pagar di tabel, bukan di RPC)
select uji.klaim(null);
select uji.harap_gagal_sebab(
  $$insert into public.pelanggan (penyewa_id, nama, cara_masuk, didaftarkan_oleh, persetujuan_privasi)
    values ('11111111-1111-1111-1111-111111111111', 'Bayangan', 'kasir',
            '90000000-0000-0000-0000-000000000004', true)$$,
  'IDENTITAS_WAJIB',
  'F-038: tabel menolak pelanggan kasir tanpa kunci identitas dari jalur mana pun'
);

-- 5..8. Penyatuan awalan negara (PMB1-F-038 ronde 2 — dikembalikan HAKIM H-F-03.4):
-- nomor yang SAMA dalam bentuk "+62…", "62…", dan "8…" (tanpa nol) harus dianggap
-- SATU identitas; hanya bentuk pertama yang lahir, sisanya ditolak kunci unik.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 5. Bentuk "+62 812-3456-7890" dari nomor pada kasus 2 -> DITOLAK kunci unik
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Orang Sama Plus Enam Dua', null, '+62 812-3456-7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.4')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038: bentuk +62 dari nomor yang sama tidak melahirkan identitas kedua'
);

-- 6. Bentuk "6281234567890" (tanpa tanda plus) -> DITOLAK kunci unik
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Orang Sama Enam Dua Polos', null, '6281234567890', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.5')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038: bentuk 62… tanpa tanda plus dari nomor yang sama ditolak'
);

-- 7. Bentuk "812-3456-7890" (tanpa nol di depan) -> DITOLAK kunci unik
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Orang Sama Tanpa Nol', null, '812-3456-7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.6')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038: bentuk tanpa nol di depan dari nomor yang sama ditolak'
);

-- 8. Kontrol positif: nomor LAIN yang ditulis berawalan +62 tetap sah dan
--    tersimpan tersatukan menjadi bentuk 0… (bukti normalisasi dua arah)
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Pelanggan Sah Plus Enam Dua', null, '+62 813-9999-8888', null, true, 'kasir', 'hp-kasir-rina', '10.9.1.7'
     ) as hasil),
  'F-038: nomor lain berawalan +62 tetap bisa didaftarkan'
);
select uji.harap(
  (select telepon from public.pelanggan where nama = 'Pelanggan Sah Plus Enam Dua') = '081399998888',
  'F-038: masukan +62 tersimpan tersatukan sebagai bentuk 0…'
);
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000038') = 2,
  'F-038: total tepat dua voucher (dua identitas sah), varian +62 tidak menambah'
);
