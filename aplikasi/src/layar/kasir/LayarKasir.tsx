/**
 * LayarKasir — terminal POS kasir (Fase 3) yang kini memakai layar Bayar (T5-01).
 *
 * **Perubahan penting (2026-09-23):** modal pembayaran lama dibuang. Dulu berkas
 * ini mengeras-kodekan tiga metode ('tunai' | 'qris' | 'kartu'), sehingga metode
 * yang dinonaktifkan pemilik tetap tampil dan metode baru mustahil muncul tanpa
 * koding. Sekarang:
 *  - daftar metode datang dari kontainer (`useBayar` → tabel `metode_bayar`,
 *    hanya `aktif = true`) dan diteruskan apa adanya ke `Bayar.tsx`;
 *  - uang dicatat lewat `onBayar`, yang di produksi dipasang ke RPC
 *    `bayar_pesanan` (migrasi 0039) — pintu tunggal uang masuk, idempoten;
 *  - kembalian yang ditampilkan sesudah pembayaran adalah ANGKA PELADEN, bukan
 *    hasil kurang-kurangan di layar;
 *  - keranjang HANYA dikosongkan setelah tagihan benar-benar lunas dan kasir
 *    menekan Selesai (pembayaran sebagian tidak boleh menghapus pesanan).
 *
 * Berkas ini tetap kontainer UI murni: tidak ada jaringan di dalamnya.
 */
import { useState } from 'react'
import { Tombol } from '../../komponen/Tombol'
import { Lapis } from '../../komponen/Lapis'
import { Katalog, type MenuItemData, type VarianItem, type TambahanItem } from './Katalog'
import { Keranjang, type ItemKeranjang, type RingkasanUang } from './Keranjang'
import { PemilihMeja, type MejaData, type TipePesanan } from './PemilihMeja'
import { TagihanTerbuka } from './TagihanTerbuka'
import { Bayar, type BarisTagihan, type HasilBayar, type MetodeBayar, type Tagihan } from './Bayar'
import { DiskonManual, type BatasDiskon, type HasilDiskon } from './DiskonManual'
import { VoidItem, type HasilVoid } from './VoidItem'
import type { DataStruk } from '../../komponen/Struk'

export interface LayarKasirProps {
  cabangId?: string
  namaCabang?: string
  onSimpanPesanan?: (
    pesananData: unknown,
  ) => Promise<{ sukses: boolean; pesananId?: string; pesan?: string }>
  onKirimKeDapur?: (pesananId: string) => Promise<{ sukses: boolean; pesan?: string }>
  /** Id tagihan yang sedang dibayar; kontainer yang menentukannya. */
  pesananId?: string
  nomorTagihan?: number
  /** Metode bayar AKTIF dari peladen. Layar tidak punya daftar bawaan. */
  metodeBayar?: MetodeBayar[]
  keadaanBayar?: 'memuat' | 'gagal' | 'siap' | 'mengirim' | 'berhasil'
  pesanBayar?: string | null
  /** Hasil pembayaran SAH dari peladen (RPC `bayar_pesanan`). */
  terakhirBayar?: BarisTagihan | null
  /** Pintu tunggal pencatatan uang — dipasang ke `useBayar().bayar`. */
  onBayar?: (masukan: {
    metodeId: string
    jumlah: number
    diterima?: number | null
    referensi?: string | null
  }) => Promise<HasilBayar | null> | void
  /** Kasir menutup struk: kontainer mengembalikan keadaan ke `siap`. */
  onSelesaiBayar?: () => void
  onCobaBayar?: () => void

  // ------------------------------------------------------------ T5-05 diskon
  /**
   * Batas diskon pemakai yang sedang masuk, dari `izin_efektif('beri_diskon')`.
   * `null` = belum diketahui; layar lalu bersikap hati-hati (minta persetujuan).
   */
  batasDiskon?: BatasDiskon | null
  /** Atasan yang bisa dimintai persetujuan PIN di layar ini. */
  daftarAtasan?: { id: string; nama: string }[]
  /** Verifikasi PIN atasan untuk pesanan ini (RPC `verifikasi_pin`). */
  onMintaPersetujuanDiskon?: (masukan: {
    atasanId: string
    pin: string
  }) => Promise<HasilDiskon | null> | void
  /** Mencatat diskon (insert `diskon_transaksi`; pagar di migrasi 0041). */
  onTerapkanDiskon?: (masukan: {
    nilai: number
    alasan: string
    disetujuiOleh: string | null
  }) => Promise<HasilDiskon | null> | void

  // ------------------------------------------------------- T5-06 void pra-dapur
  /**
   * Mencatat pembatalan item yang SUDAH tersimpan di peladen (insert baris
   * `pembatalan`; pagar di `picu_pembatalan_sah`, migrasi 0015). Bila prop ini
   * tidak dipasang, layar menganggap keranjang masih draf lokal dan tombol hapus
   * bekerja seperti biasa — draf yang belum pernah dikirim memang tidak punya
   * apa-apa untuk dicatat.
   */
  onBatalkanItem?: (masukan: { itemId: string; alasan: string }) => Promise<HasilVoid | null> | void
  /** Apakah pesanan ini sudah dikirim ke dapur (penanda untuk kasir). */
  sudahKeDapur?: boolean
}

export function LayarKasir({
  cabangId = 'cab-01',
  namaCabang = 'Cabang Utama',
  onSimpanPesanan = async () => ({ sukses: true, pesananId: 'ord-new' }),
  onKirimKeDapur = async () => ({ sukses: true }),
  pesananId = 'ord-current',
  nomorTagihan = 1,
  metodeBayar = [],
  keadaanBayar = 'siap',
  pesanBayar = null,
  terakhirBayar = null,
  onBayar,
  onSelesaiBayar,
  onCobaBayar,
  batasDiskon = null,
  daftarAtasan = [],
  onMintaPersetujuanDiskon,
  onTerapkanDiskon,
  onBatalkanItem,
  sudahKeDapur = false,
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
  const [bukaDiskonModal, setBukaDiskonModal] = useState(false)
  /** Id item yang sedang dimintai alasan pembatalan (T5-06); null = tidak ada. */
  const [itemVoid, setItemVoid] = useState<string | null>(null)

  /**
   * Diskon yang SUDAH tercatat di peladen untuk tagihan ini (T5-05).
   *
   * Dulu di sini ada voucher keras-kode: mengetik "BAROKAH10K" langsung memotong
   * Rp10.000 tanpa pagar izin, tanpa alasan, tanpa jejak siapa yang memberi, dan
   * tanpa voucher apa pun di database. Itu dibuang. Sekarang diskon hanya masuk
   * lewat `onTerapkanDiskon` → tabel `diskon_transaksi`, yang dijaga pemicu
   * `picu_diskon_batas` (migrasi 0041): batas izin, PIN atasan bila di atas
   * batas, alasan wajib, cap resto, dan jejak pelaku + penyetuju.
   */
  const [diskonAktif, setDiskonAktif] = useState<number>(0)

  /**
   * Angka ringkasan. CATATAN JUJUR: pajak & service di sini masih dihitung layar
   * dengan tarif 10 % / 5 % sebagai PERKIRAAN untuk mata kasir selagi keranjang
   * disusun. Angka yang SAH selalu datang dari peladen (`hitung_total`) dan itulah
   * yang dipakai layar Bayar serta dicetak di struk — layar tidak pernah menjadi
   * sumber kebenaran uang. Menyatukan keduanya = butir tersendiri (lihat
   * docs/TERTANGGUH.md T-027).
   */
  const subtotal = daftarItemKeranjang.reduce((sum, item) => sum + item.subtotal, 0)
  const subtotalSetelahDiskon = Math.max(0, subtotal - diskonAktif)
  const service = Math.round(subtotalSetelahDiskon * 0.05) // 5% Service charge (perkiraan)
  const pajak = Math.round(subtotalSetelahDiskon * 0.1) // 10% PB1 (perkiraan)
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

  /**
   * Menghapus item (T5-06). Dua jalur yang SENGAJA dibedakan:
   *
   *  - **Draf lokal** (`onBatalkanItem` tidak dipasang): item belum pernah sampai
   *    peladen, jadi tidak ada apa pun untuk dicatat — buang saja dari daftar.
   *  - **Sudah tercatat** (`onBatalkanItem` dipasang): item hanya boleh hilang
   *    lewat baris `pembatalan` yang beralasan. Layar membuka dialog alasan dan
   *    TIDAK membuang item sampai peladen menerima — kalau tidak, item lenyap
   *    dari mata kasir padahal masih hidup (dan masih ditagih) di database.
   */
  const tanganiHapusItem = (id: string) => {
    if (!onBatalkanItem) {
      setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== id))
      return
    }
    setItemVoid(id)
  }

  const tanganiBatalkanItem = async (masukan: { alasan: string }): Promise<HasilVoid | null> => {
    if (!itemVoid) return null
    const hasil = (await onBatalkanItem?.({ itemId: itemVoid, alasan: masukan.alasan })) ?? null
    if (hasil?.berhasil) {
      setDaftarItemKeranjang((prev) => prev.filter((i) => i.id !== itemVoid))
      setItemVoid(null)
    }
    return hasil
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
    setBukaBayarModal(true)
  }

  /** Tagihan yang diserahkan ke layar Bayar; totalnya dari ringkasan kasir. */
  const tagihanAktif: Tagihan = {
    id: pesananId,
    nomor: nomorTagihan,
    total,
    sudahDibayar: terakhirBayar ? terakhirBayar.totalDibayar : 0,
  }

  /**
   * Rincian struk (T5-03). Komponen `Struk` tidak menghitung apa pun: ia hanya
   * mencetak angka yang diberikan. Di sini angkanya masih dari ringkasan kasir;
   * begitu kontainer membaca baris `pesanan` dari peladen, cukup ganti sumbernya
   * tanpa menyentuh komponen struk.
   */
  const dataStruk: DataStruk = {
    nomor: nomorTagihan,
    tanggal: new Date().toISOString(),
    namaResto: namaCabang,
    namaMeja: tipePesanan === 'dinein' ? mejaAktif.nama : null,
    item: daftarItemKeranjang.map((baris) => ({
      nama: baris.menuItem.nama,
      qty: baris.qty,
      hargaSatuan: Math.round(baris.subtotal / baris.qty),
      subtotal: baris.subtotal,
      catatan: baris.catatan,
    })),
    subtotal: ringkasanUang.subtotal,
    totalDiskon: ringkasanUang.totalDiskon,
    pajak: ringkasanUang.pajak,
    service: ringkasanUang.service,
    total: ringkasanUang.total,
  }

  /**
   * Kasir menutup struk. Keranjang HANYA dikosongkan bila tagihan sudah lunas —
   * pembayaran sebagian harus menyisakan pesanan supaya sisanya bisa ditagih.
   */
  const tanganiSelesaiBayar = () => {
    if (terakhirBayar?.lunas) {
      setDaftarItemKeranjang([])
      setDiskonAktif(0)
      setBukaBayarModal(false)
    }
    onSelesaiBayar?.()
  }

  /**
   * Diskon dicatat peladen dulu, baru layar ikut berubah. Urutannya sengaja:
   * kalau peladen menolak (di atas batas, cap resto, tagihan sudah lunas), layar
   * TIDAK boleh terlanjur menampilkan potongan yang tidak pernah tercatat.
   */
  const tanganiTerapkanDiskon = async (masukan: {
    nilai: number
    alasan: string
    disetujuiOleh: string | null
  }): Promise<HasilDiskon | null> => {
    const hasil = (await onTerapkanDiskon?.(masukan)) ?? null
    if (hasil?.berhasil) {
      setDiskonAktif((sebelumnya) => sebelumnya + masukan.nilai)
      setBukaDiskonModal(false)
    }
    return hasil
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
          onBukaVoucher={() => setBukaDiskonModal(true)}
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

      {/* Layar Bayar (T5-01) — metode & pencatatan uang milik `Bayar.tsx`.
          Layar kasir tidak lagi punya daftar metode sendiri. */}
      {bukaBayarModal && (
        <Lapis
          buka={true}
          onTutup={() => setBukaBayarModal(false)}
          judul="Pembayaran Transaksi Kasir"
        >
          <Bayar
            tagihan={tagihanAktif}
            metode={metodeBayar}
            keadaan={keadaanBayar}
            pesan={pesanBayar}
            terakhir={terakhirBayar}
            struk={dataStruk}
            onBayar={onBayar}
            onCoba={onCobaBayar}
            onLanjut={tanganiSelesaiBayar}
            onBatal={() => setBukaBayarModal(false)}
          />
        </Lapis>
      )}

      {/* Diskon manual (T5-05) — menggantikan modal voucher keras-kode.
          Pagar sungguhannya di migrasi 0041; layar hanya lapis pertama. */}
      {bukaDiskonModal && (
        <Lapis buka={true} onTutup={() => setBukaDiskonModal(false)} judul="Beri Diskon Manual">
          <DiskonManual
            subtotal={subtotal}
            batas={batasDiskon}
            daftarAtasan={daftarAtasan}
            onMintaPersetujuan={onMintaPersetujuanDiskon}
            onTerapkan={tanganiTerapkanDiskon}
            onBatal={() => setBukaDiskonModal(false)}
          />
        </Lapis>
      )}

      {itemVoid && (
        <Lapis buka={true} onTutup={() => setItemVoid(null)} judul="Batalkan Item">
          <VoidItem
            namaTarget={
              daftarItemKeranjang.find((i) => i.id === itemVoid)?.menuItem.nama ?? 'Item pesanan'
            }
            nilai={daftarItemKeranjang.find((i) => i.id === itemVoid)?.subtotal ?? 0}
            sudahKeDapur={sudahKeDapur}
            onBatalkan={tanganiBatalkanItem}
            onTutup={() => setItemVoid(null)}
          />
        </Lapis>
      )}
    </div>
  )
}
