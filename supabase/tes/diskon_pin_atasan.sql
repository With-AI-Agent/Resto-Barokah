-- ============================================================================
-- UJI T5-05 — DISKON DI ATAS BATAS KASIR BOLEH LEWAT PERSETUJUAN PIN ATASAN
-- ----------------------------------------------------------------------------
-- DoD T5-05: "batas per pegawai dari pengaturan izin; di atas batas → wajib PIN
-- atasan; tercatat (pelaku, nilai, alasan)".
--
-- CACAT YANG DITUTUP (ditemukan 2026-09-23 saat mengerjakan T5-05):
-- `picu_diskon_batas()` memeriksa `public.boleh('beri_diskon', ...)` — yaitu izin
-- PEMANGGIL (kasir). Pemicu persetujuan `picu_diskon_setuju_jujur()` (0016) sudah
-- membuktikan bahwa atasan benar-benar menekan PIN-nya, TETAPI bukti itu tidak
-- pernah dipakai untuk menaikkan batas. Akibatnya: diskon di atas batas kasir
-- ditolak walau atasan sudah berdiri di sebelahnya dan memasukkan PIN — alur yang
-- dijanjikan PRD M3 tidak pernah bisa dijalankan, dan pesan 0019 yang menyuruh
-- "minta atasan yang memproses" memaksa atasan login ulang di tengah antrean.
--
-- Sesudah perbaikan: batas yang berlaku adalah batas PENYETUJU bila (dan hanya
-- bila) stempel `disetujui_oleh` terbukti sah — bukti PIN-nya sudah diverifikasi
-- pemicu 0016 yang berjalan pada pesanan yang sama, sekali pakai, dan penyetuju
-- dicek ulang izinnya. Tanpa stempel, batas kasir tetap berlaku apa adanya.
--
-- Data uji: kasir …0004 (batas 25.000 / 5 %), owner …0002 (100.000 / 20 %),
-- pesanan …0010 subtotal 54.000 (20 % = 10.800).
-- ============================================================================

-- Keadaan awal: tumpuk diskon menyala & cap resto dilonggarkan, supaya yang
-- benar-benar teruji adalah BATAS IZIN, bukan aturan satu-diskon atau cap resto.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set tumpuk_diskon = true,
       batas_maks_potongan_persen = 100,
       batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 1. Tanpa persetujuan: batas kasir tetap berlaku (pagar lama tidak dilemahkan).
--    9.000 dari subtotal 54.000 = 16,7 % → di atas batas kasir (25.000 / 5 %).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir Pusat
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010','manual',9000,9000,'tanpa atasan')$$,
  'melebihi batas izin Anda',
  'T5-05: diskon di atas batas kasir TETAP ditolak bila tidak ada persetujuan atasan');

-- Diskon di BAWAH batas kasir tetap jalan tanpa atasan (alur cepat tidak dirusak).
insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
values ('eeee0000-0000-0000-0000-000000000010','manual',2000,2000,'pelanggan langganan');
select uji.sama(
  (select count(*) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  1::bigint,
  'T5-05: diskon kecil tetap bisa diberikan kasir sendiri (jalur sah tidak tertutup)');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 2. Stempel persetujuan TANPA bukti PIN tetap ditolak (0016 tidak dilemahkan).
--    Dua sisi diuji, karena urutan pemicu membuat pesannya berbeda:
--    (a) nilai DI ATAS batas kasir -> pagar batas menolak lebih dulu (pemicu
--        `diskon_batas` berjalan sebelum `diskon_setuju_jujur` secara alfabetis),
--        sehingga stempel karangan tidak pernah bisa menaikkan batas;
--    (b) nilai DI BAWAH batas kasir -> pagar batas melewatkannya, dan yang
--        menolak adalah pemicu BUKTI PERSETUJUAN (0016) apa adanya.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',9000,9000,'stempel karangan',
              '90000000-0000-0000-0000-000000000002')$$,
  'melebihi batas izin Anda',
  'T5-05 (a): stempel atasan yang dikarang TIDAK menaikkan batas kasir');
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',1500,1500,'stempel karangan kecil',
              '90000000-0000-0000-0000-000000000002')$$,
  'Persetujuan diskon belum terbukti',
  'T5-05 (b): stempel atasan tanpa bukti PIN tetap ditolak walau nilainya kecil');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 3. JALUR SAH: atasan menekan PIN-nya di perangkat kasir, lalu kasir mencatat
--    diskon di atas batasnya sendiri tetapi masih di dalam batas atasan.
--    9.000 = 16,7 % → di atas kasir (5 %), di dalam owner (20 % = 10.800).
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');   -- owner memasang PIN
set local role authenticated;
select public.simpan_pin('551937', null, null,
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789');
reset role;
select uji.klaim(null);

-- Atasan memasukkan PIN-nya UNTUK pesanan ini (kupon sekali pakai, 5 menit).
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir yang memegang layar
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '551937', 'beri_diskon',
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789',
                         'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true,
  'T5-05: atasan memasukkan PIN-nya sendiri untuk aksi beri_diskon di pesanan ini');

insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
values ('eeee0000-0000-0000-0000-000000000010','manual',9000,9000,'diskon pelanggan komplain',
        '90000000-0000-0000-0000-000000000002');
select uji.sama(
  (select count(*) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'),
  2::bigint,
  'T5-05: diskon di atas batas kasir DITERIMA setelah atasan menekan PIN-nya');

-- Jejaknya jujur: pelaku tetap kasir (yang mengetik), penyetuju tetap atasan.
select uji.sama(
  (select d.pelaku_id from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
      and d.nilai = 9000),
  '90000000-0000-0000-0000-000000000004'::uuid,
  'T5-05: pelaku tercatat kasir yang mengetik, bukan atasan yang menyetujui');
select uji.sama(
  (select d.disetujui_oleh from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
      and d.nilai = 9000),
  '90000000-0000-0000-0000-000000000002'::uuid,
  'T5-05: penyetuju tercatat pada baris diskon (rekam jejak lengkap)');
select uji.harap(
  (select length(btrim(d.alasan)) > 0 from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
      and d.nilai = 9000),
  'T5-05: alasan wajib ikut tercatat (DoD: pelaku, nilai, alasan)');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 4. Persetujuan atasan BUKAN cek kosong: batas ATASAN tetap berlaku.
--    Owner berbatas 100.000 / 20 % → 20 % dari 54.000 = 10.800. Sisa ruang
--    sesudah 2.000 + 9.000 sudah menipis; 20.000 jelas di atas batas owner.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.simpan_pin('551937', null, null,
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '551937', 'beri_diskon',
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789',
                         'eeee0000-0000-0000-0000-000000000010')).berhasil,
  true, 'T5-05: kupon persetujuan kedua diterbitkan untuk uji batas atasan');
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',20000,20000,'diskon kelewat besar',
              '90000000-0000-0000-0000-000000000002')$$,
  'melebihi batas izin',
  'T5-05: PIN atasan menaikkan batas SAMPAI batas atasan saja — bukan izin tanpa batas');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 4b. Kupon PIN TERIKAT PESANAN. Atasan yang menekan PIN untuk pesanan LAIN tidak
--     boleh menaikkan batas di pesanan ini — kalau tidak, satu persetujuan di meja
--     sebelah bisa dipanen untuk tagihan mana pun.
--     Pesanan …0041 khusus uji ini (keadaan antar-berkas persisten).
-- ---------------------------------------------------------------------------
reset role;
select uji.klaim(null);
-- Rapikan dulu: kupon bagian 4 TIDAK jadi dikonsumsi (insert-nya ditolak batas
-- atasan), jadi ia masih menganggur. Kalau dibiarkan, bagian ini akan hijau/merah
-- karena kupon sisa itu — bukan karena keterikatan pesanan yang sedang diuji.
update public.percobaan_pin
   set dipakai_pada = now()
 where pengguna_id = '90000000-0000-0000-0000-000000000002'
   and aksi = 'beri_diskon'
   and pesanan_id = 'eeee0000-0000-0000-0000-000000000010'
   and dipakai_pada is null;
insert into public.pesanan (id, penyewa_id, cabang_id, nomor, tanggal, tipe, status,
                            subtotal, pajak, service, total, kunci_idempoten)
values ('eeee0000-0000-0000-0000-000000000041', '11111111-1111-1111-1111-111111111111',
        'a1a1a1a1-0000-0000-0000-000000000001', 41, current_date, 'takeaway', 'dikirim',
        54000, 5400, 2700, 62100, 'keranjang-uji-pin-pesanan-lain')
on conflict (id) do nothing;

-- Atasan menekan PIN untuk pesanan …0041 (BUKAN pesanan …0010).
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select public.simpan_pin('551937', null, null,
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000002', '551937', 'beri_diskon',
                         'de000000-0000-0000-0000-000000000001',
                         'kunci-uji-hp-owner-0123456789',
                         'eeee0000-0000-0000-0000-000000000041')).berhasil,
  true, 'T5-05: atasan menekan PIN untuk pesanan LAIN (…0041)');
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',9000,9000,'panen kupon meja sebelah',
              '90000000-0000-0000-0000-000000000002')$$,
  'melebihi batas izin Anda',
  'T5-05: persetujuan untuk pesanan lain TIDAK menaikkan batas di pesanan ini');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 4c. Kupon SEKALI PAKAI. Kupon yang sudah dikonsumsi (bagian 3) tidak boleh
--     dipakai lagi untuk menaikkan batas diskon berikutnya.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',9500,9500,'pakai ulang kupon lama',
              '90000000-0000-0000-0000-000000000002')$$,
  'melebihi batas izin Anda',
  'T5-05: kupon persetujuan yang sudah dipakai tidak bisa menaikkan batas lagi');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 4d. PIN BENAR ≠ BERHAK (pelajaran F-16). Pelayan tidak punya izin `beri_diskon`.
--     `verifikasi_pin` menyimpan baris berhasil=true SEBELUM menolak izin, jadi
--     kuponnya benar-benar ada di tabel. Kupon itu TIDAK boleh menaikkan batas —
--     kalau bisa, kasir cukup meminta rekan pelayan menekan PIN-nya.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005');   -- pelayan memasang PIN
set local role authenticated;
select public.simpan_pin('264810', null, null,
                         'de000000-0000-0000-0000-000000000004',
                         'kunci-uji-hp-pelayan-0123456789');
reset role;
select uji.klaim(null);

select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir yang memegang layar
set local role authenticated;
-- Jawabannya GAGAL (pelayan tidak berizin), tetapi jejak percobaannya tetap tercatat.
select uji.sama(
  (public.verifikasi_pin('90000000-0000-0000-0000-000000000005', '264810', 'beri_diskon',
                         'de000000-0000-0000-0000-000000000004',
                         'kunci-uji-hp-pelayan-0123456789',
                         'eeee0000-0000-0000-0000-000000000010')).berhasil,
  false, 'T5-05: PIN pelayan untuk beri_diskon dijawab GAGAL (tidak berizin)');
select uji.harap_gagal_sebab(
  $$insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan, disetujui_oleh)
      values ('eeee0000-0000-0000-0000-000000000010','manual',9000,9000,'minta tolong rekan pelayan',
              '90000000-0000-0000-0000-000000000005')$$,
  'melebihi batas izin Anda',
  'T5-05: PIN orang tanpa izin beri_diskon TIDAK menaikkan batas (kecocokan rahasia bukan otorisasi)');
reset role;
select uji.klaim(null);

-- ---------------------------------------------------------------------------
-- 5. Bersih-bersih: kembalikan pengaturan resto A ke bawaannya supaya berkas uji
--    lain tidak mewarisi keadaan longgar dari berkas ini.
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan
   set tumpuk_diskon = false,
       batas_maks_potongan_persen = 50,
       batas_maks_potongan_nominal = null
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);
