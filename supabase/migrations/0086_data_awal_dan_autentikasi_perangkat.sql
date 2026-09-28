-- ============================================================================
-- MIGRASI 0086 — Data Awal Percontohan & Resolusi Autentikasi Perangkat Mandiri
--
-- Referensi Masalah Lapangan:
--   - Lee mengalami galat [AK-601] saat mencoba login staf/owner di produksi.
--   - Akar masalah 1: Peramban baru klien menghasilkan UUID acak yang belum terdaftar
--     di tabel public.perangkat, menciptakan kebuntuan (chicken-and-egg):
--     Owner tidak bisa login sebelum mendaftarkan perangkat, dan tidak bisa
--     mendaftarkan perangkat sebelum login ke menu Pengaturan.
--   - Akar masalah 2: Lingkungan produksi Supabase belum memiliki data awal percontohan
--     (penyewa, cabang, akun staf @resto.test, kategori menu, item menu, dan meja).
--
-- Solusi Terpadu:
--   1. Mutakhirkan RPC public.verifikasi_pin_perangkat:
--      Bila perangkat belum ada (v_perangkat.id is null) dan pengguna adalah:
--        a. Pemilik resto (owner_pusat) / Pemilik platform
--        b. Akun percontohan resto (@resto.test)
--        c. Restoran yang belum memiliki satupun perangkat aktif terdaftar
--      -> Perangkat didaftarkan otomatis secara mandiri (self-provisioning) dengan
--         izin peran penuh untuk cabang utama restoran.
--      -> Perangkat yang dicabut (aktif = false) TETAP DITOLAK seketika (PERANGKAT_TIDAK_SAH).
--   2. Menyediakan seed data lengkap dan idempoten:
--      Penyewa Kedai Oasis, Cabang Utama, Pengaturan Resto, Akun Staf (Owner, Kasir, Dapur, Pelayan)
--      dengan PIN 123456, Kategori & Menu Kuliner Indonesia, dan Meja Cabang.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Pembaruan RPC verifikasi_pin_perangkat
-- ---------------------------------------------------------------------------
create or replace function public.verifikasi_pin_perangkat(
  p_email           text,
  p_pin             text,
  p_perangkat_id    uuid default null,
  p_perangkat_nama  text default null,
  p_kunci_perangkat text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_pengguna       record;
  v_perangkat      record;
  v_kunci_hash     text;
  v_hash           text;
  v_gagal_akun     int;
  v_gagal_alat     int;
  v_cabang_ids     uuid[];
  v_cabang_utama   uuid;
  v_berhasil       boolean;
  v_jumlah_alat    int;
begin
  if p_email is null or trim(p_email) = '' or p_pin is null or trim(p_pin) = '' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'INPUT_TIDAK_LENGKAP',
      'pesan', 'Email dan PIN wajib diisi.'
    );
  end if;

  -- 1. Validasi format PIN (wajib 6 angka)
  if p_pin !~ '^\d{6}$' then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'FORMAT_PIN_SALAH',
      'pesan', 'PIN harus berupa 6 digit angka.'
    );
  end if;

  -- 2. Validasi perangkat wajib diisi
  if p_perangkat_id is null then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_WAJIB',
      'pesan', 'Perangkat kasir/staf wajib terdaftar untuk mengakses sistem.'
    );
  end if;

  -- Periksa keberadaan perangkat
  select id, nama, aktif, penyewa_id, peran_diizinkan
    into v_perangkat
    from public.perangkat
   where id = p_perangkat_id;

  -- Jika perangkat sudah pernah didaftarkan namun dinonaktifkan/dicabut -> tolak
  if v_perangkat.id is not null and not coalesce(v_perangkat.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERANGKAT_TIDAK_SAH',
      'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
    );
  end if;

  -- 3. Cari data pengguna berdasarkan email
  select p.id, p.penyewa_id, p.nama, p.peran, p.aktif
    into v_pengguna
    from public.pengguna p
   where lower(trim(p.email)) = lower(trim(p_email));

  if v_pengguna.id is null or not coalesce(v_pengguna.aktif, false) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 4. Pembatasan brute-force (5x per akun / 12x per perangkat per 15 menit)
  select count(*) into v_gagal_akun
    from public.percobaan_pin pp
   where pp.pengguna_id = v_pengguna.id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  select count(*) into v_gagal_alat
    from public.percobaan_pin pp
   where pp.perangkat_id = p_perangkat_id
     and not pp.berhasil
     and pp.waktu > now() - interval '15 minutes';

  if v_gagal_akun >= 5 or v_gagal_alat >= 12 then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'AKUN_TERKUNCI',
      'pesan', 'Akun atau perangkat terkunci sementara karena 5 kali percobaan salah. Tunggu 15 menit.'
    );
  end if;

  -- 5. Periksa kecocokan hash PIN
  select pin_hash into v_hash
    from public.kredensial_pin
   where pengguna_id = v_pengguna.id;

  v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;

  if not v_berhasil then
    insert into public.percobaan_pin (
      pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
    ) values (
      v_pengguna.id,
      coalesce(v_perangkat.nama, coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat Baru')),
      false,
      'masuk_pin',
      v_pengguna.id,
      p_perangkat_id,
      now()
    );

    return jsonb_build_object(
      'berhasil', false,
      'kode', 'KREDENSIAL_TIDAK_VALID',
      'pesan', 'Email, PIN, atau perangkat tidak cocok.'
    );
  end if;

  -- 6. Pendaftaran mandiri perangkat (self-provisioning) jika belum terdaftar
  if v_perangkat.id is null then
    select count(*) into v_jumlah_alat
      from public.perangkat
     where penyewa_id = v_pengguna.penyewa_id
       and aktif = true;

    if v_pengguna.peran in ('owner_pusat', 'pemilik_platform')
       or lower(trim(p_email)) like '%@resto.test'
       or v_jumlah_alat = 0 then

      select id into v_cabang_utama
        from public.cabang
       where penyewa_id = v_pengguna.penyewa_id
       order by created_at asc limit 1;

      insert into public.perangkat (
        id,
        penyewa_id,
        cabang_id,
        nama,
        peran_diizinkan,
        aktif,
        didaftarkan_oleh,
        status
      ) values (
        p_perangkat_id,
        v_pengguna.penyewa_id,
        v_cabang_utama,
        coalesce(nullif(trim(p_perangkat_nama), ''), 'Perangkat ' || initcap(replace(v_pengguna.peran::text, '_', ' '))),
        array['owner_pusat', 'admin_cabang', 'kasir', 'dapur', 'pelayan']::text[],
        true,
        v_pengguna.id,
        'aktif'
      )
      on conflict (id) do update set
        aktif = true,
        status = 'aktif',
        terakhir_aktif = now();

      select id, nama, aktif, penyewa_id, peran_diizinkan
        into v_perangkat
        from public.perangkat
       where id = p_perangkat_id;
    else
      -- Restoran telah beroperasi dan staf biasa mencoba masuk dari perangkat tak dikenal
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Perangkat tidak terdaftar atau telah dicabut.'
      );
    end if;
  end if;

  -- 7. Validasi relasi tenant & peran terhadap perangkat
  if v_perangkat.penyewa_id <> v_pengguna.penyewa_id then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'RESTO_TIDAK_COCOK',
      'pesan', 'Perangkat tidak terdaftar pada restoran ini.'
    );
  end if;

  if not (v_pengguna.peran::text = any(v_perangkat.peran_diizinkan)) then
    return jsonb_build_object(
      'berhasil', false,
      'kode', 'PERAN_TIDAK_DIIZINKAN',
      'pesan', 'Peran pengguna tidak diizinkan pada perangkat ini.'
    );
  end if;

  -- 8. Verifikasi kunci token rahasia perangkat bila terdaftar
  if p_kunci_perangkat is not null and exists (
    select 1 from public.kredensial_perangkat kp where kp.perangkat_id = p_perangkat_id
  ) then
    select kp.kunci_hash into v_kunci_hash
      from public.kredensial_perangkat kp
     where kp.perangkat_id = p_perangkat_id;

    if v_kunci_hash is not null and crypt(p_kunci_perangkat, v_kunci_hash) <> v_kunci_hash then
      return jsonb_build_object(
        'berhasil', false,
        'kode', 'PERANGKAT_TIDAK_SAH',
        'pesan', 'Kunci token rahasia perangkat tidak cocok.'
      );
    end if;
  end if;

  -- 9. Catat percobaan berhasil dan perbarui status perangkat
  insert into public.percobaan_pin (
    pengguna_id, perangkat, berhasil, aksi, pemanggil_id, perangkat_id, waktu
  ) values (
    v_pengguna.id, v_perangkat.nama, true, 'masuk_pin', v_pengguna.id, p_perangkat_id, now()
  );

  update public.perangkat
     set terakhir_aktif = now()
   where id = v_perangkat.id;

  -- 10. Ambil daftar cabang pengguna
  select coalesce(array_agg(cabang_id), array[]::uuid[])
    into v_cabang_ids
    from public.pengguna_cabang
   where pengguna_id = v_pengguna.id
     and aktif;

  return jsonb_build_object(
    'berhasil', true,
    'kode', 'LOGIN_SUKSES',
    'pesan', 'Login dengan PIN berhasil.',
    'data', jsonb_build_object(
      'pengguna_id', v_pengguna.id,
      'nama', v_pengguna.nama,
      'peran', v_pengguna.peran,
      'penyewa_id', v_pengguna.penyewa_id,
      'cabang_ids', v_cabang_ids,
      'perangkat_id', v_perangkat.id
    )
  );
end;
$$;

comment on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) is
  'Verifikasi PIN staf saat login dari perangkat terdaftar dengan registrasi mandiri untuk Owner/Demo (T2-02, T11-01, ART-12).';

revoke all on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) from public;
grant execute on function public.verifikasi_pin_perangkat(text, text, uuid, text, text) to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Data Awal Percontohan (Seed Data Idempoten untuk Produksi)
-- ---------------------------------------------------------------------------
-- Catatan: Blok ini dieksekusi hanya di lingkungan nyata (Supabase produksi),
-- dan dilewati saat pengujian lokal PGlite (karena skema 'uji' ada dan data-uji.sql
-- yang menyediakan data uji khusus).
do $$
declare
  v_salt text;
  v_hash text;
  v_users record;
begin
  if not exists (select 1 from pg_namespace where nspname = 'uji') then
    -- 1. Penyewa Kedai Oasis
    insert into public.penyewa (id, nama, slug, zona_waktu, status)
    values (
      '11111111-1111-1111-1111-111111111111',
      'Kedai Oasis',
      'oasis',
      'Asia/Jakarta',
      'aktif'
    )
    on conflict (id) do update set status = 'aktif';

    -- 2. Cabang Utama
    insert into public.cabang (id, penyewa_id, nama, alamat, telepon, aktif)
    values (
      'a1a1a1a1-0000-0000-0000-000000000001',
      '11111111-1111-1111-1111-111111111111',
      'Cabang Utama',
      'Jl. Merdeka No. 45 Bandung',
      '081234567890',
      true
    )
    on conflict (id) do update set aktif = true;

    -- 3. Pengaturan Restoran
    insert into public.pengaturan (
      penyewa_id,
      tagline,
      pajak_pb1_persen,
      service_persen,
      header_struk,
      footer_struk,
      cara_pesan,
      jam_buka
    ) values (
      '11111111-1111-1111-1111-111111111111',
      'Sajian Lezat Penuh Berkah',
      10,
      0,
      'Kedai Oasis - Cabang Utama\nJl. Merdeka No. 45 Bandung',
      'Terima kasih atas kunjungan Anda!\nSemoga berkah dan nikmat.',
      'campur',
      '08:00 - 22:00'
    )
    on conflict (penyewa_id) do update set
      tagline = excluded.tagline,
      header_struk = excluded.header_struk,
      footer_struk = excluded.footer_struk,
      jam_buka = excluded.jam_buka;

    -- 4. Pengguna Staf & PIN 123456
    v_salt := gen_salt('bf', 10);
    v_hash := crypt('123456', v_salt);

    for v_users in (
      select * from (
        values
          ('91000000-0000-0000-0000-000000000001'::uuid, 'owner@resto.test', 'Lee - Pemilik Resto', 'owner_pusat'),
          ('91000000-0000-0000-0000-000000000002'::uuid, 'kasir@resto.test', 'Siti - Kasir Utama', 'kasir'),
          ('91000000-0000-0000-0000-000000000003'::uuid, 'dapur@resto.test', 'Budi - Kepala Dapur', 'dapur'),
          ('91000000-0000-0000-0000-000000000004'::uuid, 'pelayan@resto.test', 'Andi - Pramusaji', 'pelayan')
      ) as t(id, email, nama, peran)
    ) loop
      if not exists (select 1 from auth.users where id = v_users.id) then
        insert into auth.users (id, email) values (v_users.id, v_users.email);
      end if;

      insert into public.pengguna (id, penyewa_id, nama, email, peran, aktif)
      values (
        v_users.id,
        '11111111-1111-1111-1111-111111111111',
        v_users.nama,
        v_users.email,
        v_users.peran,
        true
      )
      on conflict (id) do update set
        nama = excluded.nama,
        email = excluded.email,
        peran = excluded.peran,
        aktif = true;

      insert into public.kredensial_pin (pengguna_id, pin_hash, diubah_pada)
      values (v_users.id, v_hash, now())
      on conflict (pengguna_id) do update set
        pin_hash = excluded.pin_hash,
        diubah_pada = now();

      insert into public.pengguna_cabang (pengguna_id, cabang_id, aktif)
      values (v_users.id, 'a1a1a1a1-0000-0000-0000-000000000001', true)
      on conflict (pengguna_id, cabang_id) do update set aktif = true;
    end loop;

    insert into public.izin (pengguna_id, kode_izin, boleh)
    values
      ('91000000-0000-0000-0000-000000000001', 'lihat_laporan', true),
      ('91000000-0000-0000-0000-000000000001', 'atur_pengaturan', true),
      ('91000000-0000-0000-0000-000000000001', 'kelola_pegawai', true),
      ('91000000-0000-0000-0000-000000000002', 'beri_diskon', true),
      ('91000000-0000-0000-0000-000000000002', 'pakai_voucher', true),
      ('91000000-0000-0000-0000-000000000002', 'tutup_kas', true)
    on conflict (pengguna_id, kode_izin) do update set boleh = excluded.boleh;

    -- 5. Kategori Menu
    insert into public.kategori_menu (id, penyewa_id, nama, urutan, aktif)
    values
      ('ca000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Makanan Utama', 1, true),
      ('ca000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'Minuman Segar', 2, true),
      ('ca000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'Camilan & Penutup', 3, true)
    on conflict (id) do update set
      nama = excluded.nama,
      urutan = excluded.urutan,
      aktif = true;

    -- 6. Menu Kuliner Indonesia
    insert into public.menu_item (
      id, penyewa_id, kategori_id, nama, deskripsi, harga, urutan, unggulan, jenis, aktif
    ) values
      (
        'ba000000-0000-0000-0000-000000000001',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000001',
        'Nasi Goreng Spesial',
        'Nasi goreng gurih dengan telur mata sapi, suwiran ayam kampung, dan kerupuk renyah.',
        28000,
        1,
        true,
        'makanan',
        true
      ),
      (
        'ba000000-0000-0000-0000-000000000002',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000001',
        'Ayam Bakar Madu',
        'Potongan ayam marinasi rempah pilihan dibakar dengan olesan madu murni dan sambal bajak.',
        32000,
        2,
        true,
        'makanan',
        true
      ),
      (
        'ba000000-0000-0000-0000-000000000003',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000001',
        'Mie Goreng Jawa',
        'Mie pipih goreng dengan bumbu khas tradisional, kubis segar, daun bawang, dan acar.',
        25000,
        3,
        false,
        'makanan',
        true
      ),
      (
        'ba000000-0000-0000-0000-000000000004',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000002',
        'Es Teh Manis',
        'Seduhan teh melati wangi dengan gula asli, disajikan dingin menyegarkan dahaga.',
        6000,
        1,
        false,
        'minuman',
        true
      ),
      (
        'ba000000-0000-0000-0000-000000000005',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000002',
        'Kopi Susu Gula Aren',
        'Espresso house-blend dipadukan dengan susu segar dan manis legit gula aren organik.',
        18000,
        2,
        true,
        'minuman',
        true
      ),
      (
        'ba000000-0000-0000-0000-000000000006',
        '11111111-1111-1111-1111-111111111111',
        'ca000000-0000-0000-0000-000000000003',
        'Pisang Goreng Keju',
        'Pisang kepok goreng krispi dengan taburan keju cheddar parut dan susu kental manis.',
        15000,
        1,
        false,
        'lainnya',
        true
      )
    on conflict (id) do update set
      nama = excluded.nama,
      deskripsi = excluded.deskripsi,
      harga = excluded.harga,
      unggulan = excluded.unggulan,
      jenis = excluded.jenis,
      aktif = true;

    -- 7. Varian Menu
    insert into public.menu_varian (menu_item_id, nama, tambahan_harga, aktif)
    values
      ('ba000000-0000-0000-0000-000000000001', 'Pedas Sedang', 0, true),
      ('ba000000-0000-0000-0000-000000000001', 'Ekstra Pedas', 2000, true),
      ('ba000000-0000-0000-0000-000000000005', 'Dingin (Ice)', 0, true),
      ('ba000000-0000-0000-0000-000000000005', 'Hangat (Hot)', 0, true)
    on conflict (menu_item_id, nama) do update set
      tambahan_harga = excluded.tambahan_harga,
      aktif = true;

    -- 8. Meja Restoran Cabang Utama
    insert into public.meja (cabang_id, nama, area, status, aktif)
    values
      ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 01', 'Indoor', 'kosong', true),
      ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 02', 'Indoor', 'kosong', true),
      ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 03', 'Indoor', 'kosong', true),
      ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 04', 'Outdoor', 'kosong', true),
      ('a1a1a1a1-0000-0000-0000-000000000001', 'Meja 05', 'Outdoor', 'kosong', true),
      ('a1a1a1a1-0000-0000-0000-000000000001', 'VIP 01', 'Lantai 2', 'kosong', true)
    on conflict (cabang_id, nama) do update set
      area = excluded.area,
      status = excluded.status,
      aktif = true;

  end if;
end
$$;
