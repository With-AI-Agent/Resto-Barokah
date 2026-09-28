#!/usr/bin/env node
/**
 * ALAT BANTU EKSEKUSI TUGAS TERJADWAL & DENYUT (T10-08 / TECH_SPEC §1 & §10)
 * Menjalankan fungsi denyut_harian, bersihkan_data_sementara, dan ambil_log_jadwal
 * di lingkungan PGlite lokal untuk pengujian dan otomasi.
 */
import { readdirSync, readFileSync, existsSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { PGlite } from '@electric-sql/pglite'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const FOLDER_MIGRASI = join(AKAR, 'supabase', 'migrations')
const DATA_UJI = join(AKAR, 'alat', 'sql', 'data-uji.sql')

const args = process.argv.slice(2)
const aksi = args[0] || '--bantuan'

const supabaseUrl = process.env.SUPABASE_URL
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_KEY
const gunakanSupabaseRemote = Boolean(
  supabaseUrl &&
    supabaseKey &&
    supabaseUrl.startsWith('http') &&
    !supabaseUrl.includes('example.com'),
)

async function panggilRpcSupabase(namaRpc, params = {}) {
  const url = `${supabaseUrl.replace(/\/+$/, '')}/rest/v1/rpc/${namaRpc}`
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(params),
  })
  if (!res.ok) {
    const teks = await res.text()
    throw new Error(`Panggilan RPC Supabase ${namaRpc} gagal (${res.status}): ${teks}`)
  }
  return await res.json()
}

const SKEMA_UJI = `
create role anon nologin;
create role authenticated nologin;
create role service_role nologin bypassrls;

create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text
);

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

grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
grant execute on function auth.jwt() to anon, authenticated, service_role;

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
    return null;
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

create or replace function uji.klaim(p_sub text, p_klaim jsonb default '{}'::jsonb)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', coalesce(p_sub, ''), true);
  perform set_config('request.jwt.claims', coalesce(p_klaim::text, '{}'), true);
end $$;
`

async function siapkanDb() {
  const pg = new PGlite()
  await pg.exec(SKEMA_UJI)

  const berkasMigrasi = readdirSync(FOLDER_MIGRASI)
    .filter((b) => b.endsWith('.sql'))
    .sort()

  for (const b of berkasMigrasi) {
    const isi = readFileSync(join(FOLDER_MIGRASI, b), 'utf-8')
    await pg.exec(isi)
  }

  if (existsSync(DATA_UJI)) {
    const isi = readFileSync(DATA_UJI, 'utf-8')
    await pg.exec(isi)
  }

  // Set peran pemilik platform default untuk eksekusi tugas terjadwal
  await pg.exec(`select uji.klaim('90000000-0000-0000-0000-000000000001');`)
  return pg
}

async function main() {
  if (aksi === '--bantuan' || aksi === '-h') {
    console.log(
      JSON.stringify({
        perintah: ['--denyut', '--bersihkan [hari]', '--log [limit]', '--simulasi-2-hari'],
      }),
    )
    process.exit(0)
  }

  // Jika kredensial Supabase remote tersedia dan bukan simulasi lokal, panggil RPC Supabase remote
  if (gunakanSupabaseRemote && aksi !== '--simulasi-2-hari') {
    if (aksi === '--denyut') {
      const data = await panggilRpcSupabase('denyut_harian')
      console.log(JSON.stringify(data, null, 2))
      return
    }
    if (aksi === '--bersihkan') {
      const hari = parseInt(args[1] || '30', 10)
      const data = await panggilRpcSupabase('bersihkan_data_sementara', { p_retensi_hari: hari })
      console.log(JSON.stringify(data, null, 2))
      return
    }
    if (aksi === '--log') {
      const limit = parseInt(args[1] || '20', 10)
      const data = await panggilRpcSupabase('ambil_log_jadwal', { p_limit: limit })
      console.log(JSON.stringify(data, null, 2))
      return
    }
    console.error(`Perintah tidak dikenal: ${aksi}`)
    process.exit(1)
  }

  const pg = await siapkanDb()

  if (aksi === '--denyut') {
    const res = await pg.query('select public.denyut_harian() as hasil;')
    console.log(JSON.stringify(res.rows[0].hasil, null, 2))
  } else if (aksi === '--bersihkan') {
    const hari = parseInt(args[1] || '30', 10)
    const res = await pg.query('select public.bersihkan_data_sementara($1) as hasil;', [hari])
    console.log(JSON.stringify(res.rows[0].hasil, null, 2))
  } else if (aksi === '--log') {
    const limit = parseInt(args[1] || '20', 10)
    const res = await pg.query('select public.ambil_log_jadwal($1) as hasil;', [limit])
    console.log(JSON.stringify(res.rows[0].hasil, null, 2))
  } else if (aksi === '--simulasi-2-hari') {
    // Hari 1 Pagi: Denyut
    const d1 = await pg.query('select public.denyut_harian() as hasil;')
    // Sisipkan data kadaluwarsa buatan
    await pg.exec(`
      insert into public.percobaan_pin (pengguna_id, perangkat, berhasil, aksi, waktu)
      values ('90000000-0000-0000-0000-000000000004', 'hp-simulasi', false, 'test', now() - interval '40 days');
    `)
    // Hari 1 Malam: Pembersihan
    const b1 = await pg.query('select public.bersihkan_data_sementara(30) as hasil;')

    // Hari 2 Pagi: Denyut
    const d2 = await pg.query('select public.denyut_harian() as hasil;')
    // Hari 2 Malam: Pembersihan
    const b2 = await pg.query('select public.bersihkan_data_sementara(30) as hasil;')

    // Ambil log keseluruhan
    const logs = await pg.query('select public.ambil_log_jadwal(10) as hasil;')

    console.log(
      JSON.stringify(
        {
          berhasil: true,
          hari_1: {
            denyut: d1.rows[0].hasil,
            pembersihan: b1.rows[0].hasil,
          },
          hari_2: {
            denyut: d2.rows[0].hasil,
            pembersihan: b2.rows[0].hasil,
          },
          log_tercatat: logs.rows[0].hasil.data,
        },
        null,
        2,
      ),
    )
  } else {
    console.error(`Perintah tidak dikenal: ${aksi}`)
    process.exit(1)
  }
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
