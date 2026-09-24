import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { useBayar } from './hook/useBayar'
import { useStok } from './hook/useStok'
import { useTiketDapur } from './hook/useTiketDapur'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'
import { LayarKasir } from './layar/kasir/LayarKasir'
import type { ShiftAktifInfo } from './layar/kasir/BukaKas'
import { KelolaPegawai } from './layar/pengaturan/KelolaPegawai'
import { DaftarPerangkat } from './layar/pengaturan/DaftarPerangkat'
import { LayarDapur } from './layar/dapur/LayarDapur'
import { LayarBar } from './layar/dapur/LayarBar'
import { Stok } from './layar/dapur/Stok'
import { Opname } from './layar/dapur/Opname'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
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
              // Penyimpanan pesanan nyata menyusul (T5-03); yang penting di sini
              // id tagihan yang dipakai layar Bayar ikut diperbarui.
              const hasil = (data as { pesananId?: string })?.pesananId ?? null
              if (hasil) setPesananAktifId(hasil)
              return { sukses: true, pesananId: hasil ?? 'ord-new' }
            }}
            shiftAktif={shiftAktif}
            namaKasir={sesi?.nama ?? 'Kasir Bertugas'}
            uangSeharusnyaPerkiraan={
              (shiftAktif?.modalAwal ?? 0) + (bayar.terakhir?.totalPesanan ?? 0)
            }
            onBukaShift={async ({ modalAwal }) => {
              const baru: ShiftAktifInfo = {
                id: `shift-${Date.now()}`,
                cabangId,
                modalAwal,
                dibukaPada: new Date().toISOString(),
              }
              setShiftAktif(baru)
              return { sukses: true, shiftId: baru.id }
            }}
            onTutupShift={async ({ uangFisik, alasanSelisih }) => {
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
      default:
        return <LayarContoh />
    }
  }

  return (
    <PenyediaBahasa>
      {!sedangMasuk ? (
        <LayarMasukPegawai
          onMasuk={async (email, pin) => masuk(email, pin)}
          onMasukSukses={() => {
            setLayarAktif(sesi?.peran === 'dapur' ? 'dapur' : 'kasir')
          }}
        />
      ) : (
        <Rangka sesi={sesi} layarAktif={layarAktif} onPilihLayar={setLayarAktif} onKeluar={keluar}>
          {renderKonten()}
        </Rangka>
      )}
    </PenyediaBahasa>
  )
}
