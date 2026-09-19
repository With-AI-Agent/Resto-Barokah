-- PROBE SAYA — PR-07: kupon tanpa ikatan pesanan (jalur Edge Function) mustahil dipakai
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
select uji.sama(public.simpan_pin('738294', null), 'PIN tersimpan.', 'owner memasang PIN');
reset role; select uji.klaim(null);
select uji.klaim('90000000-0000-0000-0000-000000000004');   -- kasir
set local role authenticated;
select uji.sama((public.verifikasi_pin('90000000-0000-0000-0000-000000000002','738294',
                  'void_sesudah_dapur','alat-kasir', null)).berhasil, true,
                'PR-07 NYATA: kupon TANPA pesanan berhasil dibuat (persis jalur Edge Function)');
select uji.harap_gagal_sebab(
  $$insert into public.pembatalan (pesanan_id, tahap, disetujui_oleh, alasan)
      values ('eeee0000-0000-0000-0000-000000000010','sesudah_dapur',
              '90000000-0000-0000-0000-000000000002','void lewat jalur Edge')$$,
  'Persetujuan belum terbukti', 'PR-07 NYATA: kupon itu DITOLAK saat dipakai → jalur Edge buntu');
reset role; select uji.klaim(null);
