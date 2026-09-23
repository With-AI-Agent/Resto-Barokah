-- ============================================================================
-- 0040 — Urutan rantai audit yang pasti (menutup cacat urutan di 0029)
--
-- Temuan (2026-09-23, saat menulis uji bayar_pesanan T5-02):
--   Rantai hash audit (0029) diurutkan dengan `waktu`, dan `waktu` memakai
--   `now()` — yaitu WAKTU MULAI TRANSAKSI. Dua baris audit yang ditulis dalam
--   SATU transaksi karena itu selalu punya `waktu` yang SAMA PERSIS, sehingga
--   urutan ditentukan oleh pemecah seri `id` (UUID acak):
--     * pembangun rantai mengambil induk lewat `order by waktu desc, id desc`,
--     * pemeriksa rantai berjalan lewat `order by waktu asc, id asc`.
--   Kalau UUID baris kedua kebetulan LEBIH KECIL dari baris pertama, pemeriksa
--   memulai dari baris kedua yang `hash_sebelumnya`-nya bukan GENESIS → rantai
--   dinyatakan PUTUS padahal tidak ada satu bit pun yang diubah orang.
--   Peluangnya ~50% per pasangan, dan nyata terjadi: `keluar_mode_dukungan`
--   (0031) menulis satu baris audit per penyewa dalam satu transaksi, dan
--   `bayar_pesanan` (0039) menulis jejak di transaksi yang sama dengan uang.
--
-- Perbaikan: rantai diurutkan oleh kolom urutan MONOTONIK yang diterbitkan
-- peladen (`bigserial`), bukan oleh jam. Jam tetap disimpan & tetap ikut di-hash
-- (payload tidak berubah → hash baris lama tetap sah); yang berubah hanya
-- URUTAN penelusuran, dan urutan itu kini tidak bisa seri.
--
-- Kenapa bukan `clock_timestamp()`? Karena jam masih bisa seri pada INSERT
-- banyak baris dalam satu pernyataan — masalah yang sama, hanya lebih jarang.
-- ============================================================================

alter table public.catatan_audit
  add column if not exists urutan bigserial;

comment on column public.catatan_audit.urutan is
  'Nomor urut penerbitan peladen (monotonik, tidak pernah seri). Sejak 0040 inilah satu-satunya penentu urutan rantai hash; `waktu` tetap disimpan & di-hash tetapi tidak lagi dipakai mengurutkan karena now() = waktu mulai transaksi.';

-- Baris lama (kalau ada) diberi nomor mengikuti urutan yang selama ini dipakai
-- pemeriksa, supaya rantai yang sudah terlanjur tersimpan tetap terbaca sama.
with baris as (
  select id, row_number() over (order by waktu asc, id asc) as nomor
    from public.catatan_audit
   where urutan is null
)
update public.catatan_audit c
   set urutan = b.nomor
  from baris b
 where c.id = b.id;

alter table public.catatan_audit
  alter column urutan set not null;

select setval(
  pg_get_serial_sequence('public.catatan_audit', 'urutan'),
  greatest((select coalesce(max(urutan), 1) from public.catatan_audit), 1),
  true
);

-- ---------------------------------------------------------------------------
-- Pembangun rantai: induk = baris dengan `urutan` terbesar, dan `urutan` baris
-- baru SELALU diambil dari urutan peladen — nilai kiriman klien diabaikan supaya
-- tidak ada yang bisa menyelipkan baris ke tengah rantai.
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

  -- Urutan diterbitkan peladen; nilai kiriman perangkat ditimpa (0040).
  NEW.urutan := nextval(pg_get_serial_sequence('public.catatan_audit', 'urutan'));

  -- Ambil hash baris terakhir untuk penyewa yang sama (dengan kunci serialisasi)
  select hash_baris
    into v_prev_hash
    from public.catatan_audit
   where penyewa_id = NEW.penyewa_id
   order by urutan desc
   limit 1
     for update;

  NEW.hash_sebelumnya := coalesce(v_prev_hash, GENESIS_HASH);

  -- Susun payload data kanonikal (TIDAK berubah dari 0029: hash lama tetap sah)
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
  'Menghitung hash baris dan mengikat hash_sebelumnya secara atomik per resto (T1-27). Sejak 0040 induk rantai dicari lewat kolom `urutan` yang monotonik, bukan `waktu` (now() = waktu mulai transaksi sehingga baris satu transaksi selalu seri).';

-- ---------------------------------------------------------------------------
-- Pemeriksa rantai: penelusuran memakai urutan yang sama persis.
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
     order by urutan asc
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
  'Memeriksa integritas kriptografis rantai catatan audit untuk penyewa tertentu (T1-27). Sejak 0040 penelusuran mengikuti kolom `urutan` supaya baris yang ditulis dalam satu transaksi tidak lagi seri urutannya.';

revoke all on function public.hitung_hash_catatan_audit() from public;
revoke all on function public.verifikasi_rantai_audit(uuid) from public;
grant execute on function public.verifikasi_rantai_audit(uuid) to authenticated, service_role;
