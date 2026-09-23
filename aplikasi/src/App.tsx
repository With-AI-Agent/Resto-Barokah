import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { useStok } from './hook/useStok'
import { useTiketDapur } from './hook/useTiketDapur'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'
import { LayarKasir } from './layar/kasir/LayarKasir'
import { KelolaPegawai } from './layar/pengaturan/KelolaPegawai'
import { DaftarPerangkat } from './layar/pengaturan/DaftarPerangkat'
import { LayarDapur } from './layar/dapur/LayarDapur'
import { LayarBar } from './layar/dapur/LayarBar'
import { Stok } from './layar/dapur/Stok'
import { Opname } from './layar/dapur/Opname'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
  const [layarAktif, setLayarAktif] = useState<string>('kasir')
  const cabangId = sesi?.cabangAktifId || 'cab-01'
  // Kabel data papan dapur & bar (sisa Fase 4 butir c): tiket nyata dari peladen,
  // waktu peladen (bukan jam perangkat), cadangan antrean saat jaringan putus,
  // dan aksi tulis lewat RPC. Komponen layar tetap murni — kontainer di sini.
  const dapur = useTiketDapur({ cabangId, bagian: 'dapur' })
  const bar = useTiketDapur({ cabangId, bagian: 'bar' })
  // Kabel data stok & opname (T4-06/T4-07): saldo bahan, buku besar, dan aksi
  // tulis lewat RPC set_stok / opname_stok (selisih dihitung peladen).
  const stok = useStok()

  const renderKonten = () => {
    switch (layarAktif) {
      case 'kasir':
        return <LayarKasir cabangId={sesi?.cabangAktifId || 'cab-01'} />
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
