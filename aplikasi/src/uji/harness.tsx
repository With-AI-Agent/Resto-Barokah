/* eslint-disable react-refresh/only-export-components */
/**
 * Harness Pengujian Komponen Antarmuka & Layar (T1-34)
 * Menyediakan konteks peran, izin, data contoh (seed), serta perekam & tiruan RPC.
 */

import { createContext, useContext, useState, type ReactNode, type ReactElement } from 'react'
import { render, type RenderOptions, type RenderResult } from '@testing-library/react'
import type { PeranPengguna } from '../lib/layar'

export interface PanggilanRpc {
  nama: string
  params?: Record<string, unknown>
  waktu: number
}

export interface DataContoh {
  menu: Array<{ id: string; nama: string; harga: number; kategori: string; habis: boolean }>
  meja: Array<{ id: string; nomor: string; status: 'tersedia' | 'terisi' | 'dipesan' }>
  pesananAktif: Array<{
    id: string
    nomor: string
    meja: string
    status: 'baru' | 'dimasak' | 'siap' | 'lunas' | 'batal'
    total: number
    items: Array<{ id: string; nama: string; qty: number; harga: number }>
  }>
}

export const DATA_CONTOH_BAWAAN: DataContoh = {
  menu: [
    { id: 'm-1', nama: 'Nasi Goreng Kampung', harga: 25000, kategori: 'Makanan', habis: false },
    { id: 'm-2', nama: 'Ayam Bakar Madu', harga: 32000, kategori: 'Makanan', habis: false },
    { id: 'm-3', nama: 'Es Teh Manis', harga: 6000, kategori: 'Minuman', habis: false },
    { id: 'm-4', nama: 'Jus Alpukat', harga: 15000, kategori: 'Minuman', habis: true },
  ],
  meja: [
    { id: 't-1', nomor: 'Meja 01', status: 'tersedia' },
    { id: 't-2', nomor: 'Meja 02', status: 'terisi' },
    { id: 't-3', nomor: 'Meja 03', status: 'tersedia' },
  ],
  pesananAktif: [
    {
      id: 'p-101',
      nomor: 'ORD-20260922-001',
      meja: 'Meja 02',
      status: 'dimasak',
      total: 57000,
      items: [
        { id: 'm-1', nama: 'Nasi Goreng Kampung', qty: 1, harga: 25000 },
        { id: 'm-2', nama: 'Ayam Bakar Madu', qty: 1, harga: 32000 },
      ],
    },
  ],
}

export interface KonteksHarness {
  peran: PeranPengguna
  daftarIzin: string[]
  penggunaId: string
  cabangId: string
  penyewaId: string
  data: DataContoh
  panggilanRpc: PanggilanRpc[]
  eksekusiRpc: (nama: string, params?: Record<string, unknown>) => Promise<unknown>
}

const KonteksUji = createContext<KonteksHarness | null>(null)

export function useHarness(): KonteksHarness {
  const ctx = useContext(KonteksUji)
  if (!ctx) {
    throw new Error('useHarness harus digunakan di dalam HarnessPenyedia.')
  }
  return ctx
}

export interface OpsiHarness {
  peran?: PeranPengguna
  daftarIzin?: string[]
  penggunaId?: string
  cabangId?: string
  penyewaId?: string
  dataAwal?: Partial<DataContoh>
  penanganRpc?: Record<string, (params?: Record<string, unknown>) => Promise<unknown> | unknown>
  renderOptions?: Omit<RenderOptions, 'wrapper'>
}

export interface HasilRenderHarness extends RenderResult {
  panggilanRpc: PanggilanRpc[]
  cekRpcDipanggil: (nama: string) => boolean
  dapatkanPanggilanTerakhir: () => PanggilanRpc | undefined
}

export function HarnessPenyedia({
  children,
  peran = 'kasir',
  daftarIzin = [],
  penggunaId = 'user-test-01',
  cabangId = 'cabang-test-01',
  penyewaId = 'penyewa-test-01',
  dataAwal,
  penanganRpc = {},
  onCatatPanggilan,
}: {
  children: ReactNode
  peran?: PeranPengguna
  daftarIzin?: string[]
  penggunaId?: string
  cabangId?: string
  penyewaId?: string
  dataAwal?: Partial<DataContoh>
  penanganRpc?: Record<string, (params?: Record<string, unknown>) => Promise<unknown> | unknown>
  onCatatPanggilan?: (p: PanggilanRpc) => void
}) {
  const [data] = useState<DataContoh>({
    ...DATA_CONTOH_BAWAAN,
    ...dataAwal,
  })
  const [panggilanRpc, setPanggilanRpc] = useState<PanggilanRpc[]>([])

  const eksekusiRpc = async (nama: string, params?: Record<string, unknown>) => {
    const p: PanggilanRpc = { nama, params, waktu: Date.now() }
    setPanggilanRpc((prev) => [...prev, p])
    if (onCatatPanggilan) {
      onCatatPanggilan(p)
    }

    if (penanganRpc[nama]) {
      return await penanganRpc[nama](params)
    }
    return { status: 'sukses', rpc: nama }
  }

  const nilaiKonteks: KonteksHarness = {
    peran,
    daftarIzin,
    penggunaId,
    cabangId,
    penyewaId,
    data,
    panggilanRpc,
    eksekusiRpc,
  }

  return <KonteksUji.Provider value={nilaiKonteks}>{children}</KonteksUji.Provider>
}

export function renderDenganHarness(ui: ReactElement, opsi: OpsiHarness = {}): HasilRenderHarness {
  const riwayat: PanggilanRpc[] = []

  const wrapper = ({ children }: { children: ReactNode }) => (
    <HarnessPenyedia
      peran={opsi.peran}
      daftarIzin={opsi.daftarIzin}
      penggunaId={opsi.penggunaId}
      cabangId={opsi.cabangId}
      penyewaId={opsi.penyewaId}
      dataAwal={opsi.dataAwal}
      penanganRpc={opsi.penanganRpc}
      onCatatPanggilan={(p) => riwayat.push(p)}
    >
      {children}
    </HarnessPenyedia>
  )

  const hasilRender = render(ui, { wrapper, ...opsi.renderOptions })

  return {
    ...hasilRender,
    panggilanRpc: riwayat,
    cekRpcDipanggil: (nama: string) => riwayat.some((p) => p.nama === nama),
    dapatkanPanggilanTerakhir: () => (riwayat.length > 0 ? riwayat[riwayat.length - 1] : undefined),
  }
}
