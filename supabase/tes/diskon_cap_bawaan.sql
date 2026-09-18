-- ============================================================================
-- UJI: CAP DISKON BAWAAN PUNYA ARTI (dulu 100% = tidak ada cap)
-- Menutup temuan audit AUD-3 2026-09-18 F-03 (K-2): dengan `tumpuk_diskon = true`
-- kasir bisa memecah diskon menjadi 20 baris @2.700 (masing-masing "di bawah
-- batas izin") sampai 100% subtotal, karena batas maks potongan resto bawaannya
-- 100.00. Bawaan baru: 50%.
-- ============================================================================
select uji.sama(
  (select p.batas_maks_potongan_persen from public.pengaturan p
    where p.penyewa_id = '11111111-1111-1111-1111-111111111111'),
  50::numeric, 'cap bawaan resto = 50% (bukan 100% yang berarti tanpa batas)'
);
-- Owner menyalakan tumpuk diskon.
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;
update public.pengaturan set tumpuk_diskon = true
 where penyewa_id = '11111111-1111-1111-1111-111111111111';
reset role;
select uji.klaim(null);

-- Kasir memecah diskon kecil-kecil: diterima sampai cap, lalu DITOLAK.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
do $$
declare
  v_diterima integer := 0;
  v_ditolak  integer := 0;
  i integer;
begin
  for i in 1..20 loop
    begin
      insert into public.diskon_transaksi (pesanan_id, jenis, nominal, nilai, alasan)
      values ('eeee0000-0000-0000-0000-000000000010', 'manual', 2700, 2700, 'pecah diskon ' || i);
      v_diterima := v_diterima + 1;
    exception when others then
      v_ditolak := v_ditolak + 1;
    end;
  end loop;
  -- Pesan hasil untuk dibaca laporan (dipaksa lewat uji)
  perform uji.harap(v_diterima <= 10, 'pecahan diskon berhenti di cap 50% (diterima ' || v_diterima || ' baris)');
  perform uji.harap(v_ditolak >= 1, 'sisa pecahan diskon DITOLAK setelah cap terlampaui (' || v_ditolak || ' baris)');
  perform uji.harap(v_diterima * 2700 <= 27000, 'total potongan tidak melewati 50% subtotal 54.000');
end $$;
select uji.sama(
  (select coalesce(sum(d.nilai),0) from public.diskon_transaksi d
    where d.pesanan_id = 'eeee0000-0000-0000-0000-000000000010') <= 27000,
  true, 'total potongan satu pesanan tidak bisa menembus cap resto (max 50% = 27.000)'
);
reset role;
select uji.klaim(null);
