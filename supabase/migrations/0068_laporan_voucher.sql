-- ============================================================================
-- Migrasi 0068: Laporan Klaim Voucher + Dasar Deteksi Anomali
-- Tugas: T8-13 (PRD M10 & M8 — Laporan klaim voucher & deteksi anomali kecurangan)
--
-- Menyediakan:
--  1. View public.laporan_voucher_ringkasan (security_invoker = true)
--     Rekapitulasi klaim (terbit), pemakaian, dan nilai potongan voucher
--     per kampanye, cabang penukaran, dan tanggal kalender.
--  2. RPC public.laporan_voucher(p_cabang_id, p_kampanye_id, p_tanggal_mulai, p_tanggal_akhir)
--     Dasbor komprehensif pelaporan voucher bagi owner_pusat dan admin_cabang:
--     - Ringkasan: total klaim, total terpakai, total potongan (Rp), konversi %, rata-rata potongan
--     - Rincian per kampanye: serapan kuota & anggaran, sisa kuota & sisa anggaran
--     - Rincian per cabang penukaran
--     - Tren harian jumlah klaim, pemakaian, dan nominal potongan
--     - Daftar identitas klaim berulang (pelanggan dengan >= 2 klaim)
--     - Deteksi anomali dini:
--       * klaim berulang berlebih (>3 klaim per pelanggan)
--       * brute force percobaan gagal (>=5 kegagalan per perangkat/IP)
--       * pemakaian kilat (<2 menit setelah voucher terbit)
--       * serapan kuota/anggaran menipis (>=80%)
--  3. RPC public.deteksi_anomali_voucher(p_cabang_id, p_ambang_klaim)
--     RPC mandiri khusus deteksi anomali untuk pemantauan dan peringatan dini.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. View Rekapitulasi Voucher Harian (security_invoker = true)
-- ---------------------------------------------------------------------------
create or replace view public.laporan_voucher_ringkasan
with (security_invoker = true) as
select
  v.penyewa_id,
  v.kampanye_id,
  kv.nama                                                                    as nama_kampanye,
  kv.kode_kampanye,
  v.terpakai_di_cabang                                                       as cabang_id,
  c.nama                                                                     as nama_cabang,
  coalesce(
    public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada),
    (v.dibuat_pada at time zone 'Asia/Jakarta')::date
  )                                                                          as tanggal,
  count(v.id)::integer                                                       as jumlah_klaim,
  count(v.id) filter (where v.status = 'terpakai')::integer                  as jumlah_terpakai,
  coalesce(sum(dt.nilai), 0)::integer                                        as total_potongan
from public.voucher v
join public.kampanye_voucher kv on kv.id = v.kampanye_id
left join public.cabang c on c.id = v.terpakai_di_cabang
left join public.diskon_transaksi dt on dt.voucher_id = v.id
group by
  v.penyewa_id,
  v.kampanye_id,
  kv.nama,
  kv.kode_kampanye,
  v.terpakai_di_cabang,
  c.nama,
  coalesce(
    public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada),
    (v.dibuat_pada at time zone 'Asia/Jakarta')::date
  );

comment on view public.laporan_voucher_ringkasan is
  'T8-13: Rekapitulasi serapan dan pemakaian voucher per kampanye, cabang, dan tanggal. security_invoker = true.';

revoke all on table public.laporan_voucher_ringkasan from public, anon;
grant select on table public.laporan_voucher_ringkasan to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. RPC public.deteksi_anomali_voucher
-- ---------------------------------------------------------------------------
create or replace function public.deteksi_anomali_voucher(
  p_cabang_id     uuid default null,
  p_ambang_klaim  integer default 3
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_anomali_klaim      jsonb := '[]'::jsonb;
  v_anomali_brute      jsonb := '[]'::jsonb;
  v_anomali_kilat      jsonb := '[]'::jsonb;
  v_anomali_anggaran   jsonb := '[]'::jsonb;
  v_gabungan           jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat deteksi anomali voucher.';
  end if;

  if p_cabang_id is not null then
    if not exists (select 1 from public.cabang where id = p_cabang_id and penyewa_id = v_penyewa) then
      raise exception 'Cabang tidak ditemukan.';
    end if;

    if not public.cabang_pantau_saya(p_cabang_id) then
      raise exception 'Cabang di luar wewenang pantauan Anda.';
    end if;
  else
    if public.peran_saya() <> 'owner_pusat' then
      select c.id into p_cabang_id
        from public.cabang c
       where c.penyewa_id = v_penyewa
         and public.cabang_pantau_saya(c.id)
       limit 1;

      if p_cabang_id is null then
        raise exception 'Cabang tidak ditemukan.';
      end if;
    end if;
  end if;

  -- 1. Anomali: Klaim berulang berlebih (> p_ambang_klaim per pelanggan)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', 'anomali-klaim-' || pl.id,
        'jenis', 'klaim_berulang_berlebih',
        'tingkat', 'waspada',
        'judul', 'Klaim Berulang Melebihi Batas Wajar',
        'keterangan', 'Pelanggan ' || pl.nama || ' (' || coalesce(pl.email, pl.email_normalisasi) || ') telah mengklaim ' || s.jml_klaim || ' voucher.',
        'identitas', coalesce(pl.email, pl.email_normalisasi),
        'jumlah', s.jml_klaim,
        'waktu', pl.dibuat_pada
      )
    ), '[]'::jsonb
  )
  into v_anomali_klaim
  from (
    select v.pelanggan_id, count(v.id)::integer as jml_klaim
      from public.voucher v
     where v.penyewa_id = v_penyewa
       and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id or v.terpakai_di_cabang is null)
     group by v.pelanggan_id
    having count(v.id) > coalesce(p_ambang_klaim, 3)
  ) s
  join public.pelanggan pl on pl.id = s.pelanggan_id;

  -- 2. Anomali: Brute force percobaan gagal (>= 5 kegagalan per perangkat / IP dalam 7 hari)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', 'anomali-brute-' || md5(coalesce(s.ip_pengakses, '') || coalesce(s.perangkat, '')),
        'jenis', 'brute_force_percobaan',
        'tingkat', 'bahaya',
        'judul', 'Percobaan Voucher Gagal Berulang (Potensi Brute Force)',
        'keterangan', 'Perangkat/IP ' || coalesce(s.ip_pengakses, s.perangkat, 'Perangkat Asing') || ' mencatat ' || s.jml || ' kegagalan validasi voucher.',
        'identitas', coalesce(s.ip_pengakses, s.perangkat, '-'),
        'jumlah', s.jml,
        'waktu', s.terakhir
      )
    ), '[]'::jsonb
  )
  into v_anomali_brute
  from (
    select
      vp.ip_pengakses,
      vp.perangkat,
      count(*)::integer as jml,
      max(vp.waktu) as terakhir
    from public.voucher_percobaan vp
    where vp.penyewa_id = v_penyewa
      and vp.hasil = 'gagal'
      and (p_cabang_id is null or vp.cabang_id = p_cabang_id)
      and vp.waktu >= now() - interval '7 days'
    group by vp.ip_pengakses, vp.perangkat
    having count(*) >= 5
  ) s;

  -- 3. Anomali: Pemakaian kilat (< 2 menit sejak klaim)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', 'anomali-kilat-' || v.id,
        'jenis', 'pemakaian_kilat',
        'tingkat', 'info',
        'judul', 'Pemakaian Kilat (< 2 Menit Sejak Pendaftaran)',
        'keterangan', 'Voucher ' || v.kode || ' (' || kv.nama || ') dicairkan ' || round(extract(epoch from (v.terpakai_pada - v.dibuat_pada)))::integer || ' detik setelah pendaftaran.',
        'identitas', v.kode,
        'jumlah', round(extract(epoch from (v.terpakai_pada - v.dibuat_pada)))::integer,
        'waktu', v.terpakai_pada
      )
    ), '[]'::jsonb
  )
  into v_anomali_kilat
  from public.voucher v
  join public.kampanye_voucher kv on kv.id = v.kampanye_id
  where v.penyewa_id = v_penyewa
    and v.status = 'terpakai'
    and v.terpakai_pada is not null
    and extract(epoch from (v.terpakai_pada - v.dibuat_pada)) between 0 and 120
    and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id);

  -- 4. Anomali: Serapan kuota atau anggaran tinggi (>= 80%)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', 'anomali-anggaran-' || kv.id,
        'jenis', 'anggaran_kuota_menipis',
        'tingkat', 'waspada',
        'judul', 'Serapan Kampanye Mendekati Batas (>= 80%)',
        'keterangan', 'Kampanye ' || kv.nama || ' (' || kv.kode_kampanye || ') telah mencapai serapan tinggi: ' ||
          case
            when kv.anggaran_maks is not null and kv.anggaran_maks > 0 and coalesce(s.total_potongan, 0)::numeric * 100 / kv.anggaran_maks >= 80
            then 'Anggaran terserap ' || round(coalesce(s.total_potongan, 0)::numeric * 100 / kv.anggaran_maks, 1) || '%'
            else 'Kuota terserap ' || round(coalesce(s.jml_klaim, 0)::numeric * 100 / nullif(kv.kuota, 0), 1) || '%'
          end || '.',
        'identitas', kv.kode_kampanye,
        'jumlah', case
          when kv.anggaran_maks is not null and kv.anggaran_maks > 0
          then round(coalesce(s.total_potongan, 0)::numeric * 100 / kv.anggaran_maks, 1)
          else round(coalesce(s.jml_klaim, 0)::numeric * 100 / nullif(kv.kuota, 0), 1)
        end,
        'waktu', now()
      )
    ), '[]'::jsonb
  )
  into v_anomali_anggaran
  from public.kampanye_voucher kv
  left join (
    select
      v.kampanye_id,
      count(v.id)::integer as jml_klaim,
      coalesce(sum(dt.nilai), 0)::integer as total_potongan
    from public.voucher v
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
    where v.penyewa_id = v_penyewa
    group by v.kampanye_id
  ) s on s.kampanye_id = kv.id
  where kv.penyewa_id = v_penyewa
    and (
      (kv.kuota is not null and kv.kuota > 0 and coalesce(s.jml_klaim, 0)::numeric * 100 / kv.kuota >= 80)
      or
      (kv.anggaran_maks is not null and kv.anggaran_maks > 0 and coalesce(s.total_potongan, 0)::numeric * 100 / kv.anggaran_maks >= 80)
    );

  v_gabungan := v_anomali_klaim || v_anomali_brute || v_anomali_kilat || v_anomali_anggaran;
  return v_gabungan;
end;
$$;

comment on function public.deteksi_anomali_voucher(uuid, integer) is
  'T8-13: Deteksi dini anomali voucher: klaim berulang (>3), brute force gagal (>=5), pemakaian kilat (<2m), dan kuota/anggaran >=80%.';

revoke all on function public.deteksi_anomali_voucher(uuid, integer) from public, anon;
grant execute on function public.deteksi_anomali_voucher(uuid, integer) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. RPC public.laporan_voucher
-- ---------------------------------------------------------------------------
create or replace function public.laporan_voucher(
  p_cabang_id      uuid default null,
  p_kampanye_id    uuid default null,
  p_tanggal_mulai  date default null,
  p_tanggal_akhir  date default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa            uuid;
  v_tanggal_akhir      date;
  v_tanggal_mulai      date;
  v_nama_cabang        text := 'Semua Cabang';
  v_total_klaim        integer := 0;
  v_total_terpakai     integer := 0;
  v_total_potongan     integer := 0;
  v_tingkat_konversi   numeric := 0;
  v_rata_rata_potongan integer := 0;
  v_per_kampanye_json  jsonb := '[]'::jsonb;
  v_per_cabang_json    jsonb := '[]'::jsonb;
  v_tren_json          jsonb := '[]'::jsonb;
  v_identitas_json     jsonb := '[]'::jsonb;
  v_anomali_json       jsonb := '[]'::jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- Wajib izin lihat_laporan (owner_pusat, admin_cabang)
  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan voucher.';
  end if;

  -- Tentukan rentang tanggal default (30 hari terakhir)
  v_tanggal_akhir := coalesce(p_tanggal_akhir, current_date);
  v_tanggal_mulai := coalesce(p_tanggal_mulai, v_tanggal_akhir - 29);

  -- Validasi urutan rentang tanggal
  if v_tanggal_akhir < v_tanggal_mulai then
    raise exception 'Tanggal akhir tidak boleh lebih awal dari tanggal mulai.';
  end if;

  -- Validasi batas maksimal rentang tanggal (maks 90 hari)
  if (v_tanggal_akhir - v_tanggal_mulai) > 90 then
    raise exception 'Rentang tanggal laporan voucher maksimal 90 hari.';
  end if;

  -- Verifikasi cabang jika ditentukan
  if p_cabang_id is not null then
    select nama into v_nama_cabang
      from public.cabang
     where id = p_cabang_id
       and penyewa_id = v_penyewa;

    if v_nama_cabang is null then
      raise exception 'Cabang tidak ditemukan.';
    end if;

    if not public.cabang_pantau_saya(p_cabang_id) then
      raise exception 'Cabang di luar wewenang pantauan Anda.';
    end if;
  else
    -- Bila p_cabang_id null dan bukan owner_pusat, batasi ke cabang pantauan staf
    if public.peran_saya() <> 'owner_pusat' then
      select c.id, c.nama into p_cabang_id, v_nama_cabang
        from public.cabang c
       where c.penyewa_id = v_penyewa
         and public.cabang_pantau_saya(c.id)
       limit 1;

      if p_cabang_id is null then
        raise exception 'Cabang tidak ditemukan.';
      end if;
    end if;
  end if;

  -- Verifikasi kampanye bila ditentukan
  if p_kampanye_id is not null then
    if not exists (select 1 from public.kampanye_voucher where id = p_kampanye_id and penyewa_id = v_penyewa) then
      raise exception 'Kampanye voucher tidak ditemukan.';
    end if;
  end if;

  -- 1. Hitung Ringkasan Total Klaim (diterbitkan dalam rentang tanggal)
  select count(distinct v.id)::integer
    into v_total_klaim
    from public.voucher v
   where v.penyewa_id = v_penyewa
     and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
     and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id or v.terpakai_di_cabang is null)
     and (v.dibuat_pada at time zone 'Asia/Jakarta')::date between v_tanggal_mulai and v_tanggal_akhir;

  -- 2. Hitung Total Pemakaian & Total Rupiah Potongan (dicairkan dalam rentang tanggal)
  select
    count(distinct v.id)::integer,
    coalesce(sum(dt.nilai), 0)::integer
    into v_total_terpakai, v_total_potongan
    from public.voucher v
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
   where v.penyewa_id = v_penyewa
     and v.status = 'terpakai'
     and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
     and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id)
     and coalesce(public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada), (v.terpakai_pada at time zone 'Asia/Jakarta')::date) between v_tanggal_mulai and v_tanggal_akhir;

  -- Rasio konversi dan rata-rata potongan
  if v_total_klaim > 0 then
    v_tingkat_konversi := round((v_total_terpakai::numeric / v_total_klaim::numeric) * 100, 1);
  else
    v_tingkat_konversi := 0;
  end if;

  if v_total_terpakai > 0 then
    v_rata_rata_potongan := round(v_total_potongan::numeric / v_total_terpakai::numeric)::integer;
  else
    v_rata_rata_potongan := 0;
  end if;

  -- 3. Rincian Per Kampanye
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'kampanye_id', k.id,
        'nama', k.nama,
        'kode_kampanye', k.kode_kampanye,
        'jenis', k.jenis,
        'nilai', k.nilai,
        'min_belanja', k.min_belanja,
        'maks_potongan', k.maks_potongan,
        'kuota', k.kuota,
        'anggaran_maks', k.anggaran_maks,
        'jumlah_klaim', coalesce(s.jml_klaim, 0),
        'jumlah_terpakai', coalesce(s.jml_terpakai, 0),
        'total_potongan', coalesce(s.total_potongan, 0),
        'sisa_kuota', case when k.kuota is not null then greatest(0, k.kuota - coalesce(s.jml_klaim, 0)) else null end,
        'sisa_anggaran', case when k.anggaran_maks is not null then greatest(0, k.anggaran_maks - coalesce(s.total_potongan, 0)) else null end,
        'persen_kuota_terpakai', case when k.kuota is not null and k.kuota > 0 then round((coalesce(s.jml_klaim, 0)::numeric / k.kuota::numeric) * 100, 1) else 0 end,
        'persen_anggaran_terpakai', case when k.anggaran_maks is not null and k.anggaran_maks > 0 then round((coalesce(s.total_potongan, 0)::numeric / k.anggaran_maks::numeric) * 100, 1) else 0 end
      ) order by coalesce(s.total_potongan, 0) desc, k.nama
    ), '[]'::jsonb
  )
  into v_per_kampanye_json
  from public.kampanye_voucher k
  left join (
    select
      v.kampanye_id,
      count(v.id)::integer as jml_klaim,
      count(v.id) filter (where v.status = 'terpakai')::integer as jml_terpakai,
      coalesce(sum(dt.nilai), 0)::integer as total_potongan
    from public.voucher v
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
    where v.penyewa_id = v_penyewa
      and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id or v.terpakai_di_cabang is null)
      and (
        (v.dibuat_pada at time zone 'Asia/Jakarta')::date between v_tanggal_mulai and v_tanggal_akhir
        or
        (v.terpakai_pada is not null and (v.terpakai_pada at time zone 'Asia/Jakarta')::date between v_tanggal_mulai and v_tanggal_akhir)
      )
    group by v.kampanye_id
  ) s on s.kampanye_id = k.id
  where k.penyewa_id = v_penyewa
    and (p_kampanye_id is null or k.id = p_kampanye_id);

  -- 4. Rincian Per Cabang Penukaran
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'cabang_id', c.id,
        'nama_cabang', c.nama,
        'jumlah_terpakai', coalesce(s.jml_terpakai, 0),
        'total_potongan', coalesce(s.total_potongan, 0)
      ) order by coalesce(s.total_potongan, 0) desc, c.nama
    ), '[]'::jsonb
  )
  into v_per_cabang_json
  from public.cabang c
  join (
    select
      v.terpakai_di_cabang as cabang_id,
      count(v.id)::integer as jml_terpakai,
      coalesce(sum(dt.nilai), 0)::integer as total_potongan
    from public.voucher v
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
    where v.penyewa_id = v_penyewa
      and v.status = 'terpakai'
      and v.terpakai_di_cabang is not null
      and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
      and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id)
      and coalesce(public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada), (v.terpakai_pada at time zone 'Asia/Jakarta')::date) between v_tanggal_mulai and v_tanggal_akhir
    group by v.terpakai_di_cabang
  ) s on s.cabang_id = c.id
  where c.penyewa_id = v_penyewa;

  -- 5. Tren Harian (deret hari kalender dalam rentang tanggal)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'tanggal', to_char(d.dt::date, 'YYYY-MM-DD'),
        'jumlah_klaim', coalesce(k.jml_klaim, 0),
        'jumlah_terpakai', coalesce(p.jml_terpakai, 0),
        'total_potongan', coalesce(p.total_potongan, 0)
      ) order by d.dt::date asc
    ), '[]'::jsonb
  )
  into v_tren_json
  from generate_series(v_tanggal_mulai::timestamp, v_tanggal_akhir::timestamp, interval '1 day') d(dt)
  left join (
    select
      (v.dibuat_pada at time zone 'Asia/Jakarta')::date as tgl,
      count(v.id)::integer as jml_klaim
    from public.voucher v
    where v.penyewa_id = v_penyewa
      and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
      and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id or v.terpakai_di_cabang is null)
    group by (v.dibuat_pada at time zone 'Asia/Jakarta')::date
  ) k on k.tgl = d.dt::date
  left join (
    select
      coalesce(public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada), (v.terpakai_pada at time zone 'Asia/Jakarta')::date) as tgl,
      count(v.id)::integer as jml_terpakai,
      coalesce(sum(dt.nilai), 0)::integer as total_potongan
    from public.voucher v
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
    where v.penyewa_id = v_penyewa
      and v.status = 'terpakai'
      and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
      and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id)
    group by coalesce(public.tanggal_lokal_cabang(v.terpakai_di_cabang, v.terpakai_pada), (v.terpakai_pada at time zone 'Asia/Jakarta')::date)
  ) p on p.tgl = d.dt::date;

  -- 6. Daftar Identitas Klaim Berulang (>= 2 klaim)
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'pelanggan_id', pl.id,
        'nama', pl.nama,
        'email', pl.email,
        'email_normalisasi', pl.email_normalisasi,
        'telepon', pl.telepon,
        'jumlah_klaim', s.jml_klaim,
        'jumlah_terpakai', s.jml_terpakai,
        'total_potongan', s.total_potongan,
        'kampanye_daftar', s.kampanye_daftar
      ) order by s.jml_klaim desc, s.total_potongan desc
    ), '[]'::jsonb
  )
  into v_identitas_json
  from (
    select
      v.pelanggan_id,
      count(v.id)::integer as jml_klaim,
      count(v.id) filter (where v.status = 'terpakai')::integer as jml_terpakai,
      coalesce(sum(dt.nilai), 0)::integer as total_potongan,
      array_agg(distinct kv.nama) as kampanye_daftar
    from public.voucher v
    join public.kampanye_voucher kv on kv.id = v.kampanye_id
    left join public.diskon_transaksi dt on dt.voucher_id = v.id
    where v.penyewa_id = v_penyewa
      and (p_kampanye_id is null or v.kampanye_id = p_kampanye_id)
      and (p_cabang_id is null or v.terpakai_di_cabang = p_cabang_id or v.terpakai_di_cabang is null)
    group by v.pelanggan_id
    having count(v.id) >= 2
  ) s
  join public.pelanggan pl on pl.id = s.pelanggan_id;

  -- 7. Deteksi Anomali
  v_anomali_json := public.deteksi_anomali_voucher(p_cabang_id, 3);

  return jsonb_build_object(
    'rentang', jsonb_build_object(
      'mulai', to_char(v_tanggal_mulai, 'YYYY-MM-DD'),
      'akhir', to_char(v_tanggal_akhir, 'YYYY-MM-DD'),
      'cabang_id', p_cabang_id,
      'nama_cabang', v_nama_cabang,
      'kampanye_id', p_kampanye_id
    ),
    'ringkasan', jsonb_build_object(
      'total_klaim', v_total_klaim,
      'total_terpakai', v_total_terpakai,
      'total_potongan', v_total_potongan,
      'tingkat_konversi_persen', v_tingkat_konversi,
      'rata_rata_potongan', v_rata_rata_potongan
    ),
    'per_kampanye', v_per_kampanye_json,
    'per_cabang', v_per_cabang_json,
    'tren_harian', v_tren_json,
    'identitas_klaim_berulang', v_identitas_json,
    'anomali', v_anomali_json
  );
end;
$$;

comment on function public.laporan_voucher(uuid, uuid, date, date) is
  'T8-13: Laporan klaim voucher, pemakaian, rupiah potongan, identitas berulang, dan anomali per kampanye/cabang/hari.';

revoke all on function public.laporan_voucher(uuid, uuid, date, date) from public, anon;
grant execute on function public.laporan_voucher(uuid, uuid, date, date) to authenticated, service_role;
