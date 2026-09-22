import { useState } from 'react'
import { PenyediaBahasa } from './bahasa'
import { useSesi } from './hook/useSesi'
import { Rangka } from './komponen/Rangka'
import LayarContoh from './layar/contoh/LayarContoh'
import { LayarMasukPegawai } from './layar/masuk/LayarMasukPegawai'

export default function App() {
  const { sesi, sedangMasuk, masuk, keluar } = useSesi()
  const [layarAktif, setLayarAktif] = useState<string>('kasir')

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
          <LayarContoh />
        </Rangka>
      )}
    </PenyediaBahasa>
  )
}
