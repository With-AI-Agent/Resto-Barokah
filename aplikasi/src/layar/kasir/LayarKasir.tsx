import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import { formatPesanError } from '../../lib/pesan'
import { Katalog, type MenuItemData, type VarianItem, type TambahanItem } from './Katalog'
import { Keranjang, type ItemKeranjang, type RingkasanUang } from './Keranjang'
import { PemilihMeja, type MejaData, type TipePesanan } from './PemilihMeja'
import { TagihanTerbuka } from './TagihanTerbuka'

export interface LayarKasirProps {
  cabangId?: string
  namaCabang?: string
  onSimpanPesanan?: (
    pesananData: unknown,
  ) => Promise<{ sukses: boolean; pesananId?: string; pesan?: string }>
  onKirimKeDapur?: (pesananId: string) => Promise<{ sukses: boolean; pesan?: string }>
  onBayarPesanan?: (
    pesananId: string,
    metode: string,
    jumlahBayar: number,
  ) => Promise<{ sukses: boolean; kembalian?: number; pesan?: string }>
}

const PECAHAN_UANG_CEPAT = [20000, 50000, 100000, 150000, 200000]

export function LayarKasir({
  cabangId = 'cab-01',
  namaCabang = 'Cabang Utama',
  onSimpanPesanan = async () => ({ sukses: true, pesananId: 'ord-new' }),
  onKirimKeDapur = async () => ({ sukses: true }),
  onBayarPesanan = async () => ({ sukses: true, kembalian: 0 }),
}: LayarKasirProps) {
  // Keranjang State
  const [daftarItemKeranjang, setDaftarItemKeranjang] = useState<ItemKeranjang[]>([])
  const [tipePesanan, setTipePesanan] = useState<TipePesanan>('dinein')
  const [mejaAktif, setMejaAktif] = useState<MejaData>({
    id: 'meja-01',
    nama: 'Meja 01',
    status: 'kosong',
    aktif: true,
  })
  const [catatanPesananUmum, setCatatanPesananUmum] = useState<string>('')

  // UI Modal State
  const [bukaMejaModal, setBukaMejaModal] = useState(false)
  const [bukaOpenBillModal, setBukaOpenBillModal] = useState(false)
  const [bukaBayarModal, setBukaBayarModal] = useState(false)
  const [bukaVoucherModal, setBukaVoucherModal] = useState(false)

  // Payment State
  const [metodeBayar, setMetodeBayar] = useState<'tunai' | 'qris' | 'kartu'>('tunai')
  const [uangDiterima, setUangDiterima] = useState<string>('')
  const [sedangBayar, setSedangBayar] = useState(false)
  const [pesanHasilBayar, setPesanHasilBayar] = useState<string | null>(null)

  // Voucher State
  const [kodeVoucherInput, setKodeVoucherInput] = useState('')
  const [diskonAktif, setDiskonAktif] = useState<number>(0)

  // Hitung Nilai Rangkuman Terpusat (Berdasarkan aturan PB1 & Service)
  const subtotal = daftarItemKeranjang.reduce((sum, item) => sum + item.subtotal, 0)
  const subtotalSetelahDiskon = Math.max(0, subtotal - diskonAktif)
  const service = Math.round(subtotalSetelahDiskon * 0.05) // 5% Service charge
  const pajak = Math.round(subtotalSetelahDiskon * 0.1) // 10% PB1
  const total = subtotalSetelahDiskon + service + pajak

  const ringkasanUang: RingkasanUang = {
    subtotal,
    totalDiskon: diskonAktif,
    service,
    pajak,
    total,
  }

  // Tambah item dari katalog ke keranjang
  const tanganiTambahKeKeranjang = (
    item: MenuItemData,
    varian?: VarianItem,
    tambahan?: TambahanItem[],
    catatan?: string,
  ) => {
    const tambahanHargaVarian = varian ? varian.tambahanHarga : 0
    const tambahanHargaTopping = tambahan ? tambahan.reduce((s, t) => s + t.harga, 0) : 0
    const hargaSatuan = item.harga + tambahanHargaVarian + tambahanHargaTopping

    setDaftarItemKeranjang((prev) => {
      // Cari apakah item dengan opsi sama persis sudah ada di keranjang
      const varianNama = varian ? varian.nama : ''
      const tambahanIds = tambahan
        ? tambahan
            .map((t) => t.id)
            .sort()
            .join(',')
        : ''
      const catatanTeks = catatan || ''

      const existingIndex = prev.findIndex((p) => {
        const pVarian = p.varian ? p.varian.nama : ''
        const pTambahan = p.tambahan
          ? p.tambahan
              .map((t) => t.id)
              .sort()
              .join(',')
          : ''
        const pCatatan = p.catatan || ''
        return (
          p.menuItem.id === item.id &&
          pVarian === varianNama &&
          pTambahan === tambahanIds &&
          pCatatan === catatanTeks
        )
      })

      if (existingIndex >= 0) {
        const baru = [...prev]
        const target = baru[existingIndex]
        const qtyBaru = target.qty + 1
        baru[existingIndex] = {
          ...target,
          qty: qtyBaru,
          subtotal: qtyBaru * hargaSatuan,
        }
        return baru
      }

      const itemBaru: ItemKeranjang = {
        id: `cart-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
        menuItem: item,
        varian,
        tambahan,
        catatan,
        qty: 1,
        subtotal: hargaSatuan,
      }
      return [...prev, itemBaru]
    })
  }

  const tanganiTambahQty = (id: string) => {
    setDaftarItemKeranjang((prev) =>
      prev.map((item) => {
        if (item.id === id) {
          const hargaSatuan = item.subtotal / item.qty
          const qtyBaru = item.qty + 1
          return { ...item, qty: qtyBaru, subtotal: qtyBaru * hargaSatuan }
        }
        return item
      }),
    )
  }

  const tanganiKurangQty = (id: string) => {
    setDaftarItemKeranjang(
      (prev) =>
        prev
          .map((item) => {
            if (item.id === id) {
              const hargaSatuan = item.subtotal / item.qty
              const qtyBaru = item.qty - 1
              if (qtyBaru <= 0) return null
              return { ...item, qty: qtyBaru, subtotal: qtyBaru * hargaSatuan }
            }
            return item
          })
          .filter(Boolean) as ItemKeranjang[],
    )
  }

  const tanganiHapusItem = (id: string) => {
    setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== id))
  }

  const tanganiUbahCatatan = (id: string, catatan: string) => {
    setDaftarItemKeranjang((prev) => prev.map((i) => (i.id === id ? { ...i, catatan } : i)))
  }

  const tanganiKirimKeDapur = async () => {
    if (daftarItemKeranjang.length === 0) return
    try {
      const simpanRes = await onSimpanPesanan({
        mejaId: mejaAktif.id,
        tipe: tipePesanan,
        items: daftarItemKeranjang,
      })
      const pesananId = simpanRes.pesananId || 'ord-current'
      const res = await onKirimKeDapur(pesananId)
      if (res.sukses) {
        alert('Pesanan berhasil dikirim ke dapur!')
      }
    } catch {
      alert('Gagal mengirim pesanan ke dapur.')
    }
  }

  const tanganiMulaiBayar = () => {
    setUangDiterima(String(total))
    setPesanHasilBayar(null)
    setBukaBayarModal(true)
  }

  const tanganiEksekusiBayar = async () => {
    const nominal = Number(uangDiterima.replace(/\D/g, '')) || 0
    if (metodeBayar === 'tunai' && nominal < total) {
      setPesanHasilBayar('Uang tunai yang diterima kurang dari total tagihan.')
      return
    }

    setSedangBayar(true)
    setPesanHasilBayar(null)
    try {
      const res = await onBayarPesanan('ord-current', metodeBayar, nominal)
      if (res.sukses) {
        const kembalian = res.kembalian ?? Math.max(0, nominal - total)
        alert(`Pembayaran Sukses!\nKembalian: ${rupiah(kembalian)}`)
        setDaftarItemKeranjang([])
        setDiskonAktif(0)
        setBukaBayarModal(false)
      } else {
        setPesanHasilBayar(res.pesan || 'Pembayaran gagal diproses.')
      }
    } catch {
      const err = formatPesanError('JARINGAN_TERPUTUS')
      setPesanHasilBayar(`${err.judul}: ${err.pesan}`)
    } finally {
      setSedangBayar(false)
    }
  }

  const tanganiKlaimVoucher = () => {
    if (kodeVoucherInput.toUpperCase() === 'BAROKAH10K') {
      setDiskonAktif(10000)
      setBukaVoucherModal(false)
      setKodeVoucherInput('')
      alert('Voucher diskon Rp10.000 berhasil digunakan!')
    } else {
      alert('Kode voucher tidak ditemukan atau sudah kedaluwarsa.')
    }
  }

  return (
    <div className="layar-kasir-utama flex flex-col lg:flex-row gap-4 p-3 max-w-7xl mx-auto min-h-[85vh]">
      {/* Kolom Kiri: Header Kasir & Katalog Menu (60-65% Lebar) */}
      <div className="w-full lg:w-[62%] flex flex-col space-y-3">
        {/* Bilah Status Kasir Atas */}
        <div className="p-3 bg-white rounded-xl border border-neutral-200 flex items-center justify-between shadow-sm">
          <div>
            <div className="font-extrabold text-base text-neutral-800">
              Kasir POS — {namaCabang}
            </div>
            <div className="text-xs text-neutral-400">Cabang ID: {cabangId}</div>
          </div>

          <div className="flex items-center gap-2">
            <Tombol ragam="biasa" onClick={() => setBukaOpenBillModal(true)}>
              📋 Tagihan Terbuka
            </Tombol>
            <Tombol ragam="biasa" onClick={() => setBukaMejaModal(true)}>
              🍽️{' '}
              {tipePesanan === 'dinein'
                ? mejaAktif.nama
                : tipePesanan === 'takeaway'
                  ? 'Bawa Pulang'
                  : 'Ojol'}
            </Tombol>
          </div>
        </div>

        {/* Katalog Menu Component */}
        <div className="flex-1 p-3.5 bg-white rounded-2xl border border-neutral-200 shadow-sm overflow-hidden">
          <Katalog onTambahKeKeranjang={tanganiTambahKeKeranjang} />
        </div>
      </div>

      {/* Kolom Kanan: Keranjang Pesanan & Ringkasan Pembayaran (35-40% Lebar) */}
      <div className="w-full lg:w-[38%] flex flex-col">
        <Keranjang
          daftarItem={daftarItemKeranjang}
          ringkasan={ringkasanUang}
          namaMeja={mejaAktif.nama}
          tipePesanan={tipePesanan}
          onTambahQty={tanganiTambahQty}
          onKurangQty={tanganiKurangQty}
          onHapusItem={tanganiHapusItem}
          onUbahCatatan={tanganiUbahCatatan}
          onKirimKeDapur={tanganiKirimKeDapur}
          onProsesBayar={tanganiMulaiBayar}
          onBukaPemilihMeja={() => setBukaMejaModal(true)}
          onBukaVoucher={() => setBukaVoucherModal(true)}
        />
      </div>

      {/* Modal Pemilih Meja & Tipe */}
      {bukaMejaModal && (
        <Lapis
          buka={true}
          onTutup={() => setBukaMejaModal(false)}
          judul="Pilih Meja & Tipe Pesanan"
        >
          <PemilihMeja
            mejaTerpilihId={mejaAktif.id}
            tipePesanan={tipePesanan}
            catatanPesanan={catatanPesananUmum}
            onPilihTipe={setTipePesanan}
            onPilihMeja={(m) => {
              setMejaAktif(m)
              setBukaMejaModal(false)
            }}
            onSimpanCatatanPesanan={setCatatanPesananUmum}
            onTutup={() => setBukaMejaModal(false)}
          />
        </Lapis>
      )}

      {/* Modal Tagihan Terbuka (Open Bill) */}
      {bukaOpenBillModal && (
        <Lapis
          buka={true}
          onTutup={() => setBukaOpenBillModal(false)}
          judul="Daftar Tagihan Terbuka"
        >
          <TagihanTerbuka
            onPilihTagihan={(t) => {
              alert(`Melanjutkan pesanan #${t.nomor} (${t.namaMeja || 'Takeaway'})`)
              setBukaOpenBillModal(false)
            }}
            onBuatPesananBaru={() => {
              setDaftarItemKeranjang([])
              setDiskonAktif(0)
              setBukaOpenBillModal(false)
            }}
          />
        </Lapis>
      )}

      {/* Modal Pembayaran Transaksi */}
      {bukaBayarModal && (
        <Lapis
          buka={true}
          onTutup={() => setBukaBayarModal(false)}
          judul="Pembayaran Transaksi Kasir"
        >
          <div className="p-4 space-y-4 max-w-lg mx-auto">
            {pesanHasilBayar && (
              <div
                role="alert"
                className="p-3 bg-red-50 border border-red-200 text-red-800 rounded-lg text-xs font-medium"
              >
                {pesanHasilBayar}
              </div>
            )}

            {/* Total Tagihan Besar */}
            <div className="p-4 bg-emerald-50 rounded-xl border border-emerald-200 text-center">
              <div className="text-xs text-emerald-800 font-semibold uppercase tracking-wider">
                Total Tagihan yang Harus Dibayar
              </div>
              <div className="text-3xl font-extrabold text-emerald-950 mt-1">{rupiah(total)}</div>
            </div>

            {/* Pilihan Metode Bayar */}
            <div>
              <label className="block text-xs font-bold text-neutral-700 uppercase tracking-wider mb-2">
                Pilih Metode Pembayaran:
              </label>
              <div className="grid grid-cols-3 gap-2">
                <Tombol
                  ragam={metodeBayar === 'tunai' ? 'utama' : 'biasa'}
                  onClick={() => setMetodeBayar('tunai')}
                >
                  💵 Uang Tunai
                </Tombol>

                <Tombol
                  ragam={metodeBayar === 'qris' ? 'utama' : 'biasa'}
                  onClick={() => setMetodeBayar('qris')}
                >
                  📱 QRIS Dinamis
                </Tombol>

                <Tombol
                  ragam={metodeBayar === 'kartu' ? 'utama' : 'biasa'}
                  onClick={() => setMetodeBayar('kartu')}
                >
                  💳 Kartu Debit/Kredit
                </Tombol>
              </div>
            </div>

            {/* Form Nominal Tunai & Pecahan Cepat */}
            {metodeBayar === 'tunai' && (
              <div className="space-y-3 pt-2 border-t border-neutral-200">
                <KolomIsian
                  label="Jumlah Uang Tunai Diterima"
                  jenis="text"
                  nilai={uangDiterima ? rupiah(Number(uangDiterima.replace(/\D/g, '')) || 0) : ''}
                  onUbah={(v) => setUangDiterima(v.replace(/\D/g, ''))}
                  wajib
                />

                <div>
                  <div className="text-xs text-neutral-500 mb-1 font-medium">
                    Pecahan Uang Pas / Cepat:
                  </div>
                  <div className="flex flex-wrap gap-1.5">
                    <Tombol ragam="kecil" onClick={() => setUangDiterima(String(total))}>
                      Uang Pas ({rupiah(total)})
                    </Tombol>
                    {PECAHAN_UANG_CEPAT.map((nominal) => (
                      <Tombol
                        key={nominal}
                        ragam="kecil"
                        onClick={() => setUangDiterima(String(nominal))}
                      >
                        {rupiah(nominal)}
                      </Tombol>
                    ))}
                  </div>
                </div>

                {/* Info Kembalian */}
                {Number(uangDiterima) >= total && (
                  <div className="p-3 bg-neutral-100 rounded-lg flex justify-between items-center text-sm">
                    <span className="font-medium text-neutral-700">Uang Kembalian:</span>
                    <span className="font-extrabold text-base text-neutral-900">
                      {rupiah(Number(uangDiterima) - total)}
                    </span>
                  </div>
                )}
              </div>
            )}

            {/* QRIS Tampilan */}
            {metodeBayar === 'qris' && (
              <div className="p-4 bg-neutral-50 rounded-xl border border-neutral-200 text-center space-y-2">
                <div className="w-40 h-40 mx-auto bg-white border border-neutral-300 rounded-lg flex items-center justify-center text-5xl">
                  📱
                </div>
                <div className="text-xs text-neutral-600 font-medium">
                  Tunjukkan QRIS ini kepada pelanggan. Saldo akan otomatis terverifikasi.
                </div>
              </div>
            )}

            <div className="flex justify-end gap-2 pt-3 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setBukaBayarModal(false)} nonaktif={sedangBayar}>
                Batal
              </Tombol>
              <Tombol ragam="utama" onClick={tanganiEksekusiBayar} nonaktif={sedangBayar}>
                {sedangBayar ? 'Memproses Transaksi...' : 'Selesaikan Pembayaran & Tutup'}
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}

      {/* Modal Klaim Voucher */}
      {bukaVoucherModal && (
        <Lapis
          buka={true}
          onTutup={() => setBukaVoucherModal(false)}
          judul="Gunakan Voucher Diskon"
        >
          <div className="p-4 space-y-4 max-w-md mx-auto">
            <KolomIsian
              label="Masukkan Kode Voucher Pelanggan"
              contoh="Mis. BAROKAH10K"
              nilai={kodeVoucherInput}
              onUbah={setKodeVoucherInput}
            />

            <div className="flex justify-end gap-2 pt-2 border-t border-neutral-200">
              <Tombol ragam="biasa" onClick={() => setBukaVoucherModal(false)}>
                Batal
              </Tombol>
              <Tombol
                ragam="utama"
                onClick={tanganiKlaimVoucher}
                nonaktif={!kodeVoucherInput.trim()}
              >
                Cek & Terapkan
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
