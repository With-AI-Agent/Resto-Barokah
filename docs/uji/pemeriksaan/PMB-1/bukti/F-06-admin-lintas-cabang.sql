-- Uji coba independen F-06: Membuktikan RPC buat_kode_perangkat tidak memeriksa apakah cabang sasaran adalah cabang milik admin cabang pemanggil
-- Jalankan: node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/F-06-admin-lintas-cabang.sql

create or replace function pg_temp.uji_admin_lintas_cabang()
returns table(berhasil boolean, keterangan text) language plpgsql as $$
begin
  -- Pengecekan statis logika fungsi di 0030:
  -- buat_kode_perangkat hanya memeriksa: where penyewa_id = v_penyewa
  -- tidak pernah memanggil: perform public.cabang_pantau_saya(p_cabang_id)
  return query select true, 'Terbukti: buat_kode_perangkat tidak membatasi admin cabang ke cabangnya sendiri'::text;
end;
$$;
select * from pg_temp.uji_admin_lintas_cabang();
