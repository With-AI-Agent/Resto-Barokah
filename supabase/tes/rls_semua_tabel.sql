-- ============================================================================
-- UJI MENYELURUH: tidak boleh ada tabel yang lupa dikunci (T1-04, ART-1)
--
-- Uji ini TIDAK menyebut nama tabel satu per satu — ia membaca katalog
-- PostgreSQL. Jadi tabel baru yang ditambahkan di Fase mana pun otomatis
-- diperiksa: kalau lupa mengaktifkan RLS atau lupa membuat policy, uji ini
-- GAGAL dan kiriman kode ditolak CI.
--
-- Tiga hal yang diperiksa:
--   1. RLS aktif di setiap tabel skema `public`.
--   2. Setiap tabel punya minimal satu policy (deny by default bukan berarti
--      tanpa policy — policy-lah yang membuka akses secara sadar).
--   3. Tabel yang punya kolom `penyewa_id` WAJIB punya policy yang menyebut
--      `penyewa_saya()` — bukti tabel itu benar-benar terikat ke satu resto.
-- ============================================================================

do $$
declare
  r       record;
  jumlah  int := 0;
begin
  for r in
    select c.relname                                        as tabel,
           c.relrowsecurity                                 as rls_aktif,
           (select count(*) from pg_policy p where p.polrelid = c.oid) as jumlah_policy,
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
      raise exception 'Tabel public.% belum mengaktifkan RLS (ART-1: wajib di semua tabel)', r.tabel;
    end if;

    if r.jumlah_policy = 0 then
      raise exception 'Tabel public.% tidak punya policy sama sekali — tidak ada yang bisa membacanya, termasuk pemiliknya (wajib ada policy resmi)', r.tabel;
    end if;

    if r.punya_penyewa then
      if not exists (
        select 1
          from pg_policy p
         where p.polrelid = (quote_ident('public') || '.' || quote_ident(r.tabel))::regclass
           and coalesce(pg_get_expr(p.polqual, p.polrelid), '') || ' ' ||
               coalesce(pg_get_expr(p.polwithcheck, p.polrelid), '') like '%penyewa_saya%'
      ) then
        raise exception 'Tabel public.% punya kolom penyewa_id tetapi policy-nya tidak memakai penyewa_saya() — isolasi resto belum terjamin', r.tabel;
      end if;
    end if;
  end loop;

  if jumlah = 0 then
    raise exception 'Tidak ada tabel di skema public — sepertinya migrasi belum diterapkan';
  end if;

  raise notice 'Diperiksa % tabel: semuanya punya RLS + policy.', jumlah;
end
$$;

-- (4) TIMBAL BALIK: tabel TANPA `penyewa_id` wajib punya rantai yang bisa dibuktikan.
-- Menulis `penyewa_saya()` di setiap policy saja tidak cukup: separuh tabel memang tidak
-- menyimpan penyewa_id, dan `periksa.klaim` cakupan RLS sebelum ini hanya memeriksa satu
-- arah — tabel tanpa penyewa_id lolos begitu saja TANPA pembuktian apa pun (temuan audit
-- AUD-3 2026-09-18 F-10: 11 dari 26 tabel punya penyewa_id, 15 tidak, dan tidak ada yang
-- memeriksa rantai 15 tabel itu).
--
-- Aturan: setiap tabel tanpa penyewa_id WAJIB terdaftar di bawah ini dengan jangkarnya,
-- dan jangkar itu benar-benar muncul di policy-nya. Tabel baru yang muncul tanpa didaftarkan
-- (atau tabel terdaftar yang policy-nya kehilangan jangkarnya) membuat uji ini GAGAL.
do $$
declare
  r          record;
  v_jangkar  text;
  v_ekspresi text;
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
    v_jangkar := (
      select j.jangkar from (values
        ('diskon_transaksi',     'pesanan_sepenyewa'),
        ('izin',                 'auth.uid'),
        ('izin_kode',            '-'),
        ('kredensial_pin',       '-'),
        ('kredensial_perangkat', '-'),
        ('meja',                 'cabang_pantau_saya'),
        ('menu_cabang',          'cabang_pantau_saya'),
        ('menu_varian',          'menu_sepenyewa'),
        ('pembatalan',           'pesanan_sepenyewa'),
        ('pembayaran',           'pesanan_sepenyewa'),
        ('pengguna_cabang',      'cabang_ids_saya'),
        ('penyewa',              'penyewa_saya'),
        ('percobaan_pin',        'auth.uid'),
        ('percobaan_simpan_pin', 'auth.uid'),
        ('pesanan_item',         'pesanan_sepenyewa'),
        ('sesi_cabang',          '-')
      ) as j(tabel, jangkar)
      where j.tabel = r.tabel
    );

    if v_jangkar is null then
      raise exception 'Tabel public.% tidak punya penyewa_id DAN tidak terdaftar rantainya. Tambahkan penyewa_id, atau daftarkan tabel + jangkarnya di dokumen ini lengkap dengan alasannya (F-10).', r.tabel;
    end if;

    if v_jangkar <> '-' then
      select string_agg(coalesce(pg_get_expr(p.polqual, p.polrelid), '') || ' ' ||
                        coalesce(pg_get_expr(p.polwithcheck, p.polrelid), ''), ' ')
        into v_ekspresi
        from pg_policy p
       where p.polrelid = (quote_ident('public') || '.' || quote_ident(r.tabel))::regclass;

      if coalesce(v_ekspresi, '') not like '%' || v_jangkar || '%' then
        raise exception 'Tabel public.% terdaftar berjangkarkan % tetapi policy-nya tidak memakai jangkar itu — pembuktian rantainya hilang (F-10).', r.tabel, v_jangkar;
      end if;
    end if;

    raise notice 'tabel tanpa penyewa_id: % → jangkar %', r.tabel, v_jangkar;
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
