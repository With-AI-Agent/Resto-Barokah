import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'
import { LayarKasir } from './layar/kasir/LayarKasir'
import { KelolaPegawai } from './layar/pengaturan/KelolaPegawai'
import { DaftarPerangkat } from './layar/pengaturan/DaftarPerangkat'
import { LayarDapur } from './layar/dapur/LayarDapur'
import { LayarBar } from './layar/dapur/LayarBar'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
  const [layarAktif, setLayarAktif] = useState<string>('kasir')

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
            tiket={[]}
            waktuSekarang={new Date().toISOString()}
            onKeBar={() => setLayarAktif('bar')}
          />
        )
      case 'bar':
        return (
          <LayarBar
            tiket={[]}
            waktuSekarang={new Date().toISOString()}
            onKeDapur={() => setLayarAktif('dapur')}
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
