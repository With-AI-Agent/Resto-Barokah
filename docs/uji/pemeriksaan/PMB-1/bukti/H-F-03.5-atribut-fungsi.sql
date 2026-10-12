-- Pembaca HAKIM H-F-03.5 (2026-10-02) — atribut fungsi pemicu kunci identitas dan kembarannya, dibaca dari pg_proc.
-- BERKAS INI SENGAJA BERAKHIR GAGAL: runner hanya mencetak baris pertama pesan galat, jadi hasil dikirim lewat
-- `uji.harap(false, ...)`. Yang dibaca adalah isi pesannya. Dijalankan pada dua pohon oleh H-F-03.5-atribut-fungsi.sh.
-- Kolom: secdef = SECURITY DEFINER; config = setelan fungsi (search_path); volatility i = immutable, v = volatile;
-- acl = hak eksekusi (default PUBLIC bila kosong).
select uji.harap(false, 'PGPROC ' || (
  select string_agg(proname || ' secdef=' || prosecdef::text || ' config=' || coalesce(proconfig::text, '-')
                    || ' volatility=' || provolatile::text || ' acl=' || coalesce(proacl::text, '(default:PUBLIC exec)'), E' ;; ' order by proname)
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and proname in ('picu_pelanggan_kunci_identitas', 'normalisasi_telepon_pelanggan',
                     'picu_pelanggan_validasi_email', 'normalisasi_email')
));
