-- ============================================================================
-- 0033 — TUJUAN ITEM (dapur/bar): pemisahan otomatis, salinan kekal (T4-02, PRD M5)
--
-- Masalah: layar bar harus menerima hanya minuman tanpa tercampur, dan satu pesanan
-- boleh muncul di DUA layar (bagian masing-masing). Tanpa kolom tujuan, item tanpa
-- kategori/petunjuk bisa tidak muncul di layar mana pun (risiko T4-02).
--
-- Prinsip:
--   * Sumber kebenaran = kategori menu (`kategori_menu.tujuan`, setelan yang bisa
--     diatur owner/admin lewat katalog — tanpa koding). Bawaan 'dapur' (aman: item
--     tidak pernah menghilang dari kedua layar; salah-sasaran paling buruk tampil
--     di dapur, bukan hilang).
--   * `pesanan_item.tujuan` = SALINAN saat pesanan dibuat (seperti nama_saat_itu /
--     harga_saat_itu): mengubah kategori kemudian tidak menggeser pesanan lama.
--   * Salinan ditulis PELADEN lewat pemicu (kiriman 'tujuan' dari perangkat
--     diabaikan) dan TIDAK bisa ditulis ulang setelah lahir.
--   * Item dari menu tanpa kategori/tujuan DITOLAK saat disimpan — tidak ada item
--     yang menghilang dari kedua layar.
-- ============================================================================

alter table public.kategori_menu
  add column if not exists tujuan text not null default 'dapur'
  check (tujuan in ('dapur', 'bar'));

comment on column public.kategori_menu.tujuan is
  'Tujuan layar produksi untuk seluruh item di kategori ini: dapur (masak) atau bar (minuman). Setelan owner/admin.';

alter table public.pesanan_item
  add column if not exists tujuan text check (tujuan in ('dapur', 'bar'));

-- Isi baris lama dari kategori menu-nya (bawaan 'dapur' bila kategori lapuk).
update public.pesanan_item pi
   set tujuan = coalesce(
         (select k.tujuan from public.menu_item m
            join public.kategori_menu k on k.id = m.kategori_id
           where m.id = pi.menu_item_id), 'dapur')
 where pi.tujuan is null;

alter table public.pesanan_item alter column tujuan set not null;

comment on column public.pesanan_item.tujuan is
  'SALINAN tujuan produksi (dapur/bar) dari kategori menu saat pesanan dibuat (T4-02) — tidak berubah walau setelan kategori diubah kemudian.';

create or replace function public.picu_item_tujuan()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_tujuan text;
begin
  if tg_op = 'INSERT' then
    select k.tujuan into v_tujuan
      from public.menu_item m
      join public.kategori_menu k on k.id = m.kategori_id
     where m.id = new.menu_item_id;
    -- Salinan ditulis peladen: kiriman 'tujuan' dari perangkat diabaikan. Menu yang
    -- tidak ada/tidak layak jual TIDAK ditangani di sini — penjaga menu 0012 punya
    -- pesan kanoniknya sendiri ("Menu tidak ditemukan atau tidak dijual di cabang
    -- ini.") dan berhak menyampaikannya lebih dulu setelah pemicu ini.
    new.tujuan := coalesce(v_tujuan, 'dapur');
    return new;
  end if;

  if new.tujuan is distinct from old.tujuan then
    raise exception 'Tujuan item adalah salinan dari kategori saat pesanan dibuat — tidak boleh diubah (% → %).', old.tujuan, new.tujuan;
  end if;
  return new;
end
$$;

drop trigger if exists item_tujuan on public.pesanan_item;
create trigger item_tujuan
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_tujuan();

comment on function public.picu_item_tujuan() is
  'Pemicu T4-02: menurunkan tujuan item (dapur/bar) dari kategori menu saat INSERT (spoof dari perangkat diabaikan) dan membekukan salinan itu dari UPDATE.';

revoke all on function public.picu_item_tujuan() from public, anon, authenticated;
