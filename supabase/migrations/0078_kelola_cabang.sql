-- ============================================================================
-- 0078 — Kelola Cabang: Tambah, Pengaturan Printer & Nonaktifkan (T9-09 / PRD M11 / ART-1 & ART-12)
--
-- Menuntaskan tata kelola multi-cabang restoran secara mandiri tanpa koding:
--  1. Penambahan kolom pada public.cabang:
--     - zona_waktu (Asia/Jakarta, Asia/Makassar, Asia/Jayapura)
--     - printer_default (konfigurasi profil dan lebar printer default cabang)
--     - diubah_pada
--  2. Pemicu fail-closed:
--     - picu_cabang_cegah_hapus: mencegah hard-delete cabang yang memiliki riwayat
--       transaksi pesanan, meja, atau shift kas (wajib soft-disable).
--     - picu_cabang_minimal_satu_aktif: menjaga restoran tidak kehilangan seluruh cabang aktif.
--  3. RPC resmi:
--     - public.tambah_cabang: membuat cabang baru resto (owner_pusat / platform).
--     - public.simpan_cabang: mengubah data profil cabang & konfigurasi printer.
--     - public.set_status_cabang: mengaktifkan / menonaktifkan cabang (soft-disable).
--     - public.set_akses_cabang: mengatur penugasan cabang pegawai (multi-penugasan ART-12).
--     - public.ambil_daftar_cabang: membaca daftar cabang resto dengan statistik.
--     - public.ambil_akses_cabang_pegawai: membaca status penugasan cabang per pegawai.
--  4. Jejak audit kekal di public.catatan_audit untuk setiap aksi.
-- ============================================================================

-- 1. Penambahan Kolom pada public.cabang
alter table public.cabang
  add column if not exists zona_waktu text not null default 'Asia/Jakarta'
    check (zona_waktu in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura')),
  add column if not exists printer_default jsonb default null,
  add column if not exists diubah_pada timestamptz not null default now();

comment on column public.cabang.zona_waktu is
  'Zona waktu lokal operasional cabang (WIB, WITA, WIT).';

comment on column public.cabang.printer_default is
  'Konfigurasi printer struk default cabang (profil_id, lebar 58/80 mm, nama perangkat).';

-- 2. Pemicu Fail-Closed Keamanan Cabang
-- 2a. Cegah hard-delete cabang ber-riwayat operasional
create or replace function public.picu_cabang_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.pesanan where cabang_id = old.id) then
    raise exception 'Cabang "%" tidak dapat dihapus karena memiliki riwayat transaksi pesanan. Silakan nonaktifkan cabang ini.', old.nama;
  end if;

  if exists (select 1 from public.meja where cabang_id = old.id) then
    raise exception 'Cabang "%" tidak dapat dihapus karena masih memiliki data meja. Silakan nonaktifkan cabang ini.', old.nama;
  end if;

  if exists (select 1 from public.shift_kas where cabang_id = old.id) then
    raise exception 'Cabang "%" tidak dapat dihapus karena memiliki riwayat shift kas. Silakan nonaktifkan cabang ini.', old.nama;
  end if;

  return old;
end;
$$;

drop trigger if exists picu_cabang_cegah_hapus on public.cabang;
create trigger picu_cabang_cegah_hapus
  before delete on public.cabang
  for each row execute function public.picu_cabang_cegah_hapus();

comment on function public.picu_cabang_cegah_hapus() is
  'Pemicu fail-closed: melindungi integritas riwayat transaksi dan data operasional cabang (ART-1 & ART-12).';

-- 2b. Minimal satu cabang aktif per restoran
create or replace function public.picu_cabang_minimal_satu_aktif()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_aktif_count integer;
begin
  v_penyewa := coalesce(new.penyewa_id, old.penyewa_id);
  if v_penyewa is null then
    return coalesce(new, old);
  end if;

  if (tg_op = 'DELETE') or (tg_op = 'UPDATE' and old.aktif = true and new.aktif = false) then
    select count(*) into v_aktif_count
      from public.cabang
     where penyewa_id = v_penyewa
       and aktif = true;

    if v_aktif_count = 0 then
      raise exception 'Minimal harus ada satu cabang yang aktif di restoran.';
    end if;
  end if;

  return coalesce(new, old);
end;
$$;

drop trigger if exists picu_cabang_minimal_satu_aktif on public.cabang;
create trigger picu_cabang_minimal_satu_aktif
  after update or delete on public.cabang
  for each row execute function public.picu_cabang_minimal_satu_aktif();

comment on function public.picu_cabang_minimal_satu_aktif() is
  'Pemicu fail-closed: menjaga agar sebuah restoran minimal memiliki satu cabang aktif.';

-- 3. RPC: tambah_cabang
create or replace function public.tambah_cabang(
  p_nama        text,
  p_alamat      text default null,
  p_telepon     text default null,
  p_zona_waktu  text default 'Asia/Jakarta',
  p_printer     jsonb default null,
  p_penyewa_id  uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa     uuid;
  v_peran_saya  text;
  v_nama_bersih text;
  v_id          uuid;
  v_printer     jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');

  if v_peran_saya = 'pemilik_platform' and p_penyewa_id is not null then
    v_penyewa := p_penyewa_id;
  else
    v_penyewa := public.penyewa_saya();
    if v_penyewa is null then
      raise exception 'Penyewa tidak ditemukan.';
    end if;

    if v_peran_saya <> 'owner_pusat' then
      raise exception 'Hanya owner pusat yang dapat membuka cabang baru.';
    end if;
  end if;

  v_nama_bersih := btrim(coalesce(p_nama, ''));
  if length(v_nama_bersih) < 1 or length(v_nama_bersih) > 120 then
    raise exception 'Nama cabang harus di antara 1 dan 120 karakter.';
  end if;

  if exists (
    select 1 from public.cabang
     where penyewa_id = v_penyewa
       and lower(nama) = lower(v_nama_bersih)
  ) then
    raise exception 'Nama cabang "%" sudah digunakan di resto Anda.', v_nama_bersih;
  end if;

  if p_zona_waktu not in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura') then
    raise exception 'Zona waktu tidak valid (pilih: Asia/Jakarta, Asia/Makassar, atau Asia/Jayapura).';
  end if;

  v_printer := p_printer;
  if v_printer is not null then
    if (v_printer->>'lebar') is not null and (v_printer->>'lebar')::int not in (58, 80) then
      raise exception 'Lebar kertas printer hanya boleh 58 atau 80 mm.';
    end if;
  end if;

  v_id := gen_random_uuid();

  insert into public.cabang (
    id,
    penyewa_id,
    nama,
    alamat,
    telepon,
    zona_waktu,
    printer_default,
    aktif,
    dibuat_pada,
    diubah_pada
  ) values (
    v_id,
    v_penyewa,
    v_nama_bersih,
    nullif(btrim(coalesce(p_alamat, '')), ''),
    nullif(btrim(coalesce(p_telepon, '')), ''),
    p_zona_waktu,
    v_printer,
    true,
    now(),
    now()
  );

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'tambah_cabang',
    'cabang',
    v_id,
    null,
    jsonb_build_object(
      'nama', v_nama_bersih,
      'alamat', p_alamat,
      'telepon', p_telepon,
      'zona_waktu', p_zona_waktu,
      'printer', v_printer
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'pesan', format('Cabang "%s" berhasil ditambahkan.', v_nama_bersih)
  );
end;
$$;

comment on function public.tambah_cabang(text, text, text, text, jsonb, uuid) is
  'Membuka cabang baru resto dengan validasi nama unik se-penyewa, zona waktu, dan konfigurasi printer.';

-- 4. RPC: simpan_cabang (Edit profil cabang & printer)
create or replace function public.simpan_cabang(
  p_id          uuid,
  p_nama        text,
  p_alamat      text default null,
  p_telepon     text default null,
  p_zona_waktu  text default 'Asia/Jakarta',
  p_printer     jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa     uuid;
  v_peran_saya  text;
  v_target      record;
  v_nama_bersih text;
  v_nilai_lama  jsonb;
  v_nilai_baru  jsonb;
  v_printer     jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');

  select id, penyewa_id, nama, alamat, telepon, zona_waktu, printer_default into v_target
    from public.cabang
   where id = p_id
     and penyewa_id = v_penyewa
     for update;

  if v_target.id is null then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  -- Otorisasi: owner_pusat, atau admin_cabang yang bertugas di cabang ini
  if v_peran_saya <> 'owner_pusat' then
    if v_peran_saya = 'admin_cabang' then
      if not exists (
        select 1 from public.pengguna_cabang
         where pengguna_id = auth.uid()
           and cabang_id = p_id
           and aktif = true
      ) then
        raise exception 'Admin cabang hanya dapat mengubah cabang tempatnya bertugas.';
      end if;
    else
      raise exception 'Hanya owner pusat atau admin cabang bertugas yang dapat mengubah profil cabang.';
    end if;
  end if;

  v_nama_bersih := btrim(coalesce(p_nama, ''));
  if length(v_nama_bersih) < 1 or length(v_nama_bersih) > 120 then
    raise exception 'Nama cabang harus di antara 1 dan 120 karakter.';
  end if;

  -- Keunikan nama jika berubah
  if lower(v_target.nama) <> lower(v_nama_bersih) then
    if exists (
      select 1 from public.cabang
       where penyewa_id = v_penyewa
         and lower(nama) = lower(v_nama_bersih)
         and id <> p_id
    ) then
      raise exception 'Nama cabang "%" sudah digunakan di resto Anda.', v_nama_bersih;
    end if;
  end if;

  if p_zona_waktu not in ('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura') then
    raise exception 'Zona waktu tidak valid (pilih: Asia/Jakarta, Asia/Makassar, atau Asia/Jayapura).';
  end if;

  v_printer := p_printer;
  if v_printer is not null then
    if (v_printer->>'lebar') is not null and (v_printer->>'lebar')::int not in (58, 80) then
      raise exception 'Lebar kertas printer hanya boleh 58 atau 80 mm.';
    end if;
  end if;

  v_nilai_lama := jsonb_build_object(
    'nama', v_target.nama,
    'alamat', v_target.alamat,
    'telepon', v_target.telepon,
    'zona_waktu', v_target.zona_waktu,
    'printer', v_target.printer_default
  );

  v_nilai_baru := jsonb_build_object(
    'nama', v_nama_bersih,
    'alamat', nullif(btrim(coalesce(p_alamat, '')), ''),
    'telepon', nullif(btrim(coalesce(p_telepon, '')), ''),
    'zona_waktu', p_zona_waktu,
    'printer', v_printer
  );

  update public.cabang
     set nama            = v_nama_bersih,
         alamat          = nullif(btrim(coalesce(p_alamat, '')), ''),
         telepon         = nullif(btrim(coalesce(p_telepon, '')), ''),
         zona_waktu      = p_zona_waktu,
         printer_default = v_printer,
         diubah_pada     = now()
   where id = p_id;

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'ubah_cabang',
    'cabang',
    p_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', format('Cabang "%s" berhasil diperbarui.', v_nama_bersih)
  );
end;
$$;

comment on function public.simpan_cabang(uuid, text, text, text, text, jsonb) is
  'Memperbarui data cabang dan konfigurasi printer default cabang dengan jejak audit kekal.';

-- 5. RPC: set_status_cabang (Aktifkan / Nonaktifkan Cabang)
create or replace function public.set_status_cabang(
  p_cabang_id uuid,
  p_aktif     boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_target     record;
  v_aktif_sisa integer;
  v_nilai_lama jsonb;
  v_nilai_baru jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' then
    raise exception 'Hanya owner pusat yang dapat mengubah status keaktifan cabang.';
  end if;

  select id, nama, aktif into v_target
    from public.cabang
   where id = p_cabang_id
     and penyewa_id = v_penyewa
     for update;

  if v_target.id is null then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  -- Pagar: cegah menonaktifkan satu-satunya cabang aktif
  if p_aktif = false then
    select count(*) into v_aktif_sisa
      from public.cabang
     where penyewa_id = v_penyewa
       and aktif = true
       and id <> p_cabang_id;

    if v_aktif_sisa = 0 then
      raise exception 'Minimal harus ada satu cabang yang aktif di restoran.';
    end if;
  end if;

  v_nilai_lama := jsonb_build_object('aktif', v_target.aktif);
  v_nilai_baru := jsonb_build_object('aktif', p_aktif);

  update public.cabang
     set aktif       = p_aktif,
         diubah_pada = now()
   where id = p_cabang_id;

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'set_status_cabang',
    'cabang',
    p_cabang_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', format('Cabang "%s" berhasil %s.', v_target.nama, case when p_aktif then 'diaktifkan' else 'dinonaktifkan' end)
  );
end;
$$;

comment on function public.set_status_cabang(uuid, boolean) is
  'Mengaktifkan atau menonaktifkan cabang tanpa merusak data masa lalu (soft-disable ART-1 & ART-12).';

-- 6. RPC: set_akses_cabang (Atur Penugasan Staf ke Cabang)
create or replace function public.set_akses_cabang(
  p_pengguna_id uuid,
  p_cabang_id   uuid,
  p_aktif       boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_peran_saya   text;
  v_target_user  record;
  v_target_cabang record;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then
    if v_peran_saya = 'admin_cabang' then
      if not exists (
        select 1 from public.pengguna_cabang
         where pengguna_id = auth.uid()
           and cabang_id = p_cabang_id
           and aktif = true
      ) then
        raise exception 'Admin cabang hanya dapat mengatur penugasan pada cabangnya sendiri.';
      end if;
    else
      raise exception 'Hanya owner pusat atau admin cabang berwenang yang dapat mengatur penugasan cabang.';
    end if;
  end if;

  -- Pastikan pengguna milik penyewa yang sama
  select id, nama, peran, aktif into v_target_user
    from public.pengguna
   where id = p_pengguna_id
     and penyewa_id = v_penyewa;

  if v_target_user.id is null then
    raise exception 'Pegawai tidak ditemukan atau bukan bagian dari restoran Anda.';
  end if;

  -- Pastikan cabang milik penyewa yang sama
  select id, nama, aktif into v_target_cabang
    from public.cabang
   where id = p_cabang_id
     and penyewa_id = v_penyewa;

  if v_target_cabang.id is null then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  -- Upsert penugasan cabang
  insert into public.pengguna_cabang (pengguna_id, cabang_id, aktif)
  values (p_pengguna_id, p_cabang_id, p_aktif)
  on conflict (pengguna_id, cabang_id) do update set
    aktif = excluded.aktif;

  -- Jejak audit kekal
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'set_akses_cabang',
    'pengguna_cabang',
    p_pengguna_id,
    null,
    jsonb_build_object(
      'pengguna_id', p_pengguna_id,
      'pengguna_nama', v_target_user.nama,
      'cabang_id', p_cabang_id,
      'cabang_nama', v_target_cabang.nama,
      'aktif', p_aktif
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', format('Penugasan pegawai "%s" di cabang "%s" berhasil diperbarui.', v_target_user.nama, v_target_cabang.nama)
  );
end;
$$;

comment on function public.set_akses_cabang(uuid, uuid, boolean) is
  'Mengatur penugasan pegawai pada cabang tertentu (mendukung staf merangkap multi-cabang ART-12).';

-- 7. RPC: ambil_daftar_cabang
create or replace function public.ambil_daftar_cabang()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_hasil   jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', c.id,
        'nama', c.nama,
        'alamat', coalesce(c.alamat, ''),
        'telepon', coalesce(c.telepon, ''),
        'zona_waktu', c.zona_waktu,
        'printer_default', c.printer_default,
        'aktif', c.aktif,
        'dibuat_pada', c.dibuat_pada,
        'jumlah_pegawai', (
          select count(distinct pc.pengguna_id)
            from public.pengguna_cabang pc
           where pc.cabang_id = c.id
             and pc.aktif = true
        ),
        'jumlah_meja', (
          select count(*)
            from public.meja m
           where m.cabang_id = c.id
             and m.aktif = true
        ),
        'jumlah_perangkat', (
          select count(*)
            from public.perangkat pr
           where pr.cabang_id = c.id
             and pr.status = 'disetujui'
        )
      ) order by c.dibuat_pada asc
    ),
    '[]'::jsonb
  ) into v_hasil
  from public.cabang c
  where c.penyewa_id = v_penyewa;

  return v_hasil;
end;
$$;

comment on function public.ambil_daftar_cabang() is
  'Membaca daftar seluruh cabang resto pemanggil beserta metrik pegawai, meja, dan perangkat kasir.';

-- 8. RPC: ambil_akses_cabang_pegawai
create or replace function public.ambil_akses_cabang_pegawai(p_pengguna_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa    uuid;
  v_peran_saya text;
  v_hasil      jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran_saya := coalesce(public.peran_saya(), '');
  if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') and auth.uid() <> p_pengguna_id then
    raise exception 'Hanya owner pusat, pemegang izin kelola_pegawai, atau pegawai bersangkutan yang dapat melihat akses cabang.';
  end if;

  -- Pastikan target pengguna adalah milik resto yang sama
  if not exists (select 1 from public.pengguna where id = p_pengguna_id and penyewa_id = v_penyewa) then
    raise exception 'Pegawai tidak ditemukan atau bukan milik resto Anda.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'cabang_id', c.id,
        'cabang_nama', c.nama,
        'cabang_aktif', c.aktif,
        'diberi_akses', coalesce(pc.aktif, false)
      ) order by c.nama asc
    ),
    '[]'::jsonb
  ) into v_hasil
  from public.cabang c
  left join public.pengguna_cabang pc
    on pc.cabang_id = c.id
   and pc.pengguna_id = p_pengguna_id
  where c.penyewa_id = v_penyewa;

  return v_hasil;
end;
$$;

comment on function public.ambil_akses_cabang_pegawai(uuid) is
  'Membaca daftar cabang resto dan status penugasan penempatan untuk pegawai tertentu.';

-- 9. Hak Eksekusi Fungsi RPC & Pemicu
revoke all on function public.tambah_cabang(text, text, text, text, jsonb, uuid) from public;
grant execute on function public.tambah_cabang(text, text, text, text, jsonb, uuid) to authenticated;

revoke all on function public.simpan_cabang(uuid, text, text, text, text, jsonb) from public;
grant execute on function public.simpan_cabang(uuid, text, text, text, text, jsonb) to authenticated;

revoke all on function public.set_status_cabang(uuid, boolean) from public;
grant execute on function public.set_status_cabang(uuid, boolean) to authenticated;

revoke all on function public.set_akses_cabang(uuid, uuid, boolean) from public;
grant execute on function public.set_akses_cabang(uuid, uuid, boolean) to authenticated;

revoke all on function public.ambil_daftar_cabang() from public;
grant execute on function public.ambil_daftar_cabang() to authenticated;

revoke all on function public.ambil_akses_cabang_pegawai(uuid) from public;
grant execute on function public.ambil_akses_cabang_pegawai(uuid) to authenticated;

revoke all on function public.picu_cabang_cegah_hapus() from public;
grant execute on function public.picu_cabang_cegah_hapus() to service_role;

revoke all on function public.picu_cabang_minimal_satu_aktif() from public;
grant execute on function public.picu_cabang_minimal_satu_aktif() to service_role;
