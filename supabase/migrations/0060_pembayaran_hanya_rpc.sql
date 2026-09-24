-- ============================================================================
-- Migrasi 0060: INSERT langsung ke public.pembayaran DITUTUP (M F-01 audit 2026-09-24)
--
-- Solusi: hapus policy `pembayaran_tambah` + revoke INSERT + trigger yang
-- menolak pemanggil non-SECURITY-DEFINER (cek `current_user = session_user`).
-- ============================================================================
drop policy if exists pembayaran_tambah on public.pembayaran;
revoke insert on table public.pembayaran from authenticated, anon, public;

create or replace function public.cegah_pembayaran_langsung()
returns trigger
language plpgsql
as $$
begin
  if current_user = session_user then
    raise exception using
      errcode = 'insufficient_privilege',
      message = 'INSERT langsung ke public.pembayaran ditolak — gunakan RPC bayar_pesanan (T5-02).';
  end if;
  return new;
end;
$$;

comment on function public.cegah_pembayaran_langsung() is
  'M F-01: menolak INSERT langsung ke public.pembayaran dari klien.';

revoke all on function public.cegah_pembayaran_langsung() from public;

drop trigger if exists aa_pembayaran_cegah_insert_langsung on public.pembayaran;
create trigger aa_pembayaran_cegah_insert_langsung
  before insert on public.pembayaran
  for each row execute function public.cegah_pembayaran_langsung();
