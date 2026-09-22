-- ============================================================================
-- 0037 — OPNAME_STOK (T4-07): mengisi jumlah NYATA hasil hitung fisik.
-- Selisih = fisik − saldo sistem, TERCATAT terbuka di buku besar `stok_pergerakan`
-- (jenis 'opname', boleh nol — opname tetap meninggalkan jejak siapa & kapan).
-- Koreksi tidak menghapus riwayat: saldo mengikuti hitungan lewat delta kekal.
-- Penguncian baris (`for update`) membuat dua opname bersamaan tidak saling
-- menimpa (bukti dua koneksi nyata: alat/uji-konkuren.py).
-- ============================================================================

create or replace function public.opname_stok(
  p_stok_bahan_id uuid,
  p_jumlah_fisik  numeric,
  p_alasan        text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_bahan   public.stok_bahan%rowtype;
  v_selisih numeric;
  v_saldo   numeric;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  if not public.boleh('ubah_stok') then
    raise exception 'Anda tidak berizin mengubah stok.';
  end if;

  if p_jumlah_fisik is null or p_jumlah_fisik < 0 then
    raise exception 'Jumlah fisik opname tidak boleh negatif.';
  end if;

  if p_alasan is null or length(btrim(p_alasan)) = 0 then
    raise exception 'Alasan wajib diisi.';
  end if;

  select * into v_bahan
    from public.stok_bahan b
   where b.id = p_stok_bahan_id
     and b.penyewa_id = public.penyewa_saya()
     for update;
  if not found then
    raise exception 'Bahan tidak ditemukan di resto ini.';
  end if;

  v_selisih := p_jumlah_fisik - v_bahan.jumlah;
  v_saldo := public.catat_stok(p_stok_bahan_id, 'opname', v_selisih, p_alasan);

  return jsonb_build_object('jumlah_baru', v_saldo, 'selisih', v_selisih);
end
$$;

comment on function public.opname_stok(uuid, numeric, text) is
  'T4-07 (TECH_SPEC §5 M9): opname berkala — masukkan jumlah fisik, sistem mencatat selisih terbuka (delta jenis opname, boleh nol) di buku besar hanya-tambah. Butuh izin ubah_stok.';

revoke all on function public.opname_stok(uuid, numeric, text) from public, anon;
grant execute on function public.opname_stok(uuid, numeric, text) to authenticated, service_role;
