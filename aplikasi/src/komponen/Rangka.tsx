import React from 'react'
import { useCabang } from '../hook/useCabang'
import type { PenggunaSesi } from '../lib/auth'
import { LembarBantuan } from './LembarBantuan'
import { Navigasi } from './Navigasi'
import { PemilihCabang } from './PemilihCabang'

export interface RangkaProps {
  sesi: PenggunaSesi | null
  layarAktif: string
  onPilihLayar: (id: string) => void
  onKeluar?: () => void
  children: React.ReactNode
}

export const Rangka: React.FC<RangkaProps> = ({
  sesi,
  layarAktif,
  onPilihLayar,
  onKeluar,
  children,
}) => {
  const { cabangAktifId, bisaPindahCabang, gantiCabang } = useCabang(sesi)

  const daftarCabang = [
    { id: 'cab-001', nama: 'Kedai Oasis - Cabang Utama' },
    { id: 'cab-002', nama: 'Kedai Oasis - Cabang Sudirman' },
  ]

  const idBantuanLayar =
    layarAktif === 'dapur'
      ? 'dapur'
      : layarAktif === 'laporan'
        ? 'laporan'
        : layarAktif === 'pengaturan'
          ? 'pengaturan'
          : layarAktif === 'voucher'
            ? 'voucher'
            : 'kasir'

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        background: 'var(--latar-utama)',
        color: 'var(--teks-utama)',
      }}
    >
      {/* Header Utama Resto */}
      <header
        style={{
          padding: 'var(--s-3) var(--s-4)',
          background: 'var(--latar-kartu)',
          borderBottom: '1px solid var(--b-netral)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 'var(--s-2)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-3)' }}>
          <div style={{ fontSize: 'var(--t-6)', fontWeight: 800, color: 'var(--warna-aksen)' }}>
            Resto Barokah
          </div>
          {sesi && (
            <PemilihCabang
              cabangAktifId={cabangAktifId}
              daftarCabang={daftarCabang}
              bisaPindahCabang={bisaPindahCabang}
              onGantiCabang={gantiCabang}
            />
          )}
        </div>

        {sesi && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--s-2)',
              fontSize: 'var(--t-3)',
            }}
          >
            <span className="lencana lencana-primer">{sesi.peran.toUpperCase()}</span>
            <span style={{ fontWeight: 600 }}>{sesi.nama}</span>
            <LembarBantuan idLayar={idBantuanLayar} />
          </div>
        )}
      </header>

      {/* Navigasi Peran */}
      <Navigasi
        peran={sesi?.peran ?? null}
        layarAktif={layarAktif}
        onPilihLayar={onPilihLayar}
        onKeluar={onKeluar}
      />

      {/* Konten Utama */}
      <main style={{ flex: 1, padding: 'var(--s-4)' }}>{children}</main>

      {/* Footer Info Sistem */}
      <footer
        style={{
          padding: 'var(--s-3) var(--s-4)',
          background: 'var(--latar-kartu)',
          borderTop: '1px solid var(--b-netral)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          fontSize: 'var(--t-2)',
          color: 'var(--teks-redup)',
          flexWrap: 'wrap',
          gap: 'var(--s-2)',
        }}
      >
        <div>Resto Barokah POS &copy; 2026 — Sistem Kasir Mandiri & Teruji</div>
        <div>Status: Terhubung & Siap Bertugas</div>
      </footer>
    </div>
  )
}
