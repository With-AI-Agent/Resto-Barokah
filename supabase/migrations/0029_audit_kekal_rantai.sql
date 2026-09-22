-- ============================================================================
-- MIGRASI 0029 — Catatan Audit Kekal & Rantai Hash Anti-Manipulasi (T1-13 & T1-27)
-- ============================================================================
-- Menutup tugas ROADMAP T1-13 (hanya-tambah, tolak UPDATE/DELETE) dan T1-27 (rantai hash).
--   * UPDATE dan DELETE ditolak secara mutlak lewat trigger database.
--   * Setiap baris audit mengikat hash baris sebelumnya (hash chaining) per resto.
--   * Fungsi verifikasi_rantai_audit memvalidasi keutuhan rantai dan mendeteksi pemutusan.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BAGIAN 1 — Kolom Rantai Hash pada tabel catatan_audit
-- ---------------------------------------------------------------------------
alter table public.catatan_audit
  add column if not exists hash_sebelumnya text,
  add column if not exists hash_baris      text;

comment on column public.catatan_audit.hash_sebelumnya is
  'Hash SHA-256 dari baris audit sebelumnya untuk penyewa yang sama (genesis = deret 0).';

comment on column public.catatan_audit.hash_baris is
  'Hash SHA-256 dari seluruh bidang baris ini + hash_sebelumnya (T1-27).';

-- ---------------------------------------------------------------------------
-- BAGIAN 2 — Trigger Penolakan Mutlak UPDATE dan DELETE (T1-13)
-- ---------------------------------------------------------------------------
create or replace function public.cegah_ubah_hapus_audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  raise exception 'Catatan audit bersifat permanen dan tidak dapat diubah atau dihapus.';
end;
$$;

comment on function public.cegah_ubah_hapus_audit() is
  'Mencegah segala bentuk UPDATE atau DELETE pada catatan_audit (T1-13).';

revoke all on function public.cegah_ubah_hapus_audit() from public;

drop trigger if exists catatan_audit_cegah_ubah_hapus on public.catatan_audit;
create trigger catatan_audit_cegah_ubah_hapus
  before update or delete on public.catatan_audit
  for each row execute function public.cegah_ubah_hapus_audit();

-- ---------------------------------------------------------------------------
-- BAGIAN 3 — Trigger Penghitungan Rantai Hash Otomatis (T1-27)
-- ---------------------------------------------------------------------------
create or replace function public.hitung_hash_catatan_audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  GENESIS_HASH constant text := '0000000000000000000000000000000000000000000000000000000000000000';
  v_prev_hash  text;
  v_payload    text;
begin
  -- Pastikan ID dan waktu terisi sebelum perhitungan hash
  if NEW.id is null then
    NEW.id := gen_random_uuid();
  end if;
  if NEW.waktu is null then
    NEW.waktu := now();
  end if;

  -- Ambil hash baris terakhir untuk penyewa yang sama (dengan kunci serialisasi)
  select hash_baris
    into v_prev_hash
    from public.catatan_audit
   where penyewa_id = NEW.penyewa_id
   order by waktu desc, id desc
   limit 1
     for update;

  NEW.hash_sebelumnya := coalesce(v_prev_hash, GENESIS_HASH);

  -- Susun payload data kanonikal
  v_payload := NEW.id::text || ':' ||
               NEW.penyewa_id::text || ':' ||
               coalesce(NEW.pelaku_id::text, 'sistem') || ':' ||
               NEW.aksi || ':' ||
               NEW.entitas || ':' ||
               coalesce(NEW.entitas_id::text, '') || ':' ||
               coalesce(NEW.nilai_lama::text, '') || ':' ||
               coalesce(NEW.nilai_baru::text, '') || ':' ||
               to_char(NEW.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || ':' ||
               NEW.hash_sebelumnya;

  NEW.hash_baris := encode(sha256(v_payload::bytea), 'hex');

  return NEW;
end;
$$;

comment on function public.hitung_hash_catatan_audit() is
  'Menghitung hash baris dan mengikat hash_sebelumnya secara atomik per resto (T1-27).';

revoke all on function public.hitung_hash_catatan_audit() from public;

drop trigger if exists catatan_audit_hitung_hash on public.catatan_audit;
create trigger catatan_audit_hitung_hash
  before insert on public.catatan_audit
  for each row execute function public.hitung_hash_catatan_audit();

-- ---------------------------------------------------------------------------
-- BAGIAN 4 — RPC Verifikasi Integritas Rantai Audit (T1-27)
-- ---------------------------------------------------------------------------
create or replace function public.verifikasi_rantai_audit(p_penyewa_id uuid default null)
returns table (
  valid boolean,
  jumlah_baris integer,
  baris_rusak_id uuid,
  pesan text
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  GENESIS_HASH constant text := '0000000000000000000000000000000000000000000000000000000000000000';
  v_target_penyewa uuid := coalesce(p_penyewa_id, public.penyewa_saya());
  v_prev_hash      text := GENESIS_HASH;
  v_hitung         integer := 0;
  r                record;
  v_payload        text;
  v_expected_hash  text;
begin
  if v_target_penyewa is null then
    return query select false, 0, null::uuid, 'Penyewa tidak ditemukan atau belum ditentukan.';
    return;
  end if;

  for r in
    select id, penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru, waktu, hash_sebelumnya, hash_baris
      from public.catatan_audit
     where penyewa_id = v_target_penyewa
     order by waktu asc, id asc
  loop
    v_hitung := v_hitung + 1;

    -- Periksa tautan hash sebelumnya
    if r.hash_sebelumnya <> v_prev_hash then
      return query select false, v_hitung, r.id,
        format('Tautan rantai terputus pada baris ke-%s (ID: %s). Hash sebelumnya tidak cocok.', v_hitung, r.id);
      return;
    end if;

    -- Hitung ulang hash baris
    v_payload := r.id::text || ':' ||
                 r.penyewa_id::text || ':' ||
                 coalesce(r.pelaku_id::text, 'sistem') || ':' ||
                 r.aksi || ':' ||
                 r.entitas || ':' ||
                 coalesce(r.entitas_id::text, '') || ':' ||
                 coalesce(r.nilai_lama::text, '') || ':' ||
                 coalesce(r.nilai_baru::text, '') || ':' ||
                 to_char(r.waktu at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || ':' ||
                 r.hash_sebelumnya;

    v_expected_hash := encode(sha256(v_payload::bytea), 'hex');

    if r.hash_baris <> v_expected_hash then
      return query select false, v_hitung, r.id,
        format('Integritas data rusak pada baris ke-%s (ID: %s). Hash baris tidak sesuai dengan payload.', v_hitung, r.id);
      return;
    end if;

    v_prev_hash := r.hash_baris;
  end loop;

  return query select true, v_hitung, null::uuid, 'Seluruh rantai audit valid dan tidak terputus.';
end;
$$;

comment on function public.verifikasi_rantai_audit(uuid) is
  'Memeriksa integritas kriptografis rantai catatan audit untuk penyewa tertentu (T1-27).';

revoke all on function public.verifikasi_rantai_audit(uuid) from public;
grant execute on function public.verifikasi_rantai_audit(uuid) to authenticated, service_role;
