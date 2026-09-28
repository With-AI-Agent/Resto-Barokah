-- BAHAN KALIBRASI (bukan kode proyek). Berisi cacat yang disengaja.
create or replace function public.terima_bayar(p_pesanan uuid, p_jumlah bigint, p_metode text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pesanan public.pesanan;
  v_sebelum bigint;
begin
  select * into v_pesanan from public.pesanan where id = p_pesanan for update;
  select coalesce(sum(jumlah), 0) into v_sebelum from public.pembayaran where pesanan_id = p_pesanan;

  if v_sebelum > v_pesanan.total then
    raise exception 'Pembayaran melebihi total pesanan';
  end if;

  insert into public.pembayaran (pesanan_id, jumlah, metode, dibuat_oleh)
  values (p_pesanan, p_jumlah, p_metode, auth.uid());

  if v_sebelum + p_jumlah >= v_pesanan.total then
    update public.pesanan set status = 'lunas' where id = p_pesanan;
  end if;
end;
$$;

revoke all on function public.terima_bayar(uuid, bigint, text) from public;
grant execute on function public.terima_bayar(uuid, bigint, text) to authenticated;
