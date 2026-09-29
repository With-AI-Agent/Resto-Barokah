import type { MejaData } from '../../layar/kasir/PemilihMeja'

export const MEJA_KASIR_UJI: MejaData[] = [
  { id: 'meja-01', nama: 'Meja 01', area: 'Indoor', status: 'kosong', aktif: true },
  { id: 'meja-02', nama: 'Meja 02', area: 'Indoor', status: 'terisi', aktif: true, jumlahTamu: 3 },
  { id: 'meja-03', nama: 'Meja 03', area: 'Indoor', status: 'siap', aktif: true },
  { id: 'meja-04', nama: 'Meja 04', area: 'Teras', status: 'kosong', aktif: true },
]
