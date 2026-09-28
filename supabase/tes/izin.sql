-- ============================================================================
-- UJI: izin berjenjang + gerbang tunggal boleh() (T1-05, ART-2)
-- Membuktikan: izin disimpan per pegawai DAN per peran; centang khusus menang;
-- tidak ada keduanya = tolak; batas nominal/persen dihormati; izin berbeda per
-- cabang untuk pegawai merangkap; dan izin tidak bisa diubah sembarang orang.
-- ============================================================================

-- 1. Kamus izin resmi lengkap.
select uji.sama((select count(*) from public.izin_kode), 10::bigint, 'kamus izin berisi 10 kode resmi');
select uji.harap(
  exists (select 1 from public.izin_kode where kode_izin = 'void_sesudah_dapur'),
  'kode izin void sesudah dapur ada'
);

-- 2. Setiap resto punya izin bawaan lengkap (5 peran × 10 izin = 50 baris).
select uji.sama(
  (select count(*) from public.izin_peran where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  50::bigint,
  'resto Kedai Oasis punya 50 baris izin bawaan'
);
select uji.sama(
  (select count(distinct peran) from public.izin_peran where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  5::bigint,
  'izin bawaan mencakup 5 peran'
);

-- 3. Sebelum masuk (anon): tidak boleh memanggil gerbang izin sama sekali.
select uji.klaim(null);
set local role anon;
select uji.harap_gagal_sebab($$select public.boleh('beri_diskon')$$, 'permission denied for function boleh', 'anon tidak boleh memanggil boleh()');
select uji.sama((select count(*) from public.izin_peran), 0::bigint, 'anon tidak melihat satu baris izin peran');
reset role;
select uji.klaim(null);

-- 4. KASIR — matriks lengkap 10 izin (bawaan peran).
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.boleh('beri_diskon'), true, 'kasir boleh memberi diskon dalam batas');
select uji.sama(public.boleh('void_sebelum_dapur'), true, 'kasir boleh membatalkan sebelum dapur mulai');
select uji.sama(public.boleh('tutup_kas'), true, 'kasir boleh menutup kas');
select uji.sama(public.boleh('pakai_voucher'), true, 'kasir boleh memakai voucher');
select uji.sama(public.boleh('ubah_harga'), false, 'kasir TIDAK boleh mengubah harga');
select uji.sama(public.boleh('void_sesudah_dapur'), false, 'kasir TIDAK boleh membatalkan setelah dapur mulai');
select uji.sama(public.boleh('lihat_laporan'), false, 'kasir TIDAK boleh melihat laporan');
select uji.sama(public.boleh('kelola_pegawai'), false, 'kasir TIDAK boleh mengelola pegawai');
select uji.sama(public.boleh('atur_pengaturan'), false, 'kasir TIDAK boleh mengubah pengaturan');
select uji.sama(public.boleh('ubah_stok'), false, 'kasir TIDAK boleh mengubah stok');

-- 4b. Batas diskon kasir: 25.000 rupiah dan 5 persen.
select uji.sama(public.boleh('beri_diskon', 25000), true, 'diskon tepat di batas nominal masih boleh');
select uji.sama(public.boleh('beri_diskon', 25001), false, 'diskon melewati batas nominal ditolak');
select uji.sama(public.boleh('beri_diskon', 0, 5), true, 'diskon tepat di batas persen masih boleh');
select uji.sama(public.boleh('beri_diskon', 0, 5.01), false, 'diskon melewati batas persen ditolak');
select uji.sama(public.boleh('beri_diskon', 10000, 20), false, 'diskon yang persen-nya keterlaluan ditolak walau nominal kecil');

-- 4c. Aksi yang tidak dikenal = tolak (bukan error, bukan izin diam-diam).
select uji.sama(public.boleh('aksi_ngawur'), false, 'aksi tidak dikenal ditolak');
reset role;
select uji.klaim(null);

-- 5. OWNER PUSAT — boleh semuanya, tanpa batas.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama((select count(*) from public.izin_efektif('atur_pengaturan') where boleh), 1::bigint, 'owner pusat boleh mengubah pengaturan');
-- Catatan: data uji memberi owner centang kh khusus diskon 100.000 / 20 persen,
-- jadi batas itu memang berlaku — bukan berarti owner tidak punya izin.
select uji.sama(public.boleh('beri_diskon', 100000, 20), true, 'diskon owner tepat di batas centangnya');
select uji.sama(public.boleh('beri_diskon', 100001, 20), false, 'diskon owner di atas batas centangnya ditolak');
select uji.sama(public.boleh('lihat_laporan'), true, 'owner pusat boleh melihat laporan tanpa batas');
select uji.sama(public.boleh('kelola_pegawai'), true, 'owner pusat boleh mengelola pegawai');
select uji.sama((select count(*) from public.izin_kode), 10::bigint, 'kamus izin bisa dibaca pegawai resto');
reset role;
select uji.klaim(null);

-- 6. ADMIN CABANG — operasi harian boleh, pengaturan tidak; batas diskon lebih longgar dari kasir.
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;
select uji.sama(public.boleh('kelola_pegawai'), true, 'admin cabang boleh mengelola pegawai');
select uji.sama(public.boleh('lihat_laporan'), true, 'admin cabang boleh melihat laporan');
select uji.sama(public.boleh('void_sesudah_dapur'), true, 'admin cabang boleh menyetujui void setelah dapur mulai');
select uji.sama(public.boleh('atur_pengaturan'), false, 'admin cabang TIDAK boleh mengubah pengaturan resto');
select uji.sama(public.boleh('beri_diskon', 50000, 10), true, 'diskon admin boleh sampai 50.000 / 10 persen');
select uji.sama(public.boleh('beri_diskon', 50001, 10), false, 'diskon admin melewati batas nominal ditolak');
reset role;
select uji.klaim(null);

-- 7. DAPUR & PELAYAN — izin paling sempit (7 tindakan sensitif ditolak).
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;
select uji.sama(public.boleh('ubah_stok'), true, 'dapur boleh mengubah stok');
select uji.sama(public.boleh('beri_diskon'), false, 'dapur TIDAK boleh memberi diskon');
select uji.sama(public.boleh('lihat_laporan'), false, 'dapur TIDAK boleh melihat laporan');
select uji.sama(public.boleh('tutup_kas'), false, 'dapur TIDAK boleh menutup kas');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;
select uji.sama(public.boleh('pakai_voucher'), true, 'pelayan boleh memakai voucher');
select uji.sama(public.boleh('beri_diskon'), false, 'pelayan TIDAK boleh memberi diskon');
select uji.sama(public.boleh('ubah_harga'), false, 'pelayan TIDAK boleh mengubah harga');
reset role;
select uji.klaim(null);

-- 8. IZIN PER CABANG dengan PERAN TUNGGAL (diganti 2026-09-17 · AUD-0 B.3).
--    Uji lama bagian ini ("pegawai merangkap dapat peran berbeda per cabang")
--    DIHAPUS karena menguji perilaku yang kini DILARANG. Yang diuji sekarang:
--    keanggotaan cabang tetap menentukan DI CABANG MANA seseorang boleh bekerja,
--    sedangkan PERANNYA satu dan sama di semua cabang (lihat juga
--    `supabase/tes/peran_tunggal.sql`).
reset role;
select uji.klaim(null);
insert into auth.users (id, email) values ('90000000-0000-0000-0000-000000000008', 'bima@contoh.test');
insert into public.pengguna (id, penyewa_id, nama, email, peran)
values ('90000000-0000-0000-0000-000000000008', '11111111-1111-1111-1111-111111111111', 'Bima', 'bima@contoh.test', 'kasir');
insert into public.pengguna_cabang (pengguna_id, cabang_id)
values ('90000000-0000-0000-0000-000000000008', 'a1a1a1a1-0000-0000-0000-000000000001');

select uji.klaim('90000000-0000-0000-0000-000000000008');
set local role authenticated;
select uji.sama(public.boleh('tutup_kas'), true, 'sebagai kasir (tanpa cabang) Bima boleh menutup kas');
select uji.sama(public.boleh('beri_diskon'), true, 'sebagai kasir Bima boleh memberi diskon (bawaan peran)');
select uji.sama(public.boleh('ubah_stok'), false, 'sebagai kasir Bima tidak boleh mengubah stok');
select uji.sama(
  public.boleh('ubah_stok', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid),
  false,
  'di cabang Pusat pun Bima TETAP kasir (peran tidak lagi bisa berbeda per cabang)'
);
select uji.sama(
  public.boleh('tutup_kas', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid),
  true,
  'di cabang tempatnya bertugas, hak kasirnya berlaku'
);
-- Diuji dengan tindakan yang BOLEH di tingkat akun (tutup_kas) tetapi TIDAK BOLEH
-- di cabang itu: kalau cabang asing diam-diam jatuh ke peran se-resto, uji ini gagal.
select uji.sama(
  public.boleh('tutup_kas', 'b1b1b1b1-0000-0000-0000-000000000001'::uuid),
  false,
  'cabang milik resto lain ditolak, bukan jatuh ke peran se-resto (kasir se-resto memang boleh tutup kas)'
);
select uji.sama(
  public.boleh('lihat_laporan', 'a1a1a1a1-0000-0000-0000-000000000002'::uuid),
  false,
  'cabang yang bukan tempatnya bertugas ditolak'
);
reset role;
select uji.klaim(null);

-- 9. OWNER PUSAT tidak bertugas di kasir, tetapi tetap boleh mengurus cabangnya.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  public.boleh('atur_pengaturan', 'a1a1a1a1-0000-0000-0000-000000000001'::uuid),
  true,
  'owner pusat tetap boleh mengubah pengaturan di cabangnya walau tidak bertugas di sana'
);
reset role;
select uji.klaim(null);

-- 10. CENTANG KHUSUS pegawai menang atas bawaan peran (boleh maupun tidak boleh).
reset role;
select uji.klaim(null);
insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000004', 'lihat_laporan', true)
on conflict (pengguna_id, kode_izin) do update set boleh = excluded.boleh;

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.boleh('lihat_laporan'), true, 'centang khusus memberi izin yang tadinya tidak ada');
reset role;
select uji.klaim(null);

reset role;
select uji.klaim(null);
-- Owner belum punya centang khusus untuk kelola_pegawai → perlu disisipkan dulu
-- (kalau hanya di-update, tidak ada baris yang berubah dan izin bawaan tetap berlaku).
insert into public.izin (pengguna_id, kode_izin, boleh)
values ('90000000-0000-0000-0000-000000000002', 'kelola_pegawai', false)
on conflict (pengguna_id, kode_izin) do update set boleh = excluded.boleh;

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.boleh('kelola_pegawai'), false, 'centang khusus juga bisa MENCABUT izin bawaan owner');
reset role;
select uji.klaim(null);

-- 11. Pemilik platform & akun nonaktif: tidak boleh apa pun.
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;
select uji.sama(public.boleh('lihat_laporan'), false, 'pemilik platform tidak memakai izin resto mana pun');
select uji.sama((select count(*) from public.izin_efektif('lihat_laporan')), 1::bigint, 'izin_efektif tetap menjawab (tidak error) untuk pemilik platform');
select uji.sama((select count(*) from public.izin_peran), 0::bigint, 'pemilik platform tidak melihat izin peran resto mana pun');
reset role;
select uji.klaim(null);

reset role;
select uji.klaim(null);
update public.pengguna set aktif = false where id = '90000000-0000-0000-0000-000000000004';
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.boleh('beri_diskon'), false, 'akun nonaktif kehilangan seluruh izin');
select uji.sama(public.boleh('tutup_kas'), false, 'akun nonaktif tidak boleh menutup kas');
reset role;
select uji.klaim(null);
update public.pengguna set aktif = true where id = '90000000-0000-0000-0000-000000000004';

-- 12. Hanya owner pusat yang boleh mengubah izin bawaan peran.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab($$insert into public.izin_peran (penyewa_id, peran, kode_izin, boleh) values ('11111111-1111-1111-1111-111111111111', 'kasir', 'ubah_harga', true)$$, 'row-level security policy for table "izin_peran"', 'kasir tidak boleh menambah izin bawaan');
update public.izin_peran set boleh = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111' and peran = 'kasir' and kode_izin = 'ubah_harga';
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(
  (select ip.boleh from public.izin_peran ip
    where ip.penyewa_id = '11111111-1111-1111-1111-111111111111' and ip.peran = 'kasir' and ip.kode_izin = 'ubah_harga'),
  false,
  'izin bawaan kasir TIDAK berubah walau ada perintah ubah dari kasir'
);

-- 12b. Owner pusat memang boleh mengubahnya, dan perubahan itu berlaku untuk pegawainya.
update public.izin_peran set boleh = false
 where penyewa_id = '11111111-1111-1111-1111-111111111111' and peran = 'kasir' and kode_izin = 'beri_diskon';
select uji.sama(
  (select ip.boleh from public.izin_peran ip
    where ip.penyewa_id = '11111111-1111-1111-1111-111111111111' and ip.peran = 'kasir' and ip.kode_izin = 'beri_diskon'),
  false,
  'owner pusat berhasil mematikan izin diskon untuk semua kasir'
);
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000008');
set local role authenticated;
select uji.sama(public.boleh('beri_diskon'), false, 'kasir tanpa centang khusus kehilangan izin diskon setelah owner mematikannya');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(public.boleh('beri_diskon'), true, 'kasir yang punya centang khusus TIDAK terpengaruh perubahan bawaan peran (centang khusus menang)');
reset role;
select uji.klaim(null);

-- 13. Resto baru otomatis mendapat izin bawaan (tidak pernah "semua tertutup").
insert into public.penyewa (id, nama, slug) values ('33333333-3333-3333-3333-333333333333', 'Resto Baru', 'resto-baru');
select uji.sama(
  (select count(*) from public.izin_peran where penyewa_id = '33333333-3333-3333-3333-333333333333'),
  50::bigint,
  'resto baru otomatis mendapat 50 izin bawaan'
);

-- 14. Resto lain tidak bisa melihat izin peran resto ini.
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;
select uji.sama((select count(*) from public.izin_peran), 50::bigint, 'kasir resto lain hanya melihat izin peran restonya sendiri');
select uji.sama(
  (select count(*) from public.izin_peran where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  0::bigint,
  'izin peran Kedai Oasis tidak terlihat oleh resto lain'
);
select uji.sama(public.boleh('lihat_laporan'), false, 'kasir resto lain tidak mendapat izin apa pun yang bukan miliknya');
reset role;
select uji.klaim(null);
