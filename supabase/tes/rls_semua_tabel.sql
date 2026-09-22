-- ============================================================================
-- UJI MENYELURUH: tidak boleh ada tabel yang lupa dikunci (T1-04, ART-1)
--
-- Uji ini TIDAK menyebut nama tabel satu per satu — ia membaca katalog
-- PostgreSQL. Jadi tabel baru yang ditambahkan di Fase mana pun otomatis
-- diperiksa: kalau lupa mengaktifkan RLS atau lupa membuat policy, uji ini
-- GAGAL dan kiriman kode ditolak CI.
--
-- Enam hal yang diperiksa:
--   1. RLS aktif di setiap tabel skema `public`.
--   2. Setiap tabel punya minimal satu policy (deny by default bukan berarti
--      tanpa policy — policy-lah yang membuka akses secara sadar).
--   3. SETIAP policy tabel ber-`penyewa_id` menyebut `penyewa_saya()` — kecuali policy
--      yang menolak-semua (B F-14: policy PERMISSIVE digabung OR, jadi satu policy
--      longgar menggugurkan semua policy ketat).
--   4. Tabel TANPA `penyewa_id` terdaftar dengan jangkar + alasannya, dan SETIAP
--      policy-nya menyebut jangkar itu (atau menolak-semua); jangkar `-` lama dipecah
--      jadi `TOLAK-SEMUA` (semua policy wajib menolak) dan `GLOBAL-TERBUKA` (terbuka
--      sadar + alasan, mis. acuan global).
--   5. Perilaku: kasir tak bisa melihat baris resto lain di tabel ber-`penyewa_id`.
--   6. Rantai jangkar: badan fungsi perantara (`pesanan_sepenyewa`, `menu_sepenyewa`,
--      `cabang_pantau_saya`) WAJIB menyebut sebutan yang terdaftar — policy yang
--      menyebut fungsi cangkang-kosong akan tertangkap di sini (B F-14).
--
-- Blok 3, 4, 6 memakai `uji.harap` (bukan `raise` langsung) supaya kegagalannya membawa
-- token asersi — syarat bukti pagar oleh `alat/uji-mutasi-0009.py` (klasifikasi menolak
-- merah tanpa token asersi sebagai "salinan rusak", bukan bukti).
-- Batasan jujur: policy RESTRICTIVE tanpa jangkar akan ditolak (belum pernah ada — kalau
-- muncul dan sah, daftarkan pengecualiannya di sini, jangan melemahkan aturannya).
-- ============================================================================

do $$
declare
  r       record;
  p       record;
  jumlah  int := 0;
  v_teks     text;
  v_tolak    boolean;
  v_perlu_q  boolean;
  v_perlu_w  boolean;
begin
  for r in
    select c.relname                                        as tabel,
           c.relrowsecurity                                 as rls_aktif,
           (select count(*) from pg_policy px where px.polrelid = c.oid) as jumlah_policy,
           exists (
             select 1 from information_schema.columns k
              where k.table_schema = 'public'
                and k.table_name = c.relname
                and k.column_name = 'penyewa_id'
           )                                                as punya_penyewa
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind = 'r'
     order by c.relname
  loop
    jumlah := jumlah + 1;
    raise notice 'tabel % : RLS=% policy=% penyewa_id=%', r.tabel, r.rls_aktif, r.jumlah_policy, r.punya_penyewa;

    if not r.rls_aktif then
      perform uji.harap(false, format('Tabel public.%s belum mengaktifkan RLS (ART-1: wajib di semua tabel)', r.tabel));
    end if;

    if r.jumlah_policy = 0 then
      perform uji.harap(false, format('Tabel public.%s tidak punya policy sama sekali — tidak ada yang bisa membacanya, termasuk pemiliknya (wajib ada policy resmi)', r.tabel));
    end if;

    if r.punya_penyewa then
      -- B F-14: SETIAP policy (bukan "ada satu") wajib menyebut penyewa_saya(),
      -- kecuali policy yang menolak-semua (tak memberi apa pun → tak bisa bocor).
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
        perform uji.harap(
          v_teks like '%penyewa_saya%' or v_tolak,
          format('Tabel public.%s policy %s tidak menyebut penyewa_saya() dan tidak menolak-semua (B F-14)', r.tabel, p.nama));
      end loop;
    end if;
  end loop;

  if jumlah = 0 then
    raise exception 'Tidak ada tabel di skema public — sepertinya migrasi belum diterapkan';
  end if;

  raise notice 'Diperiksa % tabel: semuanya punya RLS + policy.', jumlah;
end
$$;

-- (4) TIMBAL BALIK: tabel TANPA `penyewa_id` wajib punya rantai yang bisa dibuktikan.
-- (asal: F-10 2026-09-18; diperketat B F-14 2026-09-21: dulu "ada policy menyebut jangkar"
-- sudah cukup — sekarang SETIAP policy, dan `-` dipecah eksplisit.)
-- Aturan: setiap tabel tanpa penyewa_id WAJIB terdaftar di bawah ini dengan jangkar +
-- alasannya. Jangkar boleh:
--   - nama fungsi/teks (`pesanan_sepenyewa`, `auth.uid`, ...): SETIAP policy wajib
--     menyebutnya, kecuali policy yang menolak-semua;
--   - `TOLAK-SEMUA`: SETIAP policy wajib menolak-semua (tak ada yang dibuka ke klien);
--   - `GLOBAL-TERBUKA`: terbuka sadar + alasan (acuan global tanpa data penyewa).
-- Tabel baru tanpa penyewa_id yang muncul tanpa didaftarkan membuat uji ini GAGAL.
-- (Menambah kolom penyewa_id ke tabel terdaftar OTOMATIS memindahkannya ke blok (3).)
do $$
declare
  r          record;
  p          record;
  v_jangkar  text;
  v_alasan   text;
  v_teks     text;
  v_tolak    boolean;
  v_perlu_q  boolean;
  v_perlu_w  boolean;
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
      ('diskon_transaksi',     'pesanan_sepenyewa',   'turunan pesanan — ikut resto pesanan induknya'),
      ('izin',                 'auth.uid',            'terlihat pemilik akun; pimpinan melihat izin se-resto'),
      ('izin_kode',            'GLOBAL-TERBUKA',      'acuan global 10 kode izin — tanpa data penyewa, baca terbuka aman'),
      ('kredensial_pin',       'TOLAK-SEMUA',         'hash PIN — hanya fungsi peladen, klien ditolak semua'),
      ('kredensial_perangkat', 'TOLAK-SEMUA',         'kunci perangkat — hanya fungsi peladen'),
      ('meja',                 'cabang_pantau_saya',  'milik cabang — ikut cabang yang boleh dipantau'),
      ('menu_cabang',          'cabang_pantau_saya',  'harga per cabang — ikut cabang yang boleh dipantau'),
      ('menu_varian',          'menu_sepenyewa',      'varian milik menu — ikut resto menu induknya'),
      ('pembatalan',           'pesanan_sepenyewa',   'menempel pada pesanan — ikut resto pesanan induknya'),
      ('pembayaran',           'pesanan_sepenyewa',   'menempel pada pesanan — ikut resto pesanan induknya'),
      ('pengguna_cabang',      'cabang_ids_saya',     'terikat akun + cabang kelolaan'),
      ('penyewa',              'penyewa_saya',        'pengguna hanya melihat restonya sendiri'),
      ('percobaan_pin',        'auth.uid',            'terlihat pemilik akun; pengelola pegawai melihat se-resto'),
      ('percobaan_simpan_pin', 'auth.uid',            'tercatat per akun (+ policy tolak-semua untuk select)'),
      ('pesanan_item',         'pesanan_sepenyewa',   'item milik pesanan — ikut resto pesanan induknya'),
      ('pesanan_item_status_riwayat', 'pesanan_sepenyewa', 'riwayat status masak item (T4-04) — menempel pada pesanan, ikut resto pesanan induknya'),
      ('sesi_cabang',          'TOLAK-SEMUA',         'sesi cabang — hanya fungsi peladen')
    ) as j(tabel, jangkar, alasan)
    where j.tabel = r.tabel;

    if not found then
      perform uji.harap(false, format('Tabel public.%s tidak punya penyewa_id DAN tidak terdaftar rantainya. Tambahkan penyewa_id, atau daftarkan tabel + jangkar + alasannya di dokumen ini (F-10).', r.tabel));
    end if;

    perform uji.harap(
      v_alasan is not null and v_alasan <> '',
      format('Tabel public.%s terdaftar tanpa alasan — tulis kenapa jangkar %s cukup (F-10).', r.tabel, v_jangkar));

    if v_jangkar = 'GLOBAL-TERBUKA' then
      raise notice 'tabel tanpa penyewa_id: % → GLOBAL-TERBUKA (%)', r.tabel, v_alasan;
      continue;
    end if;

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
        perform uji.harap(
          v_tolak,
          format('Tabel public.%s policy %s terdaftar TOLAK-SEMUA tetapi membuka akses (B F-14)', r.tabel, p.nama));
      else
        perform uji.harap(
          v_teks like '%' || v_jangkar || '%' or v_tolak,
          format('Tabel public.%s policy %s tidak menyebut jangkar %s dan tidak menolak-semua (B F-14)', r.tabel, p.nama, v_jangkar));
      end if;
    end loop;

    raise notice 'tabel tanpa penyewa_id: % → jangkar % (%)', r.tabel, v_jangkar, v_alasan;
  end loop;
end
$$;

-- Uji tambahan: pengguna yang sudah masuk tidak boleh melihat baris tabel
-- apa pun milik resto lain. Diperiksa dengan menghitung baris yang terlihat
-- oleh kasir Kedai Oasis pada setiap tabel yang punya kolom penyewa_id.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;

do $$
declare
  r     record;
  salah int;
begin
  for r in
    select c.relname as tabel
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public'
       and c.relkind = 'r'
       and exists (
         select 1 from information_schema.columns k
          where k.table_schema = 'public'
            and k.table_name = c.relname
            and k.column_name = 'penyewa_id'
       )
     order by c.relname
  loop
    execute format(
      'select count(*) from public.%I where penyewa_id is not null and penyewa_id <> public.penyewa_saya()',
      r.tabel
    ) into salah;
    if salah > 0 then
      raise exception 'Tabel public.% membocorkan % baris milik resto lain', r.tabel, salah;
    end if;
  end loop;
end
$$;

reset role;
select uji.klaim(null);

-- (6) RANTAI JANGKAR: badan fungsi perantara WAJIB menyebut sebutan terdaftar (B F-14).
-- Policy boleh menyebut `pesanan_sepenyewa`, tetapi kalau badan fungsi itu kehilangan
-- saringannya, policy-nya jadi cangkang kosong — dan blok (4) yang hanya membaca teks policy
-- tidak akan menyalak. Blok ini membaca badan fungsi dari katalog (`pg_proc.prosrc`) dan
-- menuntut SETIAP sebutan yang terdaftar (bukan "salah satu" — mutasi yang membuang
-- `cabang_pantau_saya` dari `pesanan_sepenyewa` WAJIB membuat berkas ini GAGAL).
-- Akar tepercaya (aksioma — badannya tak diperiksa di sini, dijaga uji perilaku blok (5)
-- + serangan S-20): `penyewa_saya`, `cabang_ids_saya`, `peran_saya`, `auth.uid`.
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
        format('Fungsi public.%s kehilangan sebutan %s— rantai isolasi putus (B F-14)', r.fungsi, v_hilang));
    end loop;
    perform uji.harap(
      v_badan is not null,
      format('Fungsi public.%s tidak ada di katalog — rantai jangkar putus (B F-14)', r.fungsi));
  end loop;
end
$$;
