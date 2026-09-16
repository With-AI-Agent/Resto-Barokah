-- ============================================================================
-- 0009 — Pesanan & itemnya, dengan SALINAN harga saat itu (ART-3 & ART-4)
--
-- Aturan yang membuat riwayat tidak bisa berubah artinya:
--   * `pesanan_item` menyimpan `nama_saat_itu` dan `harga_saat_itu` (WAJIB, NOT NULL).
--     Harga menu boleh berubah kapan saja; struk dan laporan lama TIDAK ikut berubah.
--   * Nomor pesanan unik **per cabang per tanggal** (tanggal dihitung menurut zona
--     waktu resto — fungsi penomorannya menyusul di T1-17; kolomnya sudah siap).
--   * `kunci_idempoten` unik: satu keranjang tidak bisa tersimpan dua kali walau
--     koneksi terputus dan kasir menekan tombol lagi.
--   * Pesanan TIDAK PERNAH dihapus: kolom batal + alasan yang dipakai (Aturan Bisnis 7).
--   * Daftar status resmi disamakan dengan TECH_SPEC §4.3: draf → dikirim → dimasak
--     → siap → lunas, dan batal. Aturan perpindahannya dijaga di T1-18.
--   * Meja hanya boleh dipakai oleh pesanan di cabang yang sama.
-- ============================================================================

create table if not exists public.pesanan (
  id                    uuid primary key default gen_random_uuid(),
  penyewa_id            uuid not null references public.penyewa (id) on delete cascade,
  cabang_id             uuid not null references public.cabang (id) on delete restrict,
  nomor                 integer,
  tanggal               date not null default current_date,
  tipe                  text not null default 'dinein' check (tipe in ('dinein', 'takeaway', 'ojol')),
  meja_id               uuid references public.meja (id) on delete set null,
  status                text not null default 'draf'
                          check (status in ('draf', 'dikirim', 'dimasak', 'siap', 'lunas', 'batal')),
  pelayan_id            uuid references public.pengguna (id) on delete set null,
  kasir_id              uuid references public.pengguna (id) on delete set null,
  shift_id              uuid,
  dibuat_pada           timestamptz not null default now(),
  dikirim_ke_dapur_pada timestamptz,
  catatan               text,
  subtotal              integer not null default 0 check (subtotal >= 0),
  pajak                 integer not null default 0 check (pajak >= 0),
  service               integer not null default 0 check (service >= 0),
  total_diskon          integer not null default 0 check (total_diskon >= 0),
  total                 integer not null default 0 check (total >= 0),
  dibayar_pada          timestamptz,
  dibatalkan_pada       timestamptz,
  alasan_batal          text,
  kunci_idempoten       text not null,
  unique (cabang_id, kunci_idempoten),
  unique (cabang_id, tanggal, nomor)
);

comment on table public.pesanan is
  'Pesanan per cabang. Nomor unik per cabang per tanggal; kunci_idempoten mencegah pesanan ganda saat koneksi terputus. Uang dihitung peladen (hitung_total, T1-15).';

alter table public.pesanan enable row level security;

create index if not exists pesanan_cabang_tanggal_idx on public.pesanan (cabang_id, tanggal desc);
create index if not exists pesanan_status_idx on public.pesanan (cabang_id, status) where status <> 'lunas';

-- ------------------------------------------------------------- pesanan_item
create table if not exists public.pesanan_item (
  id              uuid primary key default gen_random_uuid(),
  pesanan_id      uuid not null references public.pesanan (id) on delete cascade,
  menu_item_id    uuid not null references public.menu_item (id) on delete restrict,
  nama_saat_itu   text not null,                    -- salinan nama: menu boleh diganti nama
  harga_saat_itu  integer not null check (harga_saat_itu >= 0),   -- salinan harga: WAJIB
  qty             integer not null check (qty > 0),
  varian          jsonb,
  tambahan        jsonb,
  catatan         text,
  status          text not null default 'baru' check (status in ('baru', 'dimasak', 'siap', 'batal')),
  subtotal        integer not null default 0 check (subtotal >= 0),
  dibuat_pada     timestamptz not null default now()
);

comment on table public.pesanan_item is
  'Baris pesanan. nama_saat_itu & harga_saat_itu adalah SALINAN saat pesanan dibuat sehingga perubahan menu/harga tidak mengubah riwayat.';

alter table public.pesanan_item enable row level security;

create index if not exists pesanan_item_pesanan_idx on public.pesanan_item (pesanan_id);

-- ============================ pembantu: pesanan ini milik siapa =============
create or replace function public.pesanan_sepenyewa(p_pesanan_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.pesanan p
     where p.id = p_pesanan_id
       and p.penyewa_id = public.penyewa_saya()
       and public.cabang_pantau_saya(p.cabang_id)
  )
$$;

comment on function public.pesanan_sepenyewa(uuid) is
  'Benar bila pesanan itu milik resto pengguna DAN berada di cabang yang boleh ia pantau. Dipakai policy baris item pesanan (yang tidak punya kolom penyewa_id sendiri).';

-- ============================ pemicu: menjaga pesanan tetap konsisten ======
create or replace function public.picu_pesanan_konsisten()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_cabang uuid;
  v_penyewa_meja   uuid;
  v_cabang_meja    uuid;
begin
  select c.penyewa_id into v_penyewa_cabang from public.cabang c where c.id = new.cabang_id;
  if v_penyewa_cabang is null then
    raise exception 'Cabang tidak ditemukan.';
  end if;
  if v_penyewa_cabang <> new.penyewa_id then
    raise exception 'Cabang dan pesanan harus berada di resto yang sama.';
  end if;

  if new.meja_id is not null then
    select m.cabang_id, c.penyewa_id
      into v_cabang_meja, v_penyewa_meja
      from public.meja m
      join public.cabang c on c.id = m.cabang_id
     where m.id = new.meja_id;
    if v_cabang_meja is null then
      raise exception 'Meja tidak ditemukan.';
    end if;
    if v_cabang_meja <> new.cabang_id then
      raise exception 'Meja itu berada di cabang lain — pesanan tidak boleh memakainya.';
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists pesanan_jaga_konsisten on public.pesanan;
create trigger pesanan_jaga_konsisten
  before insert or update on public.pesanan
  for each row execute function public.picu_pesanan_konsisten();

-- Item pesanan tidak boleh memakai menu resto lain (dan sekaligus mengisi salinan
-- nama/harga bila pemanggil mengirimnya kosong? TIDAK — salinan WAJIB dari pemanggil
-- supaya nilai yang dibekukan terlihat jelas di kode pemanggil, bukan tersembunyi).
create or replace function public.picu_item_pesanan_konsisten()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_menu    uuid;
  v_penyewa_pesanan uuid;
begin
  select mi.penyewa_id into v_penyewa_menu from public.menu_item mi where mi.id = new.menu_item_id;
  select p.penyewa_id into v_penyewa_pesanan from public.pesanan p where p.id = new.pesanan_id;

  if v_penyewa_menu is null or v_penyewa_pesanan is null then
    raise exception 'Menu atau pesanan tidak ditemukan.';
  end if;
  if v_penyewa_menu <> v_penyewa_pesanan then
    raise exception 'Menu dan pesanan harus berada di resto yang sama.';
  end if;
  return new;
end
$$;

drop trigger if exists pesanan_item_jaga_konsisten on public.pesanan_item;
create trigger pesanan_item_jaga_konsisten
  before insert or update on public.pesanan_item
  for each row execute function public.picu_item_pesanan_konsisten();

-- Salinan beku: nama & harga saat itu TIDAK BOLEH ditulis ulang oleh siapa pun.
-- Salah harga diperbaiki dengan membatalkan item lalu menambah baris baru —
-- itulah jalur yang meninggalkan jejak, bukan mengubah riwayat diam-diam.
create or replace function public.picu_item_salinan_beku()
returns trigger
language plpgsql
as $$
begin
  if new.nama_saat_itu  is distinct from old.nama_saat_itu
     or new.harga_saat_itu is distinct from old.harga_saat_itu
     or new.menu_item_id   is distinct from old.menu_item_id
     or new.pesanan_id     is distinct from old.pesanan_id then
    raise exception 'Nama & harga yang sudah tercatat tidak boleh diubah. Batalkan item itu lalu tambahkan baris baru.';
  end if;
  return new;
end
$$;

drop trigger if exists pesanan_item_salinan_beku on public.pesanan_item;
create trigger pesanan_item_salinan_beku
  before update on public.pesanan_item
  for each row execute function public.picu_item_salinan_beku();

-- ===================================== KEBIJAKAN (RLS) =====================
-- Pesanan terlihat oleh pegawai cabang itu; owner pusat melihat seluruh restonya.
create policy pesanan_pilih on public.pesanan
  for select to authenticated
  using (penyewa_id = public.penyewa_saya() and public.cabang_pantau_saya(cabang_id));

-- Pesanan dibuat pelayan/kasir di cabangnya (meja & jalur mandiri menyusul).
create policy pesanan_tambah on public.pesanan
  for insert to authenticated
  with check (
    penyewa_id = public.penyewa_saya()
    and public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

create policy pesanan_ubah on public.pesanan
  for update to authenticated
  using (
    penyewa_id = public.penyewa_saya()
    and public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    penyewa_id = public.penyewa_saya()
    and public.cabang_pantau_saya(cabang_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

create policy pesanan_item_pilih on public.pesanan_item
  for select to authenticated
  using (public.pesanan_sepenyewa(pesanan_id));

create policy pesanan_item_tambah on public.pesanan_item
  for insert to authenticated
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

create policy pesanan_item_ubah on public.pesanan_item
  for update to authenticated
  using (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  )
  with check (
    public.pesanan_sepenyewa(pesanan_id)
    and public.peran_saya() in ('owner_pusat', 'admin_cabang', 'kasir', 'pelayan')
  );

-- Pesanan TIDAK PERNAH dihapus (hanya dibatalkan) — dapur pun perlu MENGUBAH status
-- itemnya (baru → dimasak → siap).
create policy pesanan_item_dapur on public.pesanan_item
  for update to authenticated
  using (public.pesanan_sepenyewa(pesanan_id) and public.peran_saya() = 'dapur')
  with check (public.pesanan_sepenyewa(pesanan_id) and public.peran_saya() = 'dapur');

grant select on public.pesanan, public.pesanan_item to anon;
grant select, insert, update on public.pesanan, public.pesanan_item to authenticated;
grant select, insert, update, delete on public.pesanan, public.pesanan_item to service_role;

revoke all on function public.pesanan_sepenyewa(uuid) from public;
grant execute on function public.pesanan_sepenyewa(uuid) to authenticated, service_role;
