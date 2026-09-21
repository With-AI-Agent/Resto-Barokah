-- ============================================================================
-- MIGRASI 0017 — pesanan yang sudah TUTUP (lunas/batal) beku total bagi perangkat
-- ============================================================================
-- Temuan yang ditutup: AUD-3 2026-09-20 H F-07 (K-4).
--   Probe: docs/uji/audit/probe-2026-09-21/h-f07-kolom-non-uang.sql
--   Sebelum migrasi ini, pembekuan "pesanan tertutup" hanya ditegakkan pada:
--     - nilai uang (subtotal/pajak/service/total_diskon/total) — 0013/0014/0015,
--     - item & baris diskon (0015 D F-01), dan
--     - stempel lifecycle dibayar_pada/dibatalkan_pada/alasan_batal (0015 F-06).
--   Kolom jejak lain (catatan, tipe, shift_id, meja_id, pelayan_id, …) masih bisa
--   ditulis perangkat SETELAH pesanan lunas/batal — probe membuktikan kasir mengubah
--   catatan & tipe pesanan lunas. Laporan lalu membaca jejak yang tidak pernah terjadi.
--
-- Aturan fondasi:
--   TECH_SPEC ART-3 — pesanan lunas/batal adalah jejak penutup buku; koreksi tidak
--     pernah dilakukan dengan menulis ulang baris, melainkan lewat kejadian baru
--     yang resmi (pembatalan berjejak, pembayaran susulan) di jalur peladen.
--   DECISIONS_LOG [Uang/2026-09-20] — hitung-ulang/suntingan perangkat pada pesanan
--     tertutup ditolak; jalur peladen (pemicu & RPC SECURITY DEFINER) tetap bebas.
--
-- Mekanisme: satu pemicu BEFORE UPDATE baru. Jalur peladen dilewatkan dengan pola
-- yang SUDAH TERUJI di `picu_pesanan_jejak_jujur` (0015): `auth.uid() is null or
-- public.peran_peladen()` — di dalam RPC SECURITY DEFINER `current_user` adalah
-- pemilik tabel sehingga `peran_peladen()` TRUE; UPDATE langsung perangkat berjalan
-- sebagai `authenticated` sehingga penjaga aktif. `peran_peladen()` sendiri TIDAK
-- SECURITY DEFINER (0010) jadi tidak bisa dibutakan klien.
-- ============================================================================

create or replace function public.picu_pesanan_tertutup_beku()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or public.peran_peladen() then
    return new;   -- penyiapan / jalur peladen (pemicu pembayaran, pembatalan resmi, RPC)
  end if;

  if old.status in ('lunas', 'batal') and new is distinct from old then
    raise exception
      'Pesanan sudah ditutup (status %) — barisnya beku bagi perangkat; koreksi lewat jalur resmi peladen.',
      old.status;
  end if;

  return new;
end
$$;

comment on function public.picu_pesanan_tertutup_beku() is
  'Membekukan SELURUH kolom pesanan yang sudah lunas/batal terhadap UPDATE dari perangkat (temuan AUD-3 H F-07). Jalur peladen (pemicu & RPC SECURITY DEFINER) tetap bebas — pola bypass sama dengan picu_pesanan_jejak_jujur (0015).';

drop trigger if exists pesanan_tertutup_beku on public.pesanan;
create trigger pesanan_tertutup_beku
  before update on public.pesanan
  for each row
  execute function public.picu_pesanan_tertutup_beku();

grant execute on function public.picu_pesanan_tertutup_beku() to authenticated, service_role;
