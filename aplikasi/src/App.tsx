import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { useBayar } from './hook/useBayar'
import { useStok } from './hook/useStok'
import { useTiketDapur } from './hook/useTiketDapur'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'
import { LayarMasukPelanggan } from './layar/masuk/LayarMasukPelanggan'
import { LayarKasir } from './layar/kasir/LayarKasir'
import type { ShiftAktifInfo } from './layar/kasir/BukaKas'
import { KelolaPegawai } from './layar/pengaturan/KelolaPegawai'
import { DaftarPerangkat } from './layar/pengaturan/DaftarPerangkat'
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
import { klienSupabase } from './lib/supabase'
import { masukDenganGoogle, kirimTautanMasukEmail } from './lib/auth'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
  const [modeMasuk, setModeMasuk] = useState<'pegawai' | 'pelanggan' | 'publik'>('pegawai')
  const [layarAktif, setLayarAktif] = useState<string>('kasir')
  const [shiftAktif, setShiftAktif] = useState<ShiftAktifInfo | null>(null)
  const cabangId = sesi?.cabangAktifId || 'cab-01'
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
                } catch (e) {
                  const msg = e instanceof Error ? e.message : 'Gagal menyimpan pesanan ke peladen.'
                  return { sukses: false, pesan: msg }
                }
              }

              // Mode simulasi / lokal tanpa koneksi peladen
              const hasil = masukan?.pesananId ?? null
              if (hasil) setPesananAktifId(hasil)
              return { sukses: true, pesananId: hasil ?? 'ord-new' }
            }}
            shiftAktif={shiftAktif}
            namaKasir={sesi?.nama ?? 'Kasir Bertugas'}
            uangSeharusnyaPerkiraan={
              (shiftAktif?.modalAwal ?? 0) + (bayar.terakhir?.totalPesanan ?? 0)
            }
            onKirimKeDapur={async (id) => {
              const klien = klienSupabase()
              if (klien) {
                const { error } = await klien
                  .from('pesanan')
                  .update({ status: 'antri' })
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
        return <DaftarPerangkat />
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
      case 'riwayat':
        return (
          <DaftarTransaksi
            daftar={
              bayar.terakhir
                ? [
                    {
                      id: pesananAktifId ?? 'tx-01',
                      data: {
                        nomor: 1,
                        tanggal: new Date().toISOString(),
                        namaResto: 'Resto Barokah',
                        item: [],
                        subtotal: bayar.terakhir.totalPesanan,
                        totalDiskon: 0,
                        pajak: 0,
                        service: 0,
                        total: bayar.terakhir.totalPesanan,
                      },
                      pembayaran: [
                        {
                          metode: 'Tunai',
                          jumlah: bayar.terakhir.totalDibayar,
                        },
                      ],
                      kembalian: bayar.terakhir.kembalian,
                    },
                  ]
                : []
            }
            onTutup={() => setLayarAktif('kasir')}
          />
        )
      case 'pesanan_meja':
      case 'status_pesanan':
        return <LayarPelayan namaPelayan={sesi?.nama ?? 'Pelayan'} />
      case 'printer':
        return <PasangPrinter />
      case 'tautan_katalog':
      case 'qr_katalog':
        return <TautanKatalog onKembali={() => setLayarAktif('pengaturan')} />
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
        modeMasuk === 'publik' ? (
          <div>
            <LayarPelangganPublik onTutup={() => setModeMasuk('pegawai')} />
            <div className="text-center pb-8" style={{ marginTop: 'var(--s-4)' }}>
              <button
                type="button"
                onClick={() => setModeMasuk('pegawai')}
                className="text-xs text-neutral-500 hover:text-neutral-800 underline"
              >
                ← Kembali ke Masuk Pegawai
              </button>
            </div>
          </div>
        ) : modeMasuk === 'pelanggan' ? (
          <div>
            <LayarMasukPelanggan
              onMasukGoogle={async () => {
                await masukDenganGoogle()
              }}
              onKirimTautanEmail={kirimTautanMasukEmail}
            />
            <div className="text-center pb-8">
              <button
                type="button"
                onClick={() => setModeMasuk('pegawai')}
                className="text-xs text-neutral-500 hover:text-neutral-800 underline"
              >
                ← Kembali ke Masuk Pegawai (PIN)
              </button>
            </div>
          </div>
        ) : (
          <div>
            <LayarMasukPegawai
              onMasuk={async (email, pin) => masuk(email, pin)}
              onMasukSukses={(sesiMasuk) => {
                const peranBaru = sesiMasuk?.peran || sesi?.peran
                setLayarAktif(peranBaru === 'dapur' ? 'dapur' : 'kasir')
              }}
            />
            <div
              className="text-center pb-8"
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
                alignItems: 'center',
              }}
            >
              <button
                type="button"
                onClick={() => setModeMasuk('pelanggan')}
                className="text-xs text-neutral-500 hover:text-neutral-800 underline"
              >
                Masuk sebagai Pelanggan (Google / Email) →
              </button>
              <button
                type="button"
                onClick={() => setModeMasuk('publik')}
                className="text-xs text-neutral-500 hover:text-neutral-800 underline"
              >
                🍽️ Lihat Katalog Menu Publik (Tanpa Masuk) →
              </button>
            </div>
          </div>
        )
      ) : (
        <Rangka sesi={sesi} layarAktif={layarAktif} onPilihLayar={setLayarAktif} onKeluar={keluar}>
          {renderKonten()}
        </Rangka>
      )}
    </PenyediaBahasa>
  )
}
