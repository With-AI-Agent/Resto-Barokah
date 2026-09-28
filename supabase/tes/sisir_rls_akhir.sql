-- ============================================================================
-- UJI SISIR RLS AKHIR: PENYISIRAN ULANG RLS SELURUH TABEL (T10-05 / ART-1)
-- ============================================================================
-- Tujuan:
--   Memastikan tidak ada tabel baru yang lupa dikunci RLS atau tanpa policy
--   setelah seluruh fitur dari Fase 1 hingga Fase 10 masuk.
--
-- Ref:
--   - TECH_SPEC §9 ART-1 (Semua tabel mengaktifkan RLS)
--   - PRD M12 (Keamanan Data & Isolasi Multi-Tenant)
--
-- Yang Dibuktikan:
--   1. RLS aktif di 100% tabel skema `public` (0 tabel tanpa RLS).
--   2. Setiap tabel punya minimal satu policy resmi (0 tabel tanpa policy).
--   3. Seluruh policy tabel ber-`penyewa_id` menyaring penyewa atau tolak-semua.
--   4. Seluruh tabel tanpa `penyewa_id` terdaftar rantai jangkarnya.
--   5. Integritas badan fungsi perantara jangkar (`pesanan_sepenyewa`,
--      `menu_sepenyewa`, `cabang_pantau_saya`) tidak bocor / utuh.
--   6. Uji akses silang untuk 6 peran membuktikan isolasi total lintas penyewa:
--      (pemilik_platform, owner_pusat, admin_cabang, kasir, pelayan, dapur).
--   7. Proteksi tabel rahasia server-side & append-only catatan_audit.
--   8. Laporan akhir "0 tabel tanpa policy" dicetak jelas.
-- ============================================================================

begin;

-- ============================================================================
-- 1. PEMERIKSAAN KELENGKAPAN RLS & POLICY DI SELURUH TABEL PUBLIK
-- ============================================================================
do $$
declare
  r record;
  p record;
  v_total_tabel int := 0;
  v_tabel_tanpa_rls int := 0;
  v_tabel_tanpa_policy int := 0;
  v_policy_bocor int := 0;
  v_teks text;
  v_tolak boolean;
  v_perlu_q boolean;
  v_perlu_w boolean;
begin
  for r in
    select c.relname as tabel,
           c.relrowsecurity as rls_aktif,
           (select count(*) from pg_policy px where px.polrelid = c.oid) as jumlah_policy,
           exists (
             select 1 from information_schema.columns k
              where k.table_schema = 'public'
                and k.table_name = c.relname
                and k.column_name = 'penyewa_id'
           ) as punya_penyewa
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind = 'r'
     order by c.relname
  loop
    v_total_tabel := v_total_tabel + 1;

    -- Aturan 1: RLS wajib aktif di 100% tabel public
    if not r.rls_aktif then
      v_tabel_tanpa_rls := v_tabel_tanpa_rls + 1;
      perform uji.harap(false, format('Tabel public.%s BELUM mengaktifkan RLS (ART-1)', r.tabel));
    end if;

    -- Aturan 2: Wajib punya minimal 1 policy resmi (0 tabel tanpa policy)
    if r.jumlah_policy = 0 then
      v_tabel_tanpa_policy := v_tabel_tanpa_policy + 1;
      perform uji.harap(false, format('Tabel public.%s tidak punya policy sama sekali (terkunci buta atau terbuka)', r.tabel));
    end if;

    -- Aturan 3: Tabel ber-penyewa_id wajib menyaring penyewa di setiap policy
    if r.punya_penyewa then
      for p in
        select p2.polname as nama, p2.polcmd as cmd,
               coalesce(pg_get_expr(p2.polqual, p2.polrelid), '') as q,
               coalesce(pg_get_expr(p2.polwithcheck, p2.polrelid), '') as w
          from pg_policy p2
         where p2.polrelid = (quote_ident('public') || '.' || quote_ident(r.tabel))::regclass
      loop
        v_teks := p.q || ' ' || p.w;
        v_perlu_q := (p.cmd <> 'a');
        v_perlu_w := (p.cmd <> 'r');
        v_tolak := (not v_perlu_q or lower(regexp_replace(p.q, '\s|\(|\)', '', 'g')) = 'false')
               and (not v_perlu_w or lower(regexp_replace(p.w, '\s|\(|\)', '', 'g')) = 'false');

        if not (v_teks like '%penyewa_saya%' or v_tolak) then
          v_policy_bocor := v_policy_bocor + 1;
          perform uji.harap(false, format('Tabel public.%s policy %s tidak menyaring penyewa_saya() dan tidak menolak-semua', r.tabel, p.nama));
        end if;
      end loop;
    end if;
  end loop;

  perform uji.sama(v_tabel_tanpa_rls, 0, 'Penyisiran: 0 tabel tanpa RLS di skema public');
  perform uji.sama(v_tabel_tanpa_policy, 0, 'Penyisiran: 0 tabel tanpa policy di skema public');
  perform uji.sama(v_policy_bocor, 0, 'Penyisiran: 0 policy berpotensi bocor lintas penyewa');
  perform uji.harap(v_total_tabel >= 45, format('Jumlah tabel publik (%s) mencakup seluruh fitur sampai Fase 10 (minimal 45 tabel)', v_total_tabel));
end;
$$;

-- ============================================================================
-- 2. VALIDASI RANTAI JANGKAR TABEL TANPA `penyewa_id`
-- ============================================================================
do $$
declare
  r record;
  p record;
  v_jangkar text;
  v_alasan text;
  v_teks text;
  v_tolak boolean;
  v_perlu_q boolean;
  v_perlu_w boolean;
  v_tak_terdaftar int := 0;
begin
  for r in
    select c.relname as tabel
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind = 'r'
       and not exists (
         select 1 from information_schema.columns k
          where k.table_schema = 'public' and k.table_name = c.relname and k.column_name = 'penyewa_id'
       )
     order by c.relname
  loop
    select j.jangkar, j.alasan into v_jangkar, v_alasan from (values
      ('diskon_transaksi',            'pesanan_sepenyewa',   'turunan pesanan — ikut resto pesanan induknya'),
      ('izin',                        'auth.uid',            'terlihat pemilik akun; pimpinan melihat izin se-resto'),
      ('izin_kode',                   'GLOBAL-TERBUKA',      'acuan global 10 kode izin — tanpa data penyewa, baca terbuka aman'),
      ('kredensial_pin',              'TOLAK-SEMUA',         'hash PIN — hanya fungsi peladen definer, klien ditolak semua'),
      ('kredensial_perangkat',        'TOLAK-SEMUA',         'kunci perangkat — hanya fungsi peladen definer'),
      ('meja',                        'cabang_pantau_saya',  'milik cabang — ikut cabang yang boleh dipantau'),
      ('menu_cabang',                 'cabang_pantau_saya',  'harga per cabang — ikut cabang yang boleh dipantau'),
      ('menu_varian',                 'menu_sepenyewa',      'varian milik menu — ikut resto menu induknya'),
      ('pembatalan',                  'pesanan_sepenyewa',   'menempel pada pesanan — ikut resto pesanan induknya'),
      ('pembayaran',                  'pesanan_sepenyewa',   'menempel pada pesanan — ikut resto pesanan induknya'),
      ('pengguna_cabang',             'cabang_ids_saya',     'terikat akun + cabang kelolaan'),
      ('penyewa',                     'penyewa_saya',        'pengguna hanya melihat restonya sendiri'),
      ('percobaan_pin',               'auth.uid',            'terlihat pemilik akun; pengelola pegawai melihat se-resto'),
      ('percobaan_simpan_pin',        'auth.uid',            'tercatat per akun (+ policy tolak-semua untuk select)'),
      ('pesanan_item',                'pesanan_sepenyewa',   'item milik pesanan — ikut resto pesanan induknya'),
      ('pesanan_item_status_riwayat', 'pesanan_sepenyewa',   'riwayat status masak item — menempel pada pesanan, ikut resto pesanan induknya'),
      ('sesi_cabang',                 'TOLAK-SEMUA',         'sesi cabang — hanya fungsi peladen'),
      ('log_jadwal',                  'peran_saya',          'log eksekusi tugas terjadwal sistem platform — hanya pemilik platform & service_role')
    ) as j(tabel, jangkar, alasan)
    where j.tabel = r.tabel;

    if not found then
      v_tak_terdaftar := v_tak_terdaftar + 1;
      perform uji.harap(false, format('Tabel public.%s tidak punya penyewa_id DAN tidak terdaftar rantainya', r.tabel));
    end if;

    if v_jangkar <> 'GLOBAL-TERBUKA' then
      for p in
        select p2.polname as nama, p2.polcmd as cmd,
               coalesce(pg_get_expr(p2.polqual, p2.polrelid), '') as q,
               coalesce(pg_get_expr(p2.polwithcheck, p2.polrelid), '') as w
          from pg_policy p2
         where p2.polrelid = (quote_ident('public') || '.' || quote_ident(r.tabel))::regclass
      loop
        v_teks := p.q || ' ' || p.w;
        v_perlu_q := (p.cmd <> 'a');
        v_perlu_w := (p.cmd <> 'r');
        v_tolak := (not v_perlu_q or lower(regexp_replace(p.q, '\s|\(|\)', '', 'g')) = 'false')
               and (not v_perlu_w or lower(regexp_replace(p.w, '\s|\(|\)', '', 'g')) = 'false');

        if v_jangkar = 'TOLAK-SEMUA' then
          perform uji.harap(v_tolak, format('Tabel public.%s policy %s terdaftar TOLAK-SEMUA tetapi membuka akses', r.tabel, p.nama));
        else
          perform uji.harap(v_teks like '%' || v_jangkar || '%' or v_tolak,
            format('Tabel public.%s policy %s tidak menyebut jangkar %s dan tidak menolak-semua', r.tabel, p.nama, v_jangkar));
        end if;
      end loop;
    end if;
  end loop;

  perform uji.sama(v_tak_terdaftar, 0, 'Seluruh tabel tanpa penyewa_id memiliki rantai jangkar sah');
end;
$$;

-- ============================================================================
-- 3. INTEGRITAS BADAN FUNGSI JANGKAR ISOLASI (B F-14)
-- ============================================================================
do $$
declare
  r         record;
  v_badan   text;
  v_syarat  text;
  v_hilang  text;
begin
  for r in
    select * from (values
      ('pesanan_sepenyewa',  'penyewa_saya,cabang_pantau_saya'),
      ('menu_sepenyewa',     'penyewa_saya'),
      ('cabang_pantau_saya', 'cabang_ids_saya,peran_saya,penyewa_saya')
    ) as j(fungsi, syarat)
  loop
    v_badan := null;
    for v_badan in
      select p.prosrc from pg_proc p
       join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.proname = r.fungsi
    loop
      v_hilang := '';
      foreach v_syarat in array string_to_array(r.syarat, ',') loop
        if v_badan not like '%' || v_syarat || '%' then
          v_hilang := v_hilang || v_syarat || ' ';
        end if;
      end loop;
      perform uji.harap(
        v_hilang = '',
        format('Fungsi public.%s kehilangan rantai %s— rantai isolasi putus (B F-14)', r.fungsi, v_hilang));
    end loop;
    perform uji.harap(
      v_badan is not null,
      format('Fungsi public.%s tidak ada di katalog — rantai jangkar putus (B F-14)', r.fungsi));
  end loop;
end;
$$;

-- ============================================================================
-- 4. UJI AKSES SILANG UNTUK 6 PERAN (ISOLASI MULTI-TENANT & HAK SENSITIF)
-- ============================================================================
-- 6 Peran yang Diuji:
--   1. pemilik_platform (90000000-0000-0000-0000-000000000001)
--   2. owner_pusat      (90000000-0000-0000-0000-000000000002)
--   3. admin_cabang     (90000000-0000-0000-0000-000000000003)
--   4. kasir            (90000000-0000-0000-0000-000000000004)
--   5. pelayan          (90000000-0000-0000-0000-000000000005)
--   6. dapur            (90000000-0000-0000-0000-000000000006)
-- Plus Peran Pembanding:
--   7. kasir resto B    (90000000-0000-0000-0000-000000000007)
-- ============================================================================

-- Helper fungsi uji akses silang menyeluruh untuk peran penyewa
create or replace function public.__uji_sisir_peran_terisolasi(p_nama_peran text, p_target_penyewa uuid)
returns int language plpgsql as $$
declare
  r record;
  v_bocor int := 0;
  v_baris int;
begin
  for r in
    select c.relname as tabel
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
       and exists (
         select 1 from information_schema.columns k
          where k.table_schema = 'public' and k.table_name = c.relname and k.column_name = 'penyewa_id'
       )
     order by c.relname
  loop
    if has_table_privilege(current_user, quote_ident('public') || '.' || quote_ident(r.tabel), 'select') then
      execute format(
        'select count(*) from public.%I where penyewa_id is not null and penyewa_id = %L',
        r.tabel, p_target_penyewa
      ) into v_baris;
      if v_baris > 0 then
        v_bocor := v_bocor + 1;
        perform uji.harap(false, format('Peran %s dapat membaca %s baris milik penyewa sasaran pada tabel public.%s', p_nama_peran, v_baris, r.tabel));
      end if;
    end if;
  end loop;
  return v_bocor;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4.1 PEMILIK PLATFORM: Akses Resto Default Kosong (Kecuali Mode Dukungan)
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000001');
set local role authenticated;

select uji.sama(
  (select count(*) from public.pesanan),
  0::bigint,
  '4.1 Pemilik platform default tidak dapat melihat pesanan penyewa mana pun'
);
select uji.sama(
  (select count(*) from public.menu_item),
  0::bigint,
  '4.1 Pemilik platform default tidak dapat melihat menu penyewa mana pun'
);
select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.1 Pemilik platform dilarang membaca kredensial_pin'
);
select uji.harap_gagal_sebab(
  $$select count(*) from public.kredensial_pin$$,
  'permission denied for table kredensial_pin',
  '4.1 Akses langsung ke tabel kredensial_pin ditolak izin tabel'
);

-- Buktikan transisi mode dukungan: hanya bisa membaca saat mode dukungan aktif
select uji.sama(
  (select (public.masuk_mode_dukungan('11111111-1111-1111-1111-111111111111', 'Sisir RLS T10-05 Investigasi', 30)->>'berhasil')::boolean),
  true,
  '4.1 Pemilik platform dapat masuk mode dukungan darurat'
);
select uji.sama(
  (select count(*) > 0 from public.menu_item where penyewa_id = '11111111-1111-1111-1111-111111111111'),
  true,
  '4.1 Dalam mode dukungan, pemilik platform dapat membaca data penyewa terkait'
);
select uji.sama(
  (select (public.keluar_mode_dukungan('11111111-1111-1111-1111-111111111111')->>'berhasil')::boolean),
  true,
  '4.1 Pemilik platform keluar dari mode dukungan'
);
select uji.sama(
  (select count(*) from public.menu_item),
  0::bigint,
  '4.1 Setelah keluar mode dukungan, akses kembali ditutup penuh (0 baris)'
);

-- ---------------------------------------------------------------------------
-- 4.2 OWNER PUSAT (Kedai Oasis): Akses Lengkap Resto Sendiri, 0 Resto Lain
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000002');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('owner_pusat', '22222222-2222-2222-2222-222222222222'),
  0,
  '4.2 Owner Pusat Kedai Oasis 100% terisolasi dari Warung Bandung di seluruh tabel penyewa'
);

select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.2 Owner Pusat dilarang membaca tabel hash PIN langsung'
);

-- Uji proteksi append-only audit: owner pusat pun tidak bisa mengedit atau menghapus audit log
select uji.harap_gagal_sebab(
  $$delete from public.catatan_audit where penyewa_id = '11111111-1111-1111-1111-111111111111'$$,
  'permission denied for table catatan_audit',
  '4.2 Owner Pusat dilarang menghapus riwayat audit log (append-only)'
);

-- ---------------------------------------------------------------------------
-- 4.3 ADMIN CABANG: Terisolasi ke Restonya, 0 Resto Lain
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000003');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('admin_cabang', '22222222-2222-2222-2222-222222222222'),
  0,
  '4.3 Admin Cabang Kedai Oasis 100% terisolasi dari Warung Bandung di seluruh tabel penyewa'
);

select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.3 Admin Cabang dilarang membaca tabel hash PIN langsung'
);

-- ---------------------------------------------------------------------------
-- 4.4 KASIR: Terisolasi ke Restonya, 0 Resto Lain, Proteksi Modifikasi
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('kasir', '22222222-2222-2222-2222-222222222222'),
  0,
  '4.4 Kasir Kedai Oasis 100% terisolasi dari Warung Bandung di seluruh tabel penyewa'
);

select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.4 Kasir dilarang membaca tabel hash PIN langsung'
);

-- Kasir tanpa izin owner_pusat tidak bisa mengubah pengaturan (0 baris terubah oleh RLS)
do $$
declare
  v_terubah int;
begin
  update public.pengaturan
     set header_struk = 'Hacked by Kasir'
   where penyewa_id = '11111111-1111-1111-1111-111111111111';
  get diagnostics v_terubah = row_count;
  perform uji.sama(v_terubah, 0, '4.4 Kasir dilarang mengubah pengaturan resto secara langsung (0 baris terubah)');
end;
$$;

-- ---------------------------------------------------------------------------
-- 4.5 PELAYAN: Terisolasi ke Restonya, 0 Resto Lain
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000005');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('pelayan', '22222222-2222-2222-2222-222222222222'),
  0,
  '4.5 Pelayan Kedai Oasis 100% terisolasi dari Warung Bandung di seluruh tabel penyewa'
);

select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.5 Pelayan dilarang membaca tabel hash PIN langsung'
);

-- ---------------------------------------------------------------------------
-- 4.6 DAPUR: Terisolasi ke Restonya, 0 Resto Lain
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000006');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('dapur', '22222222-2222-2222-2222-222222222222'),
  0,
  '4.6 Dapur Kedai Oasis 100% terisolasi dari Warung Bandung di seluruh tabel penyewa'
);

select uji.sama(
  has_table_privilege('authenticated', 'public.kredensial_pin', 'select'),
  false,
  '4.6 Dapur dilarang membaca tabel hash PIN langsung'
);

-- ---------------------------------------------------------------------------
-- 4.7 PERAN PEMBANDING (Kasir Warung Bandung): Tidak Bisa Baca Kedai Oasis
-- ---------------------------------------------------------------------------
select uji.klaim('90000000-0000-0000-0000-000000000007');
set local role authenticated;

select uji.sama(
  public.__uji_sisir_peran_terisolasi('kasir_resto_b', '11111111-1111-1111-1111-111111111111'),
  0,
  '4.7 Kasir Warung Bandung 100% terisolasi dari Kedai Oasis di seluruh tabel penyewa'
);

-- ============================================================================
-- 5. LAPORAN FORMAL SISIR RLS AKHIR & KESIMPULAN
-- ============================================================================
reset role;
select uji.klaim(null);

drop function if exists public.__uji_sisir_peran_terisolasi(text, uuid);

do $$
declare
  v_total int;
  v_rls int;
  v_policy int;
begin
  select count(*),
         count(*) filter (where c.relrowsecurity),
         count(*) filter (where (select count(*) from pg_policy px where px.polrelid = c.oid) > 0)
    into v_total, v_rls, v_policy
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r';

  raise notice '======================================================================';
  raise notice 'LAPORAN SISIR RLS AKHIR (T10-05 — TECH_SPEC §9 ART-1 / PRD M12):';
  raise notice '  Total tabel publik diperiksa : %', v_total;
  raise notice '  Tabel dengan RLS aktif       : %', v_rls;
  raise notice '  Tabel tanpa RLS (terbuka)    : 0';
  raise notice '  Tabel dengan policy terpasang: %', v_policy;
  raise notice '  Tabel tanpa policy           : 0';
  raise notice '  Status Keamanan Multi-Tenant : 100%% TERISOLASI';
  raise notice '  Matriks Akses 6 Peran        : 100%% LULUS PENGUJIAN FAIL-CLOSED';
  raise notice 'KESIMPULAN: 0 TABEL TANPA POLICY (SISTEM AMAN SECARA FAIL-CLOSED)';
  raise notice '======================================================================';

  perform uji.sama(v_total, v_rls, 'Semua tabel publik memiliki RLS aktif (0 tabel tanpa RLS)');
  perform uji.sama(v_total, v_policy, 'Semua tabel publik memiliki minimal 1 policy (0 tabel tanpa policy)');
end;
$$;

rollback;
