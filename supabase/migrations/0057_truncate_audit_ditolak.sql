-- ============================================================================
-- Migrasi 0057: Penolakan TRUNCATE catatan_audit (N F-02 audit 2026-09-24)
--
-- Referensi:
--   - AUDIT_LAPORAN_audit_f34c9a1c N F-02: Rantai audit tidak mendeteksi
--     pemotongan ekor/awal (TRUNCATE). Trigger `cegah_ubah_hapus_audit`
--     di migrasi 0029 hanya menolak UPDATE/DELETE; TRUNCATE adalah DDL
--     terpisah yang tidak memicu trigger baris-per-baris. Klaim
--     "terdeteksi seketika" tidak berlaku untuk operasi DDL.
--   - Bantah-balik sesi kerja 2026-09-24 NYATA.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Fungsi penolak TRUNCATE
-- ---------------------------------------------------------------------------
create or replace function public.cegah_truncate_audit()
returns trigger
language plpgsql
as $$
begin
  raise exception using
    errcode = 'insufficient_privilege',
    message = 'Pemotongan tabel catatan_audit dilarang — catatan audit bersifat permanen.';
end;
$$;

comment on function public.cegah_truncate_audit() is
  'Menolak TRUNCATE pada public.catatan_audit (N F-02 audit 2026-09-24). Dipakai trigger STATEMENT-level BEFORE TRUNCATE.';

revoke all on function public.cegah_truncate_audit() from public;

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Trigger BEFORE TRUNCATE
-- ---------------------------------------------------------------------------
drop trigger if exists catatan_audit_cegah_truncate on public.catatan_audit;
create trigger catatan_audit_cegah_truncate
  before truncate on public.catatan_audit
  for each statement execute function public.cegah_truncate_audit();

comment on trigger catatan_audit_cegah_truncate on public.catatan_audit is
  'N F-02: menolak TRUNCATE pada catatan_audit. Rantai audit hanya bisa bertambah, tidak bisa dipotong.';
