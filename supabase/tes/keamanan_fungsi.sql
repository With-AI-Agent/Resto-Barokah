-- T1-30: periksa DEFINISI EFEKTIF setelah seluruh migrasi, bukan kemunculan awal
-- CREATE yang mungkin sudah ditimpa. ACL default NULL berarti EXECUTE PUBLIC.
-- Anon boleh diberi hak eksplisit pada RPC katalog; PUBLIC tidak pernah boleh
-- mewariskan akses tak sengaja ke fungsi berhak pemilik.
select uji.harap(
 (select count(*) > 0 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.prosecdef),
 'T130-setup: fungsi istimewa benar-benar ada, bukan sapuan kosong');

select uji.harap(
 not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.prosecdef
    and not coalesce(p.proconfig @> array['search_path=public, pg_temp'],false)
 ),
 'T130-path: semua SECURITY DEFINER wajib search_path terkunci public, pg_temp (bukan komentar)');

select uji.harap(
 not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  cross join lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
  where n.nspname='public' and p.prosecdef
    and a.grantee=0 and a.privilege_type='EXECUTE'
 ),
 'T130-public: semua SECURITY DEFINER wajib mencabut EXECUTE PUBLIC secara efektif');

select uji.harap(
 not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.prosecdef and p.prorettype='trigger'::regtype
    and (has_function_privilege('anon',p.oid,'EXECUTE')
      or has_function_privilege('authenticated',p.oid,'EXECUTE'))
 ),
 'T130-trigger: fungsi trigger istimewa bukan RPC klien');

-- A-F06: fungsi trigger non-definer yang masih punya EXECUTE bukan RPC yang
-- bisa dijalankan. PostgreSQL menolak pemanggilan langsung dengan sebab khas;
-- kunci ini membuktikan reachability, bukan hanya membaca ACL katalog.
select uji.klaim('90000000-0000-0000-0000-000000000004');
set local role authenticated;
select uji.harap_gagal_sebab(
 $$select public.picu_pesanan_status_awal()$$,
 'trigger functions can only be called as triggers',
 'A-F06: fungsi trigger tidak dapat dipanggil sebagai RPC biasa');
reset role;
select uji.klaim(null);
