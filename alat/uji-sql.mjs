#!/usr/bin/env node
/**
 * ============================================================================
 * UJI SQL LOKAL — menguji migrasi, kebijakan RLS, dan fungsi identitas
 * TANPA server database dan TANPA akun Supabase.
 *
 * Cara kerjanya: PostgreSQL asli (versi WASM lewat pustaka PGlite) dijalankan
 * di dalam Node. Jadi migrasi bisa benar-benar diterapkan dan RLS benar-benar
 * diuji di komputer sendiri — bukan hanya "kelihatannya benar".
 *
 * Yang disiapkan otomatis sebelum migrasi (meniru Supabase):
 *   - peran `anon`, `authenticated`, `service_role`
 *   - skema `auth` + tabel `auth.users` + fungsi `auth.uid()` & `auth.jwt()`
 *   - skema `uji` dengan alat bantu uji: uji.masuk(), uji.keluar(), uji.harap(),
 *     uji.harap_gagal(), uji.sama()
 * Ini HANYA untuk pengujian lokal; berkas migrasi tetap murni SQL Supabase.
 *
 * Susunan berkas:
 *   supabase/migrations/*.sql   ← diterapkan berurutan menurut nama berkas
 *   alat/sql/data-uji.sql       ← data uji (dibuat sebagai pemilik tabel)
 *   supabase/tes/*.sql          ← satu berkas = satu unit uji
 *
 * Aturan: setiap berkas uji dijalankan di dalam transaksinya sendiri dan
 * SELALU dibatalkan (rollback), jadi urutan uji tidak saling mengotori.
 *
 * Cara pakai:
 *   node alat/uji-sql.mjs                 # semua migrasi + semua uji
 *   node alat/uji-sql.mjs --daftar        # cetak daftar tabel, RLS, jumlah policy
 *   node alat/uji-sql.mjs supabase/tes/helper.sql   # satu berkas uji saja
 * ============================================================================
 */
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { PGlite } from '@electric-sql/pglite'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const FOLDER_MIGRASI = join(AKAR, 'supabase', 'migrations')
const FOLDER_TES = join(AKAR, 'supabase', 'tes')
const DATA_UJI = join(AKAR, 'alat', 'sql', 'data-uji.sql')

const args = process.argv.slice(2)
const hanyaDaftar = args.includes('--daftar')
const berkasUjiPilihan = args.filter((a) => a.endsWith('.sql'))

// ---------------------------------------------------------------------------
// 1. Alat bantu uji (skema `uji`) — meniru Supabase, hanya untuk pengujian
// ---------------------------------------------------------------------------
const SKEMA_UJI = `
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text
);

-- Mirip Supabase: subjek token & seluruh klaim token tersimpan di setelan sesi.
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

create or replace function auth.jwt() returns jsonb
language sql stable as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
$$;

create schema if not exists uji;
grant usage on schema uji to public;

-- Seperti di Supabase: pengguna yang sudah masuk (dan anon) memang boleh
-- memanggil auth.uid()/auth.jwt() — yang dijaga adalah datanya, bukan fungsinya.
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant execute on function auth.jwt() to anon, authenticated, service_role;

-- ================= tiruan pgcrypto — HANYA untuk uji lokal =================
-- Supabase memuat pgcrypto (bcrypt asli). PGlite inti TIDAK memuat pgcrypto,
-- jadi di sini dipasang tiruan yang meniru ANTARMUKA-nya saja:
--     crypt(pin, gen_salt('bf', 10))   →   hash ber-garam
--     crypt(pin, hash) = hash          →   verifikasi
-- Algoritmanya SENGAJA murah (SHA-256 ber-ulang) dan BUKAN pengganti produksi;
-- yang diuji adalah perilakunya (PIN tidak pernah tersimpan sebagai teks biasa,
-- verifikasi benar/salah, pembatasan percobaan) — bukan kekuatan KDF-nya.
create or replace function public.gen_salt(p_jenis text, p_putaran int default 10)
returns text language sql volatile as $$
  select '$tiruan$' || greatest(p_putaran, 1)::text || '$' ||
         encode(sha256(gen_random_uuid()::text::bytea), 'hex')
$$;

create or replace function public.crypt(p_pin text, p_hash text)
returns text language plpgsql immutable as $$
declare
  bagian text[];
  putaran int;
  garam text;
  hasil bytea;
  i int;
begin
  if p_hash is null or p_hash not like '$tiruan$%' then
    return null;   -- hash asing (mis. bcrypt asli) tidak bisa diverifikasi tiruan ini
  end if;
  bagian := string_to_array(trim(both '$' from p_hash), '$');
  putaran := bagian[2]::int;
  garam := bagian[3];
  hasil := sha256((garam || p_pin)::bytea);
  for i in 2..putaran loop
    hasil := sha256(hasil);
  end loop;
  return '$tiruan$' || putaran::text || '$' || garam || '$' || encode(hasil, 'hex');
end $$;

-- Menyetel klaim token (meniru token yang sudah diverifikasi Supabase).
-- Peran sesi TIDAK diubah di sini: PostgreSQL melarang SET ROLE di dalam
-- fungsi security definer. Berkas uji memakainya sebagai perintah biasa:
--     select uji.klaim('<uuid>');   set local role authenticated;
--     reset role;                   select uji.klaim(null);
create or replace function uji.klaim(p_id uuid, p_klaim jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path = uji, public, pg_temp as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  perform set_config('request.jwt.claims', coalesce(p_klaim::text, '{}'), true);
end $$;

-- Harapan sederhana: gagal kalau syaratnya tidak terpenuhi.
create or replace function uji.harap(p_syarat boolean, p_pesan text)
returns void language plpgsql as $$
begin
  if p_syarat is not true then
    raise exception 'HARAPAN TIDAK TERPENUHI: %', p_pesan;
  end if;
end $$;

-- Harapan dua nilai sama (dibandingkan sebagai teks supaya bebas tipe).
create or replace function uji.sama(p_dapat anyelement, p_harap anyelement, p_pesan text)
returns void language plpgsql as $$
begin
  if p_dapat is distinct from p_harap then
    raise exception 'HARAPAN TIDAK TERPENUHI: % (dapat %, harap %)', p_pesan, p_dapat, p_harap;
  end if;
end $$;

-- Harapan perintah DITOLAK (dipakai untuk uji negatif RLS).
create or replace function uji.harap_gagal(p_perintah text, p_catatan text default '')
returns void language plpgsql as $$
begin
  begin
    execute p_perintah;
  exception when others then
    return; -- memang harus gagal: lulus
  end;
  raise exception 'HARAPAN TIDAK TERPENUHI: perintah tidak ditolak (%). Perintah: %', p_catatan, p_perintah;
end $$;

grant execute on all functions in schema uji to public;
`

// ---------------------------------------------------------------------------
// 2. Pembantu
// ---------------------------------------------------------------------------
function berkasSql(folder) {
  if (!existsSync(folder)) return []
  return readdirSync(folder)
    .filter((f) => f.endsWith('.sql'))
    .sort()
    .map((f) => join(folder, f))
}

/** Ubah daftar berkas uji dari argumen perintah menjadi jalur lengkap. */
function jalurUji(daftar) {
  return daftar.map((j) => (j.startsWith('/') ? j : resolve(AKAR, j)))
}

function baca(jalur) {
  return readFileSync(jalur, 'utf8')
}

const hasil = { lulus: 0, gagal: 0 }
const catatanGagal = []

async function terapkan(db, label, sql) {
  try {
    await db.exec(sql)
    console.log(`  OK    ${label}`)
    return true
  } catch (e) {
    console.log(`  GAGAL ${label}`)
    console.log(`        ${String(e.message).split('\n')[0]}`)
    if (process.env.UJI_SQL_RINCI) {
      console.log(`        RINCI: ${JSON.stringify({ where: e.where, detail: e.detail, hint: e.hint, pos: e.position })}`)
    }
    catatanGagal.push(`${label}: ${String(e.message).split('\n')[0]}`)
    hasil.gagal++
    return false
  }
}

async function pola(db) {
  const q = await db.query(`
    select c.relname as tabel,
           c.relrowsecurity as rls,
           (select count(*) from pg_policy p where p.polrelid = c.oid)::int as policy,
           exists (select 1 from information_schema.columns k
                    where k.table_schema = 'public' and k.table_name = c.relname
                      and k.column_name = 'penyewa_id') as ada_penyewa
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
     order by c.relname`)
  return q.rows
}

// ---------------------------------------------------------------------------
// 3. Jalan
// ---------------------------------------------------------------------------
const db = await PGlite.create()

console.log('UJI SQL LOKAL (PostgreSQL di dalam Node — tanpa server, tanpa akun)')
console.log('Menyiapkan peran, auth, dan alat bantu uji…')
await terapkan(db, 'persiapan (peran/auth/alat uji)', SKEMA_UJI)

const migrasi = berkasSql(FOLDER_MIGRASI)
if (migrasi.length === 0) {
  console.log('BELUM ADA migrasi di supabase/migrations — tidak ada yang bisa diuji.')
}
console.log(`\nMenerapkan ${migrasi.length} migrasi:`)
for (const jalur of migrasi) {
  const ok = await terapkan(db, jalur.replace(FOLDER_MIGRASI + '/', ''), baca(jalur))
  if (!ok) {
    console.log('\nHASIL: GAGAL — migrasi tidak bisa diterapkan; uji dihentikan.')
    process.exit(1)
  }
}

if (existsSync(DATA_UJI)) {
  console.log('\nMembuat data uji:')
  const ok = await terapkan(db, 'alat/sql/data-uji.sql', baca(DATA_UJI))
  if (!ok) {
    console.log('\nHASIL: GAGAL — data uji tidak bisa dibuat; uji dihentikan.')
    process.exit(1)
  }
}

if (hanyaDaftar) {
  console.log('\nDaftar tabel & kebijakan (bukti untuk T1-04):')
  for (const r of await pola(db)) {
    console.log(
      `  ${String(r.tabel).padEnd(22)} RLS=${r.rls ? 'ya ' : 'TIDAK'}  policy=${String(r.policy).padStart(2)}  penyewa_id=${r.ada_penyewa ? 'ya' : 'tidak'}`,
    )
  }
}

const daftarUji = berkasUjiPilihan.length > 0 ? jalurUji(berkasUjiPilihan) : berkasSql(FOLDER_TES)
if (daftarUji.length > 0) {
  console.log(`\nMenjalankan ${daftarUji.length} berkas uji:`)
  for (const nama of daftarUji) {
    const label = nama.replace(AKAR + '/', '')
    if (!existsSync(nama)) {
      console.log(`  GAGAL ${label} (berkas tidak ada)`)
      hasil.gagal++
      catatanGagal.push(`${label}: berkas tidak ada`)
      continue
    }
    await db.exec('begin')
    try {
      await db.exec(baca(nama))
      console.log(`  LULUS ${label}`)
      hasil.lulus++
    } catch (e) {
      const pesan = String(e.message).split('\n')[0]
      console.log(`  GAGAL ${label}`)
      if (process.env.UJI_SQL_RINCI) {
        console.log(`        RINCI: ${JSON.stringify({ where: e.where, detail: e.detail, hint: e.hint, pos: e.position, query: e.query && String(e.query).slice(0, 300) })}`)
      }
      console.log(`        ${pesan}`)
      catatanGagal.push(`${label}: ${pesan}`)
      hasil.gagal++
    } finally {
      await db.exec('rollback')
    }
  }
}

console.log('\n' + '-'.repeat(70))
console.log(`uji: ${hasil.lulus} LULUS · ${hasil.gagal} GAGAL`)
if (catatanGagal.length > 0) {
  console.log('Rincian kegagalan:')
  for (const c of catatanGagal) console.log(`  - ${c}`)
  console.log('HASIL: GAGAL')
} else {
  console.log('HASIL: LOLOS')
}
await db.close()
process.exit(hasil.gagal > 0 ? 1 : 0)
