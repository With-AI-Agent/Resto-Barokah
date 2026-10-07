-- ============================================================================
-- MIGRASI 0104 — PMB1-F-087 (K-3): laporan bulanan "siapa menyetujui apa"
-- ============================================================================
-- Baseline yang dilanggar: `docs/KEAMANAN.md` §9 butir 4 mewajibkan laporan
-- bulanan semua penggunaan PIN persetujuan ("mencegah PIN atasan dipakai
-- berulang tanpa terasa") dan §15 butir 3 menjadikannya kompensasi resmi atas
-- risiko pembagian PIN antar-staf. Sebelum migrasi ini: tidak ada RPC, tidak
-- ada tab laporan, tidak ada tugas ROADMAP (`grep -rn -i "siapa menyetujui apa"
-- supabase/ aplikasi/ docs/ROADMAP.md` → 0).
--
-- Sumber data (semua sudah distempel saat kejadiannya):
--   * `diskon_transaksi.disetujui_oleh` (0041) — diskon manual di atas batas kasir;
--   * `pembatalan.disetujui_oleh` (0015) — void sesudah dapur;
--   * `voucher.pakai_disetujui_oleh` (0098) — pakai voucher dengan PIN atasan;
--     cabang ini hidup otomatis bila saklar 0098 dinyalakan Lee.
-- Pembatalan sebelum dapur & diskon di bawah batas memang TIDAK distempel —
-- laporan ini hanya merangkum yang melalui persetujuan PIN, sesuai janji §9.
--
-- Pola fondasi (wajib ART): SECURITY DEFINER + search_path dipaku + revoke
-- execute from public + grant authenticated/service_role; penyewa + izin
-- diperiksa di dalam badan fungsi (pola 0052). Uji: supabase/tes/laporan_persetujuan_pin.sql.
-- RUJUKAN: kartu/K-F-06.2.md §PMB1-F-087 · kartu/B-F-06.2.md.
-- ============================================================================

create or replace function public.laporan_persetujuan_pin(p_bulan date default null)
returns table (
  jenis_persetujuan text,
  penyetuju_id      uuid,
  penyetuju_nama    text,
  jumlah            bigint,
  total_nilai       bigint
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_penyewa uuid;
  v_awal    date;
  v_akhir   date;
begin
  v_penyewa := public.penyewa_saya();
  if v_penyewa is null then
    raise exception 'Identitas penyewa Anda tidak ditemukan.';
  end if;

  -- Layar laporan = izin lihat_laporan (owner_pusat, admin_cabang).
  if not public.boleh('lihat_laporan') then
    raise exception 'Anda tidak berwenang melihat laporan persetujuan.';
  end if;

  -- Rentang bulan takwim dari tanggal acuan (default: bulan berjalan).
  v_awal  := date_trunc('month', coalesce(p_bulan, current_date))::date;
  v_akhir := (v_awal + interval '1 month')::date;

  return query
  -- 1. Diskon yang memakai persetujuan PIN atasan.
  select
    'diskon ' || d.jenis            as jenis_persetujuan,
    d.disetujui_oleh                as penyetuju_id,
    g.nama                          as penyetuju_nama,
    count(*)                        as jumlah,
    coalesce(sum(d.nilai), 0)::bigint as total_nilai
  from public.diskon_transaksi d
  join public.pesanan ps on ps.id = d.pesanan_id
  left join public.pengguna g on g.id = d.disetujui_oleh
  where d.disetujui_oleh is not null
    and ps.penyewa_id = v_penyewa
    and d.waktu >= v_awal::timestamptz and d.waktu < v_akhir::timestamptz
  group by 1, 2, 3

  union all

  -- 2. Pembatalan (void) yang memakai persetujuan PIN atasan.
  select
    'pembatalan ' || b.tahap        as jenis_persetujuan,
    b.disetujui_oleh                as penyetuju_id,
    g.nama                          as penyetuju_nama,
    count(*)                        as jumlah,
    coalesce(sum(b.nilai_kerugian), 0)::bigint as total_nilai
  from public.pembatalan b
  join public.pesanan ps on ps.id = b.pesanan_id
  left join public.pengguna g on g.id = b.disetujui_oleh
  where b.disetujui_oleh is not null
    and ps.penyewa_id = v_penyewa
    and b.waktu >= v_awal::timestamptz and b.waktu < v_akhir::timestamptz
  group by 1, 2, 3

  union all

  -- 3. Voucher yang dipakai dengan persetujuan PIN atasan (saklar 0098).
  select
    'voucher'                       as jenis_persetujuan,
    v.pakai_disetujui_oleh          as penyetuju_id,
    g.nama                          as penyetuju_nama,
    count(*)                        as jumlah,
    0::bigint                       as total_nilai   -- nominal voucher mengikuti kampanye; angka di sini adalah jejak persetujuannya
  from public.voucher v
  left join public.pengguna g on g.id = v.pakai_disetujui_oleh
  where v.pakai_disetujui_oleh is not null
    and v.penyewa_id = v_penyewa
    and v.terpakai_pada >= v_awal::timestamptz and v.terpakai_pada < v_akhir::timestamptz
  group by 1, 2, 3

  order by 1, 3;
end;
$$;

comment on function public.laporan_persetujuan_pin(date) is
  'PMB1-F-087: rekap bulanan "siapa menyetujui apa" — semua penggunaan PIN persetujuan (diskon di atas batas, void sesudah dapur, voucher dengan PIN atasan) per penyetuju, untuk penyewa pemanggil. Janji KEAMANAN §9 butir 4 & kompensasi §15 butir 3.';

revoke all on function public.laporan_persetujuan_pin(date) from public;
grant execute on function public.laporan_persetujuan_pin(date) to authenticated, service_role;
