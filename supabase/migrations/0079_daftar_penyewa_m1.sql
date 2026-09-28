-- ============================================================================
-- 0079 — Pemilik Platform: Daftar & Pengelolaan Penyewa (T9-10 / PRD M1 / ART-1)
--
-- Menuntaskan tata kelola penyewa (multi-resto) oleh Pemilik Platform:
--  1. Penambahan kolom pada public.penyewa:
--     - diubah_pada (timestamptz)
--     - kontak_telepon (text)
--     - kontak_email (text)
--     - dinonaktifkan_pada (timestamptz)
--     - alasan_nonaktif (text)
--  2. Pemicu fail-closed:
--     - picu_penyewa_cegah_hapus: mencegah hard-delete penyewa yang memiliki riwayat
--       cabang, transaksi pesanan, shift kasir, atau pengguna (wajib soft-disable).
--  3. RPC resmi platform:
--     - public.buat_penyewa: mendaftarkan resto baru + cabang pertama + akun Owner
--       pertama + PIN 6 digit angka dengan isolasi total tingkat 1 (ART-1).
--     - public.set_status_penyewa: mengaktifkan / menonaktifkan penyewa (soft-disable
--       tanpa merusak riwayat transaksi finansial) dengan pencabutan sesi perangkat.
--     - public.ambil_daftar_penyewa: membaca ringkasan daftar resto, statistik cabang,
--       dan profil owner bagi pemilik platform.
--  4. Jejak audit kekal di public.catatan_audit untuk setiap tindakan platform.
-- ============================================================================

-- 1. Penambahan Kolom pada public.penyewa
alter table public.penyewa
  add column if not exists diubah_pada timestamptz not null default now(),
  add column if not exists kontak_telepon text default null,
  add column if not exists kontak_email text default null,
  add column if not exists dinonaktifkan_pada timestamptz default null,
  add column if not exists alasan_nonaktif text default null;

comment on column public.penyewa.kontak_telepon is
  'Nomor kontak resmi narahubung penyewa/resto (opsional).';

comment on column public.penyewa.kontak_email is
  'Alamat email resmi penagihan atau kontak bisnis penyewa (opsional).';

comment on column public.penyewa.dinonaktifkan_pada is
  'Stempel waktu kapan penyewa dinonaktifkan oleh pemilik platform.';

comment on column public.penyewa.alasan_nonaktif is
  'Alasan penonaktifan operasional penyewa oleh pemilik platform.';

-- 2. Pemicu Fail-Closed: Cegah Hard Delete Penyewa Ber-riwayat
create or replace function public.picu_penyewa_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.cabang where penyewa_id = old.id) then
    raise exception 'Penyewa "%" tidak dapat dihapus karena masih memiliki data cabang. Silakan nonaktifkan status penyewa.', old.nama;
  end if;

  if exists (select 1 from public.pesanan where penyewa_id = old.id) then
    raise exception 'Penyewa "%" tidak dapat dihapus karena memiliki riwayat transaksi pesanan finansial. Silakan nonaktifkan status penyewa.', old.nama;
  end if;

  if exists (select 1 from public.shift_kas where penyewa_id = old.id) then
    raise exception 'Penyewa "%" tidak dapat dihapus karena memiliki riwayat shift kasir. Silakan nonaktifkan status penyewa.', old.nama;
  end if;

  if exists (select 1 from public.pengguna where penyewa_id = old.id) then
    raise exception 'Penyewa "%" tidak dapat dihapus karena memiliki akun pegawai atau pemilik terdaftar. Silakan nonaktifkan status penyewa.', old.nama;
  end if;

  return old;
end;
$$;

comment on function public.picu_penyewa_cegah_hapus() is
  'Pemicu fail-closed: menolak penghapusan fisik (hard delete) penyewa yang memiliki cabang, akun, atau transaksi finansial.';

drop trigger if exists picu_penyewa_cegah_hapus on public.penyewa;
create trigger picu_penyewa_cegah_hapus
  before delete on public.penyewa
  for each row execute function public.picu_penyewa_cegah_hapus();

-- 3. RPC: buat_penyewa
create or replace function public.buat_penyewa(
  p_nama           text,
  p_slug           text default null,
  p_zona_waktu     text default 'Asia/Jakarta',
  p_mata_uang      text default 'IDR',
  p_kontak_telepon text default null,
  p_kontak_email   text default null,
  p_cabang_nama    text default 'Cabang Utama',
  p_cabang_alamat  text default null,
  p_cabang_telepon text default null,
  p_owner_nama     text default null,
  p_owner_email    text default null,
  p_owner_pin      text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya          uuid;
  v_peran_saya    text;
  v_nama_bersih   text;
  v_slug          text;
  v_slug_dasar    text;
  v_zona_waktu    text;
  v_mata_uang     text;
  v_cabang_nama   text;
  v_owner_nama    text;
  v_owner_email   text;
  v_lemah         text;
  v_hash          text;
  v_penyewa_id    uuid;
  v_cabang_id     uuid;
  v_owner_id      uuid;
  v_counter       integer := 1;
begin
  -- 1. Otorisasi Pemilik Platform
  v_saya := auth.uid();
  if v_saya is null then
    raise exception 'Pengguna belum terautentikasi.';
  end if;

  select p.peran into v_peran_saya
    from public.pengguna p
   where p.id = v_saya
     and p.aktif;

  if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
    raise exception 'Hanya pemilik_platform yang berhak mendaftarkan penyewa baru.';
  end if;

  -- 2. Validasi Nama Resto
  v_nama_bersih := btrim(coalesce(p_nama, ''));
  if length(v_nama_bersih) < 1 or length(v_nama_bersih) > 120 then
    raise exception 'Nama penyewa/resto wajib diisi (1-120 karakter).';
  end if;

  -- 3. Validasi & Penentuan Slug
  if p_slug is not null and btrim(p_slug) <> '' then
    v_slug := lower(btrim(p_slug));
    if v_slug !~ '^[a-z0-9][a-z0-9-]{1,30}$' then
      raise exception 'Format slug "%" tidak valid (harus 2-31 karakter alfanumerik huruf kecil dan tanda hubung).', v_slug;
    end if;
    if exists (select 1 from public.penyewa where slug = v_slug) then
      raise exception 'Slug resto "%" sudah digunakan.', v_slug;
    end if;
  else
    -- Buat slug otomatis dari nama resto
    v_slug_dasar := regexp_replace(lower(v_nama_bersih), '[^a-z0-9]+', '-', 'g');
    v_slug_dasar := btrim(v_slug_dasar, '-');
    if length(v_slug_dasar) < 2 then
      v_slug_dasar := 'resto-' || v_slug_dasar;
    end if;
    v_slug_dasar := substr(v_slug_dasar, 1, 24);
    v_slug := v_slug_dasar;

    while exists (select 1 from public.penyewa where slug = v_slug) loop
      v_counter := v_counter + 1;
      v_slug := substr(v_slug_dasar, 1, 28 - length(v_counter::text)) || '-' || v_counter::text;
    end loop;
  end if;

  -- 4. Validasi Zona Waktu & Mata Uang
  v_zona_waktu := coalesce(nullif(btrim(p_zona_waktu), ''), 'Asia/Jakarta');
  if v_zona_waktu not in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura', 'UTC') then
    raise exception 'Zona waktu "%" tidak didukung.', v_zona_waktu;
  end if;

  v_mata_uang := upper(coalesce(nullif(btrim(p_mata_uang), ''), 'IDR'));
  if v_mata_uang !~ '^[A-Z]{3}$' then
    raise exception 'Format kode mata uang "%" tidak valid (harus 3 huruf kapital).', v_mata_uang;
  end if;

  -- 5. Validasi Cabang Pertama
  v_cabang_nama := btrim(coalesce(p_cabang_nama, 'Cabang Utama'));
  if length(v_cabang_nama) < 1 or length(v_cabang_nama) > 120 then
    raise exception 'Nama cabang pertama wajib diisi (1-120 karakter).';
  end if;

  -- 6. Validasi Akun Owner Pertama
  v_owner_nama := btrim(coalesce(p_owner_nama, ''));
  if length(v_owner_nama) < 1 or length(v_owner_nama) > 120 then
    raise exception 'Nama Owner pertama wajib diisi (1-120 karakter).';
  end if;

  v_owner_email := lower(btrim(coalesce(p_owner_email, '')));
  if v_owner_email !~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$' then
    raise exception 'Format email Owner "%" tidak valid.', v_owner_email;
  end if;

  if exists (select 1 from public.pengguna where lower(email) = v_owner_email and peran = 'pemilik_platform') then
    raise exception 'Alamat email "%" sudah terdaftar sebagai pemilik platform.', v_owner_email;
  end if;

  -- 7. Validasi PIN Owner
  if p_owner_pin is null or p_owner_pin !~ '^[0-9]{6}$' then
    raise exception 'Akun Owner wajib diberikan PIN awal 6 digit angka.';
  end if;

  v_lemah := public.pin_lemah(p_owner_pin);
  if v_lemah is not null then
    raise exception 'PIN Owner ditolak: %.', v_lemah;
  end if;

  -- 8. Buat Baris Penyewa Baru
  v_penyewa_id := gen_random_uuid();
  insert into public.penyewa (
    id,
    nama,
    slug,
    status,
    zona_waktu,
    mata_uang,
    kontak_telepon,
    kontak_email,
    dibuat_pada,
    diubah_pada
  ) values (
    v_penyewa_id,
    v_nama_bersih,
    v_slug,
    'aktif',
    v_zona_waktu,
    v_mata_uang,
    nullif(btrim(p_kontak_telepon), ''),
    nullif(btrim(p_kontak_email), ''),
    now(),
    now()
  );

  -- 9. Buat Pengaturan Bawaan Penyewa
  insert into public.pengaturan (
    penyewa_id,
    pajak_pb1_persen,
    service_persen,
    pembulatan,
    tumpuk_diskon,
    batas_maks_potongan_persen,
    header_struk,
    footer_struk,
    cara_pesan,
    diubah_oleh,
    diubah_pada
  ) values (
    v_penyewa_id,
    10.0,
    5.0,
    'none',
    false,
    100.0,
    v_nama_bersih,
    'Terima kasih atas kunjungan Anda!',
    'kasir',
    v_saya,
    now()
  );

  -- 10. Buat Cabang Pertama
  v_cabang_id := gen_random_uuid();
  insert into public.cabang (
    id,
    penyewa_id,
    nama,
    alamat,
    telepon,
    aktif,
    zona_waktu,
    dibuat_pada,
    diubah_pada
  ) values (
    v_cabang_id,
    v_penyewa_id,
    v_cabang_nama,
    nullif(btrim(p_cabang_alamat), ''),
    nullif(btrim(p_cabang_telepon), ''),
    true,
    v_zona_waktu,
    now(),
    now()
  );

  -- 11. Buat Akun Owner di auth.users & public.pengguna
  v_owner_id := gen_random_uuid();
  if not exists (select 1 from auth.users where id = v_owner_id) then
    insert into auth.users (id, email) values (v_owner_id, v_owner_email);
  end if;

  insert into public.pengguna (
    id,
    penyewa_id,
    nama,
    email,
    peran,
    aktif,
    dibuat_pada,
    pin_diubah_pada
  ) values (
    v_owner_id,
    v_penyewa_id,
    v_owner_nama,
    v_owner_email,
    'owner_pusat',
    true,
    now(),
    now()
  );

  -- 12. Simpan Hash PIN Owner
  v_hash := crypt(p_owner_pin, gen_salt('bf', 10));
  insert into public.kredensial_pin (
    pengguna_id,
    pin_hash,
    diubah_pada
  ) values (
    v_owner_id,
    v_hash,
    now()
  );

  -- 13. Penugasan Cabang Pertama untuk Owner
  insert into public.pengguna_cabang (
    pengguna_id,
    cabang_id,
    aktif,
    dibuat_pada
  ) values (
    v_owner_id,
    v_cabang_id,
    true,
    now()
  );

  -- 14. Pencatatan Jejak Audit Kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa_id,
    v_saya,
    'buat_penyewa',
    'penyewa',
    v_penyewa_id,
    null,
    jsonb_build_object(
      'nama', v_nama_bersih,
      'slug', v_slug,
      'zona_waktu', v_zona_waktu,
      'mata_uang', v_mata_uang,
      'cabang_id', v_cabang_id,
      'cabang_nama', v_cabang_nama,
      'owner_id', v_owner_id,
      'owner_nama', v_owner_nama,
      'owner_email', v_owner_email
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'PENYEWA_DIBUAT',
    'pesan', format('Penyewa "%s" berhasil didaftarkan.', v_nama_bersih),
    'data', jsonb_build_object(
      'penyewa_id', v_penyewa_id,
      'slug', v_slug,
      'cabang_id', v_cabang_id,
      'owner_id', v_owner_id
    )
  );
end;
$$;

comment on function public.buat_penyewa(text, text, text, text, text, text, text, text, text, text, text, text) is
  'Pendaftaran resto baru beserta cabang pertama, akun Owner, dan pengaturan awal oleh Pemilik Platform (PRD M1).';

-- 4. RPC: set_status_penyewa
create or replace function public.set_status_penyewa(
  p_penyewa_id uuid,
  p_status     text,
  p_alasan     text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya          uuid;
  v_peran_saya    text;
  v_status_lama   text;
  v_nama_penyewa  text;
  v_alasan_bersih text;
begin
  -- 1. Otorisasi Pemilik Platform
  v_saya := auth.uid();
  if v_saya is null then
    raise exception 'Pengguna belum terautentikasi.';
  end if;

  select p.peran into v_peran_saya
    from public.pengguna p
   where p.id = v_saya
     and p.aktif;

  if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
    raise exception 'Hanya pemilik_platform yang berhak mengubah status penyewa.';
  end if;

  -- 2. Validasi Parameter Status
  if p_status not in ('aktif', 'nonaktif') then
    raise exception 'Status penyewa harus bernilai "aktif" atau "nonaktif".';
  end if;

  v_alasan_bersih := nullif(btrim(coalesce(p_alasan, '')), '');
  if p_status = 'nonaktif' and (v_alasan_bersih is null or length(v_alasan_bersih) < 5) then
    raise exception 'Alasan penonaktifan penyewa wajib diisi minimal 5 karakter.';
  end if;

  -- 3. Periksa Eksistensi Penyewa
  select nama, status
    into v_nama_penyewa, v_status_lama
    from public.penyewa
   where id = p_penyewa_id;

  if v_status_lama is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- 4. Terapkan Pembaruan Status
  update public.penyewa
     set status = p_status,
         alasan_nonaktif = case when p_status = 'nonaktif' then v_alasan_bersih else null end,
         dinonaktifkan_pada = case when p_status = 'nonaktif' then now() else null end,
         diubah_pada = now()
   where id = p_penyewa_id;

  -- 5. Jika Nonaktif: Cabut Sesi Perangkat Aktif Penyewa Tersebut
  if p_status = 'nonaktif' then
    update public.sesi_perangkat
       set status = 'dicabut',
           diperbarui_pada = now()
     where penyewa_id = p_penyewa_id
       and status = 'aktif';
  end if;

  -- 6. Pencatatan Jejak Audit Kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    p_penyewa_id,
    v_saya,
    'set_status_penyewa',
    'penyewa',
    p_penyewa_id,
    jsonb_build_object('status', v_status_lama),
    jsonb_build_object(
      'status', p_status,
      'alasan', v_alasan_bersih
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'STATUS_PENYEWA_DIUBAH',
    'pesan', format('Status penyewa "%s" berhasil diubah menjadi %s.', v_nama_penyewa, p_status),
    'data', jsonb_build_object(
      'penyewa_id', p_penyewa_id,
      'status', p_status
    )
  );
end;
$$;

comment on function public.set_status_penyewa(uuid, text, text) is
  'Mengubah status aktif/nonaktif penyewa resto (soft-disable tanpa menghapus riwayat) oleh Pemilik Platform.';

-- 5. RPC: ambil_daftar_penyewa
create or replace function public.ambil_daftar_penyewa(
  p_cari   text default null,
  p_status text default null
)
returns table (
  id             uuid,
  nama           text,
  slug           text,
  status         text,
  zona_waktu     text,
  mata_uang      text,
  kontak_telepon text,
  kontak_email   text,
  dibuat_pada    timestamptz,
  diubah_pada    timestamptz,
  jumlah_cabang  bigint,
  owner_nama     text,
  owner_email    text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_saya       uuid;
  v_peran_saya text;
begin
  -- 1. Otorisasi Pemilik Platform
  v_saya := auth.uid();
  if v_saya is null then
    raise exception 'Pengguna belum terautentikasi.';
  end if;

  select p.peran into v_peran_saya
    from public.pengguna p
   where p.id = v_saya
     and p.aktif;

  if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then
    raise exception 'Hanya pemilik_platform yang berhak melihat daftar penyewa.';
  end if;

  -- 2. Kembalikan Daftar Penyewa dengan Agregasi
  return query
    select
      p.id,
      p.nama,
      p.slug,
      p.status,
      p.zona_waktu,
      p.mata_uang,
      p.kontak_telepon,
      p.kontak_email,
      p.dibuat_pada,
      p.diubah_pada,
      count(distinct c.id) as jumlah_cabang,
      (
        select u.nama
          from public.pengguna u
         where u.penyewa_id = p.id
           and u.peran = 'owner_pusat'
         order by u.dibuat_pada asc
         limit 1
      ) as owner_nama,
      (
        select u.email
          from public.pengguna u
         where u.penyewa_id = p.id
           and u.peran = 'owner_pusat'
         order by u.dibuat_pada asc
         limit 1
      ) as owner_email
    from public.penyewa p
    left join public.cabang c on c.penyewa_id = p.id
   where (p_status is null or p.status = p_status)
     and (
       p_cari is null
       or btrim(p_cari) = ''
       or p.nama ilike '%' || btrim(p_cari) || '%'
       or p.slug ilike '%' || btrim(p_cari) || '%'
     )
   group by
     p.id, p.nama, p.slug, p.status, p.zona_waktu, p.mata_uang,
     p.kontak_telepon, p.kontak_email, p.dibuat_pada, p.diubah_pada
   order by p.dibuat_pada desc;
end;
$$;

comment on function public.ambil_daftar_penyewa(text, text) is
  'Membaca daftar resto penyewa beserta ringkasan cabang dan profil akun Owner untuk Pemilik Platform.';

-- 6. Hak Eksekusi Fungsi RPC
revoke all on function public.buat_penyewa(text, text, text, text, text, text, text, text, text, text, text, text) from public;
grant execute on function public.buat_penyewa(text, text, text, text, text, text, text, text, text, text, text, text) to authenticated;

revoke all on function public.set_status_penyewa(uuid, text, text) from public;
grant execute on function public.set_status_penyewa(uuid, text, text) to authenticated;

revoke all on function public.ambil_daftar_penyewa(text, text) from public;
grant execute on function public.ambil_daftar_penyewa(text, text) to authenticated;

revoke all on function public.picu_penyewa_cegah_hapus() from public;
grant execute on function public.picu_penyewa_cegah_hapus() to service_role;
