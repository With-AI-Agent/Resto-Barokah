-- ===========================================================================
-- Migrasi 0047: Kas Pergerakan (T7-03 — Uang Masuk/Keluar Tunai & Setoran)
--
-- Masalah yang diselesaikan (PRD M7, TECH_SPEC §4.3, §5, §9 ART-6):
-- 1. Uang tunai yang keluar-masuk di laci kas di luar penjualan pesanan
--    (mis. belanja bahan mendadak, kasbon, beli es batu, tambah uang kembalian,
--    atau setoran ke brankas/bank) wajib tercatat dengan alasan & izin yang jelas.
-- 2. Uang keluar-masuk ini secara matematis masuk ke perhitungan uang seharusnya
--    saat tutup kas (modal awal + penerimaan tunai - pengeluaran tunai).
-- 3. Setelah shift ditutup, seluruh pergerakan kas beku; koreksi pasca-tutup
--    dicatat sebagai baris kas_pergerakan baru bertanda 'koreksi' (ART-6).
-- 4. Pagar audit kekal: baris tabel kas_pergerakan dilarang di-UPDATE atau DELETE.
-- 5. Dukungan kunci idempoten mencegah pencatatan ganda saat gangguan jaringan.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Tabel kas_pergerakan
-- ---------------------------------------------------------------------------
create table if not exists public.kas_pergerakan (
  id                uuid primary key default gen_random_uuid(),
  penyewa_id        uuid not null references public.penyewa(id) on delete cascade,
  cabang_id         uuid not null references public.cabang(id) on delete cascade,
  shift_id          uuid not null references public.shift_kas(id) on delete restrict,
  jenis             text not null check (jenis in ('masuk', 'keluar', 'setoran', 'koreksi')),
  jumlah            integer not null check (jumlah >= 1),
  alasan            text not null check (btrim(alasan) <> ''),
  pelaku_id         uuid not null references public.pengguna(id),
  disetujui_oleh    uuid references public.pengguna(id),
  kunci_idempoten   text unique,
  dibuat_pada       timestamptz not null default now()
);

comment on table public.kas_pergerakan is
  'M7: Pencatatan uang tunai keluar/masuk/setoran/koreksi di luar transaksi penjualan.';

create index if not exists idx_kas_pergerakan_shift
  on public.kas_pergerakan (shift_id);

create index if not exists idx_kas_pergerakan_cabang
  on public.kas_pergerakan (cabang_id, dibuat_pada desc);

-- ---------------------------------------------------------------------------
-- 2. Keamanan RLS pada kas_pergerakan
-- ---------------------------------------------------------------------------
alter table public.kas_pergerakan enable row level security;

create policy kas_pergerakan_pilih on public.kas_pergerakan
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and public.cabang_pantau_saya(cabang_id)
  );

revoke insert, update, delete on public.kas_pergerakan from public, anon, authenticated;
grant select on public.kas_pergerakan to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Pemicu penjagaan kas_pergerakan: kekal (anti update/delete) & validasi shift
-- ---------------------------------------------------------------------------
create or replace function public.picu_kas_pergerakan_kekal()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  raise exception 'Pergerakan kas adalah jejak keuangan kekal; tidak dapat diubah atau dihapus.';
end;
$$;

revoke all on function public.picu_kas_pergerakan_kekal() from public, anon, authenticated;

drop trigger if exists trg_kas_pergerakan_kekal on public.kas_pergerakan;
create trigger trg_kas_pergerakan_kekal
  before update or delete on public.kas_pergerakan
  for each row execute function public.picu_kas_pergerakan_kekal();

create or replace function public.picu_kas_pergerakan_validasi_shift()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status_shift text;
begin
  select status into v_status_shift
    from public.shift_kas
   where id = NEW.shift_id;

  if v_status_shift is null then
    raise exception 'Shift kas tidak ditemukan.';
  end if;

  if v_status_shift <> 'terbuka' and NEW.jenis <> 'koreksi' then
    raise exception 'Shift kas sudah ditutup. Pergerakan kas operasional hanya diperbolehkan pada shift yang terbuka.';
  end if;

  return NEW;
end;
$$;

revoke all on function public.picu_kas_pergerakan_validasi_shift() from public, anon, authenticated;

drop trigger if exists trg_kas_pergerakan_validasi_shift on public.kas_pergerakan;
create trigger trg_kas_pergerakan_validasi_shift
  before insert on public.kas_pergerakan
  for each row execute function public.picu_kas_pergerakan_validasi_shift();

-- ---------------------------------------------------------------------------
-- 4. RPC kas_pergerakan
-- ---------------------------------------------------------------------------
create or replace function public.kas_pergerakan(
  p_jenis             text,
  p_jumlah            integer,
  p_alasan            text,
  p_shift_id          uuid    default null,
  p_cabang_id         uuid    default null,
  p_disetujui_oleh    uuid    default null,
  p_kunci_idempoten   text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa           uuid;
  v_shift             public.shift_kas%rowtype;
  v_cabang            uuid;
  v_hasil             public.kas_pergerakan%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- Validasi jenis pergerakan kas
  if p_jenis is null or p_jenis not in ('masuk', 'keluar', 'setoran', 'koreksi') then
    raise exception 'Jenis pergerakan kas tidak sah. Pilihan: masuk, keluar, setoran, koreksi.';
  end if;

  -- Validasi jumlah
  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Jumlah uang pergerakan kas wajib diisi dan harus lebih besar dari 0.';
  end if;

  -- Validasi alasan wajib
  if p_alasan is null or btrim(p_alasan) = '' then
    raise exception 'Alasan pergerakan kas wajib diisi.';
  end if;

  -- Idempotency guard
  if p_kunci_idempoten is not null and btrim(p_kunci_idempoten) <> '' then
    select *
      into v_hasil
      from public.kas_pergerakan
     where kunci_idempoten = btrim(p_kunci_idempoten)
       and penyewa_id = v_penyewa;

    if v_hasil.id is not null then
      return jsonb_build_object(
        'berhasil', true,
        'kode', 'KP-200',
        'pesan', 'Pergerakan kas sudah tercatat sebelumnya (idempoten).',
        'data', jsonb_build_object(
          'id', v_hasil.id,
          'shift_id', v_hasil.shift_id,
          'cabang_id', v_hasil.cabang_id,
          'jenis', v_hasil.jenis,
          'jumlah', v_hasil.jumlah,
          'alasan', v_hasil.alasan,
          'pelaku_id', v_hasil.pelaku_id,
          'disetujui_oleh', v_hasil.disetujui_oleh,
          'dibuat_pada', v_hasil.dibuat_pada
        )
      );
    end if;
  end if;

  -- Menentukan shift kas
  if p_shift_id is not null then
    select *
      into v_shift
      from public.shift_kas
     where id = p_shift_id
       and penyewa_id = v_penyewa;

    if v_shift.id is null then
      raise exception 'Shift kas tidak ditemukan.';
    end if;
  else
    v_cabang := p_cabang_id;
    if v_cabang is null then
      v_cabang := public.cabang_aktif_saya();
    end if;

    select *
      into v_shift
      from public.shift_kas
     where penyewa_id = v_penyewa
       and (v_cabang is null or cabang_id = v_cabang)
       and dibuka_oleh = auth.uid()
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1;

    if v_shift.id is null and v_cabang is not null then
      select *
        into v_shift
        from public.shift_kas
       where penyewa_id = v_penyewa
         and cabang_id = v_cabang
         and status = 'terbuka'
       order by dibuka_pada desc
       limit 1;
    end if;

    if v_shift.id is null then
      raise exception 'Tidak ada shift kas terbuka untuk mencatat pergerakan kas.';
    end if;
  end if;

  -- Shift status guard
  if v_shift.status <> 'terbuka' and p_jenis <> 'koreksi' then
    raise exception 'Shift kas sudah ditutup. Uang tidak dapat keluar/masuk di shift tertutup.';
  end if;

  -- Verifikasi hak wewenang kas
  if not public.boleh('tutup_kas', v_shift.cabang_id) then
    raise exception 'Peran % tidak berwenang mencatat pergerakan kas di cabang ini.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  -- Rekam pergerakan kas
  insert into public.kas_pergerakan (
    penyewa_id,
    cabang_id,
    shift_id,
    jenis,
    jumlah,
    alasan,
    pelaku_id,
    disetujui_oleh,
    kunci_idempoten
  )
  values (
    v_penyewa,
    v_shift.cabang_id,
    v_shift.id,
    p_jenis,
    p_jumlah,
    btrim(p_alasan),
    auth.uid(),
    p_disetujui_oleh,
    nullif(btrim(coalesce(p_kunci_idempoten, '')), '')
  )
  returning * into v_hasil;

  -- Jejak audit berantai kriptografis
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_baru
  )
  values (
    v_penyewa,
    auth.uid(),
    'kas_pergerakan_' || p_jenis,
    'kas_pergerakan',
    v_hasil.id,
    jsonb_build_object(
      'id', v_hasil.id,
      'cabang_id', v_hasil.cabang_id,
      'shift_id', v_hasil.shift_id,
      'jenis', v_hasil.jenis,
      'jumlah', v_hasil.jumlah,
      'alasan', v_hasil.alasan,
      'pelaku_id', v_hasil.pelaku_id,
      'disetujui_oleh', v_hasil.disetujui_oleh,
      'dibuat_pada', to_char(v_hasil.dibuat_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'KP-200',
    'pesan', 'Pergerakan kas berhasil dicatat.',
    'data', jsonb_build_object(
      'id', v_hasil.id,
      'cabang_id', v_hasil.cabang_id,
      'shift_id', v_hasil.shift_id,
      'jenis', v_hasil.jenis,
      'jumlah', v_hasil.jumlah,
      'alasan', v_hasil.alasan,
      'pelaku_id', v_hasil.pelaku_id,
      'disetujui_oleh', v_hasil.disetujui_oleh,
      'dibuat_pada', v_hasil.dibuat_pada
    )
  );
end;
$$;

comment on function public.kas_pergerakan(text, integer, text, uuid, uuid, uuid, text) is
  'M7: Mencatat pergerakan uang kas di luar penjualan (masuk, keluar, setoran, koreksi) dengan alasan wajib dan jejak audit.';

revoke all on function public.kas_pergerakan(text, integer, text, uuid, uuid, uuid, text) from public, anon;
grant execute on function public.kas_pergerakan(text, integer, text, uuid, uuid, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Perbarui tutup_shift agar menghitung kas_pergerakan secara bersih & terinci
-- ---------------------------------------------------------------------------
create or replace function public.tutup_shift(
  p_uang_fisik      integer,
  p_alasan_selisih  text    default null,
  p_shift_id        uuid    default null,
  p_catatan         text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa           uuid;
  v_shift             public.shift_kas%rowtype;
  v_penjualan_tunai   integer := 0;
  v_kas_masuk         integer := 0;
  v_kas_keluar        integer := 0;
  v_tunai_masuk       integer := 0;
  v_tunai_keluar      integer := 0;
  v_uang_seharusnya   integer;
  v_selisih           integer;
  v_alasan            text;
  v_hasil             public.shift_kas%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Anda belum terdaftar di resto mana pun.';
  end if;

  -- Validasi masukan uang fisik
  if p_uang_fisik is null or p_uang_fisik < 0 then
    raise exception 'Jumlah uang fisik wajib diisi dan tidak boleh negatif.';
  end if;

  -- Cari shift yang akan ditutup
  if p_shift_id is not null then
    select *
      into v_shift
      from public.shift_kas
     where id = p_shift_id
       and penyewa_id = v_penyewa
       for update;

    if v_shift.id is null then
      raise exception 'Shift kas tidak ditemukan.';
    end if;

    if v_shift.status <> 'terbuka' then
      raise exception 'Shift kas ini sudah ditutup sebelumnya.';
    end if;
  else
    select *
      into v_shift
      from public.shift_kas
     where penyewa_id = v_penyewa
       and dibuka_oleh = auth.uid()
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1
     for update;

    if v_shift.id is null then
      select *
        into v_shift
        from public.shift_kas
       where penyewa_id = v_penyewa
         and public.cabang_pantau_saya(cabang_id)
         and status = 'terbuka'
       order by dibuka_pada asc
       limit 1
       for update;
    end if;

    if v_shift.id is null then
      raise exception 'Tidak ada shift kas terbuka yang dapat ditutup.';
    end if;
  end if;

  -- Verifikasi izin tutup_kas di cabang shift bersangkutan
  if not public.boleh('tutup_kas', v_shift.cabang_id) then
    raise exception 'Peran % tidak berwenang menutup shift kas di cabang ini.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  -- Kaitkan pembayaran tunai belum terikat yang terjadi di cabang selama rentang shift
  update public.pembayaran
     set shift_id = v_shift.id
   where shift_id is null
     and pesanan_id in (select id from public.pesanan where cabang_id = v_shift.cabang_id)
     and waktu >= v_shift.dibuka_pada
     and waktu <= now();

  -- Hitung penerimaan tunai dari pembayaran pesanan
  select coalesce(sum(jumlah), 0)
    into v_penjualan_tunai
    from public.pembayaran
   where shift_id = v_shift.id
     and jenis_saat_itu = 'tunai';

  -- Perhitungkan kas_pergerakan:
  -- Uang masuk (tambahan modal)
  select coalesce(sum(jumlah), 0)
    into v_kas_masuk
    from public.kas_pergerakan
   where shift_id = v_shift.id
     and jenis = 'masuk';

  -- Uang keluar (belanja mendadak, kasbon) & setoran
  select coalesce(sum(jumlah), 0)
    into v_kas_keluar
    from public.kas_pergerakan
   where shift_id = v_shift.id
     and jenis in ('keluar', 'setoran');

  v_tunai_masuk := v_penjualan_tunai + v_kas_masuk;
  v_tunai_keluar := v_kas_keluar;

  -- Hitung uang seharusnya: modal_awal + tunai_masuk - tunai_keluar
  v_uang_seharusnya := v_shift.modal_awal + v_tunai_masuk - v_tunai_keluar;
  if v_uang_seharusnya < 0 then
    v_uang_seharusnya := 0;
  end if;

  -- Hitung selisih: fisik - seharusnya
  v_selisih := p_uang_fisik - v_uang_seharusnya;

  -- Validasi alasan selisih
  v_alasan := btrim(coalesce(p_alasan_selisih, ''));
  if v_selisih <> 0 and v_alasan = '' then
    raise exception 'Alasan selisih wajib diisi jika uang fisik berbeda dari uang seharusnya.';
  end if;

  if v_alasan = '' then
    v_alasan := null;
  end if;

  -- Tutup shift kas
  update public.shift_kas
     set status = 'ditutup',
         ditutup_oleh = auth.uid(),
         ditutup_pada = now(),
         uang_seharusnya = v_uang_seharusnya,
         uang_fisik = p_uang_fisik,
         selisih = v_selisih,
         alasan_selisih = v_alasan,
         catatan = case
           when p_catatan is not null and btrim(p_catatan) <> '' then btrim(p_catatan)
           else catatan
         end
   where id = v_shift.id
  returning * into v_hasil;

  -- Jejak audit berantai kriptografis
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
    'tutup_shift',
    'shift_kas',
    v_hasil.id,
    jsonb_build_object(
      'status', 'terbuka',
      'modal_awal', v_shift.modal_awal
    ),
    jsonb_build_object(
      'shift_id', v_hasil.id,
      'status', 'ditutup',
      'ditutup_oleh', auth.uid(),
      'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'modal_awal', v_hasil.modal_awal,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SH-200',
    'pesan', 'Shift kas berhasil ditutup.',
    'data', jsonb_build_object(
      'shift_id', v_hasil.id,
      'cabang_id', v_hasil.cabang_id,
      'dibuka_oleh', v_hasil.dibuka_oleh,
      'ditutup_oleh', v_hasil.ditutup_oleh,
      'dibuka_pada', v_hasil.dibuka_pada,
      'ditutup_pada', v_hasil.ditutup_pada,
      'modal_awal', v_hasil.modal_awal,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'status', v_hasil.status,
      'catatan', v_hasil.catatan
    )
  );
end;
$$;

comment on function public.tutup_shift(integer, text, uuid, text) is
  'M7: Menutup sesi shift kasir dengan rekonsiliasi uang seharusnya vs fisik, selisih beralasan, dan audit kriptografis.';

revoke all on function public.tutup_shift(integer, text, uuid, text) from public, anon;
grant execute on function public.tutup_shift(integer, text, uuid, text) to authenticated;
