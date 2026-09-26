-- ============================================================================
-- 0074 — PENGATURAN MENU LENGKAP (T9-05 / PRD M2 & M3)
--
-- Mengizinkan Owner Resto (atau staf yang berwenang) untuk:
--   1. CRUD Kategori menu (nama, urutan, tujuan dapur/bar, status aktif).
--   2. CRUD Menu item (nama, deskripsi, harga, foto, urutan, unggulan, jenis, aktif).
--   3. Mengelola Varian menu (rasa/ukuran/level dengan tambahan harga).
--   4. Mengelola Opsi Tambahan / Topping (khusus menu maupun global se-resto).
--   5. Mengubah urutan tampil (sorting order) kategori dan menu secara fleksibel.
--   6. Penanda habis manual di menu cabang via integrasi `tandai_habis`.
--
-- Pagar Mitigasi & Integritas:
--   - Pagar fail-closed: Menu yang pernah dipesan dalam transaksi (`pesanan_item`)
--     DILARANG dihapus secara fisik (DELETE) dari database.
--     Sistem mewajibkan soft delete (`aktif = false`) agar riwayat pesanan,
--     buku besar keuangan, dan audit trail tetap utuh.
--   - Pagar integritas: Kategori yang masih memiliki menu item dilarang dihapus.
--   - Otorisasi ketat: owner_pusat, admin_cabang, atau pemegang izin atur_pengaturan.
--   - Isolasi penyewa multi-tenant (`penyewa_saya()`).
--   - Jejak audit kekal di `public.catatan_audit`.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Pemicu Pencegahan Penghapusan Menu Ber-Riwayat (Mitigasi Risiko T9-05)
-- ----------------------------------------------------------------------------
create or replace function public.picu_menu_item_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.pesanan_item where menu_item_id = old.id) then
    raise exception 'Menu pernah dipesan dalam transaksi dan tidak boleh dihapus secara permanen. Gunakan nonaktifkan menu (aktif = false) sebagai gantinya.';
  end if;
  return old;
end;
$$;

drop trigger if exists menu_item_cegah_hapus on public.menu_item;
create trigger menu_item_cegah_hapus
  before delete on public.menu_item
  for each row execute function public.picu_menu_item_cegah_hapus();

revoke all on function public.picu_menu_item_cegah_hapus() from public, anon, authenticated;
grant execute on function public.picu_menu_item_cegah_hapus() to service_role;

-- ----------------------------------------------------------------------------
-- 2. Pemicu Pencegahan Penghapusan Kategori Yang Masih Memiliki Menu
-- ----------------------------------------------------------------------------
create or replace function public.picu_kategori_menu_cegah_hapus()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from public.menu_item where kategori_id = old.id) then
    raise exception 'Kategori masih memiliki item menu dan tidak boleh dihapus. Hapus atau pindahkan menu terlebih dahulu.';
  end if;
  return old;
end;
$$;

drop trigger if exists kategori_menu_cegah_hapus on public.kategori_menu;
create trigger kategori_menu_cegah_hapus
  before delete on public.kategori_menu
  for each row execute function public.picu_kategori_menu_cegah_hapus();

revoke all on function public.picu_kategori_menu_cegah_hapus() from public, anon, authenticated;
grant execute on function public.picu_kategori_menu_cegah_hapus() to service_role;

-- ----------------------------------------------------------------------------
-- 3. RPC `simpan_kategori_menu` (CRUD Kategori Menu)
-- ----------------------------------------------------------------------------
create or replace function public.simpan_kategori_menu(
  p_id uuid default null,
  p_nama text default null,
  p_urutan integer default null,
  p_tujuan text default 'dapur',
  p_aktif boolean default true
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

  if length(btrim(p_nama)) > 100 then
    raise exception 'Nama kategori maksimal 100 karakter.';
  end if;

  if p_tujuan is null or p_tujuan not in ('dapur', 'bar') then
    raise exception 'Tujuan kategori harus dapur atau bar.';
  end if;

  -- Keunikan nama kategori per penyewa
  if p_id is null then
    if exists (
      select 1 from public.kategori_menu
       where penyewa_id = v_penyewa
         and lower(nama) = lower(btrim(p_nama))
    ) then
      raise exception 'Nama kategori sudah digunakan di resto ini.';
    end if;

    if p_urutan is null or p_urutan <= 0 then
      select coalesce(max(urutan), 0) + 1 into v_urutan
        from public.kategori_menu
       where penyewa_id = v_penyewa;
    else
      v_urutan := p_urutan;
    end if;

    insert into public.kategori_menu (penyewa_id, nama, urutan, tujuan, aktif)
    values (v_penyewa, btrim(p_nama), v_urutan, p_tujuan, coalesce(p_aktif, true))
    returning id into v_id;
  else
    if exists (
      select 1 from public.kategori_menu
       where penyewa_id = v_penyewa
         and lower(nama) = lower(btrim(p_nama))
         and id <> p_id
    ) then
      raise exception 'Nama kategori sudah digunakan di resto ini.';
    end if;

    update public.kategori_menu
       set nama = btrim(p_nama),
           urutan = coalesce(p_urutan, urutan),
           tujuan = p_tujuan,
           aktif = coalesce(p_aktif, aktif),
           diubah_pada = now()
     where id = p_id
       and penyewa_id = v_penyewa
    returning id, urutan into v_id, v_urutan;

    if v_id is null then
      raise exception 'Kategori menu tidak ditemukan.';
    end if;
  end if;

  -- Catat jejak audit
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    auth.uid(),
    'simpan_kategori_menu',
    'kategori_menu',
    v_id,
    jsonb_build_object(
      'id', v_id,
      'nama', btrim(p_nama),
      'urutan', v_urutan,
      'tujuan', p_tujuan,
      'aktif', coalesce(p_aktif, true)
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'pesan', 'Kategori menu berhasil disimpan.'
  );
end;
$$;

comment on function public.simpan_kategori_menu(uuid, text, integer, text, boolean) is
  'T9-05: Menyimpan (tambah/edit) kategori menu resto dengan tujuan dapur/bar dan urutan.';

-- ----------------------------------------------------------------------------
-- 4. RPC `hapus_kategori_menu`
-- ----------------------------------------------------------------------------
create or replace function public.hapus_kategori_menu(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_nama text;
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

  select nama into v_nama
    from public.kategori_menu
   where id = p_id and penyewa_id = v_penyewa;

  if v_nama is null then
    raise exception 'Kategori menu tidak ditemukan.';
  end if;

  if exists (select 1 from public.menu_item where kategori_id = p_id and penyewa_id = v_penyewa) then
    raise exception 'Kategori masih memiliki item menu dan tidak boleh dihapus. Hapus atau pindahkan menu terlebih dahulu.';
  end if;

  delete from public.kategori_menu
   where id = p_id and penyewa_id = v_penyewa;

  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama)
  values (
    v_penyewa,
    auth.uid(),
    'hapus_kategori_menu',
    'kategori_menu',
    p_id,
    jsonb_build_object('id', p_id, 'nama', v_nama)
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Kategori menu berhasil dihapus.'
  );
end;
$$;

comment on function public.hapus_kategori_menu(uuid) is
  'T9-05: Menghapus kategori menu kosong (kategori ber-item dicegah).';

-- ----------------------------------------------------------------------------
-- 5. RPC `simpan_menu` (TECH_SPEC §5: `rpc/simpan_menu` / PRD M2 & M3)
-- ----------------------------------------------------------------------------
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
  p_tambahan jsonb default '[]'::jsonb
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
  v_var jsonb;
  v_var_nama text;
  v_tam jsonb;
  v_tam_nama text;
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

  -- Keunikan nama per kategori dalam satu penyewa
  if p_id is null then
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
      penyewa_id, kategori_id, nama, deskripsi, harga, foto_path, urutan, unggulan, jenis, aktif
    ) values (
      v_penyewa, p_kategori_id, btrim(p_nama), p_deskripsi, p_harga, p_foto_path,
      v_urutan, coalesce(p_unggulan, false), p_jenis, coalesce(p_aktif, true)
    ) returning id into v_id;
  else
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
           diubah_pada = now()
     where id = p_id
       and penyewa_id = v_penyewa
    returning id, urutan into v_id, v_urutan;

    if v_id is null then
      raise exception 'Menu item tidak ditemukan.';
    end if;
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
  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru)
  values (
    v_penyewa,
    auth.uid(),
    'simpan_menu',
    'menu_item',
    v_id,
    jsonb_build_object(
      'id', v_id,
      'kategori_id', p_kategori_id,
      'nama', btrim(p_nama),
      'harga', p_harga,
      'jenis', p_jenis,
      'aktif', coalesce(p_aktif, true),
      'varian_count', coalesce(jsonb_array_length(p_varian), 0),
      'tambahan_count', coalesce(jsonb_array_length(p_tambahan), 0)
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'id', v_id,
    'pesan', 'Menu berhasil disimpan.'
  );
end;
$$;

comment on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb) is
  'T9-05: Menyimpan master menu item beserta varian & opsi tambahannya dengan jejak audit kekal.';

-- ----------------------------------------------------------------------------
-- 6. RPC `hapus_menu` (Mitigasi Risiko T9-05)
-- ----------------------------------------------------------------------------
create or replace function public.hapus_menu(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_nama text;
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

  select nama into v_nama
    from public.menu_item
   where id = p_id and penyewa_id = v_penyewa;

  if v_nama is null then
    raise exception 'Menu item tidak ditemukan.';
  end if;

  -- Mitigasi ketat: menu yang pernah dipesan dilarang dihapus fisik dari database
  if exists (select 1 from public.pesanan_item where menu_item_id = p_id) then
    raise exception 'Menu pernah dipesan dalam transaksi dan tidak boleh dihapus secara permanen. Gunakan nonaktifkan menu (aktif = false) sebagai gantinya.';
  end if;

  delete from public.menu_item
   where id = p_id and penyewa_id = v_penyewa;

  insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama)
  values (
    v_penyewa,
    auth.uid(),
    'hapus_menu',
    'menu_item',
    p_id,
    jsonb_build_object('id', p_id, 'nama', v_nama)
  );

  return jsonb_build_object(
    'berhasil', true,
    'pesan', 'Menu berhasil dihapus.'
  );
end;
$$;

comment on function public.hapus_menu(uuid) is
  'T9-05: Menghapus menu baru yang belum pernah dipesan (menu ber-riwayat dicegah fail-closed).';

-- ----------------------------------------------------------------------------
-- 7. RPC `simpan_urutan_kategori` & `simpan_urutan_menu`
-- ----------------------------------------------------------------------------
create or replace function public.simpan_urutan_kategori(
  p_urutan jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_item jsonb;
  v_id uuid;
  v_urutan integer;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengatur urutan kategori.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_urutan is not null and jsonb_typeof(p_urutan) = 'array' then
    for v_item in select * from jsonb_array_elements(p_urutan) loop
      v_id := (v_item->>'id')::uuid;
      v_urutan := (v_item->>'urutan')::integer;
      if v_id is not null and v_urutan is not null then
        update public.kategori_menu
           set urutan = v_urutan,
               diubah_pada = now()
         where id = v_id
           and penyewa_id = v_penyewa;
      end if;
    end loop;
  end if;

  return jsonb_build_object('berhasil', true, 'pesan', 'Urutan kategori berhasil disimpan.');
end;
$$;

create or replace function public.simpan_urutan_menu(
  p_urutan jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_item jsonb;
  v_id uuid;
  v_urutan integer;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengatur urutan menu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_urutan is not null and jsonb_typeof(p_urutan) = 'array' then
    for v_item in select * from jsonb_array_elements(p_urutan) loop
      v_id := (v_item->>'id')::uuid;
      v_urutan := (v_item->>'urutan')::integer;
      if v_id is not null and v_urutan is not null then
        update public.menu_item
           set urutan = v_urutan,
               diubah_pada = now()
         where id = v_id
           and penyewa_id = v_penyewa;
      end if;
    end loop;
  end if;

  return jsonb_build_object('berhasil', true, 'pesan', 'Urutan menu berhasil disimpan.');
end;
$$;

-- ----------------------------------------------------------------------------
-- 8. RPC `ambil_daftar_katalog_admin`
-- ----------------------------------------------------------------------------
create or replace function public.ambil_daftar_katalog_admin(
  p_cabang_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_kategori jsonb;
  v_menu jsonb;
  v_tambahan_global jsonb;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  -- Kategori beserta total item
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', k.id,
      'nama', k.nama,
      'urutan', k.urutan,
      'tujuan', k.tujuan,
      'aktif', k.aktif,
      'jumlah_menu', (
        select count(*) from public.menu_item m
         where m.kategori_id = k.id and m.penyewa_id = v_penyewa
      )
    ) order by k.urutan, k.nama
  ), '[]'::jsonb)
  into v_kategori
  from public.kategori_menu k
  where k.penyewa_id = v_penyewa;

  -- Menu item beserta varian, tambahan khusus, dan status habis di cabang
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', m.id,
      'kategori_id', m.kategori_id,
      'kategori_nama', k.nama,
      'nama', m.nama,
      'deskripsi', coalesce(m.deskripsi, ''),
      'harga', m.harga,
      'foto_path', coalesce(m.foto_path, ''),
      'urutan', m.urutan,
      'unggulan', m.unggulan,
      'jenis', m.jenis,
      'aktif', m.aktif,
      'habis', case
        when p_cabang_id is not null then coalesce(mc.habis, false)
        else false
      end,
      'harga_cabang', case
        when p_cabang_id is not null then mc.harga
        else null
      end,
      'varian', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'nama', v.nama,
            'tambahan_harga', v.tambahan_harga,
            'aktif', v.aktif
          ) order by v.nama
        )
        from public.menu_varian v
        where v.menu_item_id = m.id
      ), '[]'::jsonb),
      'tambahan', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', t.id,
            'nama', t.nama,
            'harga', t.harga,
            'aktif', t.aktif
          ) order by t.nama
        )
        from public.menu_tambahan t
        where t.menu_item_id = m.id
      ), '[]'::jsonb)
    ) order by m.urutan, m.nama
  ), '[]'::jsonb)
  into v_menu
  from public.menu_item m
  join public.kategori_menu k on k.id = m.kategori_id
  left join public.menu_cabang mc on mc.menu_item_id = m.id and mc.cabang_id = p_cabang_id
  where m.penyewa_id = v_penyewa;

  -- Tambahan global (berlaku semua menu)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'nama', t.nama,
      'harga', t.harga,
      'aktif', t.aktif
    ) order by t.nama
  ), '[]'::jsonb)
  into v_tambahan_global
  from public.menu_tambahan t
  where t.penyewa_id = v_penyewa and t.menu_item_id is null;

  return jsonb_build_object(
    'berhasil', true,
    'kategori', v_kategori,
    'menu', v_menu,
    'tambahan_global', v_tambahan_global
  );
end;
$$;

comment on function public.ambil_daftar_katalog_admin(uuid) is
  'T9-05: Mengambil data lengkap kategori, menu, varian, dan tambahan untuk admin resto.';

-- ----------------------------------------------------------------------------
-- 9. RPC `simpan_menu_tambahan_global` & `hapus_menu_tambahan`
-- ----------------------------------------------------------------------------
create or replace function public.simpan_menu_tambahan_global(
  p_id uuid default null,
  p_nama text default null,
  p_harga integer default 0,
  p_aktif boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengelola tambahan menu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  if p_nama is null or btrim(p_nama) = '' then
    raise exception 'Nama tambahan wajib diisi.';
  end if;

  if p_harga is null or p_harga < 0 then
    raise exception 'Harga tambahan tidak boleh negatif.';
  end if;

  if p_id is null then
    insert into public.menu_tambahan (penyewa_id, menu_item_id, nama, harga, aktif)
    values (v_penyewa, null, btrim(p_nama), p_harga, coalesce(p_aktif, true))
    returning id into v_id;
  else
    update public.menu_tambahan
       set nama = btrim(p_nama),
           harga = p_harga,
           aktif = coalesce(p_aktif, aktif)
     where id = p_id
       and penyewa_id = v_penyewa
       and menu_item_id is null
    returning id into v_id;

    if v_id is null then
      raise exception 'Tambahan menu tidak ditemukan.';
    end if;
  end if;

  return jsonb_build_object('berhasil', true, 'id', v_id, 'pesan', 'Tambahan menu berhasil disimpan.');
end;
$$;

create or replace function public.hapus_menu_tambahan(
  p_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus masuk lebih dulu.';
  end if;

  if coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang')
     and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk menghapus tambahan menu.';
  end if;

  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Penyewa tidak ditemukan.';
  end if;

  delete from public.menu_tambahan
   where id = p_id and penyewa_id = v_penyewa;

  return jsonb_build_object('berhasil', true, 'pesan', 'Tambahan menu berhasil dihapus.');
end;
$$;

-- ----------------------------------------------------------------------------
-- 10. Hak Akses (ACL)
-- ----------------------------------------------------------------------------
revoke all on function public.simpan_kategori_menu(uuid, text, integer, text, boolean) from public, anon;
grant execute on function public.simpan_kategori_menu(uuid, text, integer, text, boolean) to authenticated, service_role;

revoke all on function public.hapus_kategori_menu(uuid) from public, anon;
grant execute on function public.hapus_kategori_menu(uuid) to authenticated, service_role;

revoke all on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb) from public, anon;
grant execute on function public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb) to authenticated, service_role;

revoke all on function public.hapus_menu(uuid) from public, anon;
grant execute on function public.hapus_menu(uuid) to authenticated, service_role;

revoke all on function public.simpan_urutan_kategori(jsonb) from public, anon;
grant execute on function public.simpan_urutan_kategori(jsonb) to authenticated, service_role;

revoke all on function public.simpan_urutan_menu(jsonb) from public, anon;
grant execute on function public.simpan_urutan_menu(jsonb) to authenticated, service_role;

revoke all on function public.ambil_daftar_katalog_admin(uuid) from public, anon;
grant execute on function public.ambil_daftar_katalog_admin(uuid) to authenticated, service_role;

revoke all on function public.simpan_menu_tambahan_global(uuid, text, integer, boolean) from public, anon;
grant execute on function public.simpan_menu_tambahan_global(uuid, text, integer, boolean) to authenticated, service_role;

revoke all on function public.hapus_menu_tambahan(uuid) from public, anon;
grant execute on function public.hapus_menu_tambahan(uuid) to authenticated, service_role;
