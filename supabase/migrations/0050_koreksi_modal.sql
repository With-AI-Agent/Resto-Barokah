-- ============================================================================
-- Migrasi 0050: Koreksi Modal Awal dengan Izin Atasan (T7-06)
--
-- Masalah yang diselesaikan (PRD M7, TECH_SPEC §4.3, §9 ART-6):
-- 1. Kasir yang salah ketik atau keliru menghitung modal awal saat buka kas
--    harus bisa membetulkan nilai modal tanpa menghapus data atau merusak jejak.
-- 2. Koreksi wajib berupa baris baru (append-only) pada tabel riwayat
--    `public.koreksi_modal_shift`, bukan menimpa tanpa riwayat.
-- 3. Koreksi WAJIB disetujui atasan (owner_pusat atau admin_cabang yang berwenang)
--    melalui verifikasi PIN atasan yang sah (kupon sekali pakai dalam 5 menit).
-- 4. Alasan koreksi wajib diisi secara bermakna.
-- 5. Koreksi modal hanya boleh dilakukan saat shift masih berstatus 'terbuka'.
-- 6. Direct UPDATE pada `shift_kas.modal_awal` tetap DITOLAK oleh pemicu penjaga,
--    kecuali melalui prosedur resmi `public.koreksi_modal_shift`.
-- 7. Riwayat koreksi disajikan dalam view `public.laporan_koreksi_modal`
--    dan dicatat dalam jejak audit kriptografis berantai hash SHA-256.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tabel riwayat koreksi modal awal shift (append-only)
-- ---------------------------------------------------------------------------
create table if not exists public.koreksi_modal_shift (
  id                    uuid primary key default gen_random_uuid(),
  penyewa_id            uuid not null references public.penyewa(id) on delete cascade,
  cabang_id             uuid not null references public.cabang(id) on delete cascade,
  shift_id              uuid not null references public.shift_kas(id) on delete restrict,
  modal_awal_sebelumnya integer not null check (modal_awal_sebelumnya >= 0),
  modal_awal_baru       integer not null check (modal_awal_baru >= 0),
  selisih               integer not null,
  alasan                text not null check (btrim(alasan) <> ''),
  diajukan_oleh         uuid not null references public.pengguna(id),
  disetujui_oleh        uuid not null references public.pengguna(id),
  kunci_idempoten       text unique,
  dibuat_pada           timestamptz not null default now(),
  constraint koreksi_modal_beda_nilai check (modal_awal_baru <> modal_awal_sebelumnya),
  constraint koreksi_modal_selisih_cocok check (selisih = modal_awal_baru - modal_awal_sebelumnya)
);

comment on table public.koreksi_modal_shift is
  'T7-06: Riwayat hanya-tambah (append-only) koreksi modal awal shift kasir dengan persetujuan atasan.';

create index if not exists idx_koreksi_modal_shift_shift
  on public.koreksi_modal_shift (shift_id, dibuat_pada desc);

create index if not exists idx_koreksi_modal_shift_cabang
  on public.koreksi_modal_shift (cabang_id, dibuat_pada desc);

-- ---------------------------------------------------------------------------
-- 2. Keamanan RLS pada koreksi_modal_shift
-- ---------------------------------------------------------------------------
alter table public.koreksi_modal_shift enable row level security;

create policy koreksi_modal_shift_pilih on public.koreksi_modal_shift
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
  );

revoke insert, update, delete on public.koreksi_modal_shift from public, anon, authenticated;
grant select on public.koreksi_modal_shift to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Pemicu kekal: anti update dan delete pada riwayat koreksi modal
-- ---------------------------------------------------------------------------
create or replace function public.picu_koreksi_modal_kekal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  raise exception 'Riwayat koreksi modal awal adalah jejak audit kekal; tidak dapat diubah atau dihapus.';
end;
$$;

comment on function public.picu_koreksi_modal_kekal() is
  'Menjamin tabel koreksi_modal_shift bersifat murni append-only (kekal).';

revoke all on function public.picu_koreksi_modal_kekal() from public, anon, authenticated;

drop trigger if exists trg_koreksi_modal_kekal on public.koreksi_modal_shift;
create trigger trg_koreksi_modal_kekal
  before update or delete on public.koreksi_modal_shift
  for each row execute function public.picu_koreksi_modal_kekal();

-- ---------------------------------------------------------------------------
-- 4. Perbarui pemicu shift_kas agar mengizinkan pembaruan modal awal
--    HANYA melalui prosedur koreksi modal (app.dalam_koreksi_modal = 'true')
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

    -- Modal awal tidak boleh diubah langsung lewat update biasa tanpa prosedur koreksi modal
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
  'Mencegah penghapusan riwayat shift kas dan mengunci identitas serta modal awal dari perubahan langsung tanpa prosedur koreksi modal.';

-- ---------------------------------------------------------------------------
-- 5. RPC koreksi_modal_shift
-- ---------------------------------------------------------------------------
create or replace function public.koreksi_modal_shift(
  p_shift_id        uuid,
  p_modal_awal_baru integer,
  p_alasan          text,
  p_disetujui_oleh  uuid,
  p_kunci_idempoten text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa       uuid;
  v_shift         public.shift_kas%rowtype;
  v_atasan        public.pengguna%rowtype;
  v_kupon         bigint;
  v_koreksi       public.koreksi_modal_shift%rowtype;
  v_selisih       integer;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- 1. Validasi masukan dasar
  if p_shift_id is null then
    raise exception 'Shift ID wajib diisi.';
  end if;

  if p_modal_awal_baru is null or p_modal_awal_baru < 0 then
    raise exception 'Modal awal baru wajib diisi dan tidak boleh negatif.';
  end if;

  if p_alasan is null or btrim(p_alasan) = '' then
    raise exception 'Alasan koreksi modal awal wajib diisi.';
  end if;

  if p_disetujui_oleh is null then
    raise exception 'Penyetuju koreksi modal (atasan) wajib ditentukan.';
  end if;

  -- 2. Idempotency check
  if p_kunci_idempoten is not null and btrim(p_kunci_idempoten) <> '' then
    select *
      into v_koreksi
      from public.koreksi_modal_shift
     where kunci_idempoten = btrim(p_kunci_idempoten)
       and penyewa_id = v_penyewa;

    if v_koreksi.id is not null then
      return jsonb_build_object(
        'berhasil', true,
        'kode', 'KM-200',
        'pesan', 'Koreksi modal awal sudah tercatat sebelumnya (idempoten).',
        'data', jsonb_build_object(
          'id', v_koreksi.id,
          'shift_id', v_koreksi.shift_id,
          'cabang_id', v_koreksi.cabang_id,
          'modal_awal_sebelumnya', v_koreksi.modal_awal_sebelumnya,
          'modal_awal_baru', v_koreksi.modal_awal_baru,
          'selisih', v_koreksi.selisih,
          'alasan', v_koreksi.alasan,
          'diajukan_oleh', v_koreksi.diajukan_oleh,
          'disetujui_oleh', v_koreksi.disetujui_oleh,
          'dibuat_pada', v_koreksi.dibuat_pada
        )
      );
    end if;
  end if;

  -- 3. Cari dan kunci shift_kas
  select *
    into v_shift
    from public.shift_kas
   where id = p_shift_id
     and penyewa_id = v_penyewa
     for update;

  if v_shift.id is null then
    raise exception 'Shift kas tidak ditemukan.';
  end if;

  -- Pagar status: hanya shift terbuka yang boleh dikoreksi modal awalnya
  if v_shift.status <> 'terbuka' then
    raise exception 'Shift kas sudah ditutup — koreksi modal awal hanya dapat dilakukan saat shift masih terbuka.';
  end if;

  -- Pagar nilai: tidak boleh sama dengan modal saat ini
  if p_modal_awal_baru = v_shift.modal_awal then
    raise exception 'Modal awal baru tidak boleh sama dengan modal awal saat ini (%).', v_shift.modal_awal;
  end if;

  -- 4. Validasi identitas dan wewenang atasan (penyetuju)
  select *
    into v_atasan
    from public.pengguna
   where id = p_disetujui_oleh
     and penyewa_id = v_penyewa
     and aktif;

  if v_atasan.id is null then
    raise exception 'Penyetuju tidak ditemukan atau bukan pegawai aktif di resto ini.';
  end if;

  if v_atasan.peran not in ('owner_pusat', 'admin_cabang') then
    raise exception 'Penyetuju harus merupakan atasan (owner atau admin cabang).';
  end if;

  -- Admin cabang harus mengelola cabang shift bersangkutan
  if v_atasan.peran = 'admin_cabang' and not exists (
    select 1 from public.pengguna_cabang pc
     where pc.pengguna_id = v_atasan.id
       and pc.cabang_id = v_shift.cabang_id
  ) then
    raise exception 'Admin cabang penyetuju tidak mengelola cabang shift ini.';
  end if;

  -- 5. Verifikasi kupon PIN atasan dari public.percobaan_pin
  select pp.id into v_kupon
    from public.percobaan_pin pp
   where pp.pengguna_id = p_disetujui_oleh
     and pp.berhasil
     and pp.aksi = 'koreksi_modal_shift'
     and pp.dipakai_pada is null
     and pp.waktu > now() - interval '5 minutes'
   order by pp.waktu desc
   limit 1
   for update;

  if v_kupon is null then
    raise exception 'Persetujuan belum terbukti: atasan harus memasukkan PIN untuk koreksi modal shift (maksimal 5 menit lalu).';
  end if;

  -- Konsumsi kupon (sekali pakai)
  update public.percobaan_pin
     set dipakai_pada = now()
   where id = v_kupon;

  -- 6. Rekam baris koreksi modal baru (hanya-tambah)
  v_selisih := p_modal_awal_baru - v_shift.modal_awal;

  insert into public.koreksi_modal_shift (
    penyewa_id,
    cabang_id,
    shift_id,
    modal_awal_sebelumnya,
    modal_awal_baru,
    selisih,
    alasan,
    diajukan_oleh,
    disetujui_oleh,
    kunci_idempoten
  )
  values (
    v_penyewa,
    v_shift.cabang_id,
    v_shift.id,
    v_shift.modal_awal,
    p_modal_awal_baru,
    v_selisih,
    btrim(p_alasan),
    auth.uid(),
    p_disetujui_oleh,
    nullif(btrim(coalesce(p_kunci_idempoten, '')), '')
  )
  returning * into v_koreksi;

  -- 7. Perbarui modal_awal pada shift_kas dengan izin sesi khusus
  perform set_config('app.dalam_koreksi_modal', 'true', true);

  update public.shift_kas
     set modal_awal = p_modal_awal_baru
   where id = v_shift.id;

  perform set_config('app.dalam_koreksi_modal', 'false', true);

  -- 8. Jejak audit kriptografis berantai hash SHA-256
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
    'koreksi_modal_shift',
    'shift_kas',
    v_shift.id,
    jsonb_build_object(
      'shift_id', v_shift.id,
      'modal_awal', v_shift.modal_awal
    ),
    jsonb_build_object(
      'shift_id', v_shift.id,
      'koreksi_id', v_koreksi.id,
      'modal_awal_sebelumnya', v_shift.modal_awal,
      'modal_awal_baru', p_modal_awal_baru,
      'selisih', v_selisih,
      'alasan', btrim(p_alasan),
      'diajukan_oleh', auth.uid(),
      'disetujui_oleh', p_disetujui_oleh,
      'dibuat_pada', to_char(v_koreksi.dibuat_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'KM-200',
    'pesan', 'Modal awal shift berhasil dikoreksi.',
    'data', jsonb_build_object(
      'id', v_koreksi.id,
      'shift_id', v_koreksi.shift_id,
      'cabang_id', v_koreksi.cabang_id,
      'modal_awal_sebelumnya', v_koreksi.modal_awal_sebelumnya,
      'modal_awal_baru', v_koreksi.modal_awal_baru,
      'selisih', v_koreksi.selisih,
      'alasan', v_koreksi.alasan,
      'diajukan_oleh', v_koreksi.diajukan_oleh,
      'disetujui_oleh', v_koreksi.disetujui_oleh,
      'dibuat_pada', v_koreksi.dibuat_pada
    )
  );
end;
$$;

comment on function public.koreksi_modal_shift(uuid, integer, text, uuid, text) is
  'T7-06: Mengoreksi modal awal shift terbuka dengan persetujuan PIN atasan (owner/admin cabang), alasan wajib, riwayat hanya-tambah, dan audit kriptografis berantai hash.';

revoke all on function public.koreksi_modal_shift(uuid, integer, text, uuid, text) from public, anon;
grant execute on function public.koreksi_modal_shift(uuid, integer, text, uuid, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 6. View laporan_koreksi_modal untuk pengawasan pemilik & admin
-- ---------------------------------------------------------------------------
create or replace view public.laporan_koreksi_modal
with (security_invoker = true) as
select
  k.id                              as koreksi_id,
  k.penyewa_id,
  k.cabang_id,
  k.shift_id,
  s.status                          as status_shift,
  s.dibuka_pada                     as shift_dibuka_pada,
  s.ditutup_pada                    as shift_ditutup_pada,
  k.modal_awal_sebelumnya,
  k.modal_awal_baru,
  k.selisih,
  k.alasan,
  k.diajukan_oleh,
  p_diajukan.nama                   as nama_pengaju,
  k.disetujui_oleh,
  p_setuju.nama                     as nama_penyetuju,
  k.dibuat_pada
from public.koreksi_modal_shift k
join public.shift_kas s on s.id = k.shift_id
left join public.pengguna p_diajukan on p_diajukan.id = k.diajukan_oleh
left join public.pengguna p_setuju on p_setuju.id = k.disetujui_oleh;

comment on view public.laporan_koreksi_modal is
  'T7-06: Laporan riwayat koreksi modal awal per shift untuk pengawasan owner/admin. security_invoker = true tunduk pada RLS koreksi_modal_shift & shift_kas.';

revoke all on table public.laporan_koreksi_modal from public, anon;
grant select on table public.laporan_koreksi_modal to authenticated, service_role;
