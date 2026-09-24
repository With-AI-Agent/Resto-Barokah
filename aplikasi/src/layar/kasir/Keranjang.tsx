import { useState } from 'react'
import { useBahasa } from '../../bahasa'
import { Tombol } from '../../komponen/Tombol'
import { Lencana } from '../../komponen/Lencana'
import { Lapis } from '../../komponen/Lapis'
import { KolomIsian } from '../../komponen/KolomIsian'
import { rupiah } from '../../lib/format'
import type { MenuItemData, VarianItem, TambahanItem } from './Katalog'

export interface ItemKeranjang {
  id: string
  menuItem: MenuItemData
  varian?: VarianItem
  tambahan?: TambahanItem[]
  catatan?: string
  qty: number
  subtotal: number
}

export interface RingkasanUang {
  subtotal: number
  totalDiskon: number
  pajak: number
  service: number
  total: number
}

export interface KeranjangProps {
  daftarItem?: ItemKeranjang[]
  ringkasan?: RingkasanUang
  namaMeja?: string
  tipePesanan?: 'dinein' | 'takeaway' | 'ojol'
  sedangMemproses?: boolean
  onTambahQty: (id: string) => void
  onKurangQty: (id: string) => void
  onHapusItem: (id: string) => void
  onUbahCatatan: (id: string, catatan: string) => void
  onKirimKeDapur?: () => void
  onProsesBayar?: () => void
  onBukaPemilihMeja?: () => void
  onBukaVoucher?: () => void
}

const RINGKASAN_DEFAULT: RingkasanUang = {
  subtotal: 0,
  totalDiskon: 0,
  pajak: 0,
  service: 0,
  total: 0,
}

export function Keranjang({
  daftarItem = [],
  ringkasan = RINGKASAN_DEFAULT,
  namaMeja = 'Meja 01',
  tipePesanan = 'dinein',
  sedangMemproses = false,
  onTambahQty,
  onKurangQty,
  onHapusItem,
  onUbahCatatan,
  onKirimKeDapur,
  onProsesBayar,
  onBukaPemilihMeja,
  onBukaVoucher,
}: KeranjangProps) {
  const { t } = useBahasa()
  const [itemCatatanEdit, setItemCatatanEdit] = useState<ItemKeranjang | null>(null)
  const [inputCatatan, setInputCatatan] = useState<string>('')

  const bukaEditCatatan = (item: ItemKeranjang) => {
    setItemCatatanEdit(item)
    setInputCatatan(item.catatan || '')
  }

  const simpanCatatan = () => {
    if (itemCatatanEdit) {
      onUbahCatatan(itemCatatanEdit.id, inputCatatan.trim())
      setItemCatatanEdit(null)
    }
  }

  const kosong = daftarItem.length === 0

  return (
    <div className="keranjang-kotak">
      {/* Header Info Meja & Tipe Pesanan */}
      <div className="keranjang-kepala">
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
          <div style={{ fontWeight: 800, fontSize: 'var(--t-4)', color: 'var(--text)' }}>
            {tipePesanan === 'dinein'
              ? `🍽️ ${namaMeja}`
              : tipePesanan === 'takeaway'
                ? `🥡 ${t('kasir.tipe_takeaway')}`
                : `🛵 ${t('kasir.tipe_ojol')}`}
          </div>
          <Lencana nada="info">
            {tipePesanan === 'dinein'
              ? t('kasir.tipe_dinein')
              : tipePesanan === 'takeaway'
                ? t('kasir.tipe_takeaway')
                : t('kasir.tipe_ojol')}
          </Lencana>
        </div>

        {onBukaPemilihMeja && (
          <Tombol ragam="kecil" onClick={onBukaPemilihMeja}>
            {t('kasir.pilih_meja')}
          </Tombol>
        )}
      </div>

      {/* Daftar Item Pesanan */}
      <div className="keranjang-daftar">
        {kosong ? (
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              height: '100%',
              padding: 'var(--s-8) 0',
              color: 'var(--text-muted)',
            }}
          >
            <div style={{ fontSize: '32px', marginBottom: 'var(--s-1)' }}>🛒</div>
            <div style={{ fontWeight: 700, fontSize: 'var(--t-3)' }}>Keranjang Masih Kosong</div>
            <div style={{ fontSize: 'var(--t-2)', textAlign: 'center', padding: '0 var(--s-3)' }}>
              {t('kasir.keranjang_kosong_petunjuk')}
            </div>
          </div>
        ) : (
          daftarItem.map((item) => (
            <div key={item.id} className="keranjang-item">
              <div className="keranjang-item__baris">
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="keranjang-item__nama">{item.menuItem.nama}</div>
                  {item.varian && (
                    <div style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                      {t('kasir.varian_ukuran')}: {item.varian.nama}
                    </div>
                  )}
                  {item.tambahan && item.tambahan.length > 0 && (
                    <div style={{ fontSize: 'var(--t-1)', color: 'var(--text-muted)' }}>
                      + {item.tambahan.map((tambahan) => tambahan.nama).join(', ')}
                    </div>
                  )}
                  {item.catatan && (
                    <div
                      style={{
                        fontSize: 'var(--t-1)',
                        color: 'var(--accent)',
                        background: 'var(--accent-soft)',
                        padding: '2px 6px',
                        borderRadius: '4px',
                        marginTop: '4px',
                        display: 'inline-block',
                      }}
                    >
                      📝 {item.catatan}
                    </div>
                  )}
                </div>

                {/* Subtotal Item */}
                <div className="keranjang-item__harga">{rupiah(item.subtotal)}</div>
              </div>

              {/* Kontrol Kuantitas & Catatan */}
              <div className="keranjang-item__kontrol">
                <Tombol ragam="polos" onClick={() => bukaEditCatatan(item)}>
                  <span style={{ fontSize: 'var(--t-1)', textDecoration: 'underline' }}>
                    {item.catatan ? 'Ubah Catatan' : '+ Tambah Catatan'}
                  </span>
                </Tombol>

                <div className="keranjang-item__qty">
                  <button
                    type="button"
                    className="keranjang-item__qty-btn"
                    onClick={() => onKurangQty(item.id)}
                    aria-label="Kurangi"
                  >
                    -
                  </button>
                  <span style={{ fontWeight: 700, minWidth: '22px', textAlign: 'center' }}>
                    {item.qty}
                  </span>
                  <button
                    type="button"
                    className="keranjang-item__qty-btn"
                    onClick={() => onTambahQty(item.id)}
                    aria-label="Tambah"
                  >
                    +
                  </button>
                  <Tombol ragam="bahaya" onClick={() => onHapusItem(item.id)} nama="Hapus item">
                    ✕
                  </Tombol>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Rangkuman Keuangan & Pajak */}
      <div className="keranjang-ringkasan">
        <div className="keranjang-ringkasan__baris">
          <span>{t('kasir.subtotal')}</span>
          <span style={{ fontWeight: 600, color: 'var(--text)' }}>
            {rupiah(ringkasan.subtotal)}
          </span>
        </div>

        {ringkasan.totalDiskon > 0 && (
          <div className="keranjang-ringkasan__baris" style={{ color: 'var(--success)' }}>
            <span>Diskon / Voucher Promo</span>
            <span style={{ fontWeight: 700 }}>-{rupiah(ringkasan.totalDiskon)}</span>
          </div>
        )}

        {ringkasan.service > 0 && (
          <div className="keranjang-ringkasan__baris">
            <span>{t('kasir.service')}</span>
            <span style={{ fontWeight: 600 }}>{rupiah(ringkasan.service)}</span>
          </div>
        )}

        {ringkasan.pajak > 0 && (
          <div className="keranjang-ringkasan__baris">
            <span>{t('kasir.pajak')}</span>
            <span style={{ fontWeight: 600 }}>{rupiah(ringkasan.pajak)}</span>
          </div>
        )}

        <div className="keranjang-ringkasan__total">
          <span>{t('kasir.total_belanja')}</span>
          <span style={{ color: 'var(--accent)', fontSize: 'var(--t-6)' }}>
            {rupiah(ringkasan.total)}
          </span>
        </div>
      </div>

      {/* Tombol Aksi Utama */}
      <div className="keranjang-aksi">
        {onBukaVoucher && !kosong && (
          <Tombol ragam="biasa" lebar onClick={onBukaVoucher}>
            🎟️ Tambah Voucher / Diskon
          </Tombol>
        )}

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: onKirimKeDapur && onProsesBayar ? '1fr 1fr' : '1fr',
            gap: 'var(--s-2)',
          }}
        >
          {onKirimKeDapur && (
            <Tombol ragam="biasa" onClick={onKirimKeDapur} nonaktif={kosong || sedangMemproses}>
              🍳 {t('kasir.kirim_dapur')}
            </Tombol>
          )}

          {onProsesBayar && (
            <Tombol ragam="utama" onClick={onProsesBayar} nonaktif={kosong || sedangMemproses}>
              💳 {t('kasir.proses_bayar')}
            </Tombol>
          )}
        </div>
      </div>

      {/* Modal Edit Catatan Khusus */}
      {itemCatatanEdit && (
        <Lapis
          buka={true}
          onTutup={() => setItemCatatanEdit(null)}
          judul={`Catatan: ${itemCatatanEdit.menuItem.nama}`}
        >
          <div
            style={{
              padding: 'var(--s-4)',
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-3)',
            }}
          >
            <KolomIsian
              label="Catatan Khusus untuk Dapur / Bar"
              contoh="Contoh: Es dipisah, sambal banyakin, jangan pakai MSG"
              nilai={inputCatatan}
              onUbah={setInputCatatan}
            />
            <div
              style={{
                display: 'flex',
                justifyContent: 'flex-end',
                gap: 'var(--s-2)',
                paddingTop: 'var(--s-2)',
                borderTop: '1px solid var(--border)',
              }}
            >
              <Tombol ragam="biasa" onClick={() => setItemCatatanEdit(null)}>
                {t('umum.batal')}
              </Tombol>
              <Tombol ragam="utama" onClick={simpanCatatan}>
                Simpan Catatan
              </Tombol>
            </div>
          </div>
        </Lapis>
      )}
    </div>
  )
}
