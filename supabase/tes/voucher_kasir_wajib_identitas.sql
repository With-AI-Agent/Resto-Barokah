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

-- 9..19. Penyatuan gaya penulisan RONDE 3 (PMB1-F-038 — dikembalikan HAKIM H-F-03.5:
-- 9 dari 13 penulisan masih bocor). Semua bentuk di bawah adalah nomor dasar yang
-- sama dengan kasus 2 (081234567890) atau identitas landline baru (02157901234).

-- 9. "+62 (0)812-3456-7890" (nol ikut tertulis sesudah kode negara)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Nol Dalam Kurung', null, '+62 (0)812-3456-7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.1')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk +62 (0)812… dari nomor yang sama ditolak'
);

-- 10. "+62 0812 3456 7890" (nol tertulis sesudah kode negara, tanpa kurung)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Nol Polos', null, '+62 0812 3456 7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.2')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk +62 0812… dari nomor yang sama ditolak'
);

-- 11. "620812 3456 7890" (kode negara menempel pada nol)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Enam Dua Nol', null, '620812 3456 7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.3')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk 620812… dari nomor yang sama ditolak'
);

-- 12. "00812 3456 7890" (awalan akses 00 tanpa kode negara)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Nol Nol Delapan', null, '00812 3456 7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.4')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk 00812… dari nomor yang sama ditolak'
);

-- 13. "0062 812 3456 7890" (awalan akses internasional 00 + kode negara)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Nol Nol Enam Dua', null, '0062 812 3456 7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.5')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk 0062 812… dari nomor yang sama ditolak'
);

-- 14. "0062-0812-3456-7890" (awalan akses 00 + kode negara + nol)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Gaya Nol Nol Enam Dua Nol', null, '0062-0812-3456-7890', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.6')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk 0062-0812… dari nomor yang sama ditolak'
);

-- 15. Kontrol positif identitas BARU: telepon rumah 021-5790-1234 sah terdaftar
select uji.harap(
  (select (hasil->>'berhasil')::boolean
     from public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Pelanggan Telepon Rumah', null, '021-5790-1234', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.7'
     ) as hasil),
  'F-038 r3: nomor telepon rumah tetap sah didaftarkan'
);
select uji.harap(
  (select telepon from public.pelanggan where nama = 'Pelanggan Telepon Rumah') = '02157901234',
  'F-038 r3: telepon rumah tersimpan sebagai digit dengan nol depan'
);

-- 16. "+62 (0)21 5790 1234" (bentuk internasional + nol pada telepon rumah)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Rumah Gaya Internasional Nol', null, '+62 (0)21 5790 1234', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.8')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk +62 (0)21… dari telepon rumah yang sama ditolak'
);

-- 17. "0062 21 5790 1234" (awalan akses 00 + kode negara pada telepon rumah)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Rumah Gaya Nol Nol', null, '0062 21 5790 1234', null, true, 'kasir', 'hp-kasir-rina', '10.9.2.9')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk 0062 21… dari telepon rumah yang sama ditolak'
);

-- 18. "21 5790 1234" (telepon rumah tanpa nol di depan)
select uji.harap_gagal_sebab(
  $$select public.daftar_voucher(
       '11111111-1111-1111-1111-111111111111',
       'c3000000-0000-0000-0000-000000000038',
       'Rumah Tanpa Nol', null, '21 5790 1234', null, true, 'kasir', 'hp-kasir-rina', '10.9.3.0')$$,
  'pelanggan_penyewa_telepon_unik',
  'F-038 r3: bentuk tanpa nol depan dari telepon rumah yang sama ditolak'
);

-- 19. Total akhir: tepat tiga identitas sah (dua seluler + satu rumah)
select uji.harap(
  (select count(*) from public.voucher
    where kampanye_id = 'c3000000-0000-0000-0000-000000000038') = 3,
  'F-038 r3: total tepat tiga voucher — sepuluh gaya penulisan lain tidak menambah'
);

-- ============================================================================
-- BAGIAN B PMB1-F-038 — OPSI 3 (keputusan Lee 2026-10-04):
-- BATAS PENDAFTARAN PELANGGAN OLEH SATU KASIR UNTUK SATU KAMPANYE.
-- Pelanggan fiktif massal jadi mahal: kasir hanya boleh menerbitkan
-- `pengaturan.batas_daftar_pelanggan_kasir_per_kampanye` voucher (bawaan 3)
-- per kampanye; 0 = tanpa batas. Jalur google/email tidak kena batas ini.
-- MERAH tanpa 0097: kasus 20 GAGAL (pelanggan ke-4 justru diterbitkan).
-- ============================================================================

-- 20. Kampanye lama (...0038) sudah menerbitkan 3 voucher lewat Rina
--     (kasus 2-19) -> pelanggan SAH ke-4 kasir yang sama DITOLAK batas bawaan.
select uji.sama(
  (select public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000038',
     'Tamu Keempat Sah', null, '081300000020', null, true, 'kasir', 'hp-uji', '10.8.0.20') ->> 'kode'),
  'BATAS_PENDAFTARAN_KASIR',
  'F-038 B opsi 3: pelanggan ke-4 oleh kasir yang sama pada kampanye yang sama DITOLAK (batas bawaan 3)'
);

-- Kampanye baru milik kasus 21-26 (hitungan batas per kampanye).
-- INSERT kampanye hanya boleh peran pemilik tabel -> keluar dulu dari peran kasir.
reset role;
insert into public.kampanye_voucher (
  id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif
) values (
  'c3000000-0000-0000-0000-000000000039',
  '11111111-1111-1111-1111-111111111111',
  'Kampanye uji batas kasir F-038B', 'BATASF38B', 'nominal', 10000, 40000,
  now() - interval '1 hour', now() + interval '1 day', 50, true
);
set local role authenticated;   -- kembali menjadi kasir Rina untuk kasus 21 dst.

-- 21. Kampanye baru: tiga pelanggan pertama kasir yang sama TETAP terbit
do $$
declare
  v_telp text;
  v_n int := 0;
begin
  foreach v_telp in array array['081300000021', '081300000022', '081300000023'] loop
    v_n := v_n + 1;
    perform uji.harap(
      (public.daftar_voucher(
         '11111111-1111-1111-1111-111111111111',
         'c3000000-0000-0000-0000-000000000039',
         'Tamu Batas ' || v_n, null, v_telp, null, true, 'kasir', 'hp-uji', '10.8.1.' || v_n) ->> 'berhasil')::boolean,
      'F-038 B opsi 3: pelanggan ke-' || v_n || ' kampanye baru masih terbit (di bawah batas)'
    );
  end loop;
end $$;

-- 22. Pelanggan ke-4 kasir yang sama pada kampanye baru -> DITOLAK
select uji.sama(
  (select public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000039',
     'Tamu Batas 4', null, '081300000024', null, true, 'kasir', 'hp-uji', '10.8.1.24') ->> 'kode'),
  'BATAS_PENDAFTARAN_KASIR',
  'F-038 B opsi 3: pelanggan ke-4 DITOLAK — batas per kasir per kampanye bekerja'
);

-- 23. Kasir LAIN (kasir.b1) tidak ikut terhitung — batasnya milik kasir masing-masing
select uji.klaim('90000000-0000-0000-0000-000000000007');
select uji.harap(
  (public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000039',
     'Tamu Kasir Lain', null, '081300000025', null, true, 'kasir', 'hp-uji', '10.8.1.25') ->> 'berhasil')::boolean,
  'F-038 B opsi 3: kasir lain tetap boleh mendaftarkan (batas per kasir, bukan per resto)'
);
select uji.klaim('90000000-0000-0000-0000-000000000004');

-- 24. Batas 0 = tanpa batas (pelarian resmi operator): pelanggan ke-4 terbit lagi.
-- Mengubah pengaturan hanya boleh owner_pusat (policy 0027) -> ganti peran dulu.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set batas_daftar_pelanggan_kasir_per_kampanye = 0
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.harap(
  (public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000039',
     'Tamu Batas 4b', null, '081300000026', null, true, 'kasir', 'hp-uji', '10.8.1.26') ->> 'berhasil')::boolean,
  'F-038 B opsi 3: batas 0 berarti tanpa batas (pelarian operator)'
);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set batas_daftar_pelanggan_kasir_per_kampanye = 3
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

-- 25. Sesudah batas dipulihkan ke 3: pelanggan berikutnya kasir pertama DITOLAK lagi
select uji.sama(
  (select public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000039',
     'Tamu Batas 5', null, '081300000027', null, true, 'kasir', 'hp-uji', '10.8.1.27') ->> 'kode'),
  'BATAS_PENDAFTARAN_KASIR',
  'F-038 B opsi 3: sesudah batas dipulihkan ke 3, pendaftaran ke-4 kasir pertama ditolak lagi'
);

-- 26. Percobaan nomor karangan pendek ("1", "22") ala probe H-F-03.5 ikut
--     membentur batas: yang ke-4 tidak bisa terbit walau nomornya "baru".
select uji.sama(
  (select public.daftar_voucher(
     '11111111-1111-1111-1111-111111111111',
     'c3000000-0000-0000-0000-000000000039',
     'Tamu Karangan Singkat', null, '1', null, true, 'kasir', 'hp-uji', '10.8.1.28') ->> 'kode'),
  'BATAS_PENDAFTARAN_KASIR',
  'F-038 B opsi 3: nomor karangan pendek pun tertahan oleh batas kasir'
);
