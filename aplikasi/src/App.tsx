import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { useAlamatCabang } from './hook/useAlamatCabang'
import { useRiwayatTransaksi } from './hook/useRiwayatTransaksi'
import { useBayar } from './hook/useBayar'
import { useStok } from './hook/useStok'
import { useTiketDapur } from './hook/useTiketDapur'
import { useKunciOtomatis } from './hook/useKunciOtomatis'
import { KunciSekarang } from './komponen/KunciSekarang'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'
import { LayarMasukPelanggan } from './layar/masuk/LayarMasukPelanggan'
import { LayarKasir } from './layar/kasir/LayarKasir'
import { KeadaanKosong } from './komponen/KeadaanKosong'
import { Tombol } from './komponen/Tombol'
import type { ShiftAktifInfo } from './layar/kasir/BukaKas'
import { KelolaPegawai } from './layar/pengaturan/KelolaPegawai'
import { LayarPengaturan } from './layar/pengaturan/LayarPengaturan'
import { LayarDapur } from './layar/dapur/LayarDapur'
import { LayarBar } from './layar/dapur/LayarBar'
import { Stok } from './layar/dapur/Stok'
import { Opname } from './layar/dapur/Opname'
import { LayarLaporan } from './layar/laporan/LayarLaporan'
import { LayarPelayan } from './layar/pelayan/LayarPelayan'
import { DaftarTransaksi } from './layar/kasir/DaftarTransaksi'
import { PasangPrinter } from './layar/pengaturan/PasangPrinter'
import { TautanKatalog } from './layar/pengaturan/TautanKatalog'
import { LayarPelangganPublik } from './layar/pelanggan-publik/LayarPelangganPublik'
import { Kampanye } from './layar/voucher/Kampanye'
import { klienSupabase } from './lib/supabase'
import { masukDenganGoogle, kirimTautanMasukEmail } from './lib/auth'
import { tambahKeAntrean } from './lib/antrean-offline'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
  // PMB1-F-084 (KEAMANAN §7): kunci otomatis saat tidak ada aktivitas.
  // Hook & komponen sudah ada sejak fase awal tapi tidak pernah dipasang;
  // kini wadah aplikasi menguncinya per peran (kasir/pelayan/dapur 15 menit,
  // admin cabang 30, owner 60) dan mengakhiri sesi ketika batas terlampaui.
  const { dalamPeringatan, sisaDetik, kunci, rekamAktivitas } = useKunciOtomatis({
    peran: sesi?.peran ?? 'kasir',
    onKunci: () => {
      if (sesi) void keluar()
    },
  })
  const [modeMasuk, setModeMasuk] = useState<'pegawai' | 'pelanggan' | 'publik'>('pegawai')
  const [layarAktif, setLayarAktif] = useState<string>('kasir')
  const [shiftAktif, setShiftAktif] = useState<ShiftAktifInfo | null>(null)
  const cabangId = sesi?.cabangAktifId || 'cab-01'
  // PMB1-F-020: alamat cabang untuk struk (PRD M6 baris 131).
  const alamatCabang = useAlamatCabang(cabangId)
  // PMB1-F-021: riwayat transaksi NYATA dari peladen (bukan baris sintetis).
  const riwayat = useRiwayatTransaksi(cabangId)
  // Tagihan yang sedang dilayani kasir. Untuk sekarang satu tagihan berjalan
  // per terminal; pemilihan tagihan dari Open Bill menyusul bersama T5-03.
  const [pesananAktifId, setPesananAktifId] = useState<string | null>(null)
  // Kabel data papan dapur & bar (sisa Fase 4 butir c): tiket nyata dari peladen,
  // waktu peladen (bukan jam perangkat), cadangan antrean saat jaringan putus,
  // dan aksi tulis lewat RPC. Komponen layar tetap murni — kontainer di sini.
  const dapur = useTiketDapur({ cabangId, bagian: 'dapur' })
  const bar = useTiketDapur({ cabangId, bagian: 'bar' })
  // Kabel data stok & opname (T4-06/T4-07): saldo bahan, buku besar, dan aksi
  // tulis lewat RPC set_stok / opname_stok (selisih dihitung peladen).
  const stok = useStok()
  // Kabel data pembayaran (T5-01): metode AKTIF dari peladen dan pencatatan uang
  // lewat RPC `bayar_pesanan` (migrasi 0039). Layar kasir tidak lagi punya daftar
  // metode sendiri dan tidak pernah menghitung kembalian yang disimpan.
  const bayar = useBayar(pesananAktifId)

  const renderKonten = () => {
    switch (layarAktif) {
      case 'kasir':
        return (
          <LayarKasir
            cabangId={cabangId}
            pesananId={pesananAktifId ?? 'ord-current'}
            metodeBayar={bayar.metode}
            keadaanBayar={bayar.keadaan}
            pesanBayar={bayar.pesan}
            terakhirBayar={bayar.terakhir}
            onBayar={bayar.bayar}
            onCobaBayar={() => void bayar.muat()}
            onSelesaiBayar={() => {
              bayar.lanjut()
              // Tagihan lunas selesai dilayani: terminal siap untuk tagihan baru.
              if (bayar.terakhir?.lunas) setPesananAktifId(null)
            }}
            onSimpanPesanan={async (data) => {
              const klien = klienSupabase()
              const masukan = data as {
                mejaId?: string
                tipe?: string
                pesananId?: string
                items?: Array<{ id: string; nama: string; harga: number; qty: number }>
              }

              if (klien) {
                try {
                  if (typeof navigator !== 'undefined' && !navigator.onLine) {
                    throw new Error('Jaringan luring (offline)')
                  }

                  const idPesanan = masukan.pesananId || crypto.randomUUID()
                  const { error: errPesanan } = await klien.from('pesanan').insert({
                    id: idPesanan,
                    penyewa_id: sesi?.penyewaId,
                    cabang_id: cabangId,
                    meja_id: masukan.mejaId ?? null,
                    tipe: masukan.tipe ?? 'dinein',
                    shift_id: shiftAktif?.id ?? null,
                    kunci_idempoten: `pos-${idPesanan}`,
                  })

                  if (errPesanan) {
                    return { sukses: false, pesan: errPesanan.message }
                  }

                  if (masukan.items && masukan.items.length > 0) {
                    const itemRows = masukan.items.map((it) => ({
                      pesanan_id: idPesanan,
                      menu_item_id: it.id,
                      nama_saat_itu: it.nama,
                      harga_saat_itu: it.harga,
                      qty: it.qty,
                      subtotal: it.harga * it.qty,
                    }))
                    const { error: errItems } = await klien.from('pesanan_item').insert(itemRows)
                    if (errItems) {
                      return { sukses: false, pesan: errItems.message }
                    }
                  }

                  // Panggil hitung_total eksplisit untuk memastikan nominal terkunci
                  try {
                    await klien.rpc('hitung_total', { p_pesanan_id: idPesanan })
                  } catch {
                    // Penjaga pemicu 0022 tetap berjalan jika RPC tak sengaja gagal
                  }

                  setPesananAktifId(idPesanan)
                  return { sukses: true, pesananId: idPesanan }
                } catch {
                  // Simpan ke antrean luring saat jaringan offline / putus (T10-01 / ART-8)
                  const idPesanan = masukan.pesananId || crypto.randomUUID()
                  await tambahKeAntrean({
                    jenis: 'simpan_pesanan',
                    kunciIdempoten: `pos-${idPesanan}`,
                    muatan: {
                      pesananId: idPesanan,
                      penyewaId: sesi?.penyewaId,
                      cabangId,
                      mejaId: masukan.mejaId ?? null,
                      tipe: masukan.tipe ?? 'dinein',
                      shiftId: shiftAktif?.id ?? null,
                      items: masukan.items,
                    },
                    labelRingkas: `Pesanan (${masukan.tipe || 'dinein'}) - ${masukan.items?.length || 0} item`,
                  })
                  setPesananAktifId(idPesanan)
                  return {
                    sukses: true,
                    pesananId: idPesanan,
                    pesan:
                      'Pesanan tersimpan di antrean luring (akan dikirim saat kembali daring).',
                  }
                }
              }

              // Mode simulasi / lokal tanpa koneksi peladen
              const hasil = masukan?.pesananId ?? null
              if (hasil) setPesananAktifId(hasil)
              return { sukses: true, pesananId: hasil ?? 'ord-new' }
            }}
            shiftAktif={shiftAktif}
            namaKasir={sesi?.nama ?? 'Kasir Bertugas'}
            alamatCabang={alamatCabang ?? undefined}
            uangSeharusnyaPerkiraan={
              (shiftAktif?.modalAwal ?? 0) + (bayar.terakhir?.totalPesanan ?? 0)
            }
            onKirimKeDapur={async (id) => {
              const klien = klienSupabase()
              if (klien) {
                const { error } = await klien
                  .from('pesanan')
                  .update({
                    status: 'dikirim',
                    // Wajib diisi (kontrak 0009), tetapi nilainya DITIMPA jam peladen oleh pemicu (0088, PMB1-F-132).
                    dikirim_ke_dapur_pada: new Date().toISOString(),
                  })
                  .eq('id', id)
                if (error) {
                  return { sukses: false, pesan: error.message }
                }
              }
              return { sukses: true }
            }}
            onKasPergerakan={async (data) => {
              const klien = klienSupabase()
              if (klien) {
                const { error } = await klien.rpc('kas_pergerakan', {
                  p_jenis: data.jenis,
                  p_jumlah: data.jumlah,
                  p_alasan: data.alasan,
                  p_shift_id: shiftAktif?.id ?? null,
                  p_cabang_id: cabangId,
                })
                if (error) {
                  return { sukses: false, pesan: error.message }
                }
                return { sukses: true }
              }
              return { sukses: true }
            }}
            onKoreksiModal={async (data) => {
              const klien = klienSupabase()
              if (klien) {
                const { error } = await klien.rpc('koreksi_modal_shift', {
                  p_shift_id: shiftAktif?.id,
                  p_modal_baru: data.modalAwalBaru,
                  p_alasan: data.alasan,
                })
                if (error) {
                  return { sukses: false, pesan: error.message }
                }
                if (shiftAktif) {
                  setShiftAktif({ ...shiftAktif, modalAwal: data.modalAwalBaru })
                }
                return { sukses: true }
              }
              if (shiftAktif) {
                setShiftAktif({ ...shiftAktif, modalAwal: data.modalAwalBaru })
              }
              return { sukses: true }
            }}
            onBatalkanItem={async ({ itemId, alasan }) => {
              const klien = klienSupabase()
              if (klien && pesananAktifId) {
                const { error } = await klien.from('pembatalan').insert({
                  pesanan_id: pesananAktifId,
                  pesanan_item_id:
                    itemId.startsWith('ord-item-') || itemId.length > 20 ? itemId : null,
                  alasan,
                  tahap: 'sebelum_dapur',
                })
                if (error) {
                  return { berhasil: false, pesan: error.message }
                }
                return { berhasil: true }
              }
              return { berhasil: true }
            }}
            onTerapkanDiskon={async ({ nilai, alasan, disetujuiOleh }) => {
              const klien = klienSupabase()
              if (klien && pesananAktifId) {
                const { error } = await klien.from('diskon_transaksi').insert({
                  pesanan_id: pesananAktifId,
                  jenis: 'manual',
                  nilai,
                  nominal: nilai,
                  alasan,
                  disetujui_oleh: disetujuiOleh,
                })
                if (error) {
                  return { berhasil: false, pesan: error.message }
                }
                return { berhasil: true }
              }
              return { berhasil: true }
            }}
            onBukaShift={async ({ modalAwal, catatan }) => {
              const klien = klienSupabase()
              if (klien) {
                const { data, error } = await klien.rpc('buka_shift', {
                  p_modal_awal: modalAwal,
                  p_cabang_id: cabangId,
                  p_catatan: catatan ?? null,
                })
                if (error) {
                  return { sukses: false, pesan: error.message }
                }
                const res = data as {
                  berhasil?: boolean
                  pesan?: string
                  shift_id?: string
                  cabang_id?: string
                  modal_awal?: number
                  dibuka_pada?: string
                } | null
                if (!res?.berhasil || !res.shift_id) {
                  return { sukses: false, pesan: res?.pesan || 'Gagal membuka shift kasir.' }
                }
                const baru: ShiftAktifInfo = {
                  id: res.shift_id,
                  cabangId: res.cabang_id || cabangId,
                  modalAwal: res.modal_awal ?? modalAwal,
                  dibukaPada: res.dibuka_pada || new Date().toISOString(),
                }
                setShiftAktif(baru)
                return { sukses: true, shiftId: res.shift_id }
              }

              // Mode simulasi / lokal tanpa koneksi peladen
              const baru: ShiftAktifInfo = {
                id: `shift-${Date.now()}`,
                cabangId,
                modalAwal,
                dibukaPada: new Date().toISOString(),
              }
              setShiftAktif(baru)
              return { sukses: true, shiftId: baru.id }
            }}
            onTutupShift={async ({ uangFisik, alasanSelisih, catatan }) => {
              const klien = klienSupabase()
              if (klien) {
                const { data, error } = await klien.rpc('tutup_shift', {
                  p_uang_fisik: uangFisik,
                  p_alasan_selisih: alasanSelisih ?? null,
                  p_shift_id: shiftAktif?.id ?? null,
                  p_catatan: catatan ?? null,
                })
                if (error) {
                  return { sukses: false, pesan: error.message }
                }
                const res = data as {
                  berhasil?: boolean
                  pesan?: string
                  data?: {
                    shift_id: string
                    cabang_id: string
                    modal_awal: number
                    tunai_masuk: number
                    tunai_keluar: number
                    uang_seharusnya: number
                    uang_fisik: number
                    selisih: number
                    alasan_selisih: string | null
                    status: string
                    ditutup_pada: string
                  }
                } | null
                if (!res?.berhasil || !res.data) {
                  return { sukses: false, pesan: res?.pesan || 'Gagal menutup shift kasir.' }
                }
                setShiftAktif(null)
                return {
                  sukses: true,
                  data: {
                    shiftId: res.data.shift_id,
                    cabangId: res.data.cabang_id,
                    modalAwal: res.data.modal_awal,
                    tunaiMasuk: res.data.tunai_masuk,
                    tunaiKeluar: res.data.tunai_keluar,
                    uangSeharusnya: res.data.uang_seharusnya,
                    uangFisik: res.data.uang_fisik,
                    selisih: res.data.selisih,
                    alasanSelisih: res.data.alasan_selisih,
                    status: res.data.status,
                    ditutupPada: res.data.ditutup_pada,
                  },
                }
              }

              // Mode simulasi / lokal tanpa koneksi peladen
              const modal = shiftAktif?.modalAwal ?? 0
              const tunai = bayar.terakhir?.totalPesanan ?? 0
              const seharusnya = modal + tunai
              const selisih = uangFisik - seharusnya
              setShiftAktif(null)
              return {
                sukses: true,
                data: {
                  shiftId: shiftAktif?.id ?? `shift-${Date.now()}`,
                  cabangId,
                  modalAwal: modal,
                  tunaiMasuk: tunai,
                  tunaiKeluar: 0,
                  uangSeharusnya: seharusnya,
                  uangFisik,
                  selisih,
                  alasanSelisih,
                  status: 'ditutup',
                  ditutupPada: new Date().toISOString(),
                },
              }
            }}
          />
        )
      case 'pegawai':
        return <KelolaPegawai cabangAktifId={sesi?.cabangAktifId || 'cab-01'} />
      case 'pengaturan':
        return <LayarPengaturan />
      case 'dapur':
        return (
          <LayarDapur
            tiket={dapur.tiket}
            waktuSekarang={dapur.waktuSekarang}
            keadaan={dapur.keadaan}
            antreanCadangan={dapur.antreanCadangan}
            onMulaiMasak={(itemId) => void dapur.mulaiMasak(itemId)}
            onSelesaiMasak={(itemId) => void dapur.selesaiMasak(itemId)}
            onTandaiHabis={(menuItemId) => void dapur.tandaiHabis(menuItemId)}
            onCoba={dapur.muatUlang}
            onKeBar={() => setLayarAktif('bar')}
          />
        )
      case 'bar':
        return (
          <LayarBar
            tiket={bar.tiket}
            waktuSekarang={bar.waktuSekarang}
            keadaan={bar.keadaan}
            antreanCadangan={bar.antreanCadangan}
            onMulaiMasak={(itemId) => void bar.mulaiMasak(itemId)}
            onSelesaiMasak={(itemId) => void bar.selesaiMasak(itemId)}
            onCoba={bar.muatUlang}
            onKeDapur={() => setLayarAktif('dapur')}
          />
        )
      case 'menu_stok':
        return (
          <Stok
            bahan={stok.bahan}
            riwayat={stok.riwayat}
            keadaan={stok.keadaan}
            onSimpan={(bahanId, delta, alasan) => void stok.catatStok(bahanId, delta, alasan)}
            onKeOpname={() => setLayarAktif('opname')}
            onCoba={stok.muatUlang}
          />
        )
      case 'opname':
        return (
          <Opname
            bahan={stok.bahan}
            keadaan={stok.keadaan}
            onCoba={stok.muatUlang}
            onSimpan={(bahanId, jumlahFisik, alasan) =>
              void stok.catatOpname(bahanId, jumlahFisik, alasan)
            }
            onKembali={() => setLayarAktif('menu_stok')}
          />
        )
      case 'laporan':
        return (
          <LayarLaporan
            cabangAktifId={cabangId}
            peranPengguna={
              sesi?.peran === 'owner_pusat' ||
              sesi?.peran === 'admin_cabang' ||
              sesi?.peran === 'kasir'
                ? sesi.peran
                : 'kasir'
            }
          />
        )
      case 'riwayat': {
        // PMB1-F-021: riwayat dibaca dari peladen (tabel pembayaran + pesanan),
        // bukan dibangun dari pembayaran terakhir dengan nomor/tanggal/metode palsu.
        if (riwayat.keadaan === 'gagal') {
          return (
            <KeadaanKosong
              judul="Riwayat transaksi tidak bisa dimuat"
              keterangan={riwayat.pesan ?? 'Coba lagi beberapa saat.'}
              aksi={<Tombol onClick={riwayat.muat}>Coba lagi</Tombol>}
            />
          )
        }
        if (riwayat.daftar.length === 0) {
          return (
            <KeadaanKosong
              judul="Belum ada transaksi tercatat"
              keterangan="Transaksi muncul di sini setelah pembayaran tercatat oleh peladen."
            />
          )
        }
        return <DaftarTransaksi daftar={riwayat.daftar} onTutup={() => setLayarAktif('kasir')} />
      }
      case 'status_pesanan':
        return <LayarPelayan namaPelayan={sesi?.nama ?? 'Pelayan'} />
      case 'printer':
        return <PasangPrinter />
      case 'tautan_katalog':
      case 'qr_katalog':
        return <TautanKatalog onKembali={() => setLayarAktif('pengaturan')} />
      case 'kampanye':
      case 'klaim_voucher':
        return (
          <Kampanye
            onBukaKatalog={() => setLayarAktif('katalog')}
            onMasukGoogle={masukDenganGoogle}
            onKirimEmail={kirimTautanMasukEmail}
          />
        )
      case 'pelanggan-publik':
      case 'katalog':
        return (
          <LayarPelangganPublik
            penyewaId={sesi?.penyewaId || undefined}
            cabangId={cabangId}
            onTutup={() => setLayarAktif('kasir')}
          />
        )
      default:
        return <LayarContoh />
    }
  }

  return (
    <PenyediaBahasa>
      {!sedangMasuk ? (
        <div
          style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 'var(--s-6) var(--s-3)',
            background: 'radial-gradient(ellipse at 50% 15%, var(--surface-2) 0%, var(--bg) 100%)',
          }}
        >
          {/* Header Identitas & Merek Aplikasi */}
          <div
            style={{
              textAlign: 'center',
              marginBottom: 'var(--s-4)',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: 'var(--s-2)',
            }}
          >
            <div
              style={{
                width: '56px',
                height: '56px',
                borderRadius: 'var(--radius)',
                background: 'var(--surface)',
                border: '1px solid var(--border)',
                boxShadow: 'var(--sh-2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: '28px',
              }}
            >
              🍽️
            </div>
            <div>
              <h1
                style={{
                  margin: 0,
                  fontSize: 'var(--t-7)',
                  fontFamily: 'var(--font-display)',
                  letterSpacing: '0.02em',
                  fontWeight: 800,
                  color: 'var(--text)',
                }}
              >
                RESTO BAROKAH
              </h1>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontSize: 'var(--t-3)',
                  color: 'var(--text-muted)',
                }}
              >
                Sistem Operasional Kasir POS & Layanan Kuliner
              </p>
            </div>
          </div>

          {/* Segmented Control untuk Navigasi Antar Mode */}
          <div style={{ marginBottom: 'var(--s-5)' }}>
            <div className="segmen" role="tablist">
              <button
                type="button"
                role="tab"
                aria-selected={modeMasuk === 'pegawai'}
                aria-pressed={modeMasuk === 'pegawai'}
                onClick={() => setModeMasuk('pegawai')}
              >
                🧑‍🍳 Masuk Pegawai (PIN)
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={modeMasuk === 'pelanggan'}
                aria-pressed={modeMasuk === 'pelanggan'}
                onClick={() => setModeMasuk('pelanggan')}
              >
                👤 Masuk Pelanggan
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={modeMasuk === 'publik'}
                aria-pressed={modeMasuk === 'publik'}
                onClick={() => setModeMasuk('publik')}
              >
                📖 Menu Digital Publik
              </button>
            </div>
          </div>

          {/* Area Konten Layar Terpilih */}
          <div style={{ width: '100%', display: 'flex', justifyContent: 'center' }}>
            {modeMasuk === 'publik' ? (
              <div style={{ width: '100%', maxWidth: '960px' }}>
                <LayarPelangganPublik onTutup={() => setModeMasuk('pegawai')} />
              </div>
            ) : modeMasuk === 'pelanggan' ? (
              <LayarMasukPelanggan
                onMasukGoogle={async () => {
                  await masukDenganGoogle()
                }}
                onKirimTautanEmail={kirimTautanMasukEmail}
              />
            ) : (
              <LayarMasukPegawai
                onMasuk={async (email, pin) => masuk(email, pin)}
                onMasukSukses={(sesiMasuk) => {
                  const peranBaru = sesiMasuk?.peran || sesi?.peran
                  setLayarAktif(peranBaru === 'dapur' ? 'dapur' : 'kasir')
                }}
              />
            )}
          </div>
        </div>
      ) : (
        <>
          {/* PMB1-F-084: tombol kunci manual + peringatan dini, melayang agar
              tidak menggeser tata letak Rangka (min-height 100vh). */}
          <div style={{ position: 'fixed', top: 8, right: 8, zIndex: 60 }}>
            <KunciSekarang
              onKunci={kunci}
              dalamPeringatan={dalamPeringatan}
              sisaDetik={sisaDetik}
              onBatalkanPeringatan={rekamAktivitas}
            />
          </div>
          <Rangka
            sesi={sesi}
            layarAktif={layarAktif}
            onPilihLayar={setLayarAktif}
            onKeluar={keluar}
          >
            {renderKonten()}
          </Rangka>
        </>
      )}
    </PenyediaBahasa>
  )
}
