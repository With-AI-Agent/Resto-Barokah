-- ============================================================================
-- 0071 — Tema & Warna Merek Resto (T9-02 / PRD M2)
--
-- Memungkinkan Owner Resto / staf berwenang memilih dari 10 tema merek visual
-- yang telah lolos uji kontras WCAG 2.1 (Terang Bersih, Hangat Kedai, Gelap Dapur,
-- Kontras Tinggi, Bara Panggang, Vintage Klasik, Alam Hijau, Tropis Segar,
-- Pastel Manis, Etnik Nusantara) serta mengatur kerapatan tampilan (nyaman/padat).
--
-- Pagar Keamanan & Aturan Bisnis:
-- 1. Kolom tema, warna_merek, dan kerapatan pada public.pengaturan.
-- 2. Nilai tema dibatasi ketat hanya 10 tema resmi via CHECK constraint.
-- 3. RPC simpan_tema:
--    - Otorisasi ketat: hanya owner_pusat atau staf dengan izin atur_pengaturan.
--    - Isolasi penyewa: hanya dapat mengubah resto pemanggil sendiri.
--    - Optimistic locking: menolak jika versi_lama tidak cocok (P0001).
--    - Jejak audit kekal di public.catatan_audit.
-- 4. Pembaruan ambil_pengaturan_identitas & katalog_publik agar menyertakan tema.
-- ============================================================================

-- 1. Tambah kolom tema dan kerapatan pada public.pengaturan
alter table public.pengaturan
  add column if not exists tema text not null default 'terang'
    check (tema in ('terang', 'hangat', 'gelap', 'kontras', 'bara', 'vintage', 'alam', 'tropis', 'pastel', 'etnik')),
  add column if not exists warna_merek text not null default '',
  add column if not exists kerapatan text not null default 'nyaman'
    check (kerapatan in ('nyaman', 'padat'));

comment on column public.pengaturan.tema is
  'Pilihan tema visual resto dari 10 tema resmi v3 yang lolos kontras WCAG 2.1.';
comment on column public.pengaturan.warna_merek is
  'Kode warna aksen merek khusus resto (opsional).';
comment on column public.pengaturan.kerapatan is
  'Tingkat kerapatan tampilan antarmuka: nyaman (standar) atau padat.';

-- 2. RPC Simpan Tema & Tampilan Merek Resto
create or replace function public.simpan_tema(
  p_tema         text,
  p_warna_merek  text default null,
  p_kerapatan    text default null,
  p_versi_lama   timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid            uuid;
  v_penyewa_id     uuid;
  v_peran          text;
  v_pengaturan     public.pengaturan%rowtype;
  v_versi_baru     timestamptz;
  v_tema_bersih    text;
  v_kerapatan_bersih text;
begin
  -- 1. Otentikasi
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_id := (select public.penyewa_saya());
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = '42501';
  end if;

  v_peran := (select public.peran_saya());

  -- 2. Otorisasi
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengubah tema tampilan resto.'
      using errcode = '42501';
  end if;

  -- 3. Kunci baris pengaturan
  select * into v_pengaturan
    from public.pengaturan
   where penyewa_id = v_penyewa_id
   for update;

  if v_pengaturan.penyewa_id is null then
    raise exception 'Baris pengaturan tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- 4. Optimistic locking
  if p_versi_lama is not null and v_pengaturan.versi_pengaturan is not null then
    if v_pengaturan.versi_pengaturan <> p_versi_lama then
      raise exception 'Data pengaturan sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
        using errcode = 'P0001';
    end if;
  end if;

  -- 5. Validasi tema
  v_tema_bersih := lower(trim(coalesce(p_tema, '')));
  if v_tema_bersih not in ('terang', 'hangat', 'gelap', 'kontras', 'bara', 'vintage', 'alam', 'tropis', 'pastel', 'etnik') then
    raise exception 'Pilihan tema "%" tidak valid. Pilihan tersedia: terang, hangat, gelap, kontras, bara, vintage, alam, tropis, pastel, etnik.', p_tema
      using errcode = '22023';
  end if;

  -- 6. Validasi kerapatan
  if p_kerapatan is not null then
    v_kerapatan_bersih := lower(trim(p_kerapatan));
    if v_kerapatan_bersih not in ('nyaman', 'padat') then
      raise exception 'Kerapatan "%" tidak valid. Pilihan tersedia: nyaman, padat.', p_kerapatan
        using errcode = '22023';
    end if;
  else
    v_kerapatan_bersih := v_pengaturan.kerapatan;
  end if;

  v_versi_baru := clock_timestamp();

  -- 7. Update tabel pengaturan
  update public.pengaturan
     set tema             = v_tema_bersih,
         warna_merek      = coalesce(trim(p_warna_merek), warna_merek),
         kerapatan        = v_kerapatan_bersih,
         diubah_oleh      = v_uid,
         diubah_pada      = now(),
         versi_pengaturan = v_versi_baru
   where penyewa_id = v_penyewa_id;

  -- 8. Catat jejak audit
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
    v_uid,
    'ubah_tema_resto',
    'pengaturan',
    v_penyewa_id,
    jsonb_build_object(
      'tema', v_pengaturan.tema,
      'warna_merek', v_pengaturan.warna_merek,
      'kerapatan', v_pengaturan.kerapatan,
      'versi_pengaturan', v_pengaturan.versi_pengaturan
    ),
    jsonb_build_object(
      'tema', v_tema_bersih,
      'warna_merek', coalesce(trim(p_warna_merek), v_pengaturan.warna_merek),
      'kerapatan', v_kerapatan_bersih,
      'versi_pengaturan', v_versi_baru
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Tema tampilan restoran berhasil disimpan.',
    'versi_pengaturan', v_versi_baru,
    'data', jsonb_build_object(
      'tema', v_tema_bersih,
      'warna_merek', coalesce(trim(p_warna_merek), v_pengaturan.warna_merek),
      'kerapatan', v_kerapatan_bersih,
      'versi_pengaturan', v_versi_baru
    )
  );
end;
$$;

comment on function public.simpan_tema(text, text, text, timestamptz) is
  'T9-02: Menyimpan pilihan tema dan kerapatan tampilan resto dengan validasi 10 tema resmi dan jejak audit.';

revoke all on function public.simpan_tema(text, text, text, timestamptz) from public;
grant execute on function public.simpan_tema(text, text, text, timestamptz) to authenticated;

-- 3. Perbarui ambil_pengaturan_identitas agar mengembalikan tema dan kerapatan
create or replace function public.ambil_pengaturan_identitas()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa_id uuid;
  v_res        jsonb;
begin
  if auth.uid() is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_id := (select public.penyewa_saya());
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'penyewa_id', p.id,
    'nama_resto', p.nama,
    'slug', p.slug,
    'status', p.status,
    'tagline', coalesce(peng.tagline, ''),
    'logo_url', coalesce(peng.logo_url, ''),
    'banner_url', coalesce(peng.banner_url, ''),
    'jam_buka', coalesce(peng.jam_buka, ''),
    'header_struk', coalesce(peng.header_struk, ''),
    'footer_struk', coalesce(peng.footer_struk, ''),
    'tema', coalesce(peng.tema, 'terang'),
    'warna_merek', coalesce(peng.warna_merek, ''),
    'kerapatan', coalesce(peng.kerapatan, 'nyaman'),
    'versi_pengaturan', peng.versi_pengaturan
  ) into v_res
  from public.penyewa p
  left join public.pengaturan peng on peng.penyewa_id = p.id
  where p.id = v_penyewa_id;

  return jsonb_build_object(
    'berhasil', true,
    'data', v_res
  );
end;
$$;

-- 4. Perbarui katalog_publik agar mengembalikan tema resto
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
         coalesce(peng.cara_pesan, 'kasir') as cara_pesan,
         coalesce(peng.tagline, '') as tagline,
         coalesce(peng.logo_url, '') as logo_url,
         coalesce(peng.banner_url, '') as banner_url,
         coalesce(peng.tema, 'terang') as tema,
         coalesce(peng.warna_merek, '') as warna_merek
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

  -- Kumpulkan daftar cabang aktif
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
      'tagline', v_penyewa.tagline,
      'logo_url', v_penyewa.logo_url,
      'banner_url', v_penyewa.banner_url,
      'tema', v_penyewa.tema,
      'warna_merek', v_penyewa.warna_merek,
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
