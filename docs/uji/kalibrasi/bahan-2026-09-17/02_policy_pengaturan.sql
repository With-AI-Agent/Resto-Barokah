-- BAHAN KALIBRASI (bukan kode proyek). Berisi cacat yang disengaja.
alter table public.pengaturan enable row level security;

create policy pengaturan_pilih on public.pengaturan
  for select to authenticated
  using (penyewa_id is not null);

create policy pengaturan_ubah on public.pengaturan
  for update to authenticated
  using (penyewa_id = public.penyewa_saya())
  with check (penyewa_id = public.penyewa_saya());
