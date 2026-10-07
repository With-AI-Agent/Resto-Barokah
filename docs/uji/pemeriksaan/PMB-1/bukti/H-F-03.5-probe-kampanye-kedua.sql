-- Probe HAKIM H-F-03.5 (2026-10-02) — pelanggan jalur kasir (HANYA nomor HP) yang SAMA datang lagi
-- untuk kampanye BERBEDA, sesudah indeks unik 0093 + pemicu 0095.
-- BASELINE   : PRD M10 baris 170 dan aturan bisnis 6 baris 266 — "satu voucher per identitas per KAMPANYE":
--              identitas yang sama BOLEH punya voucher dari kampanye lain.
-- CARA BACA  : konvensi PMB — HIJAU (LULUS) = celah HIDUP: kampanye kedua untuk pelanggan HP-saja yang sama
--              berakhir galat mentah `pelanggan_penyewa_telepon_unik` (bukan voucher, bukan pesan ramah).
-- KONTROL    : positif  = kampanye pertama berhasil;
--              negatif  = pelanggan yang sama BERE-MAIL (jalur lain di RPC yang sama) menerima kampanye kedua
--                         dan, untuk kampanye yang sama, jawaban ramah VOUCHER_SUDAH_DIKLAIM — jadi galat di atas
--                         berasal dari jalur HP-saja, bukan dari data uji.
-- KURSI      : kasir Rina lewat RPC asli public.daftar_voucher. Runner selalu ROLLBACK.

insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values
  ('c3000000-0000-0000-0000-000000000601', '11111111-1111-1111-1111-111111111111',
   'Kampanye A probe H-F-03.5', 'KAMPA5', 'nominal', 20000, 50000,
   now() - interval '1 hour', now() + interval '1 day', 100, true),
  ('c3000000-0000-0000-0000-000000000602', '11111111-1111-1111-1111-111111111111',
   'Kampanye B probe H-F-03.5', 'KAMPB5', 'nominal', 20000, 50000,
   now() - interval '1 hour', now() + interval '1 day', 100, true),
  ('c3000000-0000-0000-0000-000000000603', '11111111-1111-1111-1111-111111111111',
   'Kampanye C probe H-F-03.5', 'KAMPC5', 'nominal', 20000, 50000,
   now() - interval '1 hour', now() + interval '1 day', 100, true),
  ('c3000000-0000-0000-0000-000000000604', '11111111-1111-1111-1111-111111111111',
   'Kampanye D probe H-F-03.5', 'KAMPD5', 'nominal', 20000, 50000,
   now() - interval '1 hour', now() + interval '1 day', 100, true);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- KONTROL POSITIF: Budi (hanya HP 0812-3456-7890) klaim kampanye A lewat kasir
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000601',
       'Budi', null, '0812-3456-7890', null, true, 'kasir', 'hp-probe', '10.6.0.1'
     ) as hasil),
  'kontrol positif: Budi (HP-saja) klaim kampanye A berhasil'
);

-- CELAH 1: Budi yang SAMA (nama sama, nomor sama) untuk kampanye B -> seharusnya BOLEH, nyatanya galat mentah
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000602',
       'Budi', null, '0812-3456-7890', null, true, 'kasir', 'hp-probe', '10.6.0.2')$$,
  'pelanggan_penyewa_telepon_unik',
  'CELAH 1: pelanggan HP-saja yang sama ditolak untuk kampanye BERBEDA dengan galat mentah'
);

-- CELAH 2: Budi untuk kampanye A LAGI -> bukan pesan ramah VOUCHER_SUDAH_DIKLAIM, tetapi galat mentah yang sama
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000601',
       'Budi', null, '0812-3456-7890', null, true, 'kasir', 'hp-probe', '10.6.0.3')$$,
  'pelanggan_penyewa_telepon_unik',
  'CELAH 2: klaim ulang kampanye yang sama berakhir galat mentah, bukan VOUCHER_SUDAH_DIKLAIM'
);

-- KONTROL NEGATIF: pelanggan BERE-MAIL yang sama — kampanye C dan D keduanya berhasil,
-- klaim ulang kampanye C dijawab ramah VOUCHER_SUDAH_DIKLAIM
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000603',
       'Budi Email', 'budi.probe@gmail.com', null, null, true, 'kasir', 'hp-probe', '10.6.1.1'
     ) as hasil),
  'kontrol negatif: Budi (e-mail) klaim kampanye C berhasil'
);
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000604',
       'Budi Email', 'budi.probe@gmail.com', null, null, true, 'kasir', 'hp-probe', '10.6.1.2'
     ) as hasil),
  'kontrol negatif: Budi (e-mail) yang sama klaim kampanye D BERHASIL (jalur e-mail menemukan pelanggan lama)'
);
select uji.sama(
  (select hasil->>'kode'
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000603',
       'Budi Email', 'budi.probe@gmail.com', null, null, true, 'kasir', 'hp-probe', '10.6.1.3'
     ) as hasil),
  'VOUCHER_SUDAH_DIKLAIM',
  'kontrol negatif: klaim ulang kampanye C lewat e-mail dijawab ramah'
);
