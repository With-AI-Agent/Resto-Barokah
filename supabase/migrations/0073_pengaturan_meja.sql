-- ============================================================================
-- 0073 — Pengaturan meja, area, dan QR meja (T9-04 / PRD M2 & M4)
--
-- Menyediakan pengelolaan meja & area kedai untuk owner / admin cabang:
--  1. Menambah meja baru dengan nomor/nama meja unik per cabang.
--  2. Mengubah nama, area, dan status aktif/nonaktif meja.
--  3. Mitigasi risiko T9-04: Meja yang nonaktif DILARANG menerima pesanan baru
--     atau dipindahkan ke meja nonaktif di sisi server (fungsi picu_pesanan_konsisten).
--  4. Meja yang sedang memiliki pesanan aktif DILARANG dinonaktifkan sampai
--     pesanan selesai.
--  5. Jejak audit kekal di public.catatan_audit untuk setiap aksi kelola meja.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PEMBARUAN PENJAGA KONSISTENSI PESANAN (MITIGASI RISIKO T9-04)
--    Menolak pesanan baru atau pemindahan pesanan ke meja yang nonaktif.
-- ----------------------------------------------------------------------------
create or replace function public.picu_pesanan_konsisten()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_cabang uuid;
  v_penyewa_meja   uuid;
  v_cabang_meja    uuid;
  v_aktif_meja     boolean;
  v_nama_meja      text;
begin
  select c.penyewa_id into v_penyewa_cabang from public.cabang c where c.id = new.cabang_id;
  if v_penyewa_cabang is null then
    raise exception 'Cabang tidak ditemukan.';
  end if;
  if v_penyewa_cabang <> new.penyewa_id then
    raise exception 'Cabang dan pesanan harus berada di resto yang sama.';
  end if;

  if new.meja_id is not null then
    select m.cabang_id, c.penyewa_id, m.aktif, m.nama
      into v_cabang_meja, v_penyewa_meja, v_aktif_meja, v_nama_meja
      from public.meja m
      join public.cabang c on c.id = m.cabang_id
     where m.id = new.meja_id;

    if v_cabang_meja is null then
      raise exception 'Meja tidak ditemukan.';
    end if;
    if v_cabang_meja <> new.cabang_id then
      raise exception 'Meja itu berada di cabang lain — pesanan tidak boleh memakainya.';
    end if;

    -- Mitigasi risiko T9-04: Meja nonaktif dilarang menerima pesanan baru atau pemindahan meja
    if not v_aktif_meja and (tg_op = 'INSERT' or new.meja_id is distinct from old.meja_id) then
      raise exception 'Meja "%" sedang dinonaktifkan — tidak dapat menerima pesanan baru.', v_nama_meja;
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.picu_pesanan_konsisten() from public, anon, authenticated;
grant execute on function public.picu_pesanan_konsisten() to service_role;

-- ----------------------------------------------------------------------------
-- 2. RPC simpan_meja (TAMBAH / UBAH MEJA & AREA)
-- ----------------------------------------------------------------------------
create or replace function public.simpan_meja(
  p_cabang_id uuid,
  p_nama      text,
  p_area      text default 'Utama',
  p_aktif     boolean default true,
  p_meja_id   uuid default null
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
  v_cabang_penyewa uuid;
  v_nama_bersih    text;
  v_area_bersih    text;
  v_meja           record;
  v_pesanan_aktif  int;
  v_aksi           text;
  v_nilai_lama     jsonb;
  v_nilai_baru     jsonb;
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

  -- Validasi cabang milik penyewa pemanggil
  select c.penyewa_id into v_cabang_penyewa
    from public.cabang c
   where c.id = p_cabang_id;

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
     where m.cabang_id = p_cabang_id
       and lower(m.nama) = lower(v_nama_bersih)
       and (p_meja_id is null or m.id <> p_meja_id)
  ) then
    raise exception 'Nomor atau nama meja "%" sudah digunakan di cabang ini.', v_nama_bersih
      using errcode = '23505';
  end if;

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
      p_cabang_id,
      v_nama_bersih,
      v_area_bersih,
      'kosong',
      coalesce(p_aktif, true),
      now()
    )
    returning * into v_meja;

    v_aksi := 'tambah_meja';
    v_nilai_lama := null;
    v_nilai_baru := to_jsonb(v_meja);
  else
    -- Ambil meja lama
    select * into v_meja
      from public.meja m
     where m.id = p_meja_id
       and m.cabang_id = p_cabang_id;

    if v_meja.id is null then
      raise exception 'Meja yang ingin diubah tidak ditemukan.'
        using errcode = 'P0002';
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
           diubah_pada = now()
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

comment on function public.simpan_meja(uuid, text, text, boolean, uuid) is
  'Menambah atau memperbarui nomor meja dan area per cabang dengan jejak audit kekal.';

revoke all on function public.simpan_meja(uuid, text, text, boolean, uuid) from public;
grant execute on function public.simpan_meja(uuid, text, text, boolean, uuid) to authenticated;

-- ----------------------------------------------------------------------------
-- 3. RPC ambil_daftar_meja (DAFTAR MEJA & DAFTAR AREA)
-- ----------------------------------------------------------------------------
create or replace function public.ambil_daftar_meja(
  p_cabang_id uuid default null,
  p_sertakan_nonaktif boolean default true
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_cabang_id  uuid;
  v_penyewa_id uuid;
  v_daftar     jsonb;
  v_area_list  jsonb;
begin
  v_penyewa_id := public.penyewa_saya();
  v_cabang_id := coalesce(p_cabang_id, public.cabang_aktif_saya());

  if v_cabang_id is null then
    select c.id into v_cabang_id
      from public.cabang c
     where c.penyewa_id = v_penyewa_id
     order by c.dibuat_pada asc
     limit 1;
  end if;

  if not public.cabang_pantau_saya(v_cabang_id) then
    raise exception 'Akses ditolak ke cabang ini.' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', m.id,
      'cabang_id', m.cabang_id,
      'nama', m.nama,
      'area', m.area,
      'status', m.status,
      'aktif', m.aktif,
      'diubah_pada', m.diubah_pada
    ) order by m.area asc, m.nama asc
  ), '[]'::jsonb)
    into v_daftar
    from public.meja m
   where m.cabang_id = v_cabang_id
     and (p_sertakan_nonaktif or m.aktif = true);

  select coalesce(jsonb_agg(distinct m.area order by m.area asc), '[]'::jsonb)
    into v_area_list
    from public.meja m
   where m.cabang_id = v_cabang_id;

  return jsonb_build_object(
    'cabang_id', v_cabang_id,
    'daftar_meja', v_daftar,
    'daftar_area', v_area_list,
    'total_meja', coalesce(jsonb_array_length(v_daftar), 0)
  );
end;
$$;

comment on function public.ambil_daftar_meja(uuid, boolean) is
  'Mengambil daftar meja dan area untuk cabang tertentu.';

revoke all on function public.ambil_daftar_meja(uuid, boolean) from public;
grant execute on function public.ambil_daftar_meja(uuid, boolean) to authenticated;

-- ----------------------------------------------------------------------------
-- 4. RPC hapus_meja (HAPUS MEJA JIKA BELUM ADA PESANAN)
-- ----------------------------------------------------------------------------
create or replace function public.hapus_meja(
  p_meja_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna_id  uuid;
  v_penyewa_id   uuid;
  v_peran        text;
  v_meja         record;
  v_pesanan      int;
begin
  v_pengguna_id := auth.uid();
  if v_pengguna_id is null then
    raise exception 'Akses ditolak: pengguna belum masuk.' using errcode = '42501';
  end if;

  v_penyewa_id := public.penyewa_saya();
  v_peran := public.peran_saya();

  if v_peran not in ('owner_pusat', 'admin_cabang') and not public.boleh('atur_pengaturan') then
    raise exception 'Akses ditolak: hanya pemilik atau staf pengatur yang berwenang menghapus meja.'
      using errcode = '42501';
  end if;

  select m.*, c.penyewa_id
    into v_meja
    from public.meja m
    join public.cabang c on c.id = m.cabang_id
   where m.id = p_meja_id;

  if v_meja.id is null or v_meja.penyewa_id <> v_penyewa_id then
    raise exception 'Meja tidak ditemukan atau berada di luar resto Anda.'
      using errcode = 'P0002';
  end if;

  -- PR-15 / T9-04: Meja dengan riwayat pesanan (termasuk lunas/batal) DILARANG dihapus
  select count(*) into v_pesanan
    from public.pesanan p
   where p.meja_id = p_meja_id;

  if v_pesanan > 0 then
    raise exception 'Meja "%" memiliki % pesanan dalam riwayat — tidak boleh dihapus; nonaktifkan saja.', v_meja.nama, v_pesanan
      using errcode = 'P0001';
  end if;

  -- Hapus meja
  delete from public.meja where id = p_meja_id;

  -- Jejak audit
  insert into public.catatan_audit (
    penyewa_id,
    pelaku_id,
    aksi,
    entitas,
    entitas_id,
    nilai_lama
  ) values (
    v_penyewa_id,
    v_pengguna_id,
    'hapus_meja',
    'meja',
    p_meja_id,
    to_jsonb(v_meja)
  );

  return jsonb_build_object('berhasil', true, 'id', p_meja_id);
end;
$$;

comment on function public.hapus_meja(uuid) is
  'Menghapus meja yang belum pernah memiliki riwayat pesanan.';

revoke all on function public.hapus_meja(uuid) from public;
grant execute on function public.hapus_meja(uuid) to authenticated;
