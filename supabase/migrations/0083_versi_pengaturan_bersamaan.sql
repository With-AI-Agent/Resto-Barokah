-- ============================================================================
-- 0083 — Kunci Konkurensi Optimistik Pengaturan & Menu Bersamaan (T10-11)
-- TECH_SPEC §5 (M2), PRD M2 & M12 Kasus Tepi, ART-3.
--
-- Tujuan:
--   Mencegah 'last-write-wins' diam-diam saat dua pengguna (admin/owner)
--   menyunting pengaturan resto atau menu katalog pada detik yang sama.
--   Penyimpanan paralel yang membawa versi usang (stempel waktu kedaluwarsa)
--   ditolak di peladen secara fail-closed (P0001) dengan pesan jujur bahasa
--   Indonesia, data perubahan tidak hilang dari layar pengguna, dan insiden
--   konflik dapat dicatat di jejak audit (catatan_audit).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RPC `simpan_menu` dengan Kunci Konkurensi Optimistik
-- ----------------------------------------------------------------------------
drop function if exists public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb);

create or replace function public.simpan_menu(
  p_id uuid default null,
  p_kategori_id uuid default null,
  p_nama text default null,
  p_deskripsi text default null,
  p_harga integer default 0,
  p_foto_path text default null,
  p_urutan integer default null,
  p_unggulan boolean default false,
  p_jenis text default 'makanan',
  p_aktif boolean default true,
  p_varian jsonb default '[]'::jsonb,
  p_tambahan jsonb default '[]'::jsonb,
  p_versi_lama timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_id uuid;
  v_urutan integer;
  v_diubah_pada_lama timestamptz;
  v_versi_baru timestamptz;
  v_var jsonb;
  v_var_nama text;
  v_tam jsonb;
  v_tam_nama text;
  v_harga_lama integer;
  v_nama_lama text;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengelola menu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_nama is null or btrim(p_nama) = '' then
    raise exception 'Nama menu wajib diisi.';
  end if;

  if length(btrim(p_nama)) > 150 then
    raise exception 'Nama menu maksimal 150 karakter.';
  end if;

  if p_kategori_id is null then
    raise exception 'Kategori menu wajib dipilih.';
  end if;

  if not exists (
    select 1 from public.kategori_menu
     where id = p_kategori_id and penyewa_id = v_penyewa
  ) then
    raise exception 'Kategori menu tidak ditemukan di resto ini.';
  end if;

  if p_harga is null or p_harga < 0 then
    raise exception 'Harga menu tidak boleh negatif.';
  end if;

  if p_harga > 100000000 then
    raise exception 'Harga menu melebihi batas wajar.';
  end if;

  if p_jenis is null or p_jenis not in ('makanan', 'minuman', 'lainnya') then
    raise exception 'Jenis menu harus makanan, minuman, atau lainnya.';
  end if;

  v_versi_baru := clock_timestamp();

  if p_id is null then
    -- Tambah menu baru
    if exists (
      select 1 from public.menu_item
       where penyewa_id = v_penyewa
         and kategori_id = p_kategori_id
         and lower(nama) = lower(btrim(p_nama))
    ) then
      raise exception 'Nama menu sudah digunakan pada kategori ini.';
    end if;

    if p_urutan is null or p_urutan <= 0 then
      select coalesce(max(urutan), 0) + 1 into v_urutan
        from public.menu_item
       where penyewa_id = v_penyewa
         and kategori_id = p_kategori_id;
    else
      v_urutan := p_urutan;
    end if;

    insert into public.menu_item (
      penyewa_id, kategori_id, nama, deskripsi, harga, foto_path, urutan, unggulan, jenis, aktif, diubah_pada
    ) values (
      v_penyewa, p_kategori_id, btrim(p_nama), p_deskripsi, p_harga, p_foto_path,
      v_urutan, coalesce(p_unggulan, false), p_jenis, coalesce(p_aktif, true), v_versi_baru
    ) returning id into v_id;
  else
    -- Edit menu yang ada: Kunci baris untuk optimistic locking
    select diubah_pada, harga, nama
      into v_diubah_pada_lama, v_harga_lama, v_nama_lama
      from public.menu_item
     where id = p_id
       and penyewa_id = v_penyewa
     for update;

    if v_nama_lama is null then
      raise exception 'Menu item tidak ditemukan.' using errcode = 'P0002';
    end if;

    -- Validasi versi optimistik: bila versi yang dikirim basi, tolak fail-closed
    if p_versi_lama is not null and v_diubah_pada_lama is not null then
      if v_diubah_pada_lama <> p_versi_lama then
        raise exception 'Data menu sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
          using errcode = 'P0001';
      end if;
    end if;

    if exists (
      select 1 from public.menu_item
       where penyewa_id = v_penyewa
         and kategori_id = p_kategori_id
         and lower(nama) = lower(btrim(p_nama))
         and id <> p_id
    ) then
      raise exception 'Nama menu sudah digunakan pada kategori ini.';
    end if;

    update public.menu_item
       set kategori_id = p_kategori_id,
           nama = btrim(p_nama),
           deskripsi = p_deskripsi,
           harga = p_harga,
           foto_path = p_foto_path,
           urutan = coalesce(p_urutan, urutan),
           unggulan = coalesce(p_unggulan, unggulan),
           jenis = p_jenis,
           aktif = coalesce(p_aktif, aktif),
           diubah_pada = v_versi_baru
     where id = p_id
       and penyewa_id = v_penyewa
    returning id, urutan into v_id, v_urutan;
  end if;

  -- Mengelola menu_varian
  delete from public.menu_varian where menu_item_id = v_id;
  if p_varian is not null and jsonb_typeof(p_varian) = 'array' then
    for v_var in select * from jsonb_array_elements(p_varian) loop
      v_var_nama := btrim(v_var->>'nama');
      if v_var_nama is not null and v_var_nama <> '' then
        insert into public.menu_varian (menu_item_id, nama, tambahan_harga, aktif)
        values (
          v_id,
          v_var_nama,
          coalesce((v_var->>'tambahan_harga')::integer, 0),
          coalesce((v_var->>'aktif')::boolean, true)
        ) on conflict (menu_item_id, nama) do update
          set tambahan_harga = excluded.tambahan_harga,
              aktif = excluded.aktif;
      end if;
    end loop;
  end if;

  -- Mengelola menu_tambahan khusus menu ini
  delete from public.menu_tambahan where menu_item_id = v_id and penyewa_id = v_penyewa;
  if p_tambahan is not null and jsonb_typeof(p_tambahan) = 'array' then
    for v_tam in select * from jsonb_array_elements(p_tambahan) loop
      v_tam_nama := btrim(v_tam->>'nama');
      if v_tam_nama is not null and v_tam_nama <> '' then
        insert into public.menu_tambahan (penyewa_id, menu_item_id, nama, harga, aktif)
        values (
          v_penyewa,
          v_id,
          v_tam_nama,
          coalesce((v_tam->>'harga')::integer, 0),
          coalesce((v_tam->>'aktif')::boolean, true)
        );
      end if;
    end loop;
  end if;

  -- Catat jejak audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
  values (
    v_penyewa,
    auth.uid(),
    'simpan_menu',
    'menu_item',
    v_id,
    case when p_id is not null then
      jsonb_build_object(
        'harga', v_harga_lama,
        'nama', v_nama_lama,
        'diubah_pada', v_diubah_pada_lama
      )
    else null end,
    jsonb_build_object(
      'id', v_id,
      'kategori_id', p_kategori_id,
      'nama', btrim(p_nama),
      'harga', p_harga,
      'aktif', coalesce(p_aktif, true),
      'diubah_pada', v_versi_baru
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'versi_menu', v_versi_baru,
    'pesan', 'Menu berhasil disimpan.'
  );
end;
$$;

comment on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb, timestamptz) is
  'T10-11: Menyimpan (tambah/edit) menu lengkap dengan proteksi konkurensi optimistik versi_lama.';

revoke all on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb, timestamptz) from public, anon;
grant execute on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb, timestamptz) to authenticated;
grant execute on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb, timestamptz) to service_role;

-- ----------------------------------------------------------------------------
-- 2. RPC `simpan_kategori_menu` dengan Kunci Konkurensi Optimistik
-- ----------------------------------------------------------------------------
drop function if exists public.simpan_kategori_menu(uuid, text, integer, text, boolean);

create or replace function public.simpan_kategori_menu(
  p_id uuid default null,
  p_nama text default null,
  p_urutan integer default null,
  p_tujuan text default 'dapur',
  p_aktif boolean default true,
  p_versi_lama timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_id uuid;
  v_urutan integer;
  v_diubah_pada_lama timestamptz;
  v_versi_baru timestamptz;
  v_nama_lama text;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengelola kategori menu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_nama is null or btrim(p_nama) = '' then
    raise exception 'Nama kategori wajib diisi.';
  end if;

  if length(btrim(p_nama)) > 80 then
    raise exception 'Nama kategori maksimal 80 karakter.';
  end if;

  if p_tujuan not in ('dapur', 'bar') then
    raise exception 'Tujuan kategori harus dapur atau bar.';
  end if;

  v_versi_baru := clock_timestamp();

  if p_id is null then
    -- Tambah baru
    if exists (
      select 1 from public.kategori_menu
       where penyewa_id = v_penyewa
         and lower(nama) = lower(btrim(p_nama))
    ) then
      raise exception 'Nama kategori sudah digunakan.';
    end if;

    if p_urutan is null or p_urutan <= 0 then
      select coalesce(max(urutan), 0) + 1 into v_urutan
        from public.kategori_menu
       where penyewa_id = v_penyewa;
    else
      v_urutan := p_urutan;
    end if;

    insert into public.kategori_menu (
      penyewa_id, nama, urutan, tujuan, aktif, diubah_pada
    ) values (
      v_penyewa, btrim(p_nama), v_urutan, p_tujuan, coalesce(p_aktif, true), v_versi_baru
    ) returning id into v_id;
  else
    -- Edit kategori: Kunci baris untuk optimistic locking
    select diubah_pada, nama
      into v_diubah_pada_lama, v_nama_lama
      from public.kategori_menu
     where id = p_id
       and penyewa_id = v_penyewa
     for update;

    if v_nama_lama is null then
      raise exception 'Kategori menu tidak ditemukan.' using errcode = 'P0002';
    end if;

    -- Validasi versi optimistik: bila versi yang dikirim basi, tolak fail-closed
    if p_versi_lama is not null and v_diubah_pada_lama is not null then
      if v_diubah_pada_lama <> p_versi_lama then
        raise exception 'Data kategori menu sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
          using errcode = 'P0001';
      end if;
    end if;

    if exists (
      select 1 from public.kategori_menu
       where penyewa_id = v_penyewa
         and lower(nama) = lower(btrim(p_nama))
         and id <> p_id
    ) then
      raise exception 'Nama kategori sudah digunakan.';
    end if;

    update public.kategori_menu
       set nama = btrim(p_nama),
           urutan = coalesce(p_urutan, urutan),
           tujuan = p_tujuan,
           aktif = coalesce(p_aktif, aktif),
           diubah_pada = v_versi_baru
     where id = p_id
       and penyewa_id = v_penyewa
    returning id, urutan into v_id, v_urutan;
  end if;

  -- Catat jejak audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru)
  values (
    v_penyewa,
    auth.uid(),
    'simpan_kategori_menu',
    'kategori_menu',
    v_id,
    case when p_id is not null then
      jsonb_build_object(
        'nama', v_nama_lama,
        'diubah_pada', v_diubah_pada_lama
      )
    else null end,
    jsonb_build_object(
      'id', v_id,
      'nama', btrim(p_nama),
      'urutan', v_urutan,
      'tujuan', p_tujuan,
      'aktif', coalesce(p_aktif, true),
      'diubah_pada', v_versi_baru
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'versi_kategori', v_versi_baru,
    'pesan', 'Kategori menu berhasil disimpan.'
  );
end;
$$;

comment on function public.simpan_kategori_menu(uuid, text, integer, text, boolean, timestamptz) is
  'T10-11: Menyimpan (tambah/edit) kategori menu dengan proteksi konkurensi optimistik versi_lama.';

revoke all on function public.simpan_kategori_menu(uuid, text, integer, text, boolean, timestamptz) from public, anon;
grant execute on function public.simpan_kategori_menu(uuid, text, integer, text, boolean, timestamptz) to authenticated;
grant execute on function public.simpan_kategori_menu(uuid, text, integer, text, boolean, timestamptz) to service_role;

-- ----------------------------------------------------------------------------
-- 3. RPC `simpan_meja` dengan Kunci Konkurensi Optimistik
-- ----------------------------------------------------------------------------
drop function if exists public.simpan_meja(uuid, text, text, boolean, uuid);

create or replace function public.simpan_meja(
  p_cabang_id  uuid default null,
  p_nama       text default null,
  p_area       text default 'Utama',
  p_aktif      boolean default true,
  p_meja_id    uuid default null,
  p_versi_lama timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna_id    uuid;
  v_penyewa_id     uuid;
  v_peran          text;
  v_cabang_id      uuid;
  v_cabang_penyewa uuid;
  v_nama_bersih    text;
  v_area_bersih    text;
  v_meja           record;
  v_pesanan_aktif  int;
  v_aksi           text;
  v_nilai_lama     jsonb;
  v_nilai_baru     jsonb;
  v_versi_baru     timestamptz;
begin
  v_pengguna_id := auth.uid();
  if v_pengguna_id is null then
    raise exception 'Akses ditolak: pengguna belum masuk.' using errcode = '42501';
  end if;

  v_penyewa_id := public.penyewa_saya();
  v_peran := public.peran_saya();

  -- Otorisasi: owner_pusat, admin_cabang, atau staf berizin 'atur_pengaturan'
  if v_peran not in ('owner_pusat', 'admin_cabang') and not public.boleh('atur_pengaturan') then
    raise exception 'Akses ditolak: hanya pemilik atau staf pengatur yang berwenang mengelola meja.'
      using errcode = '42501';
  end if;

  if p_meja_id is null then
    v_cabang_id := coalesce(p_cabang_id, public.cabang_saya());
  else
    if p_cabang_id is not null then
      v_cabang_id := p_cabang_id;
    else
      select cabang_id into v_cabang_id
        from public.meja
       where id = p_meja_id;
    end if;
  end if;

  if v_cabang_id is null then
    raise exception 'Cabang tidak ditentukan.' using errcode = '22023';
  end if;

  -- Validasi cabang milik penyewa pemanggil
  select c.penyewa_id into v_cabang_penyewa
    from public.cabang c
   where c.id = v_cabang_id;

  if v_cabang_penyewa is null or v_cabang_penyewa <> v_penyewa_id then
    raise exception 'Cabang tidak ditemukan atau berada di luar resto Anda.'
      using errcode = '42501';
  end if;

  -- Validasi nama meja
  v_nama_bersih := trim(coalesce(p_nama, ''));
  if length(v_nama_bersih) < 1 or length(v_nama_bersih) > 50 then
    raise exception 'Nomor atau nama meja wajib diisi (1 sampai 50 karakter).'
      using errcode = '22023';
  end if;

  -- Validasi area
  v_area_bersih := trim(coalesce(p_area, ''));
  if v_area_bersih = '' then
    v_area_bersih := 'Utama';
  end if;
  if length(v_area_bersih) > 50 then
    raise exception 'Nama area maksimal 50 karakter.'
      using errcode = '22023';
  end if;

  -- Validasi keunikan nomor/nama meja di cabang
  if exists (
    select 1 from public.meja m
     where m.cabang_id = v_cabang_id
       and lower(m.nama) = lower(v_nama_bersih)
       and (p_meja_id is null or m.id <> p_meja_id)
  ) then
    raise exception 'Nomor atau nama meja "%" sudah digunakan di cabang ini.', v_nama_bersih
      using errcode = '23505';
  end if;

  v_versi_baru := clock_timestamp();

  if p_meja_id is null then
    -- Tambah meja baru
    insert into public.meja (
      cabang_id,
      nama,
      area,
      status,
      aktif,
      diubah_pada
    ) values (
      v_cabang_id,
      v_nama_bersih,
      v_area_bersih,
      'kosong',
      coalesce(p_aktif, true),
      v_versi_baru
    )
    returning * into v_meja;

    v_aksi := 'tambah_meja';
    v_nilai_lama := null;
    v_nilai_baru := to_jsonb(v_meja);
  else
    -- Ambil meja lama dengan kuncian baris
    select * into v_meja
      from public.meja m
     where m.id = p_meja_id
       and m.cabang_id = v_cabang_id
     for update;

    if v_meja.id is null then
      raise exception 'Meja yang ingin diubah tidak ditemukan.'
        using errcode = 'P0002';
    end if;

    -- Validasi versi optimistik: bila versi yang dikirim basi, tolak fail-closed
    if p_versi_lama is not null and v_meja.diubah_pada is not null then
      if v_meja.diubah_pada <> p_versi_lama then
        raise exception 'Data meja sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
          using errcode = 'P0001';
      end if;
    end if;

    v_nilai_lama := to_jsonb(v_meja);

    -- Jika dinonaktifkan (aktif -> false), pastikan tidak ada pesanan aktif
    if coalesce(p_aktif, true) = false and v_meja.aktif = true then
      select count(*)
        into v_pesanan_aktif
        from public.pesanan p
       where p.meja_id = p_meja_id
         and p.status not in ('lunas', 'batal');

      if v_pesanan_aktif > 0 then
        raise exception 'Meja "%" sedang memiliki % pesanan aktif — selesaikan transaksi terlebih dahulu sebelum menonaktifkan.', v_meja.nama, v_pesanan_aktif
          using errcode = 'P0001';
      end if;
    end if;

    update public.meja
       set nama = v_nama_bersih,
           area = v_area_bersih,
           aktif = coalesce(p_aktif, true),
           diubah_pada = v_versi_baru
     where id = p_meja_id
     returning * into v_meja;

    v_aksi := 'ubah_meja';
    v_nilai_baru := to_jsonb(v_meja);
  end if;

  -- Catat jejak audit kekal
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
    v_pengguna_id,
    v_aksi,
    'meja',
    v_meja.id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'meja', jsonb_build_object(
      'id', v_meja.id,
      'cabang_id', v_meja.cabang_id,
      'nama', v_meja.nama,
      'area', v_meja.area,
      'status', v_meja.status,
      'aktif', v_meja.aktif,
      'diubah_pada', v_meja.diubah_pada
    )
  );
end;
$$;

comment on function public.simpan_meja(uuid, text, text, boolean, uuid, timestamptz) is
  'T10-11: Menyimpan (tambah/edit) meja dengan proteksi konkurensi optimistik versi_lama.';

revoke all on function public.simpan_meja(uuid, text, text, boolean, uuid, timestamptz) from public, anon;
grant execute on function public.simpan_meja(uuid, text, text, boolean, uuid, timestamptz) to authenticated;
grant execute on function public.simpan_meja(uuid, text, text, boolean, uuid, timestamptz) to service_role;

-- ----------------------------------------------------------------------------
-- 4. RPC `catat_konflik_pengaturan` untuk Audit Insiden Tabrakan Versi
-- ----------------------------------------------------------------------------
create or replace function public.catat_konflik_pengaturan(
  p_entitas text,
  p_entitas_id uuid default null,
  p_versi_klien timestamptz default null,
  p_keterangan text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_versi_sekarang timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Pengguna belum terautentikasi.' using errcode = '42501';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- Dapatkan versi saat ini sesuai entitas
  if p_entitas = 'pengaturan' then
    select versi_pengaturan into v_versi_sekarang
      from public.pengaturan
     where penyewa_id = v_penyewa;
  elsif p_entitas = 'menu_item' and p_entitas_id is not null then
    select diubah_pada into v_versi_sekarang
      from public.menu_item
     where id = p_entitas_id and penyewa_id = v_penyewa;
  elsif p_entitas = 'kategori_menu' and p_entitas_id is not null then
    select diubah_pada into v_versi_sekarang
      from public.kategori_menu
     where id = p_entitas_id and penyewa_id = v_penyewa;
  elsif p_entitas = 'meja' and p_entitas_id is not null then
    select diubah_pada into v_versi_sekarang
      from public.meja
     where id = p_entitas_id and penyewa_id = v_penyewa;
  end if;

  -- Catat insiden tabrakan ke catatan_audit
  insert into public.catatan_audit (
    penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'konflik_versi_ditolak',
    coalesce(p_entitas, 'pengaturan'),
    p_entitas_id,
    jsonb_build_object(
      'versi_klien', p_versi_klien,
      'keterangan', coalesce(p_keterangan, 'Penyimpanan ditolak karena data telah diubah pengguna lain.')
    ),
    jsonb_build_object(
      'versi_peladen', v_versi_sekarang,
      'status', 'ditolak_fail_closed'
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Insiden konflik versi berhasil dicatat ke audit.'
  );
end;
$$;

comment on function public.catat_konflik_pengaturan(text, uuid, timestamptz, text) is
  'T10-11: Mencatat insiden percobaan simpan bersamaan yang tertolak ke catatan_audit.';

revoke all on function public.catat_konflik_pengaturan(text, uuid, timestamptz, text) from public, anon;
grant execute on function public.catat_konflik_pengaturan(text, uuid, timestamptz, text) to authenticated;
grant execute on function public.catat_konflik_pengaturan(text, uuid, timestamptz, text) to service_role;
