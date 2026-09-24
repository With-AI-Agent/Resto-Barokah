-- ============================================================================
-- 0045 — Buka shift kasir (T7-01, PRD M7, TECH_SPEC §4.3 & §9 ART-6)
--
-- Pagar integritas kas & shift:
--   1. Tabel `public.shift_kas` mencatat sesi kasir per cabang:
--      - modal_awal wajib (>= 0), uang_seharusnya, uang_fisik, selisih, alasan_selisih, status.
--      - foreign key pesanan.shift_id dan pembayaran.shift_id disambungkan ke shift_kas(id).
--   2. Aturan DoD T7-01:
--      - Modal awal wajib dicatat saat buka kas.
--      - Satu shift terbuka per kasir per cabang (dijaga indeks parsial unik + pengecekan di RPC).
--      - Tercatat siapa & kapan (dibuka_oleh dari auth.uid(), dibuka_pada dari waktu peladen now()).
--   3. Keamanan & Integritas:
--      - RLS aktif dengan helper penyewa_saya() dan cabang_pantau_saya(cabang_id).
--      - Pemicu picu_shift_kas_jaga melarang DELETE dan mengunci modal_awal/identitas saat UPDATE.
--      - Klien authenticated hanya diberi hak SELECT; penulisan wajib melalui RPC definer.
--      - RPC buka_shift mencatat peristiwa ke catatan_audit berantai hash.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tabel shift_kas
-- ---------------------------------------------------------------------------
create table if not exists public.shift_kas (
  id                uuid primary key default gen_random_uuid(),
  penyewa_id        uuid not null references public.penyewa (id) on delete cascade,
  cabang_id         uuid not null references public.cabang (id) on delete restrict,
  dibuka_oleh       uuid not null references public.pengguna (id) on delete restrict,
  ditutup_oleh      uuid references public.pengguna (id) on delete set null,
  dibuka_pada       timestamptz not null default now(),
  ditutup_pada      timestamptz,
  modal_awal        integer not null check (modal_awal >= 0),
  uang_seharusnya   integer check (uang_seharusnya is null or uang_seharusnya >= 0),
  uang_fisik        integer check (uang_fisik is null or uang_fisik >= 0),
  selisih           integer,
  alasan_selisih    text,
  status            text not null default 'terbuka' check (status in ('terbuka', 'ditutup')),
  catatan           text,
  constraint shift_kas_status_konsisten check (
    (status = 'terbuka' and ditutup_pada is null) or
    (status = 'ditutup' and ditutup_pada is not null)
  )
);

comment on table public.shift_kas is
  'M7: Sesi shift kasir per cabang. Modal awal wajib dicatat; satu shift terbuka per kasir per cabang; ditutup dengan rekonsiliasi uang fisik vs sistem.';

-- Indeks penelusuran & performa
create index if not exists shift_kas_penyewa_idx on public.shift_kas (penyewa_id);
create index if not exists shift_kas_cabang_idx on public.shift_kas (cabang_id);
create index if not exists shift_kas_dibuka_oleh_idx on public.shift_kas (dibuka_oleh);

-- DoD T7-01: Satu shift terbuka per kasir per cabang
create unique index if not exists shift_kas_aktif_unik
  on public.shift_kas (cabang_id, dibuka_oleh)
  where (status = 'terbuka');

-- ---------------------------------------------------------------------------
-- 2. Kunci asing pesanan.shift_id dan pembayaran.shift_id
-- ---------------------------------------------------------------------------
alter table public.pesanan
  drop constraint if exists pesanan_shift_fkey;
alter table public.pesanan
  add constraint pesanan_shift_fkey
  foreign key (shift_id) references public.shift_kas (id) on delete set null;

alter table public.pembayaran
  drop constraint if exists pembayaran_shift_fkey;
alter table public.pembayaran
  add constraint pembayaran_shift_fkey
  foreign key (shift_id) references public.shift_kas (id) on delete set null;

-- ---------------------------------------------------------------------------
-- 3. Pemicu penjaga integritas kekal shift_kas
-- ---------------------------------------------------------------------------
create or replace function public.picu_shift_kas_jaga()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if TG_OP = 'DELETE' then
    raise exception 'Baris shift kas tidak boleh dihapus demi integritas jejak audit.';
  end if;

  if TG_OP = 'UPDATE' then
    -- Identitas dasar tidak boleh diubah
    NEW.penyewa_id := OLD.penyewa_id;
    NEW.cabang_id := OLD.cabang_id;
    NEW.dibuka_oleh := OLD.dibuka_oleh;
    NEW.dibuka_pada := OLD.dibuka_pada;

    -- Modal awal tidak boleh diubah langsung lewat update
    if NEW.modal_awal <> OLD.modal_awal then
      if current_setting('app.dalam_koreksi_modal', true) is distinct from 'true' then
        raise exception 'Modal awal tidak boleh diubah langsung — gunakan prosedur koreksi modal.';
      end if;
    end if;

    -- Shift yang sudah ditutup tidak boleh diubah lagi
    if OLD.status = 'ditutup' then
      raise exception 'Shift yang sudah ditutup tidak boleh diubah lagi.';
    end if;
  end if;

  return NEW;
end;
$$;

comment on function public.picu_shift_kas_jaga() is
  'Mencegah penghapusan riwayat shift kas dan mengunci identitas serta modal awal dari perubahan langsung.';

drop trigger if exists trg_shift_kas_jaga on public.shift_kas;
create trigger trg_shift_kas_jaga
  before update or delete on public.shift_kas
  for each row execute function public.picu_shift_kas_jaga();

-- ---------------------------------------------------------------------------
-- 4. Hak akses & Policy RLS pada shift_kas
-- ---------------------------------------------------------------------------
alter table public.shift_kas enable row level security;

drop policy if exists shift_kas_pilih on public.shift_kas;
create policy shift_kas_pilih on public.shift_kas
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
  );

revoke all on table public.shift_kas from public, anon, authenticated;
grant select on table public.shift_kas to authenticated;
grant all on table public.shift_kas to service_role;

-- ---------------------------------------------------------------------------
-- 5. RPC buka_shift (pintu tunggal pembukaan shift kasir)
-- ---------------------------------------------------------------------------
create or replace function public.buka_shift(
  p_modal_awal  integer,
  p_cabang_id   uuid    default null,
  p_catatan     text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa        uuid;
  v_cabang_id      uuid;
  v_shift_aktif_id uuid;
  v_baru           public.shift_kas%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- Pagar peran: kasir, admin cabang, atau owner pusat
  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak berwenang membuka shift kasir.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  -- Cabang aktif
  v_cabang_id := coalesce(p_cabang_id, public.cabang_saya());
  if v_cabang_id is null then
    raise exception 'Cabang wajib ditentukan.';
  end if;

  if not public.cabang_pantau_saya(v_cabang_id) then
    raise exception 'Cabang tidak ditemukan atau di luar wewenang Anda.';
  end if;

  -- Modal awal wajib & tidak boleh negatif
  if p_modal_awal is null then
    raise exception 'Modal awal wajib diisi.';
  end if;

  if p_modal_awal < 0 then
    raise exception 'Modal awal tidak boleh bernilai negatif.';
  end if;

  -- DoD: satu shift terbuka per kasir per cabang
  select id into v_shift_aktif_id
    from public.shift_kas
   where cabang_id = v_cabang_id
     and dibuka_oleh = auth.uid()
     and status = 'terbuka'
   limit 1;

  if v_shift_aktif_id is not null then
    raise exception 'SH-409: Anda masih memiliki shift kasir yang aktif di cabang ini (ID: %).', v_shift_aktif_id;
  end if;

  insert into public.shift_kas (
    penyewa_id,
    cabang_id,
    dibuka_oleh,
    dibuka_pada,
    modal_awal,
    status,
    catatan
  )
  values (
    v_penyewa,
    v_cabang_id,
    auth.uid(),
    now(),
    p_modal_awal,
    'terbuka',
    nullif(btrim(p_catatan), '')
  )
  returning * into v_baru;

  -- Jejak audit berantai hash
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  )
  values (
    v_penyewa,
    auth.uid(),
    'buka_shift',
    'shift_kas',
    v_baru.id,
    null,
    jsonb_build_object(
      'cabang_id', v_cabang_id,
      'modal_awal', p_modal_awal,
      'dibuka_pada', to_char(v_baru.dibuka_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'catatan', v_baru.catatan
    )
  );

  return jsonb_build_object(
    'berhasil',    true,
    'kode',        'SH-200',
    'pesan',       'Shift kasir berhasil dibuka.',
    'shift_id',    v_baru.id,
    'cabang_id',   v_baru.cabang_id,
    'modal_awal',  v_baru.modal_awal,
    'dibuka_pada', to_char(v_baru.dibuka_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'status',      v_baru.status
  );
end;
$$;

comment on function public.buka_shift(integer, uuid, text) is
  'M7 / T7-01: Buka shift kasir dengan modal awal. Menegakkan aturan satu shift terbuka per kasir per cabang, merekam pelaku & waktu peladen, dan mencatat jejak audit berantai hash.';

-- ---------------------------------------------------------------------------
-- 6. Izin eksekusi fungsi
-- ---------------------------------------------------------------------------
revoke all on function public.picu_shift_kas_jaga() from public, anon, authenticated;
revoke all on function public.buka_shift(integer, uuid, text) from public, anon;
grant execute on function public.buka_shift(integer, uuid, text) to authenticated, service_role;
