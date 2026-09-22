-- PROBE SAYA — PR-06: penolakan hierarki PIN tidak meninggalkan jejak
select uji.klaim('90000000-0000-0000-0000-000000000003');   -- Pak Andi, admin cabang
set local role authenticated;
select uji.harap_gagal_sebab(
  $$select public.simpan_pin('739284', null, '90000000-0000-0000-0000-000000000002', 'alat-admin')$$,
  'lebih tinggi', 'kontrol: admin merebut PIN owner DITOLAK');
select uji.sama((select count(*) from public.percobaan_simpan_pin where alasan like '%hierarki%'),
                0::bigint, 'PR-06 NYATA: penolakan hierarki TIDAK tercatat di mana pun');
reset role; select uji.klaim(null);
