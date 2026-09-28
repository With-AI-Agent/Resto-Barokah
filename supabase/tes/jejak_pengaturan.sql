-- ============================================================================
-- UJI: JEJAK PELAKU PERUBAHAN PENGATURAN UANG
-- Menutup temuan review PR putaran8 PR-05: kolom `diubah_oleh` bisa diisi nama
-- orang lain, bisa dikosongkan, dan `diubah_pada` bisa dimundurkan — padahal yang
-- diubah adalah pajak, service, cap potongan, dan izin tumpuk diskon.
-- ============================================================================

-- 1. Owner mengubah pengaturan dengan jujur → pelakunya TERCATAT sebagai dia.
reset role;
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner pusat
set local role authenticated;
update public.pengaturan set pajak_pb1_persen = 11
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.sama(
  (select g.diubah_oleh from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'pelaku perubahan pengaturan tercatat sebagai PEMANGGIL yang sebenarnya'
);

-- 2. Menyebut ORANG LAIN sebagai pelaku → DITOLAK.
select uji.harap_gagal_sebab($$update public.pengaturan set service_persen = 0,
           diubah_oleh = '90000000-0000-0000-0000-000000000004'
     where penyewa_id = '11111111-1111-1111-1111-111111111111'$$, 'Kolom "diubah oleh" diisi sistem — tidak boleh menyebut orang lain', 'menuliskan nama orang lain sebagai pelaku perubahan pengaturan DITOLAK');

-- 3. Waktu tidak bisa dimundurkan: kiriman klien 2020 ditimpa waktu sekarang.
update public.pengaturan set pajak_pb1_persen = 10, diubah_pada = '2020-01-01+07'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.harap(
  (select g.diubah_pada from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111')
    > now() - interval '1 minute',
  'waktu perubahan pengaturan tidak bisa dimundurkan ke 2020'
);

-- 4. Mengosongkan pelaku TIDAK menghapus jejak: otomatis ditulis sebagai pemanggil
--    (sama seperti pelaku pembayaran/diskon yang diisi sistem).
update public.pengaturan set tumpuk_diskon = false, diubah_oleh = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
select uji.sama(
  (select g.diubah_oleh from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'diubah_oleh = null tidak menghapus jejak (ditulis sebagai pemanggil)'
);

-- 5. Jalur peladen (tanpa identitas) pun tidak boleh menghapus jejak, dan tetap
--    boleh mengubah nilai (mis. penyiapan awal) tanpa mengarang pelaku.
reset role;
select uji.klaim(null);
select uji.harap_gagal_sebab($$update public.pengaturan set diubah_oleh = null
     where penyewa_id = '11111111-1111-1111-1111-111111111111'$$, 'Jejak pelaku perubahan pengaturan tidak boleh dihapus', 'jalur peladen juga tidak boleh menghapus jejak pelaku');
select uji.sama(
  (select g.diubah_oleh from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'jejak pelaku tetap ada setelah percobaan penghapusan'
);

-- 6. Pemegang izin lain (admin cabang) tidak bisa mengubah pengaturan uang:
--    policy menolak (0 baris), dan jejak pelaku tetap menunjuk orang yang BENAR.
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- admin cabang
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true,
       diubah_oleh = '90000000-0000-0000-0000-000000000002'
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);
select uji.sama(
  (select g.tumpuk_diskon from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  false, 'admin cabang TIDAK bisa menyalakan tumpuk diskon (policy pengaturan_ubah)'
);
select uji.sama(
  (select g.diubah_oleh from public.pengaturan g where g.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'jejak pelaku tidak berubah oleh percobaan admin cabang'
);
