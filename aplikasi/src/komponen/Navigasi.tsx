/* eslint-disable react-refresh/only-export-components */
import React from 'react'
import { DAFTAR_BAHASA, useBahasa } from '../bahasa'
import type { KodeBahasa } from '../bahasa'
import { useTema } from '../hook/useTema'
import type { PeranPengguna } from '../lib/auth'
import { TEMA, type KodeTema } from '../lib/tema'

export interface ItemMenu {
  id: string
  label: string
  ikon: string
  path: string
}

export interface NavigasiProps {
  peran: PeranPengguna | null
  layarAktif: string
  onPilihLayar: (id: string) => void
  onKeluar?: () => void
  onBukaBantuan?: () => void
}

export function ambilMenuPeran(peran: PeranPengguna | null): ItemMenu[] {
  switch (peran) {
    case 'pemilik_platform':
      return [
        { id: 'platform_dasbor', label: 'Dasbor Platform', ikon: '🌐', path: '/platform' },
        { id: 'platform_resto', label: 'Resto Penyewa', ikon: '🏢', path: '/platform/resto' },
        { id: 'platform_dukungan', label: 'Mode Dukungan', ikon: '🛡️', path: '/platform/dukungan' },
      ]
    case 'owner_pusat':
      return [
        { id: 'kasir', label: 'Kasir POS', ikon: '💳', path: '/kasir' },
        { id: 'dapur', label: 'Layar Dapur', ikon: '🍳', path: '/dapur' },
        { id: 'laporan', label: 'Laporan & Kas', ikon: '📊', path: '/laporan' },
        { id: 'menu_stok', label: 'Menu & Stok', ikon: '📦', path: '/stok' },
        { id: 'pegawai', label: 'Kelola Pegawai', ikon: '👥', path: '/pegawai' },
        { id: 'pengaturan', label: 'Pengaturan Resto', ikon: '⚙️', path: '/pengaturan' },
      ]
    case 'admin_cabang':
      return [
        { id: 'kasir', label: 'Kasir POS', ikon: '💳', path: '/kasir' },
        { id: 'dapur', label: 'Layar Dapur', ikon: '🍳', path: '/dapur' },
        { id: 'laporan', label: 'Laporan Cabang', ikon: '📊', path: '/laporan' },
        { id: 'menu_stok', label: 'Stok Cabang', ikon: '📦', path: '/stok' },
        { id: 'pegawai', label: 'Pegawai Cabang', ikon: '👥', path: '/pegawai' },
      ]
    case 'kasir':
      return [
        { id: 'kasir', label: 'Kasir POS', ikon: '💳', path: '/kasir' },
        { id: 'riwayat', label: 'Riwayat Transaksi', ikon: '🧾', path: '/riwayat' },
        { id: 'tutup_kas', label: 'Tutup Kas Shift', ikon: '🔒', path: '/tutup-kas' },
      ]
    case 'pelayan':
      return [
        { id: 'pesanan_meja', label: 'Pesanan Meja', ikon: '🍽️', path: '/meja' },
        { id: 'status_pesanan', label: 'Status Pesanan', ikon: '📋', path: '/pesanan' },
        { id: 'voucher', label: 'Voucher Pelanggan', ikon: '🎟️', path: '/voucher' },
      ]
    case 'dapur':
      return [
        { id: 'dapur', label: 'Pesanan Dapur', ikon: '🍳', path: '/dapur' },
        { id: 'stok_habis', label: 'Tandai Stok Habis', ikon: '⚠️', path: '/dapur/stok' },
      ]
    default:
      return [
        { id: 'katalog', label: 'Katalog Menu', ikon: '📖', path: '/katalog' },
        { id: 'voucher_saya', label: 'Voucher Saya', ikon: '🎟️', path: '/voucher' },
      ]
  }
}

export const Navigasi: React.FC<NavigasiProps> = ({
  peran,
  layarAktif,
  onPilihLayar,
  onKeluar,
  onBukaBantuan,
}) => {
  const { t, bahasa, gantiBahasa } = useBahasa()
  const { tema, gantiTema, kerapatan, gantiKerapatan } = useTema()
  const daftarMenu = ambilMenuPeran(peran)

  return (
    <nav
      aria-label="Navigasi Utama"
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: 'var(--s-2) var(--s-4)',
        background: 'var(--latar-kartu)',
        borderBottom: '1px solid var(--b-netral)',
        flexWrap: 'wrap',
        gap: 'var(--s-3)',
      }}
    >
      {/* Daftar Menu Per Peran */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
        {daftarMenu.map((item) => {
          const aktif = layarAktif === item.id
          return (
            <button
              key={item.id}
              type="button"
              className={`tab ${aktif ? 'tab-aktif' : ''}`}
              onClick={() => onPilihLayar(item.id)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 'var(--s-1)',
                cursor: 'pointer',
                fontWeight: aktif ? 600 : 400,
              }}
            >
              <span>{item.ikon}</span>
              <span>
                {t(`navigasi.${item.id}`) !== `navigasi.${item.id}`
                  ? t(`navigasi.${item.id}`)
                  : item.label}
              </span>
            </button>
          )
        })}
      </div>

      {/* Kontrol Utilitas: Bahasa, Tema, Kerapatan, Bantuan, Keluar */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
        {/* Pemilih Bahasa */}
        <select
          aria-label="Pilih Bahasa"
          className="input"
          value={bahasa}
          onChange={(e) => gantiBahasa(e.target.value as KodeBahasa)}
          style={{
            padding: 'var(--s-1) var(--s-2)',
            height: '38px',
            minHeight: '38px',
            fontSize: 'var(--t-2)',
            cursor: 'pointer',
          }}
        >
          {DAFTAR_BAHASA.map((b) => (
            <option key={b.kode} value={b.kode}>
              {b.namaLokal}
            </option>
          ))}
        </select>

        {/* Pemilih Tema */}
        <select
          aria-label="Pilih Tema"
          className="input"
          value={tema}
          onChange={(e) => gantiTema(e.target.value as KodeTema)}
          style={{
            padding: 'var(--s-1) var(--s-2)',
            height: '38px',
            minHeight: '38px',
            fontSize: 'var(--t-2)',
            cursor: 'pointer',
          }}
        >
          {TEMA.map((tItem) => (
            <option key={tItem.kode} value={tItem.kode}>
              {tItem.nama}
            </option>
          ))}
        </select>

        {/* Pengalih Kerapatan */}
        <button
          type="button"
          className="btn btn-sm"
          onClick={() => gantiKerapatan(kerapatan === 'nyaman' ? 'padat' : 'nyaman')}
          title="Ubah Kerapatan Tampilan"
          style={{
            height: '38px',
            minHeight: '38px',
            padding: '0 var(--s-2)',
            fontSize: 'var(--t-2)',
          }}
        >
          {kerapatan === 'nyaman' ? '🌿 Nyaman' : '⚡ Padat'}
        </button>

        {/* Tombol Bantuan */}
        {onBukaBantuan && (
          <button
            type="button"
            className="btn btn-sm btn-sekunder"
            onClick={onBukaBantuan}
            style={{
              height: '38px',
              minHeight: '38px',
              padding: '0 var(--s-2)',
              fontSize: 'var(--t-2)',
            }}
          >
            ❓ {t('umum.bantuan')}
          </button>
        )}

        {/* Tombol Keluar */}
        {onKeluar && (
          <button
            type="button"
            className="btn btn-sm btn-bahaya"
            onClick={onKeluar}
            style={{
              height: '38px',
              minHeight: '38px',
              padding: '0 var(--s-2)',
              fontSize: 'var(--t-2)',
            }}
          >
            🚪 {t('umum.keluar')}
          </button>
        )}
      </div>
    </nav>
  )
}
