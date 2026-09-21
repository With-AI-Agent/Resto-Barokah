-- BAHAN KALIBRASI (bukan kode proyek). Berisi cacat yang disengaja.
create or replace function public.boleh(p_aksi text, p_cabang uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.pengguna p
    where p.id = auth.uid()
      and p.aktif
      and public.izin_efektif(p.id, p_aksi, p_cabang)
  );
$$;

grant execute on function public.boleh(text, uuid) to authenticated;

comment on function public.boleh(text, uuid) is
  'Gerbang izin tunggal. Wajib SECURITY DEFINER + hak execute dicabut dari public.';
