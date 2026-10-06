-- ============================================================================
-- MIGRASI 0103 — PMB1-F-072 (K-3): peringatan "perangkat berkuasa tinggal 1"
-- ============================================================================
-- Baseline yang dilanggar: `docs/KEAMANAN.md` §4 (keputusan pemilik: setiap peran
-- berkuasa — `owner_pusat`, `admin_cabang` — minimal 2 perangkat terdaftar; aplikasi
-- memperingatkan bila tinggal satu) dan §14 (matriks uji: "Peringatan perangkat
-- berkuasa tinggal 1", T1-36 + T10-13). Sebelum migrasi ini tidak ada satu pun
-- kode yang menghitung perangkat aktif per peran berkuasa (`grep -rniE
-- "perangkat_berkuasa|tinggal (satu|1)|minimal 2 perangkat"` → 0 di supabase/,
-- aplikasi/src/, docs/ops/).
--
-- Yang dibangun:
--   * RPC `hitung_perangkat_berkuasa()` — satu baris per peran berkuasa
--     (owner_pusat, admin_cabang) berisi jumlah perangkat AKTIF milik penyewa
--     pemanggil yang mengizinkan peran itu, plus penanda `cadangan_cukup`
--     (true bila >= 2). Layar peringatan tinggal membandingkan penanda ini.
--   * Penghitung menghitung per TENANT (perangkat boleh melayani semua cabang
--     resto); perangkat tidak aktif (dicabut/hilang) tidak dihitung.
--
-- Pola fondasi (wajib ART): SECURITY DEFINER + search_path dipaku + revoke
-- execute from public + grant hanya authenticated/service_role; pemeriksaan
-- penyewa + izin DI DALAM badan fungsi (pola 0052 laporan_penjualan).
-- Uji pengunci: `supabase/tes/perangkat_berkuasa.sql`.
-- RUJUKAN: kartu/K-F-06.md §PMB1-F-072 · kartu/B-F-06.2.md.
-- ============================================================================

create or replace function public.hitung_perangkat_berkuasa()
returns table (
  peran           text,
  jumlah_aktif    bigint,
  cadangan_cukup  boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
begin
  -- 1. Identitas penyewa pemanggil (bukan dari klaim klien).
  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- 2. Layar ini untuk pemilik/admin (pola laporan 0052).
  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat status perangkat berkuasa.';
  end if;

  -- 3. Hitung perangkat aktif per peran berkuasa dari peran_diizinkan perangkat.
  --    left join memastikan peran tanpa satu pun perangkat tetap tampil (0, false)
  --    — justru keadaan paling berbahaya.
  return query
  select
    r.peran,
    count(p.id)                    as jumlah_aktif,
    count(p.id) >= 2               as cadangan_cukup
  from unnest(array['owner_pusat', 'admin_cabang']::text[]) as r(peran)
  left join public.perangkat p
    on p.penyewa_id = v_penyewa
   and p.aktif = true
   and r.peran = any (p.peran_diizinkan)
  group by r.peran
  order by r.peran;
end;
$$;

comment on function public.hitung_perangkat_berkuasa() is
  'PMB1-F-072: jumlah perangkat AKTIF per peran berkuasa (owner_pusat, admin_cabang) untuk penyewa pemanggil + penanda cadangan_cukup (>= 2). Keputusan pemilik KEAMANAN §4: kehilangan satu perangkat tidak boleh menghalangi kerja; bila tinggal satu, layar peringatan harus mengingatkan.';

revoke all on function public.hitung_perangkat_berkuasa() from public;
grant execute on function public.hitung_perangkat_berkuasa() to authenticated, service_role;
