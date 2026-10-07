// Harness HAKIM H-F-03.5 (2026-10-02) — apakah BACKFILL migrasi 0095 selamat bila data lama SUDAH memuat
// satu nomor dalam dua bentuk? (Bentuk itu justru yang bisa lahir di bawah 0093, sebelum 0095 ada.)
//
// Cara jalan (dari akar repo, pakai PGlite yang sama dengan alat/uji-sql.mjs):
//   node docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-uji-backfill.cjs
//
// Urutan tiap skenario: persiapan runner (peran, auth, alat uji) -> migrasi 0001..0094 -> data-uji.sql ->
// data LAMA disisipkan -> migrasi 0095 DITERAPKAN SEBAGAI BERKAS UTUH (satu `exec` = satu transaksi, sama seperti
// satu berkas migrasi) -> keadaan sesudahnya dicetak.
//   1. KONTROL : data lama tanpa kembaran -> 0095 harus berhasil dan merapikan nomor (membuktikan harness benar).
//   2. UJI A   : kembaran disisipkan langsung (0812... dan 62812...).
//   3. UJI B   : kembaran lahir lewat RPC asli daftar_voucher oleh kasir Rina di bawah 0093 (jalur nyata).
// Tidak menulis apa pun ke repo. Tidak menyentuh produksi.
const fs = require('node:fs')
const path = require('node:path')

const AKAR = process.env.AKAR || path.resolve(__dirname, '..', '..', '..', '..', '..')
const { PGlite } = require(path.join(AKAR, 'alat', 'node_modules', '@electric-sql/pglite'))

// SKEMA_UJI diambil dari runner resmi supaya persiapannya identik (tanpa menyalin teksnya).
const runner = fs.readFileSync(path.join(AKAR, 'alat', 'uji-sql.mjs'), 'utf8')
const cocok = runner.match(/const SKEMA_UJI = `([\s\S]*?)\n`\n/)
if (!cocok) throw new Error('SKEMA_UJI tidak ditemukan di alat/uji-sql.mjs')
const SKEMA = new Function('return `' + cocok[1] + '\n`')()

const DIR_MIGRASI = path.join(AKAR, 'supabase', 'migrations')
const BERKAS_0095 = fs.readdirSync(DIR_MIGRASI).find((f) => f.startsWith('0095_'))
const PENYEWA = '11111111-1111-1111-1111-111111111111'
const RINA = '90000000-0000-0000-0000-000000000004'

async function siapkan() {
  const db = await PGlite.create()
  await db.exec(SKEMA)
  for (const f of fs.readdirSync(DIR_MIGRASI).filter((x) => x.endsWith('.sql')).sort()) {
    if (f >= '0095') continue
    await db.exec(fs.readFileSync(path.join(DIR_MIGRASI, f), 'utf8'))
  }
  await db.exec(fs.readFileSync(path.join(AKAR, 'alat', 'sql', 'data-uji.sql'), 'utf8'))
  return db
}

async function sisipLangsung(db, baris) {
  for (const [nama, telepon] of baris) {
    await db.exec(`insert into public.pelanggan
      (penyewa_id, nama, cara_masuk, didaftarkan_oleh, persetujuan_privasi, telepon)
      values ('${PENYEWA}', '${nama}', 'kasir', '${RINA}', true, '${telepon}')`)
  }
}

async function lahirLewatRpc(db, pasangan) {
  await db.exec(`insert into public.kampanye_voucher
    (id, penyewa_id, nama, kode_kampanye, jenis, nilai, min_belanja, mulai, selesai, kuota, aktif)
    values ('c3000000-0000-0000-0000-000000000801', '${PENYEWA}', 'Kampanye lama', 'LAMA', 'nominal', 20000, 50000,
            now() - interval '1 hour', now() + interval '1 day', 100, true)`)
  for (const [nama, telepon, ip] of pasangan) {
    await db.exec(`
      select uji.klaim('${RINA}');
      set role authenticated;
      select public.daftar_voucher('${PENYEWA}', 'c3000000-0000-0000-0000-000000000801',
             '${nama}', null, '${telepon}', null, true, 'kasir', 'hp-lama', '${ip}');
      reset role;`)
  }
}

async function keadaan(db) {
  return (await db.query(
    `select nama, telepon from public.pelanggan where nama like 'LAMA%' or nama like 'Orang %' order by nama`
  )).rows
}

async function skenario(judul, isi) {
  const db = await siapkan()
  await isi(db)
  const sebelum = await keadaan(db)
  let hasil
  try {
    await db.exec(fs.readFileSync(path.join(DIR_MIGRASI, BERKAS_0095), 'utf8'))
    hasil = 'MIGRASI 0095 BERHASIL'
  } catch (e) {
    hasil = 'MIGRASI 0095 GAGAL: ' + String(e.message).split('\n')[0]
  }
  const sesudah = await keadaan(db)
  const adaFungsi = (await db.query(
    `select count(*)::int as n from pg_proc where proname = 'normalisasi_telepon_pelanggan'`
  )).rows[0].n
  console.log(`\n## ${judul}`)
  console.log(`  berkas   : ${BERKAS_0095}`)
  console.log(`  sebelum  : ${JSON.stringify(sebelum)}`)
  console.log(`  hasil    : ${hasil}`)
  console.log(`  sesudah  : ${JSON.stringify(sesudah)}`)
  console.log(`  fungsi normalisasi_telepon_pelanggan ada sesudahnya: ${adaFungsi === 1 ? 'ya' : 'TIDAK (seluruh berkas migrasi dibatalkan)'}`)
  await db.close()
}

;(async () => {
  await skenario('1. KONTROL: data lama tanpa kembaran (harus berhasil dan merapikan)', (db) =>
    sisipLangsung(db, [['LAMA-A', '081234567890'], ['LAMA-B', '6281399998888']]))
  await skenario('2. UJI A: data lama memuat nomor SAMA dalam dua bentuk (0812... dan 62812...), disisipkan langsung', (db) =>
    sisipLangsung(db, [['LAMA-A', '081234567890'], ['LAMA-B', '6281234567890']]))
  await skenario('3. UJI B: kembaran lahir lewat RPC asli daftar_voucher oleh kasir Rina di bawah 0093', (db) =>
    lahirLewatRpc(db, [
      ['Orang Pertama', '0812-3456-7890', '10.8.0.1'],
      ['Orang Kedua', '+62 812-3456-7890', '10.8.0.2'],
    ]))
})().catch((e) => {
  console.error('HARNESS GALAT', e)
  process.exit(2)
})
