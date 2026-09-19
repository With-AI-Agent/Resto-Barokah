-- ============================================================================
-- 0007 — Katalog (kategori, menu, varian, tambahan, harga per cabang) & stok
--
-- Dua hal yang dijaga ketat di sini:
--   1. HARGA PER CABANG: harga menu boleh berbeda per cabang. Bila cabang tidak
--      punya harga sendiri → dipakai harga pusat. Satu fungsi `harga_berlaku()`
--      yang menentukan, jadi layar kasir, katalog pelanggan, dan perhitungan
--      uang tidak mungkin berbeda pendapat.
--   2. STOK TIDAK BOLEH MENYIMPANG DARI CATATANNYA: setiap perubahan stok wajib
--      lewat `stok_pergerakan` (buku besar yang tidak boleh diubah/dihapus), dan
--      pemicu di database yang menjumlahkannya ke `stok_bahan.jumlah`. Mengubah
--      `jumlah` langsung DITOLAK — jadi angka stok selalu bisa ditelusuri asal-usulnya.
--
-- Tambahan kolom `penyewa_id` pada `menu_tambahan` & `stok_pergerakan` bukan
-- hiasan: tanpa itu, baris "tambahan yang berlaku untuk semua menu" dan baris
-- buku besar stok tidak bisa dipisahkan per resto sesuai ART-1.
-- ============================================================================

-- ------------------------------------------------------------- kategori_menu
create table if not exists public.kategori_menu (
  id          uuid primary key default gen_random_uuid(),
  penyewa_id  uuid not null references public.penyewa (id) on delete cascade,
  nama        text not null,
  urutan      integer not null default 0,
  aktif       boolean not null default true,
  dibuat_pada timestamptz not null default now(),
  diubah_pada timestamptz not null default now(),
  unique (penyewa_id, nama)
);

alter table public.kategori_menu enable row level security;

-- ----------------------------------------------------------------- menu_item
create table if not exists public.menu_item (
  id          uuid primary key default gen_random_uuid(),
  penyewa_id  uuid not null references public.penyewa (id) on delete cascade,
  kategori_id uuid not null references public.kategori_menu (id) on delete restrict,
  nama        text not null,
  deskripsi   text,
  harga       integer not null check (harga >= 0),                    -- rupiah bulat, harga pusat
  foto_path   text,
  urutan      integer not null default 0,
  unggulan    boolean not null default false,
  jenis       text not null check (jenis in ('makanan', 'minuman', 'lainnya')),
  aktif       boolean not null default true,
  dibuat_pada timestamptz not null default now(),
  diubah_pada timestamptz not null default now(),
  unique (penyewa_id, kategori_id, nama)
);

alter table public.menu_item enable row level security;

-- --------------------------------------------------------------- menu_varian
create table if not exists public.menu_varian (
  menu_item_id    uuid not null references public.menu_item (id) on delete cascade,
  nama            text not null,
  tambahan_harga  integer not null default 0 check (tambahan_harga between -1000000 and 1000000),
  aktif           boolean not null default true,
  primary key (menu_item_id, nama)
);

alter table public.menu_varian enable row level security;

-- ------------------------------------------------------------- menu_tambahan
create table if not exists public.menu_tambahan (
  id           uuid primary key default gen_random_uuid(),
  penyewa_id   uuid not null references public.penyewa (id) on delete cascade,
  menu_item_id uuid references public.menu_item (id) on delete cascade,   -- null = berlaku semua menu
  nama         text not null,
  harga        integer not null default 0 check (harga >= 0),
  aktif        boolean not null default true
);

alter table public.menu_tambahan enable row level security;

-- --------------------------------------------------------------- menu_cabang
create table if not exists public.menu_cabang (
  cabang_id    uuid not null references public.cabang (id) on delete cascade,
  menu_item_id uuid not null references public.menu_item (id) on delete cascade,
  harga        integer check (harga is null or harga >= 0),               -- null = ikut harga pusat
  aktif        boolean not null default true,
  habis        boolean not null default false,
  primary key (cabang_id, menu_item_id)
);

alter table public.menu_cabang enable row level security;

comment on column public.menu_cabang.harga is
  'Harga khusus cabang. NULL = pakai harga pusat (menu_item.harga). Diisi hanya bila memang beda.';

-- ---------------------------------------------------------------- stok_bahan
create table if not exists public.stok_bahan (
  id          uuid primary key default gen_random_uuid(),
  penyewa_id  uuid not null references public.penyewa (id) on delete cascade,
  nama        text not null,
  satuan      text not null default 'pcs',
  jumlah      numeric(12, 3) not null default 0,     -- boleh negatif: dijaga oleh opname, bukan dilarang
  minimum     numeric(12, 3) not null default 0 check (minimum >= 0),
  dipantau    boolean not null default false,
  diubah_pada timestamptz not null default now(),
  unique (penyewa_id, nama)
);

alter table public.stok_bahan enable row level security;

-- ------------------------------------------------------------ stok_pergerakan
create table if not exists public.stok_pergerakan (
  id            bigserial primary key,
  penyewa_id    uuid references public.penyewa (id) on delete cascade,           -- diisi otomatis dari bahannya (pemicu)
  stok_bahan_id uuid not null references public.stok_bahan (id) on delete cascade,
  jenis         text not null check (jenis in ('masuk', 'keluar', 'opname', 'koreksi')),
  jumlah        numeric(12, 3) not null,           -- SELALU perubahan (delta): masuk +, keluar -.
  alasan        text,
  pelaku_id     uuid references public.pengguna (id) on delete set null,
  waktu         timestamptz not null default now(),
  check (jenis <> 'koreksi' or (alasan is not null and length(btrim(alasan)) > 0))
);

comment on table public.stok_pergerakan is
  'Buku besar stok — TIDAK PERNAH diubah atau dihapus. `jumlah` selalu PERUBAHAN (delta), bukan angka akhir: masuk +, keluar -, opname/koreksi boleh + atau -.';

alter table public.stok_pergerakan enable row level security;

create index if not exists stok_pergerakan_bahan_waktu_idx
  on public.stok_pergerakan (stok_bahan_id, waktu desc);

-- ================================ HARGA BERLAKU (satu sumber kebenaran) =====
create or replace function public.harga_berlaku(p_menu_item_id uuid, p_cabang_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(mc.harga, mi.harga)
    from public.menu_item mi
    left join public.menu_cabang mc
           on mc.menu_item_id = mi.id
          and mc.cabang_id = p_cabang_id
   where mi.id = p_menu_item_id
     and mi.penyewa_id = public.penyewa_saya()      -- tidak bisa dipakai mengintip menu resto lain
$$;

comment on function public.harga_berlaku(uuid, uuid) is
  'Harga yang benar-benar berlaku di satu cabang: harga khusus cabang bila ada, kalau tidak harga pusat. Dipakai kasir, katalog pelanggan, dan hitung_total.';

-- Cabang mana yang boleh saya lihat/urus? Cabang tempat saya bertugas, ATAU
-- seluruh cabang resto saya bila saya owner pusat (owner tidak bertugas di kasir,
-- jadi tanpa aturan ini ia tidak melihat harga cabang mana pun).
create or replace function public.cabang_pantau_saya(p_cabang_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p_cabang_id in (select public.cabang_ids_saya())
      or (
        public.peran_saya() = 'owner_pusat'
        and exists (
          select 1 from public.cabang c
           where c.id = p_cabang_id
             and c.penyewa_id = public.penyewa_saya()
        )
      )
$$;

comment on function public.cabang_pantau_saya(uuid) is
  'Benar bila cabang itu cabang tempat pengguna bertugas, atau (untuk owner pusat) cabang mana pun di restonya.';

-- Apakah menu itu milik resto pengguna yang sedang masuk?
create or replace function public.menu_sepenyewa(p_menu_item_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.menu_item mi
     where mi.id = p_menu_item_id
       and mi.penyewa_id = public.penyewa_saya()
  )
$$;

comment on function public.menu_sepenyewa(uuid) is
  'Benar bila menu berada di resto pengguna yang sedang masuk (dipakai policy varian menu, yang tidak punya kolom penyewa_id sendiri).';

-- Apakah menu sedang ditandai habis di cabang itu?
create or replace function public.menu_habis(p_menu_item_id uuid, p_cabang_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((
    select mc.habis
      from public.menu_cabang mc
      join public.cabang c on c.id = mc.cabang_id
     where mc.menu_item_id = p_menu_item_id
       and mc.cabang_id = p_cabang_id
       and c.penyewa_id = public.penyewa_saya()
  ), false)
$$;

-- =========================== STOK: buku besar & penjaga angkanya ============
-- Pemicu 1: baris buku besar mengisi penyewa_id sendiri & menolak bahan resto lain.
create or replace function public.picu_stok_pergerakan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  select b.penyewa_id into v_penyewa
    from public.stok_bahan b
   where b.id = new.stok_bahan_id;

  if v_penyewa is null then
    raise exception 'Bahan stok tidak ditemukan.';
  end if;

  if public.penyewa_saya() is not null and v_penyewa <> public.penyewa_saya() then
    raise exception 'Bahan itu bukan milik resto Anda.';
  end if;

  -- Nilai yang bertentangan dengan bahannya DITOLAK tegas (jangan diam-diam
  -- dibetulkan: catatan stok harus jujur soal milik siapa).
  if new.penyewa_id is not null and new.penyewa_id <> v_penyewa then
    raise exception 'Penyewa pada catatan stok tidak sesuai dengan bahannya.';
  end if;

  new.penyewa_id := v_penyewa;
  if new.pelaku_id is null then
    new.pelaku_id := auth.uid();
  end if;
  -- Jejak pelaku tidak boleh dikarang klien (temuan audit AUD-3 K-2, 2026-09-17).
  if auth.uid() is not null and new.pelaku_id is distinct from auth.uid() then
    raise exception 'Pelaku catatan stok diisi sistem — tidak boleh menyebut orang lain.';
  end if;
  return new;
end
$$;

drop trigger if exists stok_pergerakan_isi_penyewa on public.stok_pergerakan;
create trigger stok_pergerakan_isi_penyewa
  before insert on public.stok_pergerakan
  for each row execute function public.picu_stok_pergerakan();

-- Pemicu 2: buku besar MENJUMLAHKAN sendiri ke saldo bahan.
create or replace function public.picu_stok_jumlahkan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Tidak ada lagi penanda sesi: penjaga saldo memakai keadaan "sedang berjalan sebagai
  -- pemilik tabel" (peladen) yang TIDAK bisa dipalsukan klien — temuan audit AUD-3 K-2/A F-06.
  update public.stok_bahan
     set jumlah = jumlah + new.jumlah,
         diubah_pada = now()
   where id = new.stok_bahan_id;

  return new;
end
$$;

drop trigger if exists stok_pergerakan_jumlahkan on public.stok_pergerakan;
create trigger stok_pergerakan_jumlahkan
  after insert on public.stok_pergerakan
  for each row execute function public.picu_stok_jumlahkan();

-- Pemicu 3: menolak perubahan `jumlah` yang tidak lewat buku besar.
-- PENTING: TIDAK SECURITY DEFINER — kalau definer, `current_user` menjadi pemilik fungsi
-- sehingga `peran_peladen()` selalu benar dan penjaganya buta (pelajaran yang sama dengan
-- penjaga uang & status). Versi sebelumnya memakai penanda sesi `app.stok_dari_buku_besar`
-- yang bisa dipasang klien sendiri — temuan audit AUD-3 K-2/A F-06.
create or replace function public.picu_jaga_jumlah_stok()
returns trigger
language plpgsql
as $$
begin
  if new.jumlah is distinct from old.jumlah and not public.peran_peladen() then
    raise exception 'Jumlah stok hanya boleh berubah lewat catatan pergerakan stok (bukan ditulis langsung).';
  end if;
  return new;
end
$$;

drop trigger if exists stok_bahan_jaga_jumlah on public.stok_bahan;
create trigger stok_bahan_jaga_jumlah
  before update on public.stok_bahan
  for each row execute function public.picu_jaga_jumlah_stok();

-- Pemicu 4: tambahan yang menempel ke menu wajib satu resto dengan menunya.
create or replace function public.picu_penyewa_tambahan()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_menu uuid;
begin
  if new.menu_item_id is not null then
    select mi.penyewa_id into v_penyewa_menu
      from public.menu_item mi
     where mi.id = new.menu_item_id;
    if v_penyewa_menu is null then
      raise exception 'Menu tidak ditemukan.';
    end if;
    if v_penyewa_menu <> new.penyewa_id then
      raise exception 'Tambahan dan menunya harus berada di resto yang sama.';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists menu_tambahan_jaga_resto on public.menu_tambahan;
create trigger menu_tambahan_jaga_resto
  before insert or update on public.menu_tambahan
  for each row execute function public.picu_penyewa_tambahan();

-- Pemicu 5: harga khusus cabang hanya untuk cabang & menu satu resto.
create or replace function public.picu_jaga_menu_cabang()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_cabang uuid;
  v_penyewa_menu   uuid;
begin
  select penyewa_id into v_penyewa_cabang from public.cabang where id = new.cabang_id;
  select penyewa_id into v_penyewa_menu from public.menu_item where id = new.menu_item_id;
  if v_penyewa_cabang is null or v_penyewa_menu is null or v_penyewa_cabang <> v_penyewa_menu then
    raise exception 'Cabang dan menu harus berada di resto yang sama.';
  end if;

  -- Menandai "habis" adalah tugas harian (boleh pelayan/dapur/kasir), tetapi
  -- MENGUBAH HARGA tetap milik owner pusat / admin cabang saja.
  if (tg_op = 'INSERT' and new.harga is not null)
     or (tg_op = 'UPDATE' and new.harga is distinct from old.harga) then
    -- Tanpa pengguna masuk (penyiapan awal / peladen sendiri) pemeriksaan ini
    -- tidak berlaku: penulisan seperti itu toh sudah melewati RLS & kunci peladen.
    if auth.uid() is not null
       and coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang') then
      raise exception 'Menetapkan/mengubah harga hanya boleh oleh owner pusat atau admin cabang.';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists menu_cabang_jaga on public.menu_cabang;
create trigger menu_cabang_jaga
  before insert or update on public.menu_cabang
  for each row execute function public.picu_jaga_menu_cabang();

-- ============================== CATAT STOK (satu pintu masuk) ===============
create or replace function public.catat_stok(
  p_stok_bahan_id uuid,
  p_jenis         text,
  p_jumlah        numeric,
  p_alasan        text default null
)
returns numeric
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saldo numeric;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  if not public.boleh('ubah_stok') then
    raise exception 'Anda tidak berizin mengubah stok.';
  end if;

  if p_jenis not in ('masuk', 'keluar', 'opname', 'koreksi') then
    raise exception 'Jenis pergerakan stok tidak dikenal: %.', p_jenis;
  end if;

  insert into public.stok_pergerakan (penyewa_id, stok_bahan_id, jenis, jumlah, alasan)
  values (public.penyewa_saya(), p_stok_bahan_id, p_jenis, p_jumlah, p_alasan);

  select b.jumlah into v_saldo from public.stok_bahan b where b.id = p_stok_bahan_id;
  return v_saldo;
end
$$;

comment on function public.catat_stok(uuid, text, numeric, text) is
  'Satu pintu mencatat pergerakan stok (masuk/keluar/opname/koreksi). Saldo bahan diperbarui pemicu, bukan oleh pemanggil.';

-- ===================================== KEBIJAKAN (RLS) =====================
-- Semua pegawai resto boleh MELIHAT katalog & stok restonya (kasir/dapur perlu).
create policy kategori_menu_pilih on public.kategori_menu
  for select to authenticated using (penyewa_id = public.penyewa_saya());

create policy menu_item_pilih on public.menu_item
  for select to authenticated using (penyewa_id = public.penyewa_saya());

create policy menu_varian_pilih on public.menu_varian
  for select to authenticated
  using (public.menu_sepenyewa(menu_item_id));

create policy menu_tambahan_pilih on public.menu_tambahan
  for select to authenticated using (penyewa_id = public.penyewa_saya());

create policy menu_cabang_pilih on public.menu_cabang
  for select to authenticated using (public.cabang_pantau_saya(cabang_id));

create policy stok_bahan_pilih on public.stok_bahan
  for select to authenticated using (penyewa_id = public.penyewa_saya());

create policy stok_pergerakan_pilih on public.stok_pergerakan
  for select to authenticated using (penyewa_id = public.penyewa_saya());

-- Mengubah katalog = owner pusat & admin cabang (daftar izin resmi tidak memuat
-- "kelola menu"; keputusan ini dicatat di DECISIONS_LOG).
create policy kategori_menu_ubah on public.kategori_menu
  for all to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'))
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'));

create policy menu_item_ubah on public.menu_item
  for all to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'))
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'));

create policy menu_varian_ubah on public.menu_varian
  for all to authenticated
  using (public.peran_saya() in ('owner_pusat', 'admin_cabang') and public.menu_sepenyewa(menu_item_id))
  with check (public.peran_saya() in ('owner_pusat', 'admin_cabang') and public.menu_sepenyewa(menu_item_id));

create policy menu_tambahan_ubah on public.menu_tambahan
  for all to authenticated
  using (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'))
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'));

-- Penanda "habis" & harga khusus cabang: pegawai ber-izin ubah_stok (dapur/kasir)
-- boleh menandai habis; mengubah HARGA dijaga pemicu menu_cabang_jaga.
create policy menu_cabang_ubah on public.menu_cabang
  for all to authenticated
  using (public.cabang_pantau_saya(cabang_id) and (public.peran_saya() in ('owner_pusat', 'admin_cabang') or public.boleh('ubah_stok')))
  with check (public.cabang_pantau_saya(cabang_id) and (public.peran_saya() in ('owner_pusat', 'admin_cabang') or public.boleh('ubah_stok')));

create policy stok_bahan_ubah on public.stok_bahan
  for update to authenticated
  using (penyewa_id = public.penyewa_saya() and public.boleh('ubah_stok'))
  with check (penyewa_id = public.penyewa_saya() and public.boleh('ubah_stok'));

create policy stok_bahan_tambah on public.stok_bahan
  for insert to authenticated
  with check (penyewa_id = public.penyewa_saya() and public.peran_saya() in ('owner_pusat', 'admin_cabang'));

-- Buku besar stok: boleh MENAMBAH (lewat izin ubah_stok), tidak pernah diubah/dihapus.
create policy stok_pergerakan_tambah on public.stok_pergerakan
  for insert to authenticated
  with check (penyewa_id = public.penyewa_saya() and public.boleh('ubah_stok'));

-- =================================== HAK TINGKAT TABEL =====================
grant select on public.kategori_menu, public.menu_item, public.menu_varian,
                public.menu_tambahan, public.menu_cabang, public.stok_bahan,
                public.stok_pergerakan to anon, authenticated;

grant insert, update, delete on public.kategori_menu, public.menu_item,
                                public.menu_varian, public.menu_tambahan to authenticated;
grant insert, update on public.menu_cabang to authenticated;
grant insert, update on public.stok_bahan to authenticated;
grant insert on public.stok_pergerakan to authenticated;
grant usage, select on sequence public.stok_pergerakan_id_seq to authenticated;

grant select, insert, update, delete on public.kategori_menu, public.menu_item,
     public.menu_varian, public.menu_tambahan, public.menu_cabang, public.stok_bahan,
     public.stok_pergerakan to service_role;
grant usage, select on sequence public.stok_pergerakan_id_seq to service_role;

revoke all on function public.cabang_pantau_saya(uuid) from public;
grant execute on function public.cabang_pantau_saya(uuid) to authenticated, service_role;

revoke all on function public.menu_sepenyewa(uuid) from public;
grant execute on function public.menu_sepenyewa(uuid) to authenticated, service_role;

revoke all on function public.harga_berlaku(uuid, uuid) from public;
revoke all on function public.menu_habis(uuid, uuid) from public;
revoke all on function public.catat_stok(uuid, text, numeric, text) from public;
grant execute on function public.harga_berlaku(uuid, uuid) to anon, authenticated, service_role;
grant execute on function public.menu_habis(uuid, uuid) to anon, authenticated, service_role;
grant execute on function public.catat_stok(uuid, text, numeric, text) to authenticated, service_role;
