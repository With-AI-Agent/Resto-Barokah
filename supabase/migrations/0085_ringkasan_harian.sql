-- ============================================================================
-- Migrasi 0085: Ringkasan Peringatan Harian ke Owner (T10-13 / M12 / ART-13 / ART-14)
--
-- Tujuan:
--   1. Agregasi anomali operasional dan keamanan harian (void, diskon, selisih kas,
--      percobaan masuk gagal, perubahan perangkat, pemulihan perangkat, integritas audit).
--   2. Memungkinkan owner memantau keamanan kedai tanpa harus membuka aplikasi setiap saat
--      (dikirim via email owner DAN dapat dilihat di layar Peringatan dalam aplikasi).
--   3. Menegakkan perlindungan privasi pelanggan penuh (UU PDP & ART-14): laporan ringkasan
--      dan rincian anomali HANYA memuat angka agregat dan nama pegawai kedai, tanpa kontak
--      atau identitas pelanggan (nama, nomor telepon, email disensor/ditiadakan).
--   4. Memeriksa integritas rantai audit berantai hash (ART-13) dan melaporkan jika putus.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Tambah Kolom Konfigurasi Peringatan pada tabel public.pengaturan
-- ---------------------------------------------------------------------------
alter table public.pengaturan
  add column if not exists email_peringatan text,
  add column if not exists kirim_email_peringatan boolean not null default true,
  add column if not exists jam_ringkasan text not null default '23:00';

comment on column public.pengaturan.email_peringatan is
  'Email tujuan penerima ringkasan peringatan harian. Jika null/kosong, sistem memakai email owner_pusat pertama.';
comment on column public.pengaturan.kirim_email_peringatan is
  'Apakah pengiriman ringkasan harian via email diaktifkan.';
comment on column public.pengaturan.jam_ringkasan is
  'Jadwal waktu pengiriman ringkasan harian (format 24 jam HH:MI).';

-- ---------------------------------------------------------------------------
-- 2. Tabel public.ringkasan_harian
-- ---------------------------------------------------------------------------
create table if not exists public.ringkasan_harian (
  id                        uuid primary key default gen_random_uuid(),
  penyewa_id                uuid not null references public.penyewa (id) on delete cascade,
  tanggal                   date not null,
  omzet                     bigint not null default 0 check (omzet >= 0),
  transaksi_count           integer not null default 0 check (transaksi_count >= 0),
  void_count                integer not null default 0 check (void_count >= 0),
  void_nominal              bigint not null default 0 check (void_nominal >= 0),
  diskon_count              integer not null default 0 check (diskon_count >= 0),
  diskon_nominal            bigint not null default 0 check (diskon_nominal >= 0),
  selisih_kas_count         integer not null default 0 check (selisih_kas_count >= 0),
  selisih_kas_nominal       bigint not null default 0 check (selisih_kas_nominal >= 0),
  percobaan_gagal_count     integer not null default 0 check (percobaan_gagal_count >= 0),
  perubahan_perangkat_count integer not null default 0 check (perubahan_perangkat_count >= 0),
  pemulihan_count           integer not null default 0 check (pemulihan_count >= 0),
  rantai_audit_valid        boolean not null default true,
  rantai_audit_pesan        text not null default 'Seluruh rantai audit valid dan tidak terputus.',
  email_tujuan              text,
  status_email              text not null default 'tertunda' check (status_email in ('tertunda', 'terkirim', 'gagal', 'lewati')),
  rincian_peringatan        jsonb not null default '[]'::jsonb,
  dibuat_pada               timestamptz not null default now(),
  dikirim_pada              timestamptz,
  constraint ringkasan_harian_penyewa_tanggal_unik unique (penyewa_id, tanggal)
);

comment on table public.ringkasan_harian is
  'Rekap harian operasional dan keamanan resto (omzet, void, diskon, selisih kas, percobaan login gagal, perubahan perangkat, status rantai audit). Privasi terjaga: bebas data pribadi pelanggan (ART-14).';

create index if not exists idx_ringkasan_harian_penyewa_tanggal
  on public.ringkasan_harian (penyewa_id, tanggal desc);

-- ---------------------------------------------------------------------------
-- 3. RLS pada public.ringkasan_harian (ART-1)
-- ---------------------------------------------------------------------------
alter table public.ringkasan_harian enable row level security;

revoke all on table public.ringkasan_harian from public, anon;
grant select on table public.ringkasan_harian to authenticated;
grant all on table public.ringkasan_harian to service_role;

drop policy if exists ringkasan_harian_pilih on public.ringkasan_harian;
create policy ringkasan_harian_pilih on public.ringkasan_harian
  for select to authenticated
  using (
    penyewa_id = (select public.penyewa_saya())
    and (select public.boleh('lihat_laporan'))
  );

-- ---------------------------------------------------------------------------
-- 4. RPC public.hasilkan_ringkasan_harian
-- ---------------------------------------------------------------------------
create or replace function public.hasilkan_ringkasan_harian(
  p_penyewa_id uuid default null,
  p_tanggal date default (current_date - 1)
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id             uuid;
  v_peran                  text;
  v_omzet                  bigint := 0;
  v_transaksi_count        integer := 0;
  v_void_count             integer := 0;
  v_void_nominal           bigint := 0;
  v_diskon_count           integer := 0;
  v_diskon_nominal         bigint := 0;
  v_selisih_kas_count      integer := 0;
  v_selisih_kas_nominal    bigint := 0;
  v_percobaan_gagal_count  integer := 0;
  v_perubahan_perangkat    integer := 0;
  v_pemulihan_count        integer := 0;
  v_audit_valid            boolean := true;
  v_audit_pesan            text := 'Seluruh rantai audit valid dan tidak terputus.';
  v_email_tujuan           text;
  v_kirim_email            boolean := true;
  v_status_email           text := 'tertunda';
  v_rincian                jsonb := '[]'::jsonb;
  v_rincian_void           jsonb := '[]'::jsonb;
  v_rincian_selisih        jsonb := '[]'::jsonb;
  v_rincian_diskon         jsonb := '[]'::jsonb;
  v_rincian_masuk          jsonb := '[]'::jsonb;
  v_rincian_perangkat      jsonb := '[]'::jsonb;
  v_ringkasan_id           uuid;
  v_hasil                  jsonb;
begin
  -- Tentukan target penyewa
  v_penyewa_id := coalesce(p_penyewa_id, public.penyewa_saya());

  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan atau belum ditentukan.'
      using errcode = 'P0002';
  end if;

  -- Verifikasi hak pemanggil bila dipanggil oleh sesi terotentikasi
  if current_user <> 'postgres' and current_setting('role', true) <> 'service_role' then
    v_peran := public.peran_saya();
    if v_peran <> 'pemilik_platform' then
      if v_penyewa_id <> public.penyewa_saya() then
        raise exception 'Tidak berwenang mengakses data penyewa lain.'
          using errcode = '42501';
      end if;
      if not public.boleh('lihat_laporan') and not public.boleh('atur_pengaturan') then
        raise exception 'Tidak berwenang menghasilkan ringkasan laporan.'
          using errcode = '42501';
      end if;
    end if;
  end if;

  -- 1. Omzet & Transaksi lunas
  select coalesce(sum(total), 0), count(*)
    into v_omzet, v_transaksi_count
    from public.pesanan
   where penyewa_id = v_penyewa_id
     and status = 'lunas'
     and coalesce(dibayar_pada::date, tanggal) = p_tanggal;

  -- 2. Void & Pembatalan
  select count(*), coalesce(sum(b.nilai_kerugian), 0)
    into v_void_count, v_void_nominal
    from public.pembatalan b
    join public.pesanan p on p.id = b.pesanan_id
   where p.penyewa_id = v_penyewa_id
     and b.waktu::date = p_tanggal;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori', 'void',
      'waktu', to_char(b.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'pegawai', coalesce(u.nama, 'Pegawai'),
      'alasan', b.alasan,
      'nominal', b.nilai_kerugian,
      'tahap', b.tahap
    ) order by b.waktu desc
  ), '[]'::jsonb)
  into v_rincian_void
  from public.pembatalan b
  join public.pesanan p on p.id = b.pesanan_id
  left join public.pengguna u on u.id = b.pelaku_id
  where p.penyewa_id = v_penyewa_id
    and b.waktu::date = p_tanggal;

  -- 3. Diskon Transaksi
  select count(*), coalesce(sum(d.nilai), 0)
    into v_diskon_count, v_diskon_nominal
    from public.diskon_transaksi d
    join public.pesanan p on p.id = d.pesanan_id
   where p.penyewa_id = v_penyewa_id
     and d.waktu::date = p_tanggal;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori', 'diskon',
      'waktu', to_char(d.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'pegawai', coalesce(u.nama, 'Kasir'),
      'jenis', d.jenis,
      'nominal', d.nilai,
      'alasan', coalesce(d.alasan, '-')
    ) order by d.waktu desc
  ), '[]'::jsonb)
  into v_rincian_diskon
  from public.diskon_transaksi d
  join public.pesanan p on p.id = d.pesanan_id
  left join public.pengguna u on u.id = d.pelaku_id
  where p.penyewa_id = v_penyewa_id
    and d.waktu::date = p_tanggal;

  -- 4. Selisih Kas Shift Kasir
  select count(*), coalesce(sum(abs(coalesce(s.selisih, 0))), 0)
    into v_selisih_kas_count, v_selisih_kas_nominal
    from public.shift_kas s
   where s.penyewa_id = v_penyewa_id
     and s.status = 'ditutup'
     and s.ditutup_pada::date = p_tanggal
     and coalesce(s.selisih, 0) <> 0;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori', 'selisih_kas',
      'waktu', to_char(s.ditutup_pada at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'pegawai', coalesce(u.nama, 'Kasir'),
      'nominal', abs(coalesce(s.selisih, 0)),
      'selisih', s.selisih,
      'alasan', coalesce(s.alasan_selisih, 'Tidak ada alasan dicatat')
    ) order by s.ditutup_pada desc
  ), '[]'::jsonb)
  into v_rincian_selisih
  from public.shift_kas s
  left join public.pengguna u on u.id = s.dibuka_oleh
  where s.penyewa_id = v_penyewa_id
    and s.status = 'ditutup'
    and s.ditutup_pada::date = p_tanggal
    and coalesce(s.selisih, 0) <> 0;

  -- 5. Percobaan Masuk / PIN Gagal
  declare
    v_gagal_masuk integer := 0;
    v_gagal_pin   integer := 0;
  begin
    select count(*)
      into v_gagal_masuk
      from public.percobaan_masuk pm
     where pm.penyewa_id = v_penyewa_id
       and pm.waktu::date = p_tanggal
       and pm.berhasil = false;

    select count(*)
      into v_gagal_pin
      from public.percobaan_pin pp
      join public.pengguna u on u.id = pp.pengguna_id
     where u.penyewa_id = v_penyewa_id
       and pp.waktu::date = p_tanggal
       and pp.berhasil = false;

    v_percobaan_gagal_count := v_gagal_masuk + v_gagal_pin;
  end;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori', 'masuk_gagal',
      'waktu', to_char(pm.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'pegawai', coalesce(u.nama, 'Tidak dikenal'),
      'alasan', coalesce(pm.sebab, 'Percobaan masuk/PIN gagal')
    ) order by pm.waktu desc
  ), '[]'::jsonb)
  into v_rincian_masuk
  from public.percobaan_masuk pm
  left join public.pengguna u on u.id = pm.pengguna_id
  where pm.penyewa_id = v_penyewa_id
    and pm.waktu::date = p_tanggal
    and pm.berhasil = false;

  -- 6. Perubahan Perangkat & Sesi (daftar, setujui, cabut, hilang, akhiri_sesi)
  select count(*)
    into v_perubahan_perangkat
    from public.catatan_audit ca
   where ca.penyewa_id = v_penyewa_id
     and ca.waktu::date = p_tanggal
     and ca.aksi in ('daftar_perangkat', 'setujui_perangkat', 'cabut_perangkat', 'perangkat_hilang', 'akhiri_sesi');

  -- 7. Pemulihan Perangkat
  select count(*)
    into v_pemulihan_count
    from public.pemulihan_perangkat pp
   where pp.penyewa_id = v_penyewa_id
     and pp.diminta_pada::date = p_tanggal;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kategori', 'perangkat',
      'waktu', to_char(ca.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
      'pegawai', coalesce(u.nama, 'Sistem'),
      'aksi', ca.aksi,
      'entitas_id', ca.entitas_id
    ) order by ca.waktu desc
  ), '[]'::jsonb)
  into v_rincian_perangkat
  from public.catatan_audit ca
  left join public.pengguna u on u.id = ca.pelaku_id
  where ca.penyewa_id = v_penyewa_id
    and ca.waktu::date = p_tanggal
    and ca.aksi in ('daftar_perangkat', 'setujui_perangkat', 'cabut_perangkat', 'perangkat_hilang', 'akhiri_sesi', 'buat_kode_pemulihan', 'pulihkan_perangkat', 'batalkan_pemulihan');

  -- Gabungkan rincian anomali (semua tanpa data pribadi pelanggan!)
  v_rincian := v_rincian_void || v_rincian_selisih || v_rincian_diskon || v_rincian_masuk || v_rincian_perangkat;

  -- 8. Pemeriksaan Integritas Rantai Audit (ART-13)
  begin
    select coalesce(vra.valid, false), coalesce(vra.pesan, 'Pemeriksaan rantai audit selesai')
      into v_audit_valid, v_audit_pesan
      from public.verifikasi_rantai_audit(v_penyewa_id) vra
     limit 1;
  exception when others then
    v_audit_valid := false;
    v_audit_pesan := 'Gagal memverifikasi rantai audit: ' || SQLERRM;
  end;

  -- 9. Email Tujuan & Preferensi Pengiriman
  select p.email_peringatan, p.kirim_email_peringatan
    into v_email_tujuan, v_kirim_email
    from public.pengaturan p
   where p.penyewa_id = v_penyewa_id;

  if v_email_tujuan is null or length(btrim(v_email_tujuan)) = 0 then
    -- Ambil email owner pusat pertama dari tabel pengguna
    select u.email
      into v_email_tujuan
      from public.pengguna u
     where u.penyewa_id = v_penyewa_id
       and u.peran = 'owner_pusat'
       and u.aktif = true
       and u.email is not null
     order by u.dibuat_pada asc
     limit 1;
  end if;

  v_status_email := case when coalesce(v_kirim_email, true) then 'tertunda' else 'lewati' end;

  -- 10. Upsert ke tabel ringkasan_harian
  insert into public.ringkasan_harian (
    penyewa_id, tanggal, omzet, transaksi_count, void_count, void_nominal,
    diskon_count, diskon_nominal, selisih_kas_count, selisih_kas_nominal,
    percobaan_gagal_count, perubahan_perangkat_count, pemulihan_count,
    rantai_audit_valid, rantai_audit_pesan, email_tujuan, status_email,
    rincian_peringatan, dibuat_pada
  ) values (
    v_penyewa_id, p_tanggal, v_omzet, v_transaksi_count, v_void_count, v_void_nominal,
    v_diskon_count, v_diskon_nominal, v_selisih_kas_count, v_selisih_kas_nominal,
    v_percobaan_gagal_count, v_perubahan_perangkat, v_pemulihan_count,
    v_audit_valid, v_audit_pesan, v_email_tujuan, v_status_email,
    v_rincian, now()
  )
  on conflict (penyewa_id, tanggal) do update set
    omzet = excluded.omzet,
    transaksi_count = excluded.transaksi_count,
    void_count = excluded.void_count,
    void_nominal = excluded.void_nominal,
    diskon_count = excluded.diskon_count,
    diskon_nominal = excluded.diskon_nominal,
    selisih_kas_count = excluded.selisih_kas_count,
    selisih_kas_nominal = excluded.selisih_kas_nominal,
    percobaan_gagal_count = excluded.percobaan_gagal_count,
    perubahan_perangkat_count = excluded.perubahan_perangkat_count,
    pemulihan_count = excluded.pemulihan_count,
    rantai_audit_valid = excluded.rantai_audit_valid,
    rantai_audit_pesan = excluded.rantai_audit_pesan,
    email_tujuan = excluded.email_tujuan,
    status_email = case when ringkasan_harian.status_email = 'terkirim' then 'terkirim' else excluded.status_email end,
    rincian_peringatan = excluded.rincian_peringatan,
    dibuat_pada = now()
  returning id into v_ringkasan_id;

  -- 11. Catat ke catatan_audit
  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
  ) values (
    v_penyewa_id,
    auth.uid(),
    'ringkasan_harian',
    'ringkasan_harian',
    v_ringkasan_id,
    jsonb_build_object(
      'tanggal', p_tanggal,
      'omzet', v_omzet,
      'void_count', v_void_count,
      'void_nominal', v_void_nominal,
      'selisih_kas_nominal', v_selisih_kas_nominal,
      'rantai_audit_valid', v_audit_valid
    )
  );

  v_hasil := jsonb_build_object(
    'berhasil', true,
    'id', v_ringkasan_id,
    'penyewa_id', v_penyewa_id,
    'tanggal', p_tanggal,
    'omzet', v_omzet,
    'transaksi_count', v_transaksi_count,
    'void_count', v_void_count,
    'void_nominal', v_void_nominal,
    'diskon_count', v_diskon_count,
    'diskon_nominal', v_diskon_nominal,
    'selisih_kas_count', v_selisih_kas_count,
    'selisih_kas_nominal', v_selisih_kas_nominal,
    'percobaan_gagal_count', v_percobaan_gagal_count,
    'perubahan_perangkat_count', v_perubahan_perangkat,
    'pemulihan_count', v_pemulihan_count,
    'rantai_audit_valid', v_audit_valid,
    'rantai_audit_pesan', v_audit_pesan,
    'email_tujuan', v_email_tujuan,
    'status_email', v_status_email,
    'rincian_peringatan', v_rincian
  );

  return v_hasil;
end;
$$;

comment on function public.hasilkan_ringkasan_harian(uuid, date) is
  'Menghitung dan merekam agregat ringkasan peringatan harian (omzet, void, diskon, selisih kas, gagal login, audit). Privasi terjamin: nol data pribadi pelanggan (ART-14).';

revoke all on function public.hasilkan_ringkasan_harian(uuid, date) from public;
grant execute on function public.hasilkan_ringkasan_harian(uuid, date) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 5. RPC public.ambil_ringkasan_harian
-- ---------------------------------------------------------------------------
create or replace function public.ambil_ringkasan_harian(
  p_tanggal_awal date default null,
  p_tanggal_akhir date default null
)
returns table (
  id                        uuid,
  penyewa_id                uuid,
  tanggal                   date,
  omzet                     bigint,
  transaksi_count           integer,
  void_count                integer,
  void_nominal              bigint,
  diskon_count              integer,
  diskon_nominal            bigint,
  selisih_kas_count         integer,
  selisih_kas_nominal       bigint,
  percobaan_gagal_count     integer,
  perubahan_perangkat_count integer,
  pemulihan_count           integer,
  rantai_audit_valid        boolean,
  rantai_audit_pesan        text,
  email_tujuan              text,
  status_email              text,
  rincian_peringatan        jsonb,
  dibuat_pada               timestamptz,
  dikirim_pada              timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id    uuid;
  v_awal          date;
  v_akhir         date;
begin
  v_penyewa_id := public.penyewa_saya();
  if v_penyewa_id is null then
    return;
  end if;

  if not public.boleh('lihat_laporan') and not public.boleh('atur_pengaturan') then
    raise exception 'Tidak berwenang melihat laporan peringatan.'
      using errcode = '42501';
  end if;

  v_akhir := coalesce(p_tanggal_akhir, current_date);
  v_awal := coalesce(p_tanggal_awal, v_akhir - 30);

  return query
    select r.id,
           r.penyewa_id,
           r.tanggal,
           r.omzet,
           r.transaksi_count,
           r.void_count,
           r.void_nominal,
           r.diskon_count,
           r.diskon_nominal,
           r.selisih_kas_count,
           r.selisih_kas_nominal,
           r.percobaan_gagal_count,
           r.perubahan_perangkat_count,
           r.pemulihan_count,
           r.rantai_audit_valid,
           r.rantai_audit_pesan,
           r.email_tujuan,
           r.status_email,
           r.rincian_peringatan,
           r.dibuat_pada,
           r.dikirim_pada
      from public.ringkasan_harian r
     where r.penyewa_id = v_penyewa_id
       and r.tanggal between v_awal and v_akhir
     order by r.tanggal desc;
end;
$$;

comment on function public.ambil_ringkasan_harian(date, date) is
  'Mengambil riwayat ringkasan peringatan harian untuk penyewa pemanggil dalam rentang tanggal tertentu.';

revoke all on function public.ambil_ringkasan_harian(date, date) from public;
grant execute on function public.ambil_ringkasan_harian(date, date) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 6. RPC public.simpan_pengaturan_peringatan
-- ---------------------------------------------------------------------------
create or replace function public.simpan_pengaturan_peringatan(
  p_email_peringatan text,
  p_kirim_email boolean,
  p_jam_ringkasan text default '23:00'
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_jam text;
begin
  v_penyewa_id := public.penyewa_saya();
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = 'P0002';
  end if;

  if not public.boleh('atur_pengaturan') and (public.peran_saya() <> 'owner_pusat') then
    raise exception 'Hanya owner atau pengguna dengan izin atur_pengaturan yang dapat mengubah setelan ini.'
      using errcode = '42501';
  end if;

  v_jam := coalesce(nullif(btrim(p_jam_ringkasan), ''), '23:00');
  if not (v_jam ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') then
    raise exception 'Format jam ringkasan tidak valid. Gunakan format 24 jam HH:MI (mis. 23:00).'
      using errcode = '22007';
  end if;

  if p_email_peringatan is not null and length(btrim(p_email_peringatan)) > 0 then
    if not (btrim(p_email_peringatan) ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') then
      raise exception 'Format alamat email peringatan tidak valid.'
        using errcode = '22000';
    end if;
  end if;

  update public.pengaturan
     set email_peringatan = nullif(btrim(p_email_peringatan), ''),
         kirim_email_peringatan = coalesce(p_kirim_email, true),
         jam_ringkasan = v_jam,
         diubah_oleh = auth.uid(),
         diubah_pada = now()
   where penyewa_id = v_penyewa_id;

  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru
  ) values (
    v_penyewa_id,
    auth.uid(),
    'simpan_pengaturan_peringatan',
    'pengaturan',
    v_penyewa_id,
    jsonb_build_object(
      'email_peringatan', p_email_peringatan,
      'kirim_email_peringatan', p_kirim_email,
      'jam_ringkasan', v_jam
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Pengaturan notifikasi peringatan harian berhasil disimpan.'
  );
end;
$$;

comment on function public.simpan_pengaturan_peringatan(text, boolean, text) is
  'Menyimpan preferensi email, aktivasi notifikasi, dan jam pengiriman ringkasan harian resto.';

revoke all on function public.simpan_pengaturan_peringatan(text, boolean, text) from public;
grant execute on function public.simpan_pengaturan_peringatan(text, boolean, text) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 7. RPC public.set_status_email_ringkasan
-- ---------------------------------------------------------------------------
create or replace function public.set_status_email_ringkasan(
  p_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_ringkasan record;
begin
  if p_status not in ('tertunda', 'terkirim', 'gagal', 'lewati') then
    raise exception 'Status email tidak valid.' using errcode = '22023';
  end if;

  select * into v_ringkasan
    from public.ringkasan_harian
   where id = p_id;

  if not found then
    raise exception 'Data ringkasan tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- Jika dipanggil authenticated, pastikan penyewa sama
  if current_user <> 'postgres' and current_setting('role', true) <> 'service_role' then
    if v_ringkasan.penyewa_id <> public.penyewa_saya() then
      raise exception 'Tidak berwenang memperbarui status ringkasan penyewa lain.' using errcode = '42501';
    end if;
  end if;

  update public.ringkasan_harian
     set status_email = p_status,
         dikirim_pada = case when p_status = 'terkirim' then now() else dikirim_pada end
   where id = p_id;

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Status email ringkasan berhasil diperbarui.'
  );
end;
$$;

comment on function public.set_status_email_ringkasan(uuid, text) is
  'Memperbarui status pengiriman email pada ringkasan harian (service_role atau owner).';

revoke all on function public.set_status_email_ringkasan(uuid, text) from public;
grant execute on function public.set_status_email_ringkasan(uuid, text) to authenticated, service_role;
