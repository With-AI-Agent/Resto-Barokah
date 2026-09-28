/**
 * PasangPrinter.tsx (T6-02) — layar memasang printer struk.
 *
 * Yang dijaga layar ini, dan alasannya dari sisi kedai:
 *
 *  1. **Printer merek apa pun boleh dipasang.** Daftar merek hanya jalan pintas;
 *     selalu ada pilihan "Printer ESC/POS umum". Ini janji langsung kepada
 *     pemilik (pertanyaan Lee 2026-09-23) dan dikunci uji.
 *
 *  2. **Lebar kertas bisa diubah pengguna.** Itu satu-satunya hal yang benar-benar
 *     harus diketahui agar struk rapi, dan siapa pun bisa menjawabnya sambil
 *     melihat kertasnya (5 cm atau 8 cm) — tidak perlu tahu istilah teknis.
 *
 *  3. **Perangkat yang tidak mendukung diberi pesan jelas + jalan keluar**, bukan
 *     tombol mati tanpa penjelasan. iPhone tidak akan pernah bisa menyambung
 *     printer Bluetooth dari peramban; kasir harus tahu bahwa struk digital
 *     adalah gantinya, bukan mengira aplikasinya rusak.
 *
 *  4. **Uji cetak halaman contoh** disediakan, karena satu-satunya bukti printer
 *     benar-benar siap adalah kertas yang keluar — bukan tulisan "tersambung".
 *
 * Komponen ini murni tampilan + pemanggilan jalur cetak; ia tidak menyusun
 * perintah ESC/POS sendiri (itu tugas `lib/printer/`).
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import {
  SEMUA_PROFIL,
  profilDariId,
  tebakProfil,
  type ProfilPrinter,
} from '../../lib/printer/profil'
import { LEBAR_58MM, LEBAR_80MM, PenyusunEscPos } from '../../lib/printer/expos'
import { dukungBluetooth, dukungUsb, pesanTakDidukung } from '../../lib/printer/kirim'

export interface PrinterTersimpan {
  profilId: string
  lebar: number
  namaPerangkat?: string | null
}

/**
 * Halaman contoh untuk uji cetak.
 *
 * Sengaja memuat garis selebar kertas dan satu baris "kiri … kanan": dua hal
 * itulah yang langsung memperlihatkan apakah lebar kertas sudah benar. Kalau
 * lebarnya salah, garisnya akan terlipat atau terlalu pendek — terlihat mata
 * telanjang tanpa perlu membandingkan angka.
 */
export function halamanUji(lebar: number): Uint8Array {
  return new PenyusunEscPos(lebar)
    .awal()
    .pilihCp437()
    .rata('tengah')
    .tebal(true)
    .baris('UJI CETAK')
    .tebal(false)
    .rata('kiri')
    .garis()
    .baris(`Lebar kertas: ${lebar} kolom`)
    .kiriKanan('Contoh item', 'Rp12.345')
    .garis()
    .baris('Jika garis di atas pas selebar')
    .baris('kertas, pengaturan sudah benar.')
    .potongKertas()
    .selesai()
}

export function PasangPrinter({
  tersimpan,
  onSimpan,
  onUjiCetak,
}: {
  tersimpan?: PrinterTersimpan | null
  onSimpan?: (nilai: PrinterTersimpan) => void
  /** Dipanggil dengan byte halaman uji; jalur nyata disuntik dari luar. */
  onUjiCetak?: (data: Uint8Array) => void
}) {
  const awal = tersimpan ?? null
  const [profilId, setProfilId] = useState<string>(awal?.profilId ?? 'umum-58')
  const [lebar, setLebar] = useState<number>(awal?.lebar ?? LEBAR_58MM)

  const profil: ProfilPrinter = profilDariId(profilId)
  const adaBluetooth = dukungBluetooth()
  const adaUsb = dukungUsb()

  function pilihProfil(id: string) {
    setProfilId(id)
    // Lebar ikut menyesuaikan profil, tetapi tetap bisa diubah pengguna sesudahnya.
    setLebar(profilDariId(id).lebar)
  }

  return (
    <section className="pasang-printer" data-testid="pasang-printer">
      <h2>Pasang printer struk</h2>

      <p className="pasang-printer__catatan">
        Pilih merek printer Anda. Kalau merek Anda tidak ada di daftar, pilih
        <strong> Printer ESC/POS umum</strong> — hampir semua printer struk termal bisa dipakai
        dengan pilihan itu.
      </p>

      <label className="pasang-printer__label" htmlFor="profil-printer">
        Merek printer
      </label>
      <select
        id="profil-printer"
        className="pasang-printer__pilih"
        value={profilId}
        onChange={(e) => pilihProfil(e.target.value)}
      >
        {SEMUA_PROFIL.map((p) => (
          <option key={p.id} value={p.id}>
            {p.nama}
          </option>
        ))}
      </select>

      {profil.catatan ? (
        <p className="pasang-printer__keterangan" data-testid="keterangan-profil">
          {profil.catatan}
        </p>
      ) : null}

      <fieldset className="pasang-printer__lebar">
        <legend>Lebar kertas</legend>
        <label>
          <input
            type="radio"
            name="lebar"
            value={LEBAR_58MM}
            checked={lebar === LEBAR_58MM}
            onChange={() => setLebar(LEBAR_58MM)}
          />
          58 mm (kertas kecil, selebar ±5 cm)
        </label>
        <label>
          <input
            type="radio"
            name="lebar"
            value={LEBAR_80MM}
            checked={lebar === LEBAR_80MM}
            onChange={() => setLebar(LEBAR_80MM)}
          />
          80 mm (kertas besar, selebar ±8 cm)
        </label>
      </fieldset>

      {!adaBluetooth ? (
        <p className="pasang-printer__peringatan" data-testid="tanpa-bluetooth">
          {pesanTakDidukung('bluetooth')}
        </p>
      ) : null}
      {!adaUsb ? (
        <p className="pasang-printer__peringatan" data-testid="tanpa-usb">
          {pesanTakDidukung('usb')}
        </p>
      ) : null}

      <div className="pasang-printer__aksi">
        <Tombol
          ragam="polos"
          nama="Uji cetak halaman contoh"
          onClick={() => onUjiCetak?.(halamanUji(lebar))}
        >
          Uji cetak
        </Tombol>
        <Tombol
          nama="Simpan pengaturan printer"
          onClick={() =>
            onSimpan?.({ profilId, lebar, namaPerangkat: awal?.namaPerangkat ?? null })
          }
        >
          Simpan
        </Tombol>
      </div>
    </section>
  )
}

export { tebakProfil }
