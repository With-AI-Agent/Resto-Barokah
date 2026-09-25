-- ===========================================================================
-- Migrasi 0046: Tutup Kas / Shift (T7-02 — Rekonsiliasi Kas Seharusnya vs Fisik)
--
-- Masalah yang diselesaikan (PRD M7, TECH_SPEC §4.3, §9 ART-6):
-- 1. Penutupan shift kasir membandingkan uang seharusnya dari sistem
--    (modal awal + penerimaan tunai - pengeluaran tunai) dengan uang fisik
--    yang dihitung kasir di laci kas.
-- 2. Bila ada selisih (baik kurang maupun lebih), kasir WAJIB mengisi alasan.
--    Pagar ini ditegakkan di dua tingkat:
--    - Tingkat RPC: menolak bila selisih != 0 dan alasan kosong (SH-422).
--    - Tingkat Skema: constraint tabel `shift_kas_selisih_alasan` menolak
--      baris ditutup dengan selisih tanpa alasan.
-- 3. Kasus dua kasir satu shift: Kasir B dapat menutup shift yang dibuka
--    oleh Kasir A; keduanya tercatat kekal di `dibuka_oleh` dan `ditutup_oleh`.
-- 4. Audit berantai hash SHA-256 otomatis tercatat di `public.catatan_audit`.
-- 5. Pemicu auto-kait pembayaran ke shift kasir aktif memastikan seluruh
--    transaksi tunai terhitung akurat.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. Constraint alasan selisih pada tabel shift_kas
-- ---------------------------------------------------------------------------
alter table public.shift_kas
  drop constraint if exists shift_kas_selisih_alasan;

alter table public.shift_kas
  add constraint shift_kas_selisih_alasan check (
    status <> 'ditutup' or
    selisih = 0 or
    (alasan_selisih is not null and btrim(alasan_selisih) <> '')
  );

-- ---------------------------------------------------------------------------
-- 2. Pemicu otomatis mengaitkan pembayaran ke shift kasir yang aktif
-- ---------------------------------------------------------------------------
create or replace function public.picu_pembayaran_kait_shift()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if NEW.shift_id is null then
    -- Cari shift kasir aktif di cabang pesanan ini
    select s.id into NEW.shift_id
      from public.shift_kas s
      join public.pesanan p on p.id = NEW.pesanan_id
     where s.cabang_id = p.cabang_id
       and s.status = 'terbuka'
       and (s.dibuka_oleh = NEW.kasir_id or s.dibuka_oleh = auth.uid())
     limit 1;

    -- Bila belum ketemu per kasir, cari shift terbuka apa pun di cabang itu
    if NEW.shift_id is null then
      select s.id into NEW.shift_id
        from public.shift_kas s
        join public.pesanan p on p.id = NEW.pesanan_id
       where s.cabang_id = p.cabang_id
         and s.status = 'terbuka'
       order by s.dibuka_pada desc
       limit 1;
    end if;
  end if;
  return NEW;
end;
$$;

comment on function public.picu_pembayaran_kait_shift() is
  'Memastikan baris pembayaran otomatis terkait ke shift kasir aktif di cabang bersangkutan.';

revoke all on function public.picu_pembayaran_kait_shift() from public, anon, authenticated;

drop trigger if exists trg_pembayaran_kait_shift on public.pembayaran;
create trigger trg_pembayaran_kait_shift
  before insert on public.pembayaran
  for each row execute function public.picu_pembayaran_kait_shift();

-- ---------------------------------------------------------------------------
-- 3. RPC tutup_shift
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
  v_tunai_masuk       integer := 0;
  v_tunai_keluar      integer := 0;
  v_kas_pergerakan    integer := 0;
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
    -- Cari shift kasir aktif milik akun ini
    select *
      into v_shift
      from public.shift_kas
     where penyewa_id = v_penyewa
       and dibuka_oleh = auth.uid()
       and status = 'terbuka'
     order by dibuka_pada desc
     limit 1
     for update;

    -- Bila tidak ada shift yang dibuka sendiri, cari shift terbuka di cabang yang dipantau
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
     and pesanan_id in (select id from public.pesanan where cabang_id = v_shift.cabang_id and penyewa_id = v_penyewa)
     and waktu >= v_shift.dibuka_pada
     and waktu <= now();

  -- Hitung penerimaan tunai dari pembayaran pesanan
  select coalesce(sum(jumlah), 0)
    into v_tunai_masuk
    from public.pembayaran
   where shift_id = v_shift.id
     and jenis_saat_itu = 'tunai';

  -- Perhitungkan kas_pergerakan bila tabelnya sudah dibuat di T7-03
  if to_regclass('public.kas_pergerakan') is not null then
    execute 'select coalesce(sum(case when jenis = ''masuk'' then jumlah when jenis in (''keluar'', ''setoran'') then -jumlah else 0 end), 0) from public.kas_pergerakan where shift_id = $1'
      into v_kas_pergerakan
      using v_shift.id;

    if v_kas_pergerakan < 0 then
      v_tunai_keluar := -v_kas_pergerakan;
    else
      v_tunai_masuk := v_tunai_masuk + v_kas_pergerakan;
    end if;
  end if;

  -- Hitung uang seharusnya: modal_awal + tunai_masuk - tunai_keluar
  v_uang_seharusnya := v_shift.modal_awal + v_tunai_masuk - v_tunai_keluar;
  if v_uang_seharusnya < 0 then
    v_uang_seharusnya := 0;
  end if;

  -- Hitung selisih: fisik - seharusnya
  v_selisih := p_uang_fisik - v_uang_seharusnya;

  -- Validasi alasan selisih (DoD T7-02: bila selisih -> alasan wajib)
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

  -- Jejak audit berantai kriptografis (ART-6 / T1-13)
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
