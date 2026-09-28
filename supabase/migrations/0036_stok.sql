-- ============================================================================
-- 0036 — SET_STOK (T4-06): penyesuaian stok sederhana per bahan (delta +/−),
-- lewat pintu tunggal `catat_stok` (0007) sehingga buku besar `stok_pergerakan`
-- tetap SATU-SATUNYA sumber riwayat (siapa, kapan, berapa, alasannya).
-- Pencatatan sederhana, bukan resep otomatis (fase 2 G2/G3 — lihat keputusan
-- rencana stok bertahap di DECISIONS_LOG).
-- ============================================================================

create or replace function public.set_stok(
  p_stok_bahan_id uuid,
  p_jumlah        numeric,
  p_alasan        text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_bahan public.stok_bahan%rowtype;
  v_jenis text;
  v_saldo numeric;
  v_id    bigint;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  if not public.boleh('ubah_stok') then
    raise exception 'Anda tidak berizin mengubah stok.';
  end if;

  if p_jumlah is null or p_jumlah = 0 then
    raise exception 'Perubahan stok tidak boleh nol.';
  end if;

  if p_alasan is null or length(btrim(p_alasan)) = 0 then
    raise exception 'Alasan wajib diisi.';
  end if;

  select * into v_bahan
    from public.stok_bahan b
   where b.id = p_stok_bahan_id
     and b.penyewa_id = public.penyewa_saya();
  if not found then
    raise exception 'Bahan tidak ditemukan di resto ini.';
  end if;

  v_jenis := case when p_jumlah > 0 then 'masuk' else 'keluar' end;
  v_saldo := public.catat_stok(p_stok_bahan_id, v_jenis, p_jumlah, p_alasan);
  select currval('public.stok_pergerakan_id_seq') into v_id;

  return jsonb_build_object('jumlah_baru', v_saldo, 'pergerakan_id', v_id, 'jenis', v_jenis);
end
$$;

comment on function public.set_stok(uuid, numeric, text) is
  'T4-06 (TECH_SPEC §5 M9): mencatat penambahan (+) / pengurangan (−) stok bahan dengan alasan wajib. Delta, bukan angka akhir; saldo diperbarui pemicu buku besar. Butuh izin ubah_stok.';

revoke all on function public.set_stok(uuid, numeric, text) from public, anon;
grant execute on function public.set_stok(uuid, numeric, text) to authenticated, service_role;
