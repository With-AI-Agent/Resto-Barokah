-- ============================================================================
-- 0049 — Pengingat shift belum ditutup (T7-05, PRD M7 kasus tepi & TECH_SPEC §4.3)
--
-- PRD M7 Kasus Tepi:
-- "Shift tidak ditutup sampai besok (sistem mengingatkan)"
--
-- Pagar & Mekanisme:
-- 1. Penanda shift melewati tengah malam:
--    Kolom `melewati_tengah_malam boolean not null default false` pada `public.shift_kas`.
-- 2. Konfigurasi operasional cabang:
--    Kolom `jam_tutup text default '22:00'` pada `public.pengaturan`.
-- 3. Pemicu otomatis penanda tanggal berbeda:
--    Pemicu `picu_shift_kas_melewati_tengah_malam` menandai kolom `melewati_tengah_malam`
--    saat shift terbuka diperbarui atau ditutup pada tanggal kalender yang berbeda
--    di zona waktu resto (Asia/Jakarta).
-- 4. Audit trail kekal berantai hash:
--    Saat shift yang melewati tengah malam ditutup, catatan audit `shift_melewati_tengah_malam`
--    otomatis direkam ke `public.catatan_audit` sebagai jejak audit bagi laporan owner (M8).
-- 5. View pemantau shift menggantung:
--    View `public.laporan_shift_menggantung` (security_invoker = true) untuk memantau
--    shift aktif yang melebihi jam operasional atau melewati tengah malam.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Kolom melewati_tengah_malam pada shift_kas dan jam_tutup pada pengaturan
-- ---------------------------------------------------------------------------
alter table public.shift_kas
  add column if not exists melewati_tengah_malam boolean not null default false;

comment on column public.shift_kas.melewati_tengah_malam is
  'T7-05: Penanda apakah shift dibiarkan terbuka hingga melewati tengah malam (hari kalender berikutnya) di zona waktu resto.';

alter table public.pengaturan
  add column if not exists jam_tutup text default '22:00';

comment on column public.pengaturan.jam_tutup is
  'T7-05: Jam penutupan operasional resto dalam format HH:MI (bawaan: 22:00).';

-- ---------------------------------------------------------------------------
-- 2. Pemicu picu_shift_kas_melewati_tengah_malam
-- ---------------------------------------------------------------------------
create or replace function public.picu_shift_kas_melewati_tengah_malam()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if timezone('Asia/Jakarta', coalesce(new.ditutup_pada, now()))::date > timezone('Asia/Jakarta', new.dibuka_pada)::date then
    new.melewati_tengah_malam := true;
  end if;
  return new;
end;
$$;

comment on function public.picu_shift_kas_melewati_tengah_malam() is
  'T7-05: Menandai melewati_tengah_malam = true jika waktu evaluasi/penutupan melewati tanggal kalender pembukaan shift di zona waktu Asia/Jakarta.';

drop trigger if exists trg_shift_kas_tengah_malam on public.shift_kas;
create trigger trg_shift_kas_tengah_malam
  before update on public.shift_kas
  for each row
  execute function public.picu_shift_kas_melewati_tengah_malam();

-- ---------------------------------------------------------------------------
-- 3. Perbarui tutup_shift agar mencatat penanda & audit shift melewati tengah malam
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
  v_penyewa                 uuid;
  v_shift                   public.shift_kas%rowtype;
  v_penjualan_tunai         integer := 0;
  v_kas_masuk               integer := 0;
  v_kas_keluar              integer := 0;
  v_tunai_masuk             integer := 0;
  v_tunai_keluar            integer := 0;
  v_uang_seharusnya         integer;
  v_selisih                 integer;
  v_alasan                  text;
  v_melewati_tengah_malam   boolean := false;
  v_hasil                   public.shift_kas%rowtype;
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

  -- Evaluasi apakah shift melewati tengah malam di zona waktu lokal Asia/Jakarta
  if timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', v_shift.dibuka_pada)::date then
    v_melewati_tengah_malam := true;
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
         melewati_tengah_malam = (v_shift.melewati_tengah_malam or v_melewati_tengah_malam),
         catatan = case
           when p_catatan is not null and btrim(p_catatan) <> '' then btrim(p_catatan)
           else catatan
         end
   where id = v_shift.id
  returning * into v_hasil;

  -- Jejak audit berantai kriptografis penutupan shift
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
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam
    )
  );

  -- Jika shift melewati tengah malam, catat jejak audit khusus untuk laporan owner
  if v_melewati_tengah_malam then
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
      'shift_melewati_tengah_malam',
      'shift_kas',
      v_hasil.id,
      null,
      jsonb_build_object(
        'shift_id', v_hasil.id,
        'cabang_id', v_hasil.cabang_id,
        'dibuka_pada', to_char(v_hasil.dibuka_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'ditutup_pada', to_char(v_hasil.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'melewati_tengah_malam', true
      )
    );
  end if;

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
      'penjualan_tunai', v_penjualan_tunai,
      'kas_masuk', v_kas_masuk,
      'kas_keluar', v_kas_keluar,
      'tunai_masuk', v_tunai_masuk,
      'tunai_keluar', v_tunai_keluar,
      'uang_seharusnya', v_hasil.uang_seharusnya,
      'uang_fisik', v_hasil.uang_fisik,
      'selisih', v_hasil.selisih,
      'alasan_selisih', v_hasil.alasan_selisih,
      'melewati_tengah_malam', v_hasil.melewati_tengah_malam,
      'status', v_hasil.status,
      'catatan', v_hasil.catatan
    )
  );
end;
$$;

comment on function public.tutup_shift(integer, text, uuid, text) is
  'T7-02/T7-03/T7-05: Tutup shift kasir dengan rekonsiliasi uang seharusnya (modal + tunai masuk - tunai keluar) vs fisik, alasan wajib jika selisih, penanda & audit shift melewati tengah malam, dan jejak audit kekal berantai hash.';

-- ---------------------------------------------------------------------------
-- 4. View laporan_shift_menggantung
-- ---------------------------------------------------------------------------
create or replace view public.laporan_shift_menggantung
with (security_invoker = true) as
  select
    s.id                              as shift_id,
    s.penyewa_id,
    s.cabang_id,
    c.nama                            as cabang_nama,
    s.dibuka_oleh,
    p.nama                            as kasir_nama,
    s.dibuka_pada,
    s.modal_awal,
    s.status,
    (s.melewati_tengah_malam or timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', s.dibuka_pada)::date) as melewati_tengah_malam,
    coalesce(pg.jam_tutup, '22:00')   as jam_tutup_cabang,
    case
      when (s.melewati_tengah_malam or timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', s.dibuka_pada)::date) then 'melewati_tengah_malam'
      when extract(epoch from (now() - s.dibuka_pada)) >= 43200 then 'durasi_kritis'
      when to_char(timezone('Asia/Jakarta', now()), 'HH24:MI') >= coalesce(pg.jam_tutup, '22:00') then 'melewati_jam_tutup'
      else 'normal'
    end                               as tingkat_peringatan
  from public.shift_kas s
  join public.cabang c on c.id = s.cabang_id
  join public.pengguna p on p.id = s.dibuka_oleh
  left join public.pengaturan pg on pg.penyewa_id = s.penyewa_id
 where s.status = 'terbuka';

comment on view public.laporan_shift_menggantung is
  'T7-05: Daftar shift terbuka untuk pemantauan pengingat tutup kasir. security_invoker = true tunduk pada RLS shift_kas & cabang.';

-- ---------------------------------------------------------------------------
-- 5. Izin akses
-- ---------------------------------------------------------------------------
revoke all on function public.picu_shift_kas_melewati_tengah_malam() from public, anon, authenticated;
revoke all on function public.tutup_shift(integer, text, uuid, text) from public, anon;
grant execute on function public.tutup_shift(integer, text, uuid, text) to authenticated, service_role;

revoke all on table public.laporan_shift_menggantung from public, anon;
grant select on table public.laporan_shift_menggantung to authenticated, service_role;
