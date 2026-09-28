/**
 * StrukDigital.tsx (T5-09) — cara menyerahkan struk ke pelanggan saat printer
 * bermasalah.
 *
 * KENAPA ADA: printer termal adalah bagian paling sering rusak di kedai (kertas
 * habis, kepala kotor, kabel longgar). Tanpa jalan cadangan, pelanggan pulang
 * tanpa bukti bayar dan kasir tidak punya apa-apa untuk ditunjukkan kalau ada
 * sengketa. `TECH_SPEC` §13 K3 menyebutnya kasus tepi yang wajib punya jawaban.
 *
 * MITIGASI YANG DIPEGANG (ART-7, tertulis di ROADMAP T5-09): **satu tampilan
 * struk untuk semua jalur**. Berkas ini TIDAK menggambar ulang struk — ia
 * membungkus `<Struk>` yang sama persis dipakai pratinjau dan cetak termal
 * (T5-03). Kalau isinya digambar dua kali, cepat atau lambat struk digital dan
 * struk kertas akan berbeda angka, dan itu jenis cacat yang baru ketahuan saat
 * pelanggan protes. Karena itu ada juga uji penjaga yang melarang berkas ini
 * menghitung uang sendiri.
 *
 * TIGA JALAN PENYERAHAN, sengaja berlapis dari yang paling enak ke yang paling
 * pasti tersedia:
 *   1. **Bagikan** (`navigator.share`) — di HP Android/iOS membuka lembar
 *      berbagi bawaan: WhatsApp, Telegram, surel. Ini jalan tercepat di lapangan.
 *   2. **Simpan PDF** (`window.print`) — dialog cetak peramban punya pilihan
 *      "Simpan sebagai PDF" di Android maupun desktop. Jalur yang sama juga
 *      dipakai bila kasir ingin mencetak ke printer biasa (bukan termal).
 *   3. **Salin teks** (`navigator.clipboard`) — jaring pengaman terakhir: selalu
 *      bisa ditempel ke chat apa pun, bahkan saat peramban lama tidak mendukung
 *      dua cara di atas.
 *
 * Tombol yang tidak didukung peramban **disembunyikan**, bukan ditampilkan lalu
 * gagal saat ditekan — kasir yang sedang diburu antrean tidak boleh menebak-nebak
 * tombol mana yang benar-benar bekerja.
 */
import { useState } from 'react'
import { Struk, type DataStruk, type PembayaranStruk } from './Struk'
import { Tombol } from './Tombol'
import { rupiah } from '../lib/format'

/** Peramban tidak seragam; semua kemampuan diperiksa sebelum dipakai. */
export function bisaBagikan(): boolean {
  return typeof navigator !== 'undefined' && typeof navigator.share === 'function'
}

export function bisaSalin(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    typeof navigator.clipboard === 'object' &&
    navigator.clipboard !== null &&
    typeof navigator.clipboard.writeText === 'function'
  )
}

/**
 * Ringkasan teks untuk dibagikan/disalin.
 *
 * Sengaja ringkas: nomor, tanggal, total, dan status lunas — bukan salinan penuh
 * struk. Yang dibutuhkan pelanggan di chat adalah bukti bayar yang bisa dibaca
 * sekilas; rincian lengkapnya ada di struk PDF dan di catatan resto. Angkanya
 * diambil apa adanya dari `data`, tidak dihitung ulang di sini.
 */
export function ringkasanTeks(data: DataStruk, lunas: boolean): string {
  const baris = [
    data.namaResto ? data.namaResto : 'Struk pembayaran',
    `No. ${data.nomor}`,
    `Tanggal: ${new Date(data.tanggal).toLocaleString('id-ID')}`,
    `Total: ${rupiah(data.total)}`,
    lunas ? 'LUNAS — terima kasih.' : 'Belum lunas.',
  ]
  return baris.join('\n')
}

export interface StrukDigitalProps {
  data: DataStruk
  pembayaran?: PembayaranStruk[]
  kembalian?: number
  /**
   * Alasan struk digital dipakai (mis. "Printer tidak merespons"). Ditampilkan
   * supaya pelanggan mengerti kenapa tidak menerima kertas — dan supaya kasir
   * tidak perlu menjelaskan berulang kali.
   */
  alasan?: string | null
  onTutup?: () => void
}

export function StrukDigital({
  data,
  pembayaran = [],
  kembalian = 0,
  alasan = null,
  onTutup,
}: StrukDigitalProps) {
  const [kabar, setKabar] = useState<string | null>(null)

  const totalDibayar = pembayaran.reduce((jumlah, bayar) => jumlah + bayar.jumlah, 0)
  const lunas = pembayaran.length > 0 && totalDibayar >= data.total

  const tanganiBagikan = async () => {
    setKabar(null)
    try {
      await navigator.share({
        title: `Struk No. ${data.nomor}`,
        text: ringkasanTeks(data, lunas),
      })
    } catch {
      // Pengguna membatalkan lembar berbagi, atau perangkat menolak. Bukan galat
      // yang perlu ditakuti — struk masih bisa disimpan PDF atau disalin.
      setKabar('Berbagi dibatalkan. Struk masih bisa disimpan PDF atau disalin.')
    }
  }

  const tanganiSimpanPdf = () => {
    setKabar(null)
    window.print()
  }

  const tanganiSalin = async () => {
    setKabar(null)
    try {
      await navigator.clipboard.writeText(ringkasanTeks(data, lunas))
      setKabar('Ringkasan struk disalin. Tinggal tempel di chat pelanggan.')
    } catch {
      setKabar('Gagal menyalin. Coba Simpan PDF atau bacakan nomor struknya.')
    }
  }

  return (
    <div className="struk-digital" data-testid="struk-digital">
      {alasan && (
        <p className="struk-digital__alasan" data-testid="struk-digital-alasan">
          {alasan} — struk diserahkan secara digital.
        </p>
      )}

      {/* SATU tampilan struk untuk semua jalur (cetak & digital). */}
      <div className="struk-digital__isi">
        <Struk data={data} pembayaran={pembayaran} kembalian={kembalian} />
      </div>

      {kabar && (
        <p className="struk-digital__kabar" role="status" data-testid="struk-digital-kabar">
          {kabar}
        </p>
      )}

      <div className="struk-digital__aksi">
        {bisaBagikan() && (
          <Tombol ragam="utama" onClick={tanganiBagikan} nama="Bagikan struk">
            Bagikan
          </Tombol>
        )}
        <Tombol ragam="biasa" onClick={tanganiSimpanPdf} nama="Simpan struk sebagai PDF">
          Simpan PDF
        </Tombol>
        {bisaSalin() && (
          <Tombol ragam="biasa" onClick={tanganiSalin} nama="Salin ringkasan struk">
            Salin teks
          </Tombol>
        )}
        {onTutup && (
          <Tombol ragam="biasa" onClick={onTutup}>
            Tutup
          </Tombol>
        )}
      </div>
    </div>
  )
}
