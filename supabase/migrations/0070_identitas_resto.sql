-- ============================================================================
-- 0070 — Pengaturan Identitas & Tampilan Resto (T9-01 / PRD M2)
--
-- Memungkinkan Owner / Admin berwenang mengubah nama restoran, tagline, logo,
-- dan banner tanpa koding dan tanpa menghubungi platform.
--
-- Pagar Keamanan & Aturan Bisnis:
-- 1. Kolom tagline, logo_url, banner_url, dan versi_pengaturan pada public.pengaturan.
-- 2. RPC simpan_pengaturan:
--    - Otorisasi ketat: hanya owner_pusat atau staf dengan izin atur_pengaturan.
--    - Isolasi penyewa: hanya dapat mengubah penyewa pemanggil sendiri.
--    - Optimistic concurrency locking: menolak jika versi_lama tidak cocok (konflik versi).
--    - Validasi: nama 1-120 karakter, panjang URL/data wajar.
--    - Pencatatan jejak audit kekal di public.catatan_audit.
-- 3. RPC ambil_pengaturan_identitas:
--    - Mengambil data identitas resto aktif untuk layar pengaturan.
-- 4. Pembaruan RPC katalog_publik:
--    - Menyertakan tagline, logo_url, dan banner_url pada objek resto agar
--      perubahan langsung terlihat di katalog pelanggan publik.
-- ============================================================================

-- 1. Tambah kolom identitas dan versi optimistik pada tabel pengaturan
alter table public.pengaturan
  add column if not exists tagline text not null default '',
  add column if not exists logo_url text not null default '',
  add column if not exists banner_url text not null default '',
  add column if not exists versi_pengaturan timestamptz not null default now();

comment on column public.pengaturan.tagline is
  'Slogan / tagline resto yang tampil di katalog publik dan cetakan struk.';
comment on column public.pengaturan.logo_url is
  'URL atau data URL logo resto untuk katalog dan kop surat struk.';
comment on column public.pengaturan.banner_url is
  'URL atau data URL banner utama halaman depan katalog resto.';
comment on column public.pengaturan.versi_pengaturan is
  'Stempel waktu versi pengaturan untuk mendeteksi konflik pengubahan bersamaan (optimistic locking).';

-- 2. RPC Simpan Pengaturan (Identitas & Pengaturan Umum)
create or replace function public.simpan_pengaturan(
  p_nama_resto      text default null,
  p_tagline         text default null,
  p_logo_url        text default null,
  p_banner_url      text default null,
  p_pajak_pb1_persen numeric default null,
  p_service_persen  numeric default null,
  p_pembulatan      text default null,
  p_tumpuk_diskon   boolean default null,
  p_header_struk    text default null,
  p_footer_struk    text default null,
  p_cara_pesan      text default null,
  p_jam_buka        text default null,
  p_versi_lama      timestamptz default null
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
  v_nama_lama      text;
  v_pengaturan     public.pengaturan%rowtype;
  v_versi_baru     timestamptz;
  v_nama_bersih    text;
begin
  -- 1. Verifikasi otentikasi pemanggil
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Tidak diautentikasi.' using errcode = '42501';
  end if;

  v_penyewa_id := (select public.penyewa_saya());
  if v_penyewa_id is null then
    raise exception 'Penyewa tidak ditemukan.' using errcode = '42501';
  end if;

  v_peran := (select public.peran_saya());

  -- 2. Verifikasi otorisasi: wajib owner_pusat atau memiliki izin atur_pengaturan
  if v_peran <> 'owner_pusat' and not public.boleh('atur_pengaturan') then
    raise exception 'Anda tidak memiliki wewenang untuk mengubah pengaturan resto.'
      using errcode = '42501';
  end if;

  -- 3. Kunci baris pengaturan dan penyewa untuk pembaruan aman
  select * into v_pengaturan
    from public.pengaturan
   where penyewa_id = v_penyewa_id
   for update;

  select nama into v_nama_lama
    from public.penyewa
   where id = v_penyewa_id
   for update;

  if v_pengaturan.penyewa_id is null then
    raise exception 'Baris pengaturan tidak ditemukan.' using errcode = 'P0002';
  end if;

  -- 4. Optimistic locking: tolak jika versi lama yang dikirim tidak cocok
  if p_versi_lama is not null and v_pengaturan.versi_pengaturan is not null then
    if v_pengaturan.versi_pengaturan <> p_versi_lama then
      raise exception 'Data pengaturan sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'
        using errcode = 'P0001';
    end if;
  end if;

  -- 5. Validasi & update nama resto di public.penyewa jika disediakan
  if p_nama_resto is not null then
    v_nama_bersih := trim(p_nama_resto);
    if length(v_nama_bersih) < 1 or length(v_nama_bersih) > 120 then
      raise exception 'Nama resto wajib diisi antara 1 sampai 120 karakter.'
        using errcode = '22023';
    end if;

    update public.penyewa
       set nama = v_nama_bersih
     where id = v_penyewa_id;
  else
    v_nama_bersih := v_nama_lama;
  end if;

  -- 6. Validasi batas panjang URL/gambar (mencegah payload berlebihan)
  if p_logo_url is not null and length(p_logo_url) > 2000000 then
    raise exception 'Ukuran berkas logo terlalu besar (maksimal 2 MB).' using errcode = '22023';
  end if;

  if p_banner_url is not null and length(p_banner_url) > 3000000 then
    raise exception 'Ukuran berkas banner terlalu besar (maksimal 3 MB).' using errcode = '22023';
  end if;

  v_versi_baru := clock_timestamp();

  -- 7. Update baris pengaturan
  update public.pengaturan
     set tagline                   = coalesce(p_tagline, tagline),
         logo_url                  = coalesce(p_logo_url, logo_url),
         banner_url                = coalesce(p_banner_url, banner_url),
         pajak_pb1_persen          = coalesce(p_pajak_pb1_persen, pajak_pb1_persen),
         service_persen            = coalesce(p_service_persen, service_persen),
         pembulatan                = coalesce(p_pembulatan, pembulatan),
         tumpuk_diskon             = coalesce(p_tumpuk_diskon, tumpuk_diskon),
         header_struk              = coalesce(p_header_struk, header_struk),
         footer_struk              = coalesce(p_footer_struk, footer_struk),
         cara_pesan                = coalesce(p_cara_pesan, cara_pesan),
         jam_buka                  = coalesce(p_jam_buka, jam_buka),
         diubah_oleh               = v_uid,
         diubah_pada               = now(),
         versi_pengaturan          = v_versi_baru
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
    'ubah_identitas_resto',
    'pengaturan',
    v_penyewa_id,
    jsonb_build_object(
      'nama_resto', v_nama_lama,
      'tagline', v_pengaturan.tagline,
      'logo_url', case when length(v_pengaturan.logo_url) > 0 then '[tersimpan]' else '[kosong]' end,
      'banner_url', case when length(v_pengaturan.banner_url) > 0 then '[tersimpan]' else '[kosong]' end,
      'versi_pengaturan', v_pengaturan.versi_pengaturan
    ),
    jsonb_build_object(
      'nama_resto', v_nama_bersih,
      'tagline', coalesce(p_tagline, v_pengaturan.tagline),
      'logo_url', case when length(coalesce(p_logo_url, v_pengaturan.logo_url)) > 0 then '[tersimpan]' else '[kosong]' end,
      'banner_url', case when length(coalesce(p_banner_url, v_pengaturan.banner_url)) > 0 then '[tersimpan]' else '[kosong]' end,
      'versi_pengaturan', v_versi_baru
    )
  );

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'SUKSES',
    'pesan', 'Pengaturan identitas resto berhasil disimpan.',
    'versi_pengaturan', v_versi_baru,
    'data', jsonb_build_object(
      'nama_resto', v_nama_bersih,
      'tagline', coalesce(p_tagline, v_pengaturan.tagline),
      'logo_url', coalesce(p_logo_url, v_pengaturan.logo_url),
      'banner_url', coalesce(p_banner_url, v_pengaturan.banner_url),
      'versi_pengaturan', v_versi_baru
    )
  );
end;
$$;

comment on function public.simpan_pengaturan(
  text, text, text, text, numeric, numeric, text, boolean, text, text, text, text, timestamptz
) is 'T9-01: Menyimpan perubahan identitas dan konfigurasi operasional resto dengan validasi izin dan kunci optimistik.';

revoke all on function public.simpan_pengaturan(
  text, text, text, text, numeric, numeric, text, boolean, text, text, text, text, timestamptz
) from public;

grant execute on function public.simpan_pengaturan(
  text, text, text, text, numeric, numeric, text, boolean, text, text, text, text, timestamptz
) to authenticated;

-- 3. RPC Ambil Pengaturan Identitas Resto
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

comment on function public.ambil_pengaturan_identitas() is
  'T9-01: Mengambil data identitas resto aktif untuk formulir pengaturan.';

revoke all on function public.ambil_pengaturan_identitas() from public;
grant execute on function public.ambil_pengaturan_identitas() to authenticated;

-- 4. Pembaruan RPC katalog_publik agar langsung menyajikan tagline, logo, dan banner
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

  -- 1. Ambil data resto (penyewa) aktif & pengaturan publik (termasuk tagline, logo, banner)
  select p.id, p.nama, p.slug, p.zona_waktu, p.mata_uang,
         coalesce(peng.jam_buka, '') as jam_buka,
         coalesce(peng.cara_pesan, 'kasir') as cara_pesan,
         coalesce(peng.tagline, '') as tagline,
         coalesce(peng.logo_url, '') as logo_url,
         coalesce(peng.banner_url, '') as banner_url
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
      'tagline', v_penyewa.tagline,
      'logo_url', v_penyewa.logo_url,
      'banner_url', v_penyewa.banner_url,
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
  'T8-01 & T9-01: RPC katalog publik untuk pelanggan (tanpa login/anon). Mengembalikan info resto (nama, tagline, logo, banner), menu, harga, foto, jam buka, cabang tanpa membocorkan data sensitif.';

revoke all on function public.katalog_publik(text, uuid) from public;
grant execute on function public.katalog_publik(text, uuid) to anon, authenticated, service_role;
