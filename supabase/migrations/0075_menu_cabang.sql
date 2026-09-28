-- ============================================================================
-- 0075 — HARGA & KETERSEDIAAN MENU BERBEDA PER CABANG (T9-06 / PRD M11)
--
-- Tujuan:
--   1. Memungkinkan cabang memiliki harga khusus atau menyembunyikan item
--      tanpa memecah integritas master data pusat (multi-cabang PRD M11).
--   2. Satu sumber kebenaran: `public.menu_cabang` (harga, aktif, habis).
--      Bila harga is null -> otomatis mengikuti harga pusat (`menu_item.harga`).
--      Bila aktif is false -> item disembunyikan khusus pada cabang tersebut.
--   3. Menjaga fungsi `harga_berlaku` agar menghormati ketersediaan cabang
--      (`mc.aktif` dan `mi.aktif`). Bila item disembunyikan/nonaktif di cabang,
--      fungsi mengembalikan NULL sehingga pesanan item otomatis ditolak (fail-closed).
--   4. Menyediakan RPC:
--      - `simpan_menu_cabang`: simpan harga khusus / status aktif per item per cabang.
--      - `simpan_banyak_menu_cabang`: simpan banyak perubahan menu cabang sekaligus.
--      - `ambil_perbandingan_menu_cabang`: matriks perbandingan harga & ketersediaan.
--      - `salin_harga_cabang`: salin konfigurasi menu dari satu cabang ke cabang lain.
--      - `reset_harga_cabang`: kembalikan harga cabang ke harga pusat.
--   5. Hak akses ketat: `owner_pusat`, pemegang izin `atur_pengaturan`, atau
--      `admin_cabang` pada cabang bersangkutan.
--   6. Jejak audit kekal di `public.catatan_audit`.
-- ============================================================================

-- Tambahkan kolom diubah_pada pada tabel menu_cabang bila belum ada
alter table public.menu_cabang
  add column if not exists diubah_pada timestamptz not null default now();

-- ============================================================================
-- 1. PEMBARUAN HARGA BERLAKU (MENGHORMATI mc.aktif & mi.aktif)
-- ============================================================================
create or replace function public.harga_berlaku(p_menu_item_id uuid, p_cabang_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_harga integer;
begin
  select coalesce(mc.harga, mi.harga) into v_harga
    from public.menu_item mi
    left join public.menu_cabang mc
           on mc.menu_item_id = mi.id
          and mc.cabang_id = p_cabang_id
   where mi.id = p_menu_item_id
     and mi.penyewa_id = public.penyewa_saya()
     and mi.aktif
     and coalesce(mc.aktif, true);

  return v_harga;
end;
$$;

comment on function public.harga_berlaku(uuid, uuid) is
  'Harga yang benar-benar berlaku di satu cabang: harga khusus cabang bila ada, kalau tidak harga pusat. Mengembalikan NULL bila menu nonaktif pusat atau disembunyikan di cabang.';

revoke all on function public.harga_berlaku(uuid, uuid) from public, anon;
grant execute on function public.harga_berlaku(uuid, uuid) to authenticated, service_role;

-- ============================================================================
-- 2. RPC SIMPAN_MENU_CABANG
-- ============================================================================
create or replace function public.simpan_menu_cabang(
  p_cabang_id    uuid,
  p_menu_item_id uuid,
  p_harga        integer default null,
  p_aktif        boolean default true,
  p_habis        boolean default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_peran        text;
  v_cabang_ada   boolean;
  v_menu_ada     boolean;
  v_nilai_lama   jsonb;
  v_nilai_baru   jsonb;
  v_habis_akhir  boolean;
begin
  -- 1. Validasi Autentikasi
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- 2. Validasi Otorisasi
  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    if v_peran = 'admin_cabang' then
      if not exists (
        select 1 from public.pengguna
         where id = auth.uid() and cabang_id = p_cabang_id
      ) then
        raise exception 'Admin cabang hanya boleh mengatur cabangnya sendiri.';
      end if;
    else
      raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur menu cabang.';
    end if;
  end if;

  -- 3. Validasi Cabang & Menu milik penyewa yang sama
  select exists(
    select 1 from public.cabang
     where id = p_cabang_id and penyewa_id = v_penyewa
  ) into v_cabang_ada;

  if not v_cabang_ada then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  select exists(
    select 1 from public.menu_item
     where id = p_menu_item_id and penyewa_id = v_penyewa
  ) into v_menu_ada;

  if not v_menu_ada then
    raise exception 'Menu tidak ditemukan atau bukan milik resto Anda.';
  end if;

  -- 4. Validasi Harga
  if p_harga is not null and p_harga < 0 then
    raise exception 'Harga khusus cabang tidak boleh negatif.';
  end if;

  -- 5. Ambil data lama bila ada
  select jsonb_build_object(
    'harga', mc.harga,
    'aktif', mc.aktif,
    'habis', mc.habis
  ) into v_nilai_lama
  from public.menu_cabang mc
  where mc.cabang_id = p_cabang_id and mc.menu_item_id = p_menu_item_id;

  -- Tentukan status habis
  if p_habis is not null then
    v_habis_akhir := p_habis;
  else
    v_habis_akhir := coalesce((v_nilai_lama->>'habis')::boolean, false);
  end if;

  -- 6. Upsert data ke menu_cabang
  insert into public.menu_cabang (cabang_id, menu_item_id, harga, aktif, habis, diubah_pada)
  values (p_cabang_id, p_menu_item_id, p_harga, coalesce(p_aktif, true), v_habis_akhir, now())
  on conflict (cabang_id, menu_item_id)
  do update set
    harga = excluded.harga,
    aktif = excluded.aktif,
    habis = excluded.habis,
    diubah_pada = now();

  v_nilai_baru := jsonb_build_object(
    'cabang_id', p_cabang_id,
    'menu_item_id', p_menu_item_id,
    'harga', p_harga,
    'aktif', coalesce(p_aktif, true),
    'habis', v_habis_akhir
  );

  -- 7. Catat Jejak Audit
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
    'simpan_menu_cabang',
    'menu_cabang',
    p_menu_item_id,
    v_nilai_lama,
    v_nilai_baru
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Pengaturan menu cabang berhasil disimpan.',
    'data', v_nilai_baru
  );
end;
$$;

comment on function public.simpan_menu_cabang(uuid, uuid, integer, boolean, boolean) is
  'T9-06: Mengatur harga khusus cabang, status aktif (sembunyikan item), dan status habis per menu per cabang.';

revoke all on function public.simpan_menu_cabang(uuid, uuid, integer, boolean, boolean) from public, anon;
grant execute on function public.simpan_menu_cabang(uuid, uuid, integer, boolean, boolean) to authenticated, service_role;

-- ============================================================================
-- 3. RPC SIMPAN_BANYAK_MENU_CABANG
-- ============================================================================
create or replace function public.simpan_banyak_menu_cabang(
  p_cabang_id uuid,
  p_daftar    jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_peran        text;
  v_item         jsonb;
  v_menu_id      uuid;
  v_harga        integer;
  v_aktif        boolean;
  v_habis        boolean;
  v_jumlah       integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    if v_peran = 'admin_cabang' then
      if not exists (
        select 1 from public.pengguna
         where id = auth.uid() and cabang_id = p_cabang_id
      ) then
        raise exception 'Admin cabang hanya boleh mengatur cabangnya sendiri.';
      end if;
    else
      raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur menu cabang.';
    end if;
  end if;

  if not exists (
    select 1 from public.cabang
     where id = p_cabang_id and penyewa_id = v_penyewa
  ) then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  if p_daftar is null or jsonb_typeof(p_daftar) <> 'array' then
    raise exception 'Daftar perubahan harus berupa array JSON.';
  end if;

  for v_item in select * from jsonb_array_elements(p_daftar) loop
    v_menu_id := (v_item->>'menu_item_id')::uuid;
    if v_item ? 'harga' and (v_item->>'harga') is not null then
      v_harga := (v_item->>'harga')::integer;
      if v_harga < 0 then
        raise exception 'Harga khusus cabang tidak boleh negatif.';
      end if;
    else
      v_harga := null;
    end if;

    if v_item ? 'aktif' and (v_item->>'aktif') is not null then
      v_aktif := (v_item->>'aktif')::boolean;
    else
      v_aktif := true;
    end if;

    if v_item ? 'habis' and (v_item->>'habis') is not null then
      v_habis := (v_item->>'habis')::boolean;
    else
      v_habis := null;
    end if;

    perform public.simpan_menu_cabang(
      p_cabang_id,
      v_menu_id,
      v_harga,
      v_aktif,
      v_habis
    );
    v_jumlah := v_jumlah + 1;
  end loop;

  return jsonb_build_object(
    'berhasil', true,
    'jumlah', v_jumlah,
    'pesan', format('%s pengaturan menu cabang berhasil disimpan.', v_jumlah)
  );
end;
$$;

comment on function public.simpan_banyak_menu_cabang(uuid, jsonb) is
  'T9-06: Menyimpan konfigurasi banyak menu cabang sekaligus.';

revoke all on function public.simpan_banyak_menu_cabang(uuid, jsonb) from public, anon;
grant execute on function public.simpan_banyak_menu_cabang(uuid, jsonb) to authenticated, service_role;

-- ============================================================================
-- 4. RPC AMBIL_PERBANDINGAN_MENU_CABANG
-- ============================================================================
create or replace function public.ambil_perbandingan_menu_cabang(
  p_cabang_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_daftar_cabang jsonb;
  v_daftar_kategori jsonb;
  v_daftar_menu   jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- 1. Daftar Cabang
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'nama', c.nama,
      'alamat', coalesce(c.alamat, ''),
      'aktif', c.aktif
    ) order by c.nama
  ), '[]'::jsonb)
  into v_daftar_cabang
  from public.cabang c
  where c.penyewa_id = v_penyewa
    and (p_cabang_id is null or c.id = p_cabang_id);

  -- 2. Daftar Kategori
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', k.id,
      'nama', k.nama,
      'urutan', k.urutan,
      'tujuan', k.tujuan,
      'aktif', k.aktif
    ) order by k.urutan, k.nama
  ), '[]'::jsonb)
  into v_daftar_kategori
  from public.kategori_menu k
  where k.penyewa_id = v_penyewa;

  -- 3. Daftar Menu beserta rincian status per cabang
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', m.id,
      'kategori_id', m.kategori_id,
      'kategori_nama', k.nama,
      'nama', m.nama,
      'harga_pusat', m.harga,
      'aktif_pusat', m.aktif,
      'foto_path', coalesce(m.foto_path, ''),
      'urutan', m.urutan,
      'cabang', (
        select coalesce(jsonb_agg(
          jsonb_build_object(
            'cabang_id', c.id,
            'cabang_nama', c.nama,
            'harga_khusus', mc.harga,
            'harga_efektif', coalesce(mc.harga, m.harga),
            'beda_harga', (mc.harga is not null and mc.harga <> m.harga),
            'aktif_cabang', coalesce(mc.aktif, true),
            'habis_cabang', coalesce(mc.habis, false)
          ) order by c.nama
        ), '[]'::jsonb)
        from public.cabang c
        left join public.menu_cabang mc
          on mc.cabang_id = c.id
         and mc.menu_item_id = m.id
        where c.penyewa_id = v_penyewa
          and (p_cabang_id is null or c.id = p_cabang_id)
      )
    ) order by k.urutan, m.urutan, m.nama
  ), '[]'::jsonb)
  into v_daftar_menu
  from public.menu_item m
  join public.kategori_menu k on k.id = m.kategori_id
  where m.penyewa_id = v_penyewa;

  return jsonb_build_object(
    'berhasil', true,
    'daftar_cabang', v_daftar_cabang,
    'daftar_kategori', v_daftar_kategori,
    'daftar_menu', v_daftar_menu
  );
end;
$$;

comment on function public.ambil_perbandingan_menu_cabang(uuid) is
  'T9-06: Mengambil perbandingan harga dan ketersediaan menu antar seluruh cabang atau cabang spesifik.';

revoke all on function public.ambil_perbandingan_menu_cabang(uuid) from public, anon;
grant execute on function public.ambil_perbandingan_menu_cabang(uuid) to authenticated, service_role;

-- ============================================================================
-- 5. RPC SALIN_HARGA_CABANG
-- ============================================================================
create or replace function public.salin_harga_cabang(
  p_cabang_asal_id    uuid,
  p_cabang_tujuan_id  uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa      uuid;
  v_peran        text;
  v_jumlah       integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Hanya owner pusat atau pemegang izin atur_pengaturan yang dapat menyalin konfigurasi cabang.';
  end if;

  if p_cabang_asal_id = p_cabang_tujuan_id then
    raise exception 'Cabang asal dan cabang tujuan tidak boleh sama.';
  end if;

  -- Pastikan kedua cabang milik penyewa pemanggil
  if not exists (select 1 from public.cabang where id = p_cabang_asal_id and penyewa_id = v_penyewa) then
    raise exception 'Cabang asal tidak ditemukan atau bukan milik resto Anda.';
  end if;

  if not exists (select 1 from public.cabang where id = p_cabang_tujuan_id and penyewa_id = v_penyewa) then
    raise exception 'Cabang tujuan tidak ditemukan atau bukan milik resto Anda.';
  end if;

  -- Salin seluruh baris menu_cabang dari asal ke tujuan
  insert into public.menu_cabang (cabang_id, menu_item_id, harga, aktif, habis, diubah_pada)
  select p_cabang_tujuan_id, mc.menu_item_id, mc.harga, mc.aktif, mc.habis, now()
    from public.menu_cabang mc
   where mc.cabang_id = p_cabang_asal_id
  on conflict (cabang_id, menu_item_id)
  do update set
    harga = excluded.harga,
    aktif = excluded.aktif,
    habis = excluded.habis,
    diubah_pada = now();

  get diagnostics v_jumlah = row_count;

  -- Jejak audit
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'salin_harga_cabang',
    'cabang',
    p_cabang_tujuan_id,
    jsonb_build_object(
      'cabang_asal_id', p_cabang_asal_id,
      'cabang_tujuan_id', p_cabang_tujuan_id,
      'jumlah_disalin', v_jumlah
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'jumlah', v_jumlah,
    'pesan', format('%s konfigurasi menu cabang berhasil disalin.', v_jumlah)
  );
end;
$$;

comment on function public.salin_harga_cabang(uuid, uuid) is
  'T9-06: Menyalin seluruh pengaturan harga dan ketersediaan menu dari cabang asal ke cabang tujuan.';

revoke all on function public.salin_harga_cabang(uuid, uuid) from public, anon;
grant execute on function public.salin_harga_cabang(uuid, uuid) to authenticated, service_role;

-- ============================================================================
-- 6. RPC RESET_HARGA_CABANG
-- ============================================================================
create or replace function public.reset_harga_cabang(
  p_cabang_id    uuid,
  p_menu_item_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_peran   text;
  v_jumlah  integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk terlebih dahulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  v_peran := coalesce(public.peran_saya(), '');
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    if v_peran = 'admin_cabang' then
      if not exists (
        select 1 from public.pengguna
         where id = auth.uid() and cabang_id = p_cabang_id
      ) then
        raise exception 'Admin cabang hanya boleh mengatur cabangnya sendiri.';
      end if;
    else
      raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur menu cabang.';
    end if;
  end if;

  if not exists (
    select 1 from public.cabang
     where id = p_cabang_id and penyewa_id = v_penyewa
  ) then
    raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda.';
  end if;

  if p_menu_item_id is not null then
    update public.menu_cabang
       set harga = null,
           diubah_pada = now()
     where cabang_id = p_cabang_id
       and menu_item_id = p_menu_item_id;
    v_jumlah := 1;
  else
    update public.menu_cabang
       set harga = null,
           diubah_pada = now()
     where cabang_id = p_cabang_id;
    get diagnostics v_jumlah = row_count;
  end if;

  -- Jejak audit
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_baru
  ) values (
    v_penyewa,
    auth.uid(),
    'reset_harga_cabang',
    'cabang',
    p_cabang_id,
    jsonb_build_object(
      'cabang_id', p_cabang_id,
      'menu_item_id', p_menu_item_id,
      'jumlah_direset', v_jumlah
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'jumlah', v_jumlah,
    'pesan', format('%s menu berhasil dikembalikan ke harga pusat.', v_jumlah)
  );
end;
$$;

comment on function public.reset_harga_cabang(uuid, uuid) is
  'T9-06: Mengembalikan harga khusus cabang ke harga pusat (harga = null).';

revoke all on function public.reset_harga_cabang(uuid, uuid) from public, anon;
grant execute on function public.reset_harga_cabang(uuid, uuid) to authenticated, service_role;
