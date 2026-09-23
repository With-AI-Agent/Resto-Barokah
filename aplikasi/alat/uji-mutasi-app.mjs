#!/usr/bin/env node
/**
 * uji-mutasi-app.mjs — membuktikan uji aplikasi (Vitest) BENAR-BENAR menjaga perilaku.
 *
 * Kenapa ada: tiga temuan audit ditutup pada 2026-09-20 dan ketiganya kelas yang SAMA —
 * "alat bilang aman, padahal belum terbukti":
 *   * **I F-19** uji bernama "memanggil onUbah saat diisi" tidak pernah mengisi input;
 *   * **F F-14 / I F-05** `ujiSambungan()` melaporkan "berhasil" hanya dari kesehatan Auth,
 *     walau jalur data menolak/gagal;
 *   * **I F-06** kegagalan `localStorage` (izin ditolak / penyimpanan penuh) menembus
 *     helper tema dan memutus effect React.
 *
 * Uji yang baru ditulis bisa ikut "tumpul" di kemudian hari (mis. assert-nya dihapus saat
 * refactor). Harness ini menutup pintu itu: setiap mutasi perilaku di bawah WAJIB membuat
 * uji MERAH. Kalau ada mutasi yang lolos (uji tetap hijau), harness GAGAL — jaring bocor.
 *
 * Cara kerja (jujur, bukan tiruan):
 *   1. Salinan `aplikasi/` (tanpa `node_modules`/`dist`) dibuat di folder sementara;
 *      `node_modules` disambung ke aslinya supaya `vitest` yang dipakai sama persis.
 *   2. Salinan UTUH dijalankan dulu → wajib hijau (kontrol).
 *   3. Tiap mutasi ditulis ke berkas salinan (cari → ganti; pola tidak ketemu = GAGAL,
 *      karena berarti mutasinya tidak benar-benar diterapkan), lalu uji dijalankan dan
 *      WAJIB keluar bukan-nol. Sesudah itu berkas salinan dipulihkan.
 *   4. Tidak ada berkas repo yang disentuh — semua di folder sementara.
 *
 * Jalankan:  node aplikasi/alat/uji-mutasi-app.mjs      (--uji-diri membuktikan bisa GAGAL)
 * Butuh `npm ci` di `aplikasi/` (vitest). Keluar 2 kalau vitest tidak ada.
 */
import {
  cpSync,
  existsSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from 'node:fs'
import { spawnSync } from 'node:child_process'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { tmpdir } from 'node:os'

const AKAR_REPO = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..')
const APLIKASI = join(AKAR_REPO, 'aplikasi')
const VITEST = join(APLIKASI, 'node_modules', '.bin', 'vitest')

if (!existsSync(VITEST)) {
  console.log('GAGAL: vitest tidak ditemukan — tidak bisa membuktikan apa pun dengan jujur.')
  console.log('       Jalankan dulu: (cd aplikasi && npm ci)')
  process.exit(2)
}

/**
 * Daftar mutasi perilaku. `cari` harus KHAS: kalau kode berubah sampai pola ini hilang,
 * harness GAGAL (lebih baik berisik daripada diam-diam tidak menguji apa pun).
 */
const MUTASI = [
  {
    nama: 'handler onChange dilepas dari KolomIsian (I F-19)',
    berkas: 'src/komponen/KolomIsian.tsx',
    cari: 'onChange={(kejadian) => onUbah(kejadian.target.value)}',
    ganti: 'onChange={() => {}}',
    uji: 'src/komponen/komponen.test.tsx',
  },
  {
    nama: 'nilai yang dikirim onChange dirusak (I F-19)',
    berkas: 'src/komponen/KolomIsian.tsx',
    cari: 'onUbah(kejadian.target.value)',
    ganti: "onUbah(kejadian.target.value + 'X')",
    uji: 'src/komponen/komponen.test.tsx',
  },
  {
    nama: 'ok uji sambungan kembali hanya melihat jalur Auth (F F-14 / I F-05)',
    berkas: 'src/lib/supabase.ts',
    cari: 'if (jalur.auth && jalur.data) {',
    ganti: 'if (jalur.auth) {',
    uji: 'src/lib/supabase.test.ts',
  },
  {
    nama: 'getItem Storage dipanggil tanpa penjagaan (I F-06)',
    berkas: 'src/lib/tema.ts',
    cari: "  try {\n    return simpan?.getItem(kunci) ?? ''\n  } catch {\n    return ''\n  }",
    ganti: "  return simpan?.getItem(kunci) ?? ''",
    uji: 'src/lib/tema.test.ts',
  },
  {
    nama: 'setItem Storage dipanggil tanpa penjagaan (I F-06)',
    berkas: 'src/lib/tema.ts',
    cari: '  if (!simpan) return false\n  try {\n    simpan.setItem(kunci, nilai)\n    return true\n  } catch {\n    return false\n  }',
    ganti: '  if (!simpan) return false\n  simpan.setItem(kunci, nilai)\n  return true',
    uji: 'src/hook/useTema.test.tsx',
  },
  {
    nama: 'Bayar: penjaga uang diterima kurang dilepas (T5-01)',
    berkas: 'src/layar/kasir/Bayar.tsx',
    cari: '    (!tunai || nilaiDiterima >= jumlahBayar) &&',
    ganti: '    (!tunai || true) &&',
    uji: 'src/layar/kasir/Bayar.test.tsx',
  },
  {
    nama: 'Bayar: perkiraan kembalian tidak mengurangi tagihan (T5-01)',
    berkas: 'src/layar/kasir/Bayar.tsx',
    cari: 'Math.max(0, nilaiDiterima - sisa)',
    ganti: 'Math.max(0, nilaiDiterima)',
    uji: 'src/layar/kasir/Bayar.test.tsx',
  },
  {
    nama: 'useBayar: kunci idempoten diacak per klik — dobel tekan mencatat uang dua kali (T5-01)',
    berkas: 'src/hook/useBayar.ts',
    cari: 'p_kunci_idempoten: kunciIdempoten(pesananId, urutanBayar.current + 1),',
    ganti: 'p_kunci_idempoten: `bayar-${Math.random()}`,',
    uji: 'src/hook/useBayar.test.tsx',
  },
  {
    nama: 'useBayar: balasan dobel tetap memajukan urutan kunci (T5-01)',
    berkas: 'src/hook/useBayar.ts',
    cari: 'if (!balasan.dobel) urutanBayar.current += 1',
    ganti: 'urutanBayar.current += 1',
    uji: 'src/hook/useBayar.test.tsx',
  },
  {
    nama: 'LayarKasir: metode bayar dikeras-kodekan lagi di layar (T5-01)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '            metode={metodeBayar}',
    ganti:
      "            metode={[{ id: 'qris', nama: 'QRIS Dinamis', jenis: 'non_tunai', butuhReferensi: false, urutan: 1 }]}",
    uji: 'src/layar/kasir/LayarKasirBayar.test.tsx',
  },
  {
    nama: 'LayarKasir: keranjang dikosongkan walau tagihan belum lunas (T5-01)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '    if (terakhirBayar?.lunas) {',
    ganti: '    if (true) {',
    uji: 'src/layar/kasir/LayarKasirBayar.test.tsx',
  },
  {
    nama: 'Struk: pajak dihitung ulang di layar, bukan memakai angka peladen (T5-03)',
    berkas: 'src/komponen/Struk.tsx',
    cari: '<Baris label="PB1 (pajak)" nilai={rupiah(data.pajak)} penanda="pajak" />',
    ganti:
      '<Baris label="PB1 (pajak)" nilai={rupiah(Math.round(data.subtotal * 0.1))} penanda="pajak" />',
    uji: 'src/komponen/Struk.test.tsx',
  },
  {
    nama: 'Struk: selisih pembulatan tidak memperhitungkan diskon (T5-03)',
    berkas: 'src/komponen/Struk.tsx',
    cari: 'return data.total - (data.subtotal - data.totalDiskon + data.pajak + data.service)',
    ganti: 'return data.total - (data.subtotal + data.pajak + data.service)',
    uji: 'src/komponen/Struk.test.tsx',
  },
  {
    nama: 'Struk: baris pajak 0 persen disembunyikan (T5-03)',
    berkas: 'src/komponen/Struk.tsx',
    cari: '        <Baris label="Service" nilai={rupiah(data.service)} penanda="service" />',
    ganti:
      '        {data.service > 0 ? <Baris label="Service" nilai={rupiah(data.service)} penanda="service" /> : null}',
    uji: 'src/komponen/Struk.test.tsx',
  },
  {
    nama: 'DiskonManual: batas yang belum diketahui dianggap AMAN (T5-05) — layar berjanji lebih longgar daripada peladen',
    berkas: 'src/layar/kasir/DiskonManual.tsx',
    cari: '  if (!batas) return true',
    ganti: '  if (!batas) return false',
    uji: 'src/layar/kasir/DiskonManual.test.tsx',
  },
  {
    nama: 'DiskonManual: batas PERSEN tidak diperiksa (T5-05) — diskon kecil-rupiah tapi besar-persen lolos tanpa atasan',
    berkas: 'src/layar/kasir/DiskonManual.tsx',
    cari: '  if (batas.batasPersen !== null && persenEfektif(nilai, subtotal) > batas.batasPersen) return true',
    ganti: '  // mutasi: batas persen tidak diperiksa',
    uji: 'src/layar/kasir/DiskonManual.test.tsx',
  },
  {
    nama: 'DiskonManual: tombol terapkan hidup tanpa persetujuan atasan (T5-05)',
    berkas: 'src/layar/kasir/DiskonManual.tsx',
    cari: '    nilai > 0 && alasanTerisi && !sedangKirim && (!perluPersetujuan || sudahDisetujui)',
    ganti: '    nilai > 0 && alasanTerisi && !sedangKirim',
    uji: 'src/layar/kasir/DiskonManual.test.tsx',
  },
  {
    nama: 'DiskonManual: alasan tidak lagi wajib (T5-05) — laporan diskon kehilangan maknanya',
    berkas: 'src/layar/kasir/DiskonManual.tsx',
    cari: '  const alasanTerisi = alasan.trim().length > 0',
    ganti: '  const alasanTerisi = true',
    uji: 'src/layar/kasir/DiskonManual.test.tsx',
  },
  {
    nama: 'DiskonManual: PIN yang DITOLAK tetap dianggap persetujuan sah (T5-05)',
    berkas: 'src/layar/kasir/DiskonManual.tsx',
    cari: '    if (hasil?.berhasil) {\n      setDisetujuiOleh(atasanId)',
    ganti: '    if (true) {\n      setDisetujuiOleh(atasanId)',
    uji: 'src/layar/kasir/DiskonManual.test.tsx',
  },
  {
    nama: 'LayarKasir: diskon yang DITOLAK peladen tetap memotong tagihan di layar (T5-05)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '    if (hasil?.berhasil) {\n      setDiskonAktif((sebelumnya) => sebelumnya + masukan.nilai)',
    ganti: '    if (true) {\n      setDiskonAktif((sebelumnya) => sebelumnya + masukan.nilai)',
    uji: 'src/layar/kasir/LayarKasirDiskon.test.tsx',
  },

  // ----------------------------------------------------------- T5-06 void pra-dapur
  {
    nama: 'VoidItem: alasan tidak lagi wajib (T5-06) — laporan pembatalan jadi kosong artinya',
    berkas: 'src/layar/kasir/VoidItem.tsx',
    cari: '  const alasanTerisi = alasan.trim().length > 0',
    ganti: '  const alasanTerisi = true',
    uji: 'src/layar/kasir/VoidItem.test.tsx',
  },
  {
    nama: 'VoidItem: penolakan peladen disulap jadi berhasil (T5-06)',
    berkas: 'src/layar/kasir/VoidItem.tsx',
    cari: '    if (hasil && !hasil.berhasil) {',
    ganti: '    if (false) {',
    uji: 'src/layar/kasir/VoidItem.test.tsx',
  },
  {
    nama: 'LayarKasir: item tercatat dihapus tanpa alasan (T5-06) — celah lama kambuh',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '    if (!onBatalkanItem) {',
    ganti: '    if (true) {',
    uji: 'src/layar/kasir/LayarKasirVoid.test.tsx',
  },
  {
    nama: 'LayarKasir: item lenyap dari layar walau peladen MENOLAK pembatalan (T5-06)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '    if (hasil?.berhasil) {\n      setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== itemVoid))',
    ganti:
      '    if (true) {\n      setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== itemVoid))',
    uji: 'src/layar/kasir/LayarKasirVoid.test.tsx',
  },

  // ------------------------------------------------- T5-08 data pelanggan (privasi)
  {
    nama: 'DataPelanggan: nomor HP terkirim TANPA persetujuan (T5-08) — pelanggaran UU PDP',
    berkas: 'src/layar/kasir/DataPelanggan.tsx',
    cari: '  const bolehSimpan = setuju && nomorMasukAkal(noHp) && !sedangKirim',
    ganti: '  const bolehSimpan = nomorMasukAkal(noHp) && !sedangKirim',
    uji: 'src/layar/kasir/DataPelanggan.test.tsx',
  },
  {
    nama: 'DataPelanggan: tombol Lewati dimatikan (T5-08) — data pelanggan jadi syarat membayar',
    berkas: 'src/layar/kasir/DataPelanggan.tsx',
    cari: '<Tombol ragam="biasa" onClick={onLewati} nama="Lewati data pelanggan">',
    ganti: '<Tombol ragam="biasa" onClick={onLewati} nama="Lewati data pelanggan" nonaktif>',
    uji: 'src/layar/kasir/DataPelanggan.test.tsx',
  },

  // ------------------------------------------------- T5-09 struk digital (cadangan)
  {
    nama: 'StrukDigital: tombol Bagikan tampil walau peramban tidak mendukung (T5-09) — kasir menekan tombol mati saat antre',
    berkas: 'src/komponen/StrukDigital.tsx',
    cari: '        {bisaBagikan() && (',
    ganti: '        {true && (',
    uji: 'src/komponen/StrukDigital.test.tsx',
  },
  {
    nama: 'StrukDigital: ringkasan mengaku LUNAS walau belum dibayar (T5-09)',
    berkas: 'src/komponen/StrukDigital.tsx',
    cari: "    lunas ? 'LUNAS — terima kasih.' : 'Belum lunas.',",
    ganti: "    'LUNAS — terima kasih.',",
    uji: 'src/komponen/StrukDigital.test.tsx',
  },

  // ------------------------------------------- T5-10 cetak ulang struk (SALINAN)
  {
    nama: 'Struk: tanda SALINAN tidak pernah tampil (T5-10) — cetak ulang bisa menyamar jadi struk asli',
    berkas: 'src/komponen/Struk.tsx',
    cari: '        {salinan ? (',
    ganti: '        {false ? (',
    uji: 'src/layar/kasir/DaftarTransaksi.test.tsx',
  },
  {
    nama: 'DaftarTransaksi: pratinjau cetak ulang dirender TANPA tanda salinan (T5-10)',
    berkas: 'src/layar/kasir/DaftarTransaksi.tsx',
    cari: '            kembalian={barisDipilih.kembalian ?? 0}\n            salinan',
    ganti: '            kembalian={barisDipilih.kembalian ?? 0}',
    uji: 'src/layar/kasir/DaftarTransaksi.test.tsx',
  },
  {
    nama: 'DaftarTransaksi: tombol cetak ulang hidup tanpa memilih transaksi (T5-10)',
    berkas: 'src/layar/kasir/DaftarTransaksi.tsx',
    cari: '          nonaktif={!barisDipilih}',
    ganti: '          nonaktif={false}',
    uji: 'src/layar/kasir/DaftarTransaksi.test.tsx',
  },
]

/**
 * Jalankan vitest pada satu berkas uji di dalam salinan.
 *
 * Mengembalikan { kode, keluaran, merahSah }. `merahSah` PENTING: kode bukan-nol saja tidak
 * cukup, karena vitest juga keluar bukan-nol saat GAGAL MULAI. Pelajaran nyata sesi ini:
 * opsi `--reporter=basic` sudah tidak ada di Vitest 5, dan akibatnya SEMUA mutasi terlihat
 * "merah" padahal ujinya tidak pernah jalan. Karena itu kode bukan-nol hanya dihitung bukti
 * kalau keluaran benar-benar memuat kegagalan uji (dan bukan galat startup).
 */
function jalankanUji(akarSalinan, berkasUji, { tampilSaatGagal = false } = {}) {
  const hasil = spawnSync(VITEST, ['run', berkasUji], {
    cwd: akarSalinan,
    encoding: 'utf8',
    env: { ...process.env, CI: 'true' },
  })
  const keluaran = `${hasil.stdout || ''}\n${hasil.stderr || ''}`
  const kode = hasil.status ?? 1
  const gagalMulai = /Startup Error|Failed to load (custom Reporter|url)/.test(keluaran)
  const gagalUji = /(Test Files|Tests)\s+[^\n]*failed/.test(keluaran)
  if (kode !== 0 && tampilSaatGagal) {
    console.log(keluaran.split('\n').slice(-18).join('\n'))
  }
  return { kode, keluaran, merahSah: kode !== 0 && gagalUji && !gagalMulai, gagalMulai }
}

/** Salin aplikasi/ (tanpa node_modules & hasil bangun) lalu sambungkan node_modules. */
function siapkanSalinan(sementara) {
  const salinan = join(sementara, 'aplikasi')
  cpSync(APLIKASI, salinan, {
    recursive: true,
    filter: (sumber) => !/[/\\](node_modules|dist|coverage|\.vite)([/\\]|$)/.test(sumber),
  })
  symlinkSync(join(APLIKASI, 'node_modules'), join(salinan, 'node_modules'), 'dir')
  return salinan
}

/** Terapkan satu mutasi (cari→ganti) ke salinan. Kembalikan `false` kalau pola tak ketemu. */
function terapkanMutasi(salinan, mutasi) {
  const berkas = join(salinan, mutasi.berkas)
  const asli = readFileSync(berkas, 'utf8')
  if (!asli.includes(mutasi.cari)) return false
  writeFileSync(berkas, asli.replace(mutasi.cari, mutasi.ganti), 'utf8')
  return true
}

/**
 * Inti harness: jalankan kontrol (opsional) + daftar mutasi pada salinan.
 * Kembalikan { kasus, gagal } — dipakai mode normal DAN mode --uji-diri.
 */
function jalankan(salinan, daftar, { kontrol = true } = {}) {
  const kasus = []
  let gagal = 0
  if (kontrol) {
    const hasilKontrol = jalankanUji(salinan, 'src', { tampilSaatGagal: true })
    const sesuai = hasilKontrol.kode === 0
    kasus.push([
      'kontrol: salinan utuh (seluruh uji aplikasi)',
      sesuai,
      sesuai ? 'hijau' : `kode ${hasilKontrol.kode} — salinan utuh pun gagal, bukan soal mutasi`,
    ])
    if (!sesuai) gagal += 1
  }
  for (const m of daftar) {
    if (!terapkanMutasi(salinan, m)) {
      kasus.push([`mutasi: ${m.nama}`, false, 'pola TIDAK ketemu — mutasi tidak diterapkan'])
      gagal += 1
      continue
    }
    const hasil = jalankanUji(salinan, m.uji)
    // Pulihkan berkas salinan supaya mutasi berikutnya berangkat dari kode yang benar.
    const asli = readFileSync(join(salinan, m.berkas), 'utf8')
    writeFileSync(join(salinan, m.berkas), asli.replace(m.ganti, m.cari), 'utf8')
    kasus.push([
      `mutasi: ${m.nama}`,
      hasil.merahSah,
      hasil.merahSah
        ? 'uji MERAH (benar)'
        : hasil.gagalMulai
          ? 'vitest GAGAL MULAI — merah palsu, BUKAN bukti'
          : 'uji TETAP HIJAU (jaring bocor)',
    ])
    if (!hasil.merahSah) gagal += 1
  }
  return { kasus, gagal }
}

function cetak(kasus, gagal, jumlahMutasi) {
  for (const [nama, sesuai, ringkas] of kasus) {
    console.log(`  ${sesuai ? 'OK ' : 'X  '} ${nama} → ${ringkas}`)
  }
  console.log('-'.repeat(70))
  if (gagal) {
    console.log(
      `HASIL: GAGAL — ${gagal} kasus. Jaring pengaman uji aplikasi bocor; perbaiki ujinya.`,
    )
    return
  }
  console.log(
    `HASIL: LOLOS — salinan utuh hijau, ${jumlahMutasi} mutasi perilaku semuanya membuat uji MERAH.`,
  )
}

/** Membuktikan harness ini bisa GAGAL: ujinya dilemahkan, mutasi yang sama harus lolos → terdeteksi. */
function ujiDiri() {
  console.log('UJI-DIRI uji-mutasi-app — harness wajib bisa MENOLAK saat jaring ujinya bocor\n')
  const sementara = mkdtempSync(join(tmpdir(), 'uji-mutasi-app-diri-'))
  const hasil = []
  try {
    const salinan = siapkanSalinan(sementara)
    // 1. Pola mutasi yang tidak ada di kode → wajib dianggap GAGAL (fail-closed).
    const mutasiSalah = [{ ...MUTASI[0], cari: 'pola-yang-tidak-pernah-ada', ganti: 'apa saja' }]
    const a = jalankan(salinan, mutasiSalah, { kontrol: false })
    hasil.push(['pola mutasi tidak ketemu → harness GAGAL', a.gagal > 0, `${a.gagal} kasus gagal`])

    // 2. Uji dilemahkan (assert interaksi dibuang) → mutasi yang sama harus terdeteksi lolos.
    const berkas = join(salinan, 'src/komponen/komponen.test.tsx')
    const asli = readFileSync(berkas, 'utf8')
    const lemah = asli
      .replace('    expect(onUbah).toHaveBeenCalledTimes(1)\n', '')
      .replace("    expect(onUbah).toHaveBeenCalledWith('Budi')\n", '')
    if (lemah === asli) {
      hasil.push(['uji bisa dilemahkan untuk uji-diri', false, 'pola assert tidak ketemu'])
    } else {
      writeFileSync(berkas, lemah, 'utf8')
      const b = jalankan(salinan, [MUTASI[0]], { kontrol: false })
      writeFileSync(berkas, asli, 'utf8')
      hasil.push([
        'uji dilemahkan → mutasi DILOLOSKAN dan harness menolaknya',
        b.gagal > 0,
        b.gagal > 0 ? 'terdeteksi' : 'TIDAK terdeteksi (harness buta)',
      ])
    }
  } finally {
    rmSync(sementara, { recursive: true, force: true })
  }

  let gagal = 0
  for (const [nama, sesuai, ringkas] of hasil) {
    if (!sesuai) gagal += 1
    console.log(`  ${sesuai ? 'OK ' : 'X  '} ${nama} → ${ringkas}`)
  }
  console.log('-'.repeat(70))
  if (gagal) {
    console.log(`HASIL: GAGAL — ${gagal} kasus uji-diri tidak sesuai harapan.`)
    process.exit(1)
  }
  console.log('HASIL: LOLOS — harness terbukti bisa MENOLAK saat jaring ujinya bocor.')
}

console.log('UJI MUTASI KODE APLIKASI — membuktikan uji Vitest bisa MERAH pada cacat nyata')
console.log('(salinan sementara; berkas repo tidak disentuh)\n')

if (process.argv.includes('--uji-diri')) {
  ujiDiri()
} else {
  const sementara = mkdtempSync(join(tmpdir(), 'uji-mutasi-app-'))
  let hasil
  try {
    hasil = jalankan(siapkanSalinan(sementara), MUTASI)
  } finally {
    rmSync(sementara, { recursive: true, force: true })
  }
  cetak(hasil.kasus, hasil.gagal, MUTASI.length)
  if (hasil.gagal) process.exit(1)
}
