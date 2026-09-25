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

  // ------------------------- T5-11 tagihan ditinggal & pembayaran sebagian
  {
    nama: 'DaftarTagihan: tingkat umur selalu "baru" (T5-11) — tagihan 3 jam terlihat sama santainya dengan yang 5 menit',
    berkas: 'src/layar/kasir/DaftarTagihan.tsx',
    cari: "  if (menit >= BATAS_MENDESAK_MENIT) return 'mendesak'",
    ganti: "  if (false) return 'mendesak'",
    uji: 'src/layar/kasir/DaftarTagihan.test.tsx',
  },
  {
    nama: 'DaftarTagihan: sisa tagihan mengabaikan uang yang sudah masuk (T5-11) — tamu ditagih dua kali',
    berkas: 'src/layar/kasir/DaftarTagihan.tsx',
    cari: '  return Math.max(0, baris.total - baris.sudahDibayar)',
    ganti: '  return baris.total',
    uji: 'src/layar/kasir/DaftarTagihan.test.tsx',
  },
  {
    nama: 'DaftarTagihan: umur ditulis sebagai angka menit mentah (T5-11) — "200 menit" harus dihitung sendiri oleh kasir',
    berkas: 'src/layar/kasir/DaftarTagihan.tsx',
    cari: '  if (menit < 60) return `${menit} menit`',
    ganti: '  return `${menit} menit`\n  if (menit < 60) return `${menit} menit`',
    uji: 'src/layar/kasir/DaftarTagihan.test.tsx',
  },

  // ------------------------------ T-027 tarif pajak/service dari pengaturan
  {
    nama: 'Keranjang kembali memakai pajak 10% keras-kode (T-027) — kedai bertarif lain melihat angka meleset',
    berkas: 'src/lib/tarif.ts',
    cari: '  const pajak = Math.round((dasar * bersihkanPersen(tarif.pajakPersen)) / 100)',
    ganti: '  const pajak = Math.round(dasar * 0.1)',
    uji: 'src/lib/tarif.test.ts',
  },
  {
    nama: 'Perkiraan menghitung pajak SEBELUM diskon (T-027) — beda dari peladen tepat saat ada diskon',
    berkas: 'src/lib/tarif.ts',
    cari: '  const dasar = Math.max(0, subtotal - totalDiskon)',
    ganti: '  const dasar = Math.max(0, subtotal)',
    uji: 'src/lib/tarif.test.ts',
  },
  {
    nama: 'Pembulatan total dibulatkan NAIK (T-027) — perkiraan lebih besar daripada tagihan sebenarnya',
    berkas: 'src/lib/tarif.ts',
    cari: '  const total = langkah > 0 ? Math.floor(kasar / langkah) * langkah : kasar',
    ganti: '  const total = langkah > 0 ? Math.ceil(kasar / langkah) * langkah : kasar',
    uji: 'src/lib/tarif.test.ts',
  },
  {
    nama: 'LayarKasir mengabaikan prop tarif dan memakai bawaan (T-027)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '  const ringkasanUang: RingkasanUang = hitungPerkiraan(subtotal, diskonAktif, tarif)',
    ganti:
      '  const ringkasanUang: RingkasanUang = hitungPerkiraan(subtotal, diskonAktif, TARIF_BAWAAN)',
    uji: 'src/layar/kasir/LayarKasir.test.tsx',
  },

  // ------------------------------------------ T5-12 laporan pembatalan
  {
    nama: 'Laporan pembatalan menghitung SEMUA baris sebagai kerugian (T5-12) — pesanan yang belum dimasak pun dilaporkan rugi',
    berkas: 'src/layar/laporan/DaftarPembatalan.tsx',
    cari: '        totalKerugian: akum.totalKerugian + (sesudah ? baris.nilaiKerugian : 0),',
    ganti: '        totalKerugian: akum.totalKerugian + baris.nilaiKerugian,',
    uji: 'src/layar/laporan/DaftarPembatalan.test.tsx',
  },
  {
    nama: 'Laporan pembatalan menyembunyikan alasan (T5-12) — pola masalah berulang tidak bisa ditelusuri',
    berkas: 'src/layar/laporan/DaftarPembatalan.tsx',
    cari: '                “{baris.alasan}”',
    ganti: '                “dibatalkan”',
    uji: 'src/layar/laporan/DaftarPembatalan.test.tsx',
  },
  {
    nama: 'Laporan pembatalan tidak menyebut pelakunya (T5-12) — PRD M8 menuntut "siapa"',
    berkas: 'src/layar/laporan/DaftarPembatalan.tsx',
    cari: "                  oleh {baris.pelakuNama ?? 'pengguna terhapus'}",
    ganti: '                  oleh pegawai',
    uji: 'src/layar/laporan/DaftarPembatalan.test.tsx',
  },
  {
    nama: 'Semua pembatalan ditandai sebagai pra-dapur (T5-12) — kerugian nyata tak bisa dibedakan',
    berkas: 'src/layar/laporan/DaftarPembatalan.tsx',
    cari: "  return tahap === 'sesudah_dapur' ? 'Sesudah dapur mulai' : 'Sebelum dapur mulai'",
    ganti: "  return 'Sebelum dapur mulai'",
    uji: 'src/layar/laporan/DaftarPembatalan.test.tsx',
  },

  // ------------------------------------------------ T6-01 ESC/POS termal
  {
    nama: 'ESC/POS memotong ANGKA saat baris sempit (T6-01) — struk menyebut nilai uang yang salah',
    berkas: 'src/lib/printer/expos.ts',
    cari: '  if (lebarKanan >= lebar) return kanan',
    ganti: '  if (lebarKanan >= lebar) return potong(kanan, lebar)',
    uji: 'src/lib/printer/expos.test.ts',
  },
  {
    nama: 'Huruf beraksen DIBUANG, bukan diganti (T6-01) — panjang baris meleset, kolom rupiah bergeser',
    berkas: 'src/lib/printer/expos.ts',
    cari: "    keluar.push(0x3f) // '?'",
    ganti: '    continue',
    uji: 'src/lib/printer/expos.test.ts',
  },
  {
    nama: 'Potong kertas tanpa umpan baris (T6-01) — baris terakhir struk ikut terpotong pisau',
    berkas: 'src/lib/printer/expos.ts',
    cari: '    this.lf().lf().lf()\n    this.bagian.push(GS, 0x56, 0x00)',
    ganti: '    this.bagian.push(GS, 0x56, 0x00)',
    uji: 'src/lib/printer/expos.test.ts',
  },
  {
    nama: 'Lebar 80 mm disamakan dengan 58 mm (T6-01) — separuh kertas terbuang',
    berkas: 'src/lib/printer/expos.ts',
    cari: 'export const LEBAR_80MM = 48',
    ganti: 'export const LEBAR_80MM = 32',
    uji: 'src/lib/printer/expos.test.ts',
  },
  {
    nama: 'Pembungkus catatan memenggal kata di tengah (T6-01) — catatan dapur berubah arti',
    berkas: 'src/lib/printer/expos.ts',
    cari: '    if (lebarCetak(calon) <= lebar) {',
    ganti: '    if (lebarCetak(calon) <= lebar + 4) {',
    uji: 'src/lib/printer/expos.test.ts',
  },

  // -------------------------------------------------- T6-04 struk termal
  {
    nama: 'Struk termal menyembunyikan pajak/service saat 0 persen (T6-04) — resto tampak menyembunyikan pungutan',
    berkas: 'src/lib/printer/struk.ts',
    cari: "  p.kiriKanan('PB1 (pajak)', rupiah(data.pajak))\n  p.kiriKanan('Service', rupiah(data.service))",
    ganti:
      "  if (data.pajak > 0) p.kiriKanan('PB1 (pajak)', rupiah(data.pajak))\n  if (data.service > 0) p.kiriKanan('Service', rupiah(data.service))",
    uji: 'src/lib/printer/struk.test.ts',
  },
  {
    nama: 'Struk termal diam soal sisa tagihan (T6-04) — tamu mengira sudah lunas, selisih baru ketahuan saat tutup kas',
    berkas: 'src/lib/printer/struk.ts',
    cari: "      p.kiriKanan('Sisa tagihan', rupiah(sisa))",
    ganti: '      void sisa',
    uji: 'src/lib/printer/struk.test.ts',
  },
  {
    nama: 'Struk termal menghitung kembalian sendiri (T6-04) — melanggar ART-3, angka layar bisa beda dari kas',
    berkas: 'src/lib/printer/struk.ts',
    cari: "    p.kiriKanan('Kembalian', rupiah(opsi.kembalian ?? 0))",
    ganti:
      "    p.kiriKanan('Kembalian', rupiah(Math.max(0, dibayarSementara(pembayaran) - data.total)))",
    uji: 'src/lib/printer/struk.test.ts',
  },
  {
    nama: 'Struk termal membuka laci kas untuk SEMUA metode (T6-04) — laci terbuka saat bayar QRIS',
    berkas: 'src/lib/printer/struk.ts',
    cari: '  if (opsi.bukaLaci) p.bukaLaci()',
    ganti: '  p.bukaLaci()',
    uji: 'src/lib/printer/struk.test.ts',
  },
  {
    nama: 'Nama menu panjang dicetak mentah (T6-04) — baris melebihi kertas, printer melipat sembarangan',
    berkas: 'src/lib/printer/struk.ts',
    cari: '    for (const barisNama of bungkusTeks(item.nama, lebar)) p.baris(barisNama)',
    ganti: '    p.baris(item.nama)',
    uji: 'src/lib/printer/struk.test.ts',
  },
  {
    nama: 'Tanda SALINAN dihapus dari struk termal (T6-04/T5-10) — cetakan kedua bisa menyamar jadi bukti asli',
    berkas: 'src/lib/printer/struk.ts',
    cari: "    p.tebal(true).baris('SALINAN - CETAK ULANG').tebal(false)",
    ganti: '    p.tebal(false)',
    uji: 'src/lib/printer/struk.test.ts',
  },

  // -------------------------------------------------- T6-05 tiket dapur
  {
    nama: 'Catatan khusus tidak lagi dicetak tebal (T6-05) — "tanpa kacang" tenggelam, padahal bisa berarti alergi',
    berkas: 'src/lib/printer/tiket.ts',
    cari: '      for (const baris of bungkusTeks(`>> ${item.catatan}`, lebar)) p.baris(baris)',
    ganti: '      for (const baris of bungkusTeks(`${item.catatan}`, lebar)) p.baris(baris)',
    uji: 'src/lib/printer/tiket.test.ts',
  },
  {
    nama: 'Catatan khusus dibuang dari tiket (T6-05) — dapur tidak pernah tahu permintaan tamu',
    berkas: 'src/lib/printer/tiket.ts',
    cari: '    if (item.catatan) {',
    ganti: '    if (false && item.catatan) {',
    uji: 'src/lib/printer/tiket.test.ts',
  },
  {
    nama: 'Nomor pesanan dicetak ukuran biasa (T6-05) — pelayan salah ambil pesanan',
    berkas: 'src/lib/printer/tiket.ts',
    cari: '  p.hurufBesar(true).tebal(true).baris(`#${data.nomor}`).tebal(false).hurufBesar(false)',
    ganti: '  p.baris(`#${data.nomor}`)',
    uji: 'src/lib/printer/tiket.test.ts',
  },
  {
    nama: 'Tiket stasiun ikut memuat item stasiun lain (T6-05) — dapur memasak minuman, bar memasak nasi',
    berkas: 'src/lib/printer/tiket.ts',
    cari: "  const minuman = data.item.filter((i) => i.stasiun === 'minuman')",
    ganti: '  const minuman = data.item',
    uji: 'src/lib/printer/tiket.test.ts',
  },
  {
    nama: 'Stasiun kosong tetap mencetak tiket (T6-05) — kertas terbuang & tiket kosong membingungkan',
    berkas: 'src/lib/printer/tiket.ts',
    cari: '  if (minuman.length > 0) {',
    ganti: '  if (true) {',
    uji: 'src/lib/printer/tiket.test.ts',
  },
  {
    nama: 'Nama menu panjang dicetak mentah di tiket (T6-05) — baris melebihi kertas',
    berkas: 'src/lib/printer/tiket.ts',
    cari: '    for (const baris of bungkusTeks(`${item.qty}x ${item.nama}`, lebar)) p.baris(baris)',
    ganti: '    p.baris(`${item.qty}x ${item.nama}`)',
    uji: 'src/lib/printer/tiket.test.ts',
  },

  // ------------------- T6-02/T6-03 sambungan + JAMINAN merek lain jalan
  {
    nama: 'Printer di luar daftar DITOLAK (T6-02) — janji "merek lain tetap jalan" dilanggar',
    berkas: 'src/lib/printer/profil.ts',
    cari: '  return PROFIL_UMUM\n}',
    ganti: "  throw new Error('printer tidak dikenal')\n}",
    uji: 'src/lib/printer/profil.test.ts',
  },
  {
    nama: 'Profil umum diam-diam jadi 80 mm (T6-02) — struk 58 mm kehilangan angka di kanan',
    berkas: 'src/lib/printer/profil.ts',
    cari: "  id: 'umum-58',\n  nama: 'Printer ESC/POS umum (58 mm)',\n  lebar: LEBAR_58MM,",
    ganti: "  id: 'umum-58',\n  nama: 'Printer ESC/POS umum (58 mm)',\n  lebar: LEBAR_80MM,",
    uji: 'src/lib/printer/profil.test.ts',
  },
  {
    nama: 'Penelusuran BLE menyeluruh dicabut (T6-02) — hanya printer beralamat dikenal yang bisa dipakai',
    berkas: 'src/lib/printer/kirim.ts',
    cari: "  if (typeof peladen.getPrimaryServices === 'function') {",
    ganti: '  if (false) {',
    uji: 'src/lib/printer/kirim.test.ts',
  },
  {
    nama: 'USB hanya menerima kelas 7 (T6-03) — printer yang tidak mengaku printer ditolak',
    berkas: 'src/lib/printer/kirim.ts',
    cari: '  // Tahap 2 — jalur keluar apa pun.\n  for (const antarmuka of konfigurasi.interfaces) {',
    ganti: '  // Tahap 2 dicabut.\n  for (const antarmuka of [] as AntarmukaUsb[]) {',
    uji: 'src/lib/printer/kirim.test.ts',
  },
  {
    nama: 'Data dikirim sekaligus tanpa dipotong (T6-02) — printer mencetak setengah lalu berhenti',
    berkas: 'src/lib/printer/kirim.ts',
    cari: '  for (let i = 0; i < data.length; i += besar) {\n    hasil.push(data.slice(i, i + besar))\n  }',
    ganti: '  hasil.push(data)',
    uji: 'src/lib/printer/kirim.test.ts',
  },
  {
    nama: 'Antarmuka USB tidak dilepas sesudah cetak (T6-03) — cetak berikutnya gagal "dipakai program lain"',
    berkas: 'src/lib/printer/kirim.ts',
    cari: '      if (nomorAntarmuka !== null && perangkat.releaseInterface) {\n        await perangkat.releaseInterface(nomorAntarmuka)\n      }',
    ganti: '      void nomorAntarmuka',
    uji: 'src/lib/printer/kirim.test.ts',
  },

  // ------------------- T7-01 buka kas / modal awal (M7)
  {
    nama: 'BukaKas: tombol lanjut aktif meski modal awal kosong (T7-01) — modal awal tidak lagi wajib',
    berkas: 'src/layar/kasir/BukaKas.tsx',
    cari: 'nonaktif={!nominalValid || statusAktif}',
    ganti: 'nonaktif={false}',
    uji: 'src/layar/kasir/BukaKas.test.tsx',
  },
  {
    nama: 'BukaKas: nominal dikirim 0 mentah mengabaikan masukan kasir (T7-01)',
    berkas: 'src/layar/kasir/BukaKas.tsx',
    cari: 'modalAwal: Math.round(nominalBersih),',
    ganti: 'modalAwal: 0,',
    uji: 'src/layar/kasir/BukaKas.test.tsx',
  },
  {
    nama: 'BukaKas: peringatan shift aktif disembunyikan (T7-01) — kasir bisa lupa shift sudah jalan',
    berkas: 'src/layar/kasir/BukaKas.tsx',
    cari: '  if (shiftAktif) {',
    ganti: '  if (false && shiftAktif) {',
    uji: 'src/layar/kasir/BukaKas.test.tsx',
  },
  {
    nama: 'BukaKas: langkah konfirmasi ditiadakan (T7-01) — salah ketik modal langsung terkirim',
    berkas: 'src/layar/kasir/BukaKas.tsx',
    cari: '      {!konfirmasi ? (',
    ganti: '      {false ? (',
    uji: 'src/layar/kasir/BukaKas.test.tsx',
  },
  // ------------------------------------------------- T7-02 tutup shift kasir
  {
    nama: 'TutupKas: alasan selisih kas tidak wajib meski ada selisih (T7-02)',
    berkas: 'src/layar/kasir/TutupKas.tsx',
    cari: "    if (adaSelisih && alasanInput.trim() === '') {",
    ganti: "    if (false && alasanInput.trim() === '') {",
    uji: 'src/layar/kasir/TutupKas.test.tsx',
  },
  {
    nama: 'TutupKas: nominal fisik dikirim 0 mentah mengabaikan input kasir (T7-02)',
    berkas: 'src/layar/kasir/TutupKas.tsx',
    cari: '        uangFisik: Math.round(uangFisikBersih),',
    ganti: '        uangFisik: 0,',
    uji: 'src/layar/kasir/TutupKas.test.tsx',
  },
  {
    nama: 'TutupKas: selisih kas selalu dianggap pas nol (T7-02)',
    berkas: 'src/layar/kasir/TutupKas.tsx',
    cari: '    adaUangSeharusnya && nominalValid ? Math.round(uangFisikBersih) - uangSeharusnyaPerkiraan : 0',
    ganti: '    0',
    uji: 'src/layar/kasir/TutupKas.test.tsx',
  },
  {
    nama: 'TutupKas: langkah konfirmasi ditiadakan sebelum eksekusi (T7-02)',
    berkas: 'src/layar/kasir/TutupKas.tsx',
    cari: '      {!konfirmasi ? (',
    ganti: '      {false ? (',
    uji: 'src/layar/kasir/TutupKas.test.tsx',
  },
  {
    nama: 'KasKeluarMasuk: tombol simpan hidup walau jumlah uang 0 (T7-03)',
    berkas: 'src/layar/kasir/KasKeluarMasuk.tsx',
    cari: 'nonaktif={memproses || jumlah <= 0 || !alasan.trim()}',
    ganti: 'nonaktif={memproses || !alasan.trim()}',
    uji: 'src/layar/kasir/KasKeluarMasuk.test.tsx',
  },
  {
    nama: 'KasKeluarMasuk: alasan pergerakan kas tidak lagi wajib (T7-03)',
    berkas: 'src/layar/kasir/KasKeluarMasuk.tsx',
    cari: 'if (!alasan.trim()) {',
    ganti: 'if (false && !alasan.trim()) {',
    uji: 'src/layar/kasir/KasKeluarMasuk.test.tsx',
  },
  // ------------------------------------------------- T7-04 transaksi wajib shift
  {
    nama: 'LayarKasir: banner peringatan shift disembunyikan walau shift kosong (T7-04)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '        {wajibShift && !shiftAktif && (',
    ganti: '        {false && (',
    uji: 'src/layar/kasir/LayarKasir.test.tsx',
  },
  {
    nama: 'LayarKasir: kasir tanpa shift aktif lolos bayar tanpa buka kas (T7-04)',
    berkas: 'src/layar/kasir/LayarKasir.tsx',
    cari: '    if (wajibShift && !shiftAktif) {\n      setBukaShiftModal(true)\n      return\n    }\n    setBukaBayarModal(true)',
    ganti: '    setBukaBayarModal(true)',
    uji: 'src/layar/kasir/LayarKasir.test.tsx',
  },

  // ------------------------------------------------- T8-09 & T8-10 voucher & scan
  {
    nama: 'VoucherKasir: tombol Cek diam-diam memanggil onPakai (T8-09)',
    berkas: 'src/layar/kasir/VoucherKasir.tsx',
    cari: '    setSedangCek(true)\n    try {\n      const res = await onCek({',
    ganti:
      '    setSedangCek(true)\n    try {\n      void onPakai({ kode: kodeBersih, pinKasir: "1234" })\n      const res = await onCek({',
    uji: 'src/layar/kasir/VoucherKasir.test.tsx',
  },
  {
    nama: 'ScanVoucher: masukan manual dihilangkan saat kamera gagal (T8-10)',
    berkas: 'src/layar/kasir/ScanVoucher.tsx',
    cari: '      {/* Jalur Cadangan Wajib: Masukan Manual (Selalu Tersedia) */}\n      <div className="scan-voucher__manual" data-testid="scan-voucher-manual">',
    ganti:
      '      {/* mutasi: jalur manual disembunyikan saat kamera galat */}\n      {statusKamera === "aktif" && <div className="scan-voucher__manual" data-testid="scan-voucher-manual">',
    uji: 'src/layar/kasir/ScanVoucher.test.tsx',
  },
  {
    nama: 'Kampanye: validasi diskon persen > 100% dilepas di formulir (T8-11)',
    berkas: 'src/layar/pengaturan/Kampanye.tsx',
    cari: "    if (jenisAturan === 'persen') {\n      const persen = Number(nilaiDiskon)\n      if (persen <= 0 || persen > 100) {",
    ganti:
      "    if (jenisAturan === 'persen') {\n      const persen = Number(nilaiDiskon)\n      if (false) {",
    uji: 'src/layar/pengaturan/Kampanye.test.tsx',
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
