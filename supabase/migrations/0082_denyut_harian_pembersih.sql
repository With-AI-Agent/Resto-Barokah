-- Migrasi 0082: Denyut Harian & Pembersih Data Sementara (T10-08 / M12 / TECH_SPEC §1 & §10)
--
-- Tujuan:
-- 1. Proyek gratis tidak "tidur" setelah 7 hari tidak aktif (heartbeat / denyut harian).
-- 2. Data sementara (percobaan PIN, percobaan login, voucher percobaan, kode/token kadaluwarsa)
--    tidak menumpuk dan membebani batas kuota penyimpanan 500 MB (pembersih data sementara).
-- 3. Mencatat riwayat eksekusi jadwal di tabel public.log_jadwal.
-- 4. Pagar perlindungan keamanan: tabel inti finansial, menu, audit, dan pelanggan
--    DILINDUNGI PENUH dari pembersihan (whitelist ketat tabel sementara saja).

-- ============================================================================
-- 1. Tabel Log Jadwal Terjadwal (log_jadwal)
-- ============================================================================
create table if not exists public.log_jadwal (
  id uuid primary key default gen_random_uuid(),
  jenis text not null check (jenis in ('denyut', 'pembersihan', 'penutup_hari')),
  dimulai_pada timestamptz not null default clock_timestamp(),
  selesai_pada timestamptz,
  sukses boolean not null default true,
  rincian jsonb not null default '{}'::jsonb,
  pesan text
);

comment on table public.log_jadwal is
  'Rekam jejak eksekusi tugas terjadwal (denyut anti-tidur dan pembersihan malam) untuk pengawasan operasional.';

create index if not exists idx_log_jadwal_waktu
  on public.log_jadwal (dimulai_pada desc);

create index if not exists idx_log_jadwal_jenis_waktu
  on public.log_jadwal (jenis, dimulai_pada desc);

-- RLS wajib aktif
alter table public.log_jadwal enable row level security;

-- Cabut akses modifikasi dari publik & authenticated biasa
revoke all on table public.log_jadwal from public, anon;
grant select on table public.log_jadwal to authenticated;
grant all on table public.log_jadwal to service_role;

-- Kebijakan RLS:
-- Pemilik platform dapat membaca log jadwal (dibungkus initplan)
drop policy if exists log_jadwal_pilih on public.log_jadwal;
create policy log_jadwal_pilih on public.log_jadwal
  for select to authenticated
  using ((select public.peran_saya()) = 'pemilik_platform');

-- ============================================================================
-- 2. Fungsi Denyut Harian (public.denyut_harian)
-- ============================================================================
create or replace function public.denyut_harian()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_mulai timestamptz := clock_timestamp();
  v_selesai timestamptz;
  v_saya uuid := auth.uid();
  v_peran_saya text;
  v_penyewa_aktif int := 0;
  v_cabang_aktif int := 0;
  v_log_id uuid;
  v_hasil jsonb;
begin
  -- Otorisasi: jika dipanggil authenticated, wajib peran pemilik_platform
  if v_saya is not null then
    select p.peran into v_peran_saya
      from public.pengguna p
     where p.id = v_saya
       and p.aktif;
    if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
      raise exception 'Hanya pemilik platform atau sistem yang dapat memicu denyut'
        using errcode = 'P0001';
    end if;
  end if;

  -- Kueri kesehatan sistem (membuat aktivitas database nyata)
  select count(*) into v_penyewa_aktif from public.penyewa where status = 'aktif';
  select count(*) into v_cabang_aktif from public.cabang where aktif = true;
  v_selesai := clock_timestamp();

  -- Catat log jadwal
  insert into public.log_jadwal (
    jenis,
    dimulai_pada,
    selesai_pada,
    sukses,
    rincian,
    pesan
  ) values (
    'denyut',
    v_mulai,
    v_selesai,
    true,
    jsonb_build_object(
      'penyewa_aktif', v_penyewa_aktif,
      'cabang_aktif', v_cabang_aktif,
      'durasi_ms', round(extract(epoch from (v_selesai - v_mulai)) * 1000, 2),
      'waktu_peladen', now()
    ),
    'Denyut harian sistem berhasil dijalankan'
  ) returning id into v_log_id;

  v_hasil := jsonb_build_object(
    'berhasil', true,
    'log_id', v_log_id,
    'jenis', 'denyut',
    'penyewa_aktif', v_penyewa_aktif,
    'cabang_aktif', v_cabang_aktif,
    'waktu', now()
  );

  return v_hasil;
end;
$$;

revoke all on function public.denyut_harian() from public, anon;
grant execute on function public.denyut_harian() to authenticated, service_role;

-- ============================================================================
-- 3. Fungsi Pembersih Data Sementara (public.bersihkan_data_sementara)
-- ============================================================================
create or replace function public.bersihkan_data_sementara(
  p_hari_retensi int default 30
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_mulai timestamptz := clock_timestamp();
  v_selesai timestamptz;
  v_batas timestamptz;
  v_saya uuid := auth.uid();
  v_peran_saya text;
  v_hapus_pin int := 0;
  v_hapus_simpan_pin int := 0;
  v_hapus_masuk int := 0;
  v_hapus_voucher int := 0;
  v_hapus_kode_perangkat int := 0;
  v_hapus_pemulihan int := 0;
  v_hapus_sesi int := 0;
  v_nonaktif_dukungan int := 0;
  v_hapus_log_lama int := 0;
  v_total_dibersihkan int := 0;
  v_log_id uuid;
  v_rincian jsonb;
begin
  -- Validasi parameter
  if p_hari_retensi is null or p_hari_retensi < 1 then
    raise exception 'Hari retensi minimal 1 hari' using errcode = 'P0001';
  end if;
  if p_hari_retensi > 365 then
    raise exception 'Hari retensi maksimal 365 hari' using errcode = 'P0001';
  end if;

  -- Otorisasi: jika dipanggil authenticated, wajib peran pemilik_platform
  if v_saya is not null then
    select p.peran into v_peran_saya
      from public.pengguna p
     where p.id = v_saya
       and p.aktif;
    if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
      raise exception 'Hanya pemilik platform atau sistem yang dapat menjalankan pembersihan'
        using errcode = 'P0001';
    end if;
  end if;

  v_batas := now() - (p_hari_retensi || ' days')::interval;

  -- 1. Hapus catatan percobaan PIN lama
  delete from public.percobaan_pin where waktu < v_batas;
  get diagnostics v_hapus_pin = row_count;

  -- 2. Hapus catatan percobaan simpan PIN lama
  delete from public.percobaan_simpan_pin where waktu < v_batas;
  get diagnostics v_hapus_simpan_pin = row_count;

  -- 3. Hapus catatan percobaan login staf/perangkat lama
  delete from public.percobaan_masuk where waktu < v_batas;
  get diagnostics v_hapus_masuk = row_count;

  -- 4. Hapus catatan percobaan voucher lama
  delete from public.voucher_percobaan where waktu < v_batas;
  get diagnostics v_hapus_voucher = row_count;

  -- 5. Hapus kode pendaftaran perangkat kadaluwarsa yang tidak pernah dipakai
  delete from public.kode_pendaftaran_perangkat
    where kedaluwarsa_pada < v_batas and dipakai_pada is null;
  get diagnostics v_hapus_kode_perangkat = row_count;

  -- 6. Hapus catatan pemulihan perangkat yang selesai / dibatalkan lama
  delete from public.pemulihan_perangkat
    where status in ('selesai', 'dibatalkan') and diminta_pada < v_batas;
  get diagnostics v_hapus_pemulihan = row_count;

  -- 7. Hapus riwayat sesi perangkat yang sudah selesai / dicabut lama
  delete from public.sesi_perangkat
    where status in ('selesai', 'dicabut') and diperbarui_pada < v_batas;
  get diagnostics v_hapus_sesi = row_count;

  -- 8. Nonaktifkan mode dukungan platform yang telah melewati waktu berakhir
  update public.mode_dukungan
    set aktif = false, diakhiri_pada = coalesce(diakhiri_pada, now())
    where aktif = true and berakhir_pada < now();
  get diagnostics v_nonaktif_dukungan = row_count;

  -- 9. Hapus log jadwal lama (retensi 3x lipat, minimal 90 hari)
  delete from public.log_jadwal
    where dimulai_pada < (now() - (greatest(p_hari_retensi * 3, 90) || ' days')::interval);
  get diagnostics v_hapus_log_lama = row_count;

  v_total_dibersihkan := v_hapus_pin + v_hapus_simpan_pin + v_hapus_masuk +
                         v_hapus_voucher + v_hapus_kode_perangkat +
                         v_hapus_pemulihan + v_hapus_sesi + v_hapus_log_lama;
  v_selesai := clock_timestamp();

  v_rincian := jsonb_build_object(
    'hari_retensi', p_hari_retensi,
    'batas_waktu', v_batas,
    'percobaan_pin', v_hapus_pin,
    'percobaan_simpan_pin', v_hapus_simpan_pin,
    'percobaan_masuk', v_hapus_masuk,
    'voucher_percobaan', v_hapus_voucher,
    'kode_pendaftaran_kadaluwarsa', v_hapus_kode_perangkat,
    'pemulihan_selesai_kadaluwarsa', v_hapus_pemulihan,
    'sesi_diakhiri_kadaluwarsa', v_hapus_sesi,
    'mode_dukungan_dinonaktifkan', v_nonaktif_dukungan,
    'log_jadwal_lama', v_hapus_log_lama,
    'total_baris_dibersihkan', v_total_dibersihkan,
    'durasi_ms', round(extract(epoch from (v_selesai - v_mulai)) * 1000, 2)
  );

  insert into public.log_jadwal (
    jenis,
    dimulai_pada,
    selesai_pada,
    sukses,
    rincian,
    pesan
  ) values (
    'pembersihan',
    v_mulai,
    v_selesai,
    true,
    v_rincian,
    format('Pembersihan data sementara berhasil: %s baris dibersihkan', v_total_dibersihkan)
  ) returning id into v_log_id;

  return jsonb_build_object(
    'berhasil', true,
    'log_id', v_log_id,
    'jenis', 'pembersihan',
    'total_baris_dibersihkan', v_total_dibersihkan,
    'dibersihkan', v_rincian
  );
end;
$$;

revoke all on function public.bersihkan_data_sementara(int) from public, anon;
grant execute on function public.bersihkan_data_sementara(int) to authenticated, service_role;

-- ============================================================================
-- 4. Fungsi Ambil Log Jadwal (public.ambil_log_jadwal)
-- ============================================================================
create or replace function public.ambil_log_jadwal(
  p_limit int default 20
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya uuid := auth.uid();
  v_peran_saya text;
  v_data jsonb;
begin
  -- Otorisasi: pemilik_platform atau service_role
  if v_saya is not null then
    select p.peran into v_peran_saya
      from public.pengguna p
     where p.id = v_saya
       and p.aktif;
    if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
      raise exception 'Hanya pemilik platform atau sistem yang dapat melihat log jadwal'
        using errcode = 'P0001';
    end if;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'jenis', jenis,
        'dimulai_pada', dimulai_pada,
        'selesai_pada', selesai_pada,
        'sukses', sukses,
        'rincian', rincian,
        'pesan', pesan
      ) order by dimulai_pada desc
    ),
    '[]'::jsonb
  ) into v_data
  from (
    select * from public.log_jadwal
    order by dimulai_pada desc
    limit greatest(1, least(coalesce(p_limit, 20), 100))
  ) sub;

  return jsonb_build_object(
    'berhasil', true,
    'data', v_data
  );
end;
$$;

revoke all on function public.ambil_log_jadwal(int) from public, anon;
grant execute on function public.ambil_log_jadwal(int) to authenticated, service_role;

-- ============================================================================
-- 5. Pengaturan Tugas Terjadwal pg_cron (Bila Didukung Platform)
-- ============================================================================
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    -- Pada Supabase hosted yang memiliki pg_cron, jadwal otomatis dapat didaftarkan.
    -- Di lingkungan tanpa ekstensi pg_cron (mis. PGlite pengujian lokal),
    -- blok ini dilewati secara aman.
  end if;
exception
  when others then
    null;
end;
$$;
