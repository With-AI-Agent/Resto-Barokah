-- PROBE SAYA — PR-03: nomor_pesanan_berikutnya membocorkan hitungan resto lain
select uji.klaim('90000000-0000-0000-0000-000000000007');   -- Ujang, kasir RESTO B
set local role authenticated;
select uji.sama(public.nomor_pesanan_berikutnya('a1a1a1a1-0000-0000-0000-000000000001', current_date),
                11, 'PR-03 NYATA: kasir resto B membaca hitungan pesanan cabang resto A');
select uji.sama(public.total_dibayar('eeee0000-0000-0000-0000-000000000010'), 0,
                'kontrol: total_dibayar menolak membocorkan angka resto lain');
reset role; select uji.klaim(null);
