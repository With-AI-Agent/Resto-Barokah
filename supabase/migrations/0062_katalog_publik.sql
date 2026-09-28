-- ============================================================================
-- 0062 — RPC KATALOG PUBLIK (T8-01 / ART-10, ART-1)
--
-- RPC katalog_publik memungkinkan pelanggan publik (anon/tanpa masuk) melihat
-- informasi resto, cabang, kategori, dan menu makanan/minuman tanpa pernah
-- menyentuh atau membocorkan data sensitif (pegawai, keuangan, pelanggan, audit).
--
-- Karakteristik keamanan:
--   1. SECURITY DEFINER dengan search_path terkunci (public, pg_temp).
--   2. Proyeksi kolom tegas (eksplisit) — dilarang menggunakan SELECT *.
--   3. Menghormati penanda menu_cabang.habis dan harga khusus cabang bila ada.
--   4. Hak execute diberikan kepada anon, authenticated, dan service_role.
-- ============================================================================

create or replace function public.katalog_publik(
  p_slug      text,
  p_cabang_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa     record;
  v_cabang_id   uuid;
  v_cabang_info jsonb;
  v_kategori    jsonb;
  v_menu        jsonb;
begin
  if p_slug is null or trim(p_slug) = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'SLUG_WAJIB',
      'pesan', 'Slug restoran wajib diisi.'
    );
  end if;

  -- 1. Ambil data resto (penyewa) aktif & pengaturan publik
  select p.id, p.nama, p.slug, p.zona_waktu, p.mata_uang,
         coalesce(peng.jam_buka, '') as jam_buka,
         coalesce(peng.cara_pesan, 'kasir') as cara_pesan
    into v_penyewa
    from public.penyewa p
    left join public.pengaturan peng on peng.penyewa_id = p.id
   where p.slug = lower(trim(p_slug))
     and p.status = 'aktif';

  if v_penyewa.id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'RESTO_TIDAK_DITEMUKAN',
      'pesan', 'Restoran tidak ditemukan atau sedang tidak aktif.'
    );
  end if;

  -- 2. Validasi & kumpulkan cabang
  if p_cabang_id is not null then
    if not exists (
      select 1 from public.cabang c
       where c.id = p_cabang_id
         and c.penyewa_id = v_penyewa.id
         and c.aktif
    ) then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'CABANG_TIDAK_VALID',
        'pesan', 'Cabang tidak ditemukan atau tidak aktif di restoran ini.'
      );
    end if;
    v_cabang_id := p_cabang_id;
  end if;

  -- Kumpulkan daftar cabang aktif (hanya kolom publik: id, nama, alamat, telepon)
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', c.id,
      'nama', c.nama,
      'alamat', coalesce(c.alamat, ''),
      'telepon', coalesce(c.telepon, '')
    ) order by c.dibuat_pada
  ), '[]'::jsonb)
    into v_cabang_info
    from public.cabang c
   where c.penyewa_id = v_penyewa.id
     and c.aktif;

  -- 3. Kumpulkan kategori menu aktif
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', k.id,
      'nama', k.nama,
      'urutan', k.urutan
    ) order by k.urutan, k.nama
  ), '[]'::jsonb)
    into v_kategori
    from public.kategori_menu k
   where k.penyewa_id = v_penyewa.id
     and k.aktif;

  -- 4. Kumpulkan item menu aktif beserta varian dan status habis
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', m.id,
      'kategori_id', m.kategori_id,
      'nama', m.nama,
      'deskripsi', coalesce(m.deskripsi, ''),
      'harga', case
                 when v_cabang_id is not null and mc.harga is not null then mc.harga
                 else m.harga
               end,
      'foto_path', coalesce(m.foto_path, ''),
      'urutan', m.urutan,
      'unggulan', m.unggulan,
      'jenis', m.jenis,
      'habis', case
                 when v_cabang_id is not null then coalesce(mc.habis, false)
                 else false
               end,
      'varian', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'nama', v.nama,
            'tambahan_harga', v.tambahan_harga
          ) order by v.nama
        )
        from public.menu_varian v
        where v.menu_item_id = m.id and v.aktif
      ), '[]'::jsonb),
      'tambahan', coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'id', t.id,
            'nama', t.nama,
            'harga', t.harga
          ) order by t.nama
        )
        from public.menu_tambahan t
        where (t.menu_item_id = m.id or t.menu_item_id is null)
          and t.penyewa_id = v_penyewa.id
          and t.aktif
      ), '[]'::jsonb)
    ) order by m.urutan, m.nama
  ), '[]'::jsonb)
    into v_menu
    from public.menu_item m
    left join public.menu_cabang mc
      on mc.menu_item_id = m.id
     and mc.cabang_id = v_cabang_id
   where m.penyewa_id = v_penyewa.id
     and m.aktif
     and (mc.aktif is null or mc.aktif);

  return jsonb_build_object(
    'berhasil', true,
    'resto', jsonb_build_object(
      'id', v_penyewa.id,
      'nama', v_penyewa.nama,
      'slug', v_penyewa.slug,
      'jam_buka', v_penyewa.jam_buka,
      'cara_pesan', v_penyewa.cara_pesan,
      'zona_waktu', v_penyewa.zona_waktu,
      'mata_uang', v_penyewa.mata_uang
    ),
    'cabang_terpilih', v_cabang_id,
    'daftar_cabang', v_cabang_info,
    'kategori', v_kategori,
    'menu', v_menu
  );
end;
$$;

comment on function public.katalog_publik(text, uuid) is
  'T8-01: RPC katalog publik untuk pelanggan (tanpa login/anon). Mengembalikan info menu, harga, foto, jam buka, cabang tanpa membocorkan data sensitif.';

revoke all on function public.katalog_publik(text, uuid) from public;
grant execute on function public.katalog_publik(text, uuid) to anon, authenticated, service_role;
