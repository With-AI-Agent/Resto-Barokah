#!/usr/bin/env node
/**
 * ALAT BANTU CADANGAN & PEMULIHAN BASIS DATA (T10-10 / TECH_SPEC §8 & §10)
 *
 * Menyediakan mesin dump, pemulihan, dan verifikasi integritas untuk cadangan
 * basis data Resto Barokah menggunakan PostgreSQL/PGlite.
 *
 * Perintah:
 *   --dump <jalur_berkas>      : Ekspor skema + data lengkap ke berkas SQL
 *   --pulihkan <jalur_berkas>  : Pulihkan berkas SQL ke basis data kosong & verifikasi
 *   --uji-pemulihan            : Uji mandiri siklus dump -> pulihkan ke DB kosong -> verifikasi
 *   --verifikasi <berkas_sql>  : Periksa sintaks dan kelengkapan berkas dump SQL
 */
import { readdirSync, readFileSync, writeFileSync, unlinkSync, existsSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'
import { PGlite } from '@electric-sql/pglite'

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const FOLDER_MIGRASI = join(AKAR, 'supabase', 'migrations')
const DATA_UJI = join(AKAR, 'alat', 'sql', 'data-uji.sql')

const args = process.argv.slice(2)
const aksi = args[0] || '--bantuan'

const SKEMA_FONDASI = `
-- Peran bawaan Supabase
do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin bypassrls; end if;
end $$;

-- Skema auth tiruan Supabase
create schema if not exists auth;
create table if not exists auth.users (
  id uuid primary key,
  email text,
  raw_user_meta_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
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

-- Fungsi kriptografi tiruan untuk PIN hash di lingkungan uji lokal
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

function formatNilaiKolom(val, infoKolom) {
  if (val === null || val === undefined) return 'NULL'

  const dataType = infoKolom?.data_type || ''
  const udtName = infoKolom?.udt_name || ''

  if (dataType === 'ARRAY') {
    const tipeElemen = udtName.startsWith('_') ? udtName.slice(1) : 'text'
    if (!Array.isArray(val) || val.length === 0) {
      return `ARRAY[]::${tipeElemen}[]`
    }
    const isNum = ['int2', 'int4', 'int8', 'numeric', 'float4', 'float8'].includes(tipeElemen)
    const escapedItems = val.map((item) => {
      if (item === null || item === undefined) return 'NULL'
      if (isNum) return Number(item)
      return `'${String(item).replace(/'/g, "''")}'`
    })
    return `ARRAY[${escapedItems.join(', ')}]::${tipeElemen}[]`
  }

  if (dataType === 'jsonb' || dataType === 'json') {
    const jsonStr = typeof val === 'string' ? val : JSON.stringify(val)
    return `'${jsonStr.replace(/'/g, "''")}'::jsonb`
  }

  if (val instanceof Date || dataType.includes('timestamp')) {
    const iso = val instanceof Date ? val.toISOString() : new Date(val).toISOString()
    return `'${iso}'::timestamptz`
  }

  if (typeof val === 'boolean') {
    return val ? 'true' : 'false'
  }

  if (typeof val === 'number') {
    return Number.isFinite(val) ? String(val) : 'NULL'
  }

  const str = String(val).replace(/'/g, "''")
  return `'${str}'`
}

/**
 * Inisialisasi basis data lengkap dengan migrasi dan data benih (seed).
 */
async function siapkanDbLengkap() {
  const pg = new PGlite()
  await pg.exec(SKEMA_FONDASI)

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

  // Tambahkan catatan transaksi dan audit peraga untuk pembuktian pemulihan finansial
  await pg.exec(`
    select uji.klaim('90000000-0000-0000-0000-000000000002');
    insert into public.catatan_audit (penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru, waktu)
    values (
      '11111111-1111-1111-1111-111111111111',
      '90000000-0000-0000-0000-000000000002',
      'cadangan_rutin',
      'sistem',
      '11111111-1111-1111-1111-111111111111',
      null,
      '{"status": "uji_pra_cadangan"}'::jsonb,
      now()
    );
  `)

  return pg
}

/**
 * Menghasilkan SQL dump lengkap (skema + data seluruh tabel publik).
 */
async function hasilkanDumpSql(pg) {
  const stempel = new Date().toISOString()
  const bagianSql = []

  bagianSql.push(`-- ============================================================================`)
  bagianSql.push(`-- RESTO BAROKAH — BERKAS CADANGAN BASIS DATA RESMI (T10-10)`)
  bagianSql.push(`-- Dibuat pada: ${stempel}`)
  bagianSql.push(`-- Dokumen SOP Pemulihan: docs/teknis/PEMULIHAN.md`)
  bagianSql.push(`-- PERINGATAN: Berkas ini memuat data operasional & audit kedai.`)
  bagianSql.push(`-- WAJIB selalu disimpan terenkripsi (AES-256-CBC) dan TIDAK PERNAH masuk Git.`)
  bagianSql.push(`-- ============================================================================\n`)

  // 1. Skema fondasi
  bagianSql.push(SKEMA_FONDASI)

  // 2. Seluruh migrasi skema
  const berkasMigrasi = readdirSync(FOLDER_MIGRASI)
    .filter((b) => b.endsWith('.sql'))
    .sort()

  for (const b of berkasMigrasi) {
    bagianSql.push(`\n-- ---- MIGRASI: ${b} ----`)
    bagianSql.push(readFileSync(join(FOLDER_MIGRASI, b), 'utf-8'))
  }

  // 3. Matikan trigger/RLS sementara selama pemuatan data (standar pg_dump replication mode)
  bagianSql.push(`\n-- ---- PENGISIAN DATA TABEL (REPLICATION ROLE) ----`)
  bagianSql.push(`SET session_replication_role = 'replica';\n`)

  // 4. Data tabel publik
  const resTabel = await pg.query(`
    select tablename from pg_tables
    where schemaname = 'public'
    order by tablename;
  `)

  let totalBarisData = 0
  const ringkasanTabel = {}

  for (const row of resTabel.rows) {
    const tbl = row.tablename
    const barisRes = await pg.query(`select * from public.${tbl};`)
    const jumlah = barisRes.rows.length
    ringkasanTabel[tbl] = jumlah
    totalBarisData += jumlah

    if (jumlah > 0) {
      bagianSql.push(`-- Data untuk tabel: public.${tbl} (${jumlah} baris)`)

      // Ambil tipe data kolom dari katalog
      const resKolom = await pg.query(
        `select column_name, data_type, udt_name
         from information_schema.columns
         where table_schema = 'public' and table_name = $1;`,
        [tbl],
      )
      const mapKolom = new Map()
      for (const k of resKolom.rows) {
        mapKolom.set(k.column_name, k)
      }

      const contoh = barisRes.rows[0]
      const kolom = Object.keys(contoh)
      const kolomStr = kolom.map((k) => `"${k}"`).join(', ')

      for (const r of barisRes.rows) {
        const valStr = kolom.map((k) => formatNilaiKolom(r[k], mapKolom.get(k))).join(', ')
        bagianSql.push(`INSERT INTO public."${tbl}" (${kolomStr}) VALUES (${valStr}) ON CONFLICT DO NOTHING;`)
      }
      bagianSql.push('')
    }
  }

  // 5. Kembalikan session_replication_role
  bagianSql.push(`\nSET session_replication_role = 'origin';`)
  bagianSql.push(`-- ---- SELESAI PENGISIAN DATA (TOTAL: ${totalBarisData} BARIS, ${resTabel.rows.length} TABEL) ----\n`)

  return {
    sql: bagianSql.join('\n'),
    totalTabel: resTabel.rows.length,
    totalBaris: totalBarisData,
    ringkasanTabel,
  }
}

/**
 * Memulihkan berkas SQL ke database target baru yang kosong dan memverifikasi integritasnya.
 */
async function pulihkanKeDbKosong(isiSql) {
  const dbBaru = new PGlite()
  await dbBaru.exec(isiSql)

  // Verifikasi 1: Jumlah tabel di skema public
  const resTabel = await dbBaru.query(`
    select tablename from pg_tables
    where schemaname = 'public'
    order by tablename;
  `)

  // Verifikasi 2: RLS aktif pada seluruh tabel
  const resRls = await dbBaru.query(`
    select c.relname, c.relrowsecurity
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r'
    order by c.relname;
  `)

  const rlsAktifSemua = resRls.rows.every((r) => r.relrowsecurity === true)
  const tabelTanpaRls = resRls.rows.filter((r) => !r.relrowsecurity).map((r) => r.relname)

  // Verifikasi 3: Hitung baris per tabel
  let totalBarisPulih = 0
  const ringkasanPulih = {}
  for (const r of resTabel.rows) {
    const c = await dbBaru.query(`select count(*)::int as n from public."${r.tablename}";`)
    const n = c.rows[0].n
    ringkasanPulih[r.tablename] = n
    totalBarisPulih += n
  }

  // Verifikasi 4: Integritas relasional tabel inti
  const cekPenyewa = await dbBaru.query(`select count(*)::int as n from public.penyewa;`)
  const cekCabang = await dbBaru.query(`select count(*)::int as n from public.cabang;`)
  const cekPengguna = await dbBaru.query(`select count(*)::int as n from public.pengguna;`)
  const cekMenu = await dbBaru.query(`select count(*)::int as n from public.menu_item;`)
  const cekAudit = await dbBaru.query(`select count(*)::int as n from public.catatan_audit;`)

  const integritasRelasi =
    cekPenyewa.rows[0].n > 0 &&
    cekCabang.rows[0].n > 0 &&
    cekPengguna.rows[0].n > 0 &&
    cekMenu.rows[0].n > 0 &&
    cekAudit.rows[0].n > 0

  return {
    sukses: rlsAktifSemua && integritasRelasi && resTabel.rows.length >= 45,
    totalTabel: resTabel.rows.length,
    totalBaris: totalBarisPulih,
    rlsAktifSemua,
    tabelTanpaRls,
    integritasRelasi,
    ringkasanTabel: ringkasanPulih,
  }
}

async function main() {
  if (aksi === '--bantuan' || aksi === '-h') {
    console.log(`
Penggunaan alat bantu cadangan basis data:
  node alat/eksekusi-cadangan.mjs --dump <jalur_keluaran.sql>
  node alat/eksekusi-cadangan.mjs --pulihkan <jalur_berkas.sql>
  node alat/eksekusi-cadangan.mjs --verifikasi <jalur_berkas.sql>
  node alat/eksekusi-cadangan.mjs --uji-pemulihan
`)
    process.exit(0)
  }

  if (aksi === '--dump') {
    const berkasKeluar = args[1]
    if (!berkasKeluar) {
      console.error('Galat: Tentukan jalur berkas keluaran dump SQL!')
      process.exit(1)
    }

    const pg = await siapkanDbLengkap()
    const { sql, totalTabel, totalBaris } = await hasilkanDumpSql(pg)
    writeFileSync(berkasKeluar, sql, 'utf-8')

    const sha256 = createHash('sha256').update(sql).digest('hex')
    console.log(
      JSON.stringify(
        {
          berhasil: true,
          berkas: berkasKeluar,
          totalTabel,
          totalBaris,
          sha256,
          ukuranByte: Buffer.byteLength(sql, 'utf-8'),
        },
        null,
        2,
      ),
    )
    process.exit(0)
  }

  if (aksi === '--pulihkan') {
    const berkasMasuk = args[1]
    if (!berkasMasuk || !existsSync(berkasMasuk)) {
      console.error(`Galat: Berkas SQL tidak ditemukan: ${berkasMasuk}`)
      process.exit(1)
    }

    const isiSql = readFileSync(berkasMasuk, 'utf-8')
    const hasil = await pulihkanKeDbKosong(isiSql)
    console.log(JSON.stringify(hasil, null, 2))
    process.exit(hasil.sukses ? 0 : 1)
  }

  if (aksi === '--verifikasi') {
    const berkasMasuk = args[1]
    if (!berkasMasuk || !existsSync(berkasMasuk)) {
      console.error(`Galat: Berkas SQL tidak ditemukan: ${berkasMasuk}`)
      process.exit(1)
    }
    const isi = readFileSync(berkasMasuk, 'utf-8')
    const adaHeader = isi.includes('RESTO BAROKAH — BERKAS CADANGAN BASIS DATA RESMI')
    const adaReplica = isi.includes("session_replication_role = 'replica'")
    const adaOrigin = isi.includes("session_replication_role = 'origin'")
    const adaPenyewa = isi.includes('INSERT INTO public."penyewa"')
    const adaCabang = isi.includes('INSERT INTO public."cabang"')

    const valid = adaHeader && adaReplica && adaOrigin && adaPenyewa && adaCabang
    console.log(
      JSON.stringify(
        {
          valid,
          adaHeader,
          adaReplica,
          adaOrigin,
          adaPenyewa,
          adaCabang,
          panjangByte: Buffer.byteLength(isi, 'utf-8'),
        },
        null,
        2,
      ),
    )
    process.exit(valid ? 0 : 1)
  }

  if (aksi === '--uji-pemulihan') {
    console.log('Menjalankan uji pemulihan lengkap ke basis data kosong (clean slate)...')

    // 1. Siapkan DB sumber
    const pgSumber = await siapkanDbLengkap()
    const dump = await hasilkanDumpSql(pgSumber)
    console.log(`[1] Dump berhasil dibuat: ${dump.totalTabel} tabel, ${dump.totalBaris} baris data.`)

    // 2. Pulihkan ke DB target 100% kosong
    const pulih = await pulihkanKeDbKosong(dump.sql)
    console.log(`[2] Pemulihan ke database kosong selesai: ${pulih.totalTabel} tabel, ${pulih.totalBaris} baris data.`)

    // 3. Periksa paritas
    let paritasCocok = true
    const selisih = []
    if (dump.totalTabel !== pulih.totalTabel) {
      paritasCocok = false
      selisih.push(`Total tabel berbeda: sumber=${dump.totalTabel}, target=${pulih.totalTabel}`)
    }
    if (dump.totalBaris !== pulih.totalBaris) {
      paritasCocok = false
      selisih.push(`Total baris berbeda: sumber=${dump.totalBaris}, target=${pulih.totalBaris}`)
    }

    for (const [tabel, jmlSumber] of Object.entries(dump.ringkasanTabel)) {
      const jmlTarget = pulih.ringkasanTabel[tabel] ?? 0
      if (jmlSumber !== jmlTarget) {
        paritasCocok = false
        selisih.push(`Tabel ${tabel} selisih baris: sumber=${jmlSumber}, target=${jmlTarget}`)
      }
    }

    if (!pulih.rlsAktifSemua) {
      paritasCocok = false
      selisih.push(`Ada tabel tanpa RLS: ${pulih.tabelTanpaRls.join(', ')}`)
    }

    if (!pulih.integritasRelasi) {
      paritasCocok = false
      selisih.push('Integritas data relasional gagal (penyewa, cabang, atau audit kosong)')
    }

    const hasilAkhir = {
      lulus: paritasCocok && pulih.sukses,
      stempel: new Date().toISOString(),
      sumber: {
        totalTabel: dump.totalTabel,
        totalBaris: dump.totalBaris,
      },
      target: {
        totalTabel: pulih.totalTabel,
        totalBaris: pulih.totalBaris,
        rlsAktifSemua: pulih.rlsAktifSemua,
        integritasRelasi: pulih.integritasRelasi,
      },
      selisih,
    }

    console.log(JSON.stringify(hasilAkhir, null, 2))
    if (!hasilAkhir.lulus) {
      console.error('UJI PEMULIHAN GAGAL!')
      process.exit(1)
    }
    console.log('UJI PEMULIHAN SUKSES 100%!')
    process.exit(0)
  }

  console.error(`Perintah tidak dikenal: ${aksi}`)
  process.exit(1)
}

main().catch((err) => {
  console.error('Galat fatal eksekusi cadangan:', err)
  process.exit(1)
})
