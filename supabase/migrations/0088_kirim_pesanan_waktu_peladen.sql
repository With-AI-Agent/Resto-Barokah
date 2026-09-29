-- ============================================================================
-- 0088 — KIRIM PESANAN DENGAN WAKTU PELADEN (PMB-1 F-132)
--
-- Timestamp kirim menentukan umur dan urutan tiket dapur. Klien hanya mengirim
-- id pesanan; waktu dibuat oleh PostgreSQL, bukan oleh jam perangkat.
-- SECURITY INVOKER mempertahankan RLS dan pemeriksaan peran pada pemicu pesanan.
-- ============================================================================

create or replace function public.kirim_pesanan(p_pesanan_id uuid)
returns timestamptz
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_waktu timestamptz;
begin
  update public.pesanan
     set status = 'dikirim',
         dikirim_ke_dapur_pada = now()
   where id = p_pesanan_id
     and status = 'draf'
  returning dikirim_ke_dapur_pada into v_waktu;

  if found then
    return v_waktu;
  end if;

  -- Aman diulang setelah klien kehilangan jawaban RPC: kembalikan stempel yang
  -- sudah tersimpan, jangan mengganti waktu kirim dengan waktu percobaan ulang.
  select p.dikirim_ke_dapur_pada
    into v_waktu
    from public.pesanan p
   where p.id = p_pesanan_id
     and p.status = 'dikirim';
  if found and v_waktu is not null then
    return v_waktu;
  end if;

  raise exception 'Pesanan tidak ditemukan, tidak dapat diakses, atau bukan lagi draf.';
end
$$;

comment on function public.kirim_pesanan(uuid) is
  'Mengirim pesanan draf ke dapur secara idempoten. Waktu kirim selalu now() dari peladen; RLS dan pemicu status tetap berlaku.';

revoke all on function public.kirim_pesanan(uuid) from public, anon;
grant execute on function public.kirim_pesanan(uuid) to authenticated;
