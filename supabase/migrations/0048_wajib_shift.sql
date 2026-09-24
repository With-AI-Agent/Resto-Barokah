-- ============================================================================
-- Migrasi 0048: Transaksi Hanya Dalam Shift Terbuka (T7-04)
--
-- Referensi:
--   - PRD M7: "Transaksi hanya bisa dilakukan dalam shift yang sudah dibuka."
--   - TECH_SPEC §9 ART-6: "Transaksi hanya boleh terjadi bila ada shift terbuka di cabang itu."
--   - ROADMAP T7-04: "DoD: memesan/membayar di luar shift terbuka ditolak dengan pesan jelas; uji lulus."
--
-- Fitur:
--   1. Kolom `public.pengaturan.wajib_shift` (boolean, default false):
--      Mengatur apakah cabang penyewa mewajibkan shift kasir aktif untuk setiap
--      transaksi pesanan dan pembayaran uang.
--   2. Pemicu `picu_pesanan_wajib_shift`:
--      Menolak pesanan baru jika `wajib_shift = true` dan belum ada shift terbuka
--      di cabang yang bersangkutan, serta otomatis menyematkan `shift_id` aktif.
--   3. Pemicu `picu_pembayaran_wajib_shift`:
--      Menolak pencatatan pembayaran jika `wajib_shift = true` dan belum ada shift
--      terbuka di cabang bersangkutan, serta otomatis mengaitkan `shift_id` aktif.
--   4. Pembaruan RPC `public.bayar_pesanan`:
--      Memeriksa `wajib_shift` di gerbang pembayaran dan memastikan kasir atau
--      cabang memiliki shift aktif sebelum memproses pembayaran pesanan.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tambah kolom wajib_shift pada tabel pengaturan
-- ---------------------------------------------------------------------------
alter table public.pengaturan
  add column if not exists wajib_shift boolean not null default false;

comment on column public.pengaturan.wajib_shift is
  'Bila true, transaksi pemesanan dan pembayaran kasir wajib berada di dalam shift kasir yang aktif/terbuka (PRD M7 / ART-6).';

-- ---------------------------------------------------------------------------
-- 2. Pemicu penjaga pesanan pada shift terbuka
-- ---------------------------------------------------------------------------
create or replace function public.picu_pesanan_wajib_shift()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_wajib boolean;
  v_shift_id uuid;
begin
  -- Baca preferensi wajib_shift penyewa
  select coalesce(p.wajib_shift, false) into v_wajib
    from public.pengaturan p
   where p.penyewa_id = NEW.penyewa_id;

  if tg_op = 'INSERT' then
    if v_wajib then
      if NEW.shift_id is null then
        -- Cari shift terbuka di cabang ini (prioritas: dibuka oleh pembuat atau shift cabang terbaru)
        select s.id into v_shift_id
          from public.shift_kas s
         where s.cabang_id = NEW.cabang_id
           and s.status = 'terbuka'
         order by (s.dibuka_oleh = auth.uid()) desc, s.dibuka_pada desc
         limit 1;

        if v_shift_id is null then
          raise exception 'SH-400: Tidak dapat membuat pesanan: belum ada shift kas yang dibuka di cabang ini.';
        end if;

        NEW.shift_id := v_shift_id;
      else
        -- Pastikan shift_id yang dioper berstatus terbuka
        select s.id into v_shift_id
          from public.shift_kas s
         where s.id = NEW.shift_id
           and s.status = 'terbuka';

        if v_shift_id is null then
          raise exception 'SH-400: Shift kas % sudah ditutup atau tidak valid.', NEW.shift_id;
        end if;
      end if;
    else
      -- Mode fleksibel: bila ada shift terbuka, tetap tautkan shift_id untuk kerapian jejak
      if NEW.shift_id is null then
        select s.id into v_shift_id
          from public.shift_kas s
         where s.cabang_id = NEW.cabang_id
           and s.status = 'terbuka'
         order by (s.dibuka_oleh = auth.uid()) desc, s.dibuka_pada desc
         limit 1;

        if v_shift_id is not null then
          NEW.shift_id := v_shift_id;
        end if;
      end if;
    end if;
  elsif tg_op = 'UPDATE' then
    -- Hanya periksa jika shift_id diubah secara eksplisit
    if NEW.shift_id is distinct from OLD.shift_id and NEW.shift_id is not null then
      select s.id into v_shift_id
        from public.shift_kas s
       where s.id = NEW.shift_id
         and s.status = 'terbuka';

      if v_shift_id is null then
        raise exception 'SH-400: Shift kas % sudah ditutup atau tidak valid.', NEW.shift_id;
      end if;
    end if;
  end if;

  return NEW;
end;
$$;

comment on function public.picu_pesanan_wajib_shift() is
  'Memastikan pesanan ditolak bila wajib_shift aktif dan belum ada shift terbuka di cabang bersangkutan.';

revoke all on function public.picu_pesanan_wajib_shift() from public, anon, authenticated;

drop trigger if exists trg_pesanan_wajib_shift on public.pesanan;
create trigger trg_pesanan_wajib_shift
  before insert or update of shift_id on public.pesanan
  for each row
  execute function public.picu_pesanan_wajib_shift();

-- ---------------------------------------------------------------------------
-- 3. Pemicu penjaga pembayaran pada shift terbuka
-- ---------------------------------------------------------------------------
create or replace function public.picu_pembayaran_wajib_shift()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pesanan record;
  v_wajib boolean;
  v_shift_id uuid;
begin
  select p.id, p.cabang_id, p.penyewa_id, p.shift_id
    into v_pesanan
    from public.pesanan p
   where p.id = NEW.pesanan_id;

  if v_pesanan.id is null then
    return NEW;
  end if;

  select coalesce(pg.wajib_shift, false) into v_wajib
    from public.pengaturan pg
   where pg.penyewa_id = v_pesanan.penyewa_id;

  if v_wajib then
    -- Periksa shift aktif
    if NEW.shift_id is null then
      select s.id into v_shift_id
        from public.shift_kas s
       where s.cabang_id = v_pesanan.cabang_id
         and s.status = 'terbuka'
       order by (s.dibuka_oleh = coalesce(NEW.kasir_id, auth.uid())) desc, s.dibuka_pada desc
       limit 1;

      if v_shift_id is null then
        raise exception 'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.';
      end if;

      NEW.shift_id := v_shift_id;
    else
      -- Pastikan shift yang dirujuk berstatus terbuka
      select s.id into v_shift_id
        from public.shift_kas s
       where s.id = NEW.shift_id
         and s.status = 'terbuka';

      if v_shift_id is null then
        raise exception 'SH-400: Shift kas % sudah ditutup atau tidak valid.', NEW.shift_id;
      end if;
    end if;
  else
    -- Mode fleksibel: tetap tautkan shift aktif jika ada
    if NEW.shift_id is null then
      select s.id into v_shift_id
        from public.shift_kas s
       where s.cabang_id = v_pesanan.cabang_id
         and s.status = 'terbuka'
       order by (s.dibuka_oleh = coalesce(NEW.kasir_id, auth.uid())) desc, s.dibuka_pada desc
       limit 1;

      if v_shift_id is not null then
        NEW.shift_id := v_shift_id;
      end if;
    end if;
  end if;

  return NEW;
end;
$$;

comment on function public.picu_pembayaran_wajib_shift() is
  'Memastikan pembayaran ditolak bila wajib_shift aktif dan belum ada shift terbuka di cabang bersangkutan.';

revoke all on function public.picu_pembayaran_wajib_shift() from public, anon, authenticated;

drop trigger if exists trg_pembayaran_wajib_shift on public.pembayaran;
create trigger trg_pembayaran_wajib_shift
  before insert or update of shift_id on public.pembayaran
  for each row
  execute function public.picu_pembayaran_wajib_shift();

-- ---------------------------------------------------------------------------
-- 4. Perbarui RPC public.bayar_pesanan untuk memeriksa shift kas terbuka
-- ---------------------------------------------------------------------------
create or replace function public.bayar_pesanan(
  p_pesanan_id      uuid,
  p_metode_id       uuid,
  p_jumlah          integer,
  p_diterima        integer default null,
  p_referensi       text default null,
  p_kunci_idempoten text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa   uuid;
  v_pesanan   record;
  v_metode    record;
  v_total     integer;
  v_sudah     integer;
  v_kembalian integer;
  v_kunci     text;
  v_lama      record;
  v_baru      record;
  v_wajib_shift boolean;
  v_shift_id  uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then
    raise exception 'Peran % tidak berwenang mencatat uang masuk.', coalesce(public.peran_saya(), '(kosong)');
  end if;

  if p_jumlah is null or p_jumlah <= 0 then
    raise exception 'Jumlah bayar harus lebih besar dari nol.';
  end if;

  select m.id, m.nama, m.jenis, m.aktif
    into v_metode
    from public.metode_bayar m
   where m.id = p_metode_id
     and m.penyewa_id = v_penyewa;

  if v_metode.id is null then
    raise exception 'Metode bayar itu tidak ada di resto ini.';
  end if;
  if not v_metode.aktif then
    raise exception 'Metode bayar "%" sedang tidak aktif.', v_metode.nama;
  end if;

  select p.id, p.penyewa_id, p.cabang_id, p.status, p.total, p.shift_id
    into v_pesanan
    from public.pesanan p
   where p.id = p_pesanan_id
     and p.penyewa_id = v_penyewa
     for update;

  if v_pesanan.id is null then
    raise exception 'Pesanan tidak ditemukan.';
  end if;

  if v_pesanan.status = 'batal' then
    raise exception 'Pesanan ini sudah dibatalkan — uang tidak boleh dicatat lagi.';
  end if;

  if coalesce(v_pesanan.total, 0) <= 0 then
    raise exception 'Total pesanan belum dihitung — pembayaran belum boleh dicatat.';
  end if;

  -- Periksa wajib shift bila diaktifkan di pengaturan penyewa
  select coalesce(pg.wajib_shift, false) into v_wajib_shift
    from public.pengaturan pg
   where pg.penyewa_id = v_penyewa;

  if v_wajib_shift then
    select s.id into v_shift_id
      from public.shift_kas s
     where s.cabang_id = v_pesanan.cabang_id
       and s.status = 'terbuka'
     order by (s.dibuka_oleh = auth.uid()) desc, s.dibuka_pada desc
     limit 1;

    if v_shift_id is null then
      raise exception 'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.';
    end if;
  else
    -- Mode fleksibel: ambil shift aktif jika ada
    select s.id into v_shift_id
      from public.shift_kas s
     where s.cabang_id = v_pesanan.cabang_id
       and s.status = 'terbuka'
     order by (s.dibuka_oleh = auth.uid()) desc, s.dibuka_pada desc
     limit 1;
  end if;

  if v_metode.jenis = 'tunai' then
    if p_diterima is null then
      raise exception 'Pembayaran tunai wajib menyebut uang yang diterima.';
    end if;
    if p_diterima < p_jumlah then
      raise exception 'Uang diterima (%) lebih kecil dari jumlah bayar (%).', p_diterima, p_jumlah;
    end if;
    v_kembalian := p_diterima - p_jumlah;
  else
    if p_referensi is null or length(btrim(p_referensi)) = 0 then
      raise exception 'Pembayaran bukan tunai wajib menyebut nomor referensi.';
    end if;
    v_kembalian := null;
  end if;

  v_total := coalesce(v_pesanan.total, 0);
  v_sudah := public.total_dibayar(p_pesanan_id);
  if v_sudah + p_jumlah > v_total then
    raise exception 'BY-301: pembayaran % membuat total dibayar % melebihi total pesanan %.',
      p_jumlah, v_sudah + p_jumlah, v_total;
  end if;

  v_kunci := coalesce(nullif(btrim(p_kunci_idempoten), ''), 'bayar-' || gen_random_uuid()::text);

  select pb.id, pb.jumlah, pb.kembalian into v_lama
    from public.pembayaran pb
   where pb.pesanan_id = p_pesanan_id
     and pb.kunci_idempoten = v_kunci;

  if v_lama.id is not null then
    return jsonb_build_object(
      'berhasil',      true,
      'kode',          'BY-200',
      'pesan',         'Pembayaran dengan kunci ini sudah tercatat — tidak dicatat dua kali.',
      'pembayaran_id', v_lama.id,
      'jumlah',        v_lama.jumlah,
      'kembalian',     v_lama.kembalian,
      'total_dibayar', v_sudah,
      'total_pesanan', v_total,
      'lunas',         v_sudah >= v_total,
      'dobel',         true
    );
  end if;

  insert into public.pembayaran (
    pesanan_id, metode_id, jumlah, diterima, kembalian, referensi, kasir_id, shift_id, kunci_idempoten
  ) values (
    p_pesanan_id,
    v_metode.id,
    p_jumlah,
    case when v_metode.jenis = 'tunai' then p_diterima else null end,
    v_kembalian,
    case when v_metode.jenis = 'tunai' then null else btrim(p_referensi) end,
    auth.uid(),
    coalesce(v_shift_id, v_pesanan.shift_id),
    v_kunci
  )
  returning id, jumlah, kembalian into v_baru;

  if v_sudah + p_jumlah >= v_total and v_pesanan.status <> 'lunas' then
    update public.pesanan
       set status = 'lunas',
           dibayar_pada = now()
     where id = p_pesanan_id;
  end if;

  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'bayar_pesanan',
    'pembayaran',
    v_baru.id,
    jsonb_build_object('total_dibayar', v_sudah, 'status_pesanan', v_pesanan.status),
    jsonb_build_object(
      'pesanan_id',    p_pesanan_id,
      'metode_id',     v_metode.id,
      'metode_nama',   v_metode.nama,
      'jenis',         v_metode.jenis,
      'jumlah',        p_jumlah,
      'diterima',      p_diterima,
      'kembalian',     v_baru.kembalian,
      'total_dibayar', v_sudah + p_jumlah,
      'total_pesanan', v_total,
      'lunas',         v_sudah + p_jumlah >= v_total,
      'shift_id',      coalesce(v_shift_id, v_pesanan.shift_id)
    )
  );

  return jsonb_build_object(
    'berhasil',      true,
    'kode',          'BY-200',
    'pesan',         'Pembayaran berhasil dicatat.',
    'pembayaran_id', v_baru.id,
    'jumlah',        v_baru.jumlah,
    'kembalian',     v_baru.kembalian,
    'total_dibayar', v_sudah + p_jumlah,
    'total_pesanan', v_total,
    'lunas',         v_sudah + p_jumlah >= v_total
  );
end;
$$;

comment on function public.bayar_pesanan(uuid, uuid, integer, integer, text, text) is
  'Pencatatan pembayaran pesanan dengan validasi shift kasir aktif bila wajib_shift berlaku (T7-04).';
