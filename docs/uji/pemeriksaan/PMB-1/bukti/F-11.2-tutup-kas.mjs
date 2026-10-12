// Probe render komponen NYATA tanpa mengubah aplikasi. Bukan uji peramban/produksi.
// node docs/uji/pemeriksaan/PMB-1/bukti/F-11.2-tutup-kas.mjs
import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import { resolve, dirname } from 'node:path'
import { readFileSync } from 'node:fs'
const akar = resolve(dirname(fileURLToPath(import.meta.url)), '../../../../..')
const requireAlat = createRequire(resolve(akar, 'alat/package.json'))
const requireApp = createRequire(resolve(akar, 'aplikasi/package.json'))
const { build } = requireAlat('esbuild')
const React = requireApp('react')
const { renderToStaticMarkup } = requireApp('react-dom/server')
const berkas = resolve(akar, 'aplikasi/src/layar/kasir/TutupKas.tsx')
const hasil = await build({ entryPoints: [berkas], bundle: true, write: false,
  platform: 'node', format: 'cjs', packages: 'external', jsx: 'automatic' })
const modul = { exports: {} }
new Function('require', 'module', 'exports', hasil.outputFiles[0].text)(requireApp, modul, modul.exports)
const props = { shiftId: 'shift-uji', namaCabang: 'Cabang Uji F11',
  namaKasir: 'Kasir Uji F11', modalAwal: 100000, uangSeharusnyaPerkiraan: 120000 }
const html = renderToStaticMarkup(React.createElement(modul.exports.TutupKas, props))
assert.ok(html.includes('Cabang Uji F11') && html.includes('Kasir Uji F11'), 'artefak nyata menerima props')
assert.ok(html.includes('Uang Seharusnya (Sistem)'), 'ringkasan tunai nyata ada')
const daftarNontunai = /referensi|non.?tunai|QRIS|transfer|kartu/i
assert.equal(daftarNontunai.test(html), false, 'tidak ada daftar non-tunai di render siap')
assert.equal(daftarNontunai.test(readFileSync(berkas, 'utf8')), false,
  'tidak tersembunyi di cabang render lain atau props')
// Kontrol negatif untuk detektor: teks referensi harus terdeteksi dan klaim
// wajib-daftar pada HTML artefak nyata harus ditolak (bukan uji selalu hijau).
assert.ok(daftarNontunai.test('Nomor referensi QRIS'))
assert.throws(() => assert.match(html, daftarNontunai), { name: 'AssertionError' })
const htmlGagal = renderToStaticMarkup(React.createElement(modul.exports.TutupKas,
  { ...props, keadaan: 'gagal', pesanGalat: 'F11_PENOLAKAN_UJI' }))
assert.ok(htmlGagal.includes('F11_PENOLAKAN_UJI'), 'kontrol keadaan gagal benar-benar dirender')
console.log('LOLOS reproduksi: TutupKas nyata menampilkan ringkasan tunai; tidak ada daftar referensi non-tunai.')
console.log('Kontrol negatif: assertion wajib-daftar pada HTML nyata MERAH; keadaan gagal tampil.')
console.log('Batas: render React server + inspeksi props/sumber, bukan klik browser atau transaksi bank.')
