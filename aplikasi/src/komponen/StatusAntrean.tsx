/**
 * StatusAntrean.tsx — Komponen pemulihan kegagalan kirim & status antrean (T10-03).
 *
 * Sesuai panduan AGENT_OPERATING_GUIDE §6 dan PRD M4 (kasus tepi):
 *  1. Indikator selalu terlihat di kasir: Terkirim, Tertunda, Gagal + jumlah pesanan.
 *  2. Percobaan ulang otomatis (saat kembali online) & manual (per-item atau massal).
 *  3. Tidak ada pesan "gagal diam-diam": pesan galat jujur dari peladen/jaringan
 *     selalu ditampilkan gamblang beserta waktu percobaan terakhir.
 *  4. Kasir mengira gagal padahal terkirim (atau sebaliknya) dicegah dengan verifikasi
 *     status dari peladen dan kunci idempoten menyeluruh (ART-8).
 */

import { useState, type ReactElement } from 'react'
import { useAntrean } from '../hook/useAntrean'
import { type ItemAntrean } from '../lib/antrean-offline'
import { Lencana, type NadaLencana } from './Lencana'
import { Tombol } from './Tombol'
import { Lapis } from './Lapis'

export interface StatusAntreanProps {
  className?: string
  /**
   * Jika true, indikator selalu terlihat meskipun antrean kosong.
   * Default: true (sesuai DoD T10-03).
   */
  selaluTampil?: boolean
  /** Mode ringkas hanya menampilkan lencana dalam satu baris */
  ringkas?: boolean
  /**
   * Penangan pengiriman kustom (opsional, berguna untuk pengujian terisolasi atau integrasi khusus).
   */
  penanganKustom?: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>
}

export function StatusAntrean({
  className = '',
  selaluTampil = true,
  ringkas = false,
  penanganKustom,
}: StatusAntreanProps): ReactElement | null {
  const {
    apakahDaring,
    jumlahMenunggu,
    jumlahTertunda,
    jumlahGagal,
    jumlahTerkirim,
    daftarAntrean,
    sedangSinkronisasi,
    pesanStatus,
    sinkronkanAntrean,
    cobaLagiItem,
    cobaLagiSemuaGagal,
    hapusAntrean,
    bersihkanSukses,
  } = useAntrean()

  const [bukaRincian, setBukaRincian] = useState<boolean>(false)
  const [idAkanDihapus, setIdAkanDihapus] = useState<string | null>(null)
  const [pesanAksi, setPesanAksi] = useState<string | null>(null)

  // Jika tidak selalu tampil, sembunyikan saat daring dan semua beres
  if (!selaluTampil && apakahDaring && jumlahMenunggu === 0 && !sedangSinkronisasi) {
    return null
  }

  const tanganiSinkron = async () => {
    await sinkronkanAntrean(penanganKustom)
  }

  const tanganiCobaLagiSemua = async () => {
    setPesanAksi('Mempersiapkan pengiriman ulang semua item gagal...')
    const total = await cobaLagiSemuaGagal(penanganKustom)
    setPesanAksi(`Mengirim ulang ${total} item ke peladen...`)
    setTimeout(() => setPesanAksi(null), 3000)
  }

  const tanganiCobaLagiItem = async (id: string) => {
    setPesanAksi('Mencoba kirim ulang item terpilih...')
    await cobaLagiItem(id, penanganKustom)
    setPesanAksi('Proses kirim ulang telah dikirimkan ke peladen.')
    setTimeout(() => setPesanAksi(null), 3000)
  }

  const tanganiHapus = async (id: string) => {
    await hapusAntrean(id)
    setIdAkanDihapus(null)
    setPesanAksi('Item berhasil dihapus dari antrean lokal.')
    setTimeout(() => setPesanAksi(null), 3000)
  }

  const tanganiBersihkanSukses = async () => {
    const total = await bersihkanSukses()
    setPesanAksi(`${total} riwayat antrean terkirim berhasil dibersihkan.`)
    setTimeout(() => setPesanAksi(null), 3000)
  }

  // Nada visual untuk bilah utama
  let nadaStatus: NadaLencana = 'success'
  if (!apakahDaring) {
    nadaStatus = 'warn'
  } else if (jumlahGagal > 0) {
    nadaStatus = 'danger'
  } else if (jumlahTertunda > 0) {
    nadaStatus = 'accent'
  }

  if (ringkas) {
    return (
      <div
        role="status"
        aria-live="polite"
        data-testid="indikator-antrean-ringkas"
        className={`status-antrean-ringkas ${className}`}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 'var(--s-1)',
          cursor: 'pointer',
        }}
        onClick={() => setBukaRincian(true)}
      >
        <Lencana nada={nadaStatus}>
          {!apakahDaring ? '📡 Luring' : sedangSinkronisasi ? '🔄 Mengirim' : '🟢 Daring'}
          {' · '}
          <span data-testid="ringkasan-hitung-ringkas">
            ✓{jumlahTerkirim} ⏳{jumlahTertunda} ❌{jumlahGagal}
          </span>
        </Lencana>
      </div>
    )
  }

  return (
    <>
      <aside
        role="status"
        aria-live="polite"
        data-testid="bilah-status-antrean"
        className={`bilah-status-antrean ${className}`}
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 'var(--s-2)',
          padding: 'var(--s-2) var(--s-3)',
          borderRadius: 'var(--radius)',
          border: '1px solid var(--border)',
          backgroundColor: 'var(--bg-kartu)',
          color: 'var(--text)',
        }}
      >
        {/* Sisi Kiri: Status Koneksi & Pesan Manusia */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)', flexWrap: 'wrap' }}>
          <span style={{ fontSize: '1.25rem' }} aria-hidden="true">
            {!apakahDaring ? '📡' : jumlahGagal > 0 ? '⚠️' : sedangSinkronisasi ? '🔄' : '🟢'}
          </span>
          <div>
            <div
              style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}
            >
              <span>
                {!apakahDaring
                  ? 'Mode Luring (Offline)'
                  : sedangSinkronisasi
                    ? 'Sinkronisasi Berjalan'
                    : 'Terhubung ke Peladen'}
              </span>
              <Lencana nada={nadaStatus}>
                {!apakahDaring ? 'Luring' : sedangSinkronisasi ? 'Sinkronisasi' : 'Daring'}
              </Lencana>
            </div>
            <div style={{ fontSize: '0.875rem', opacity: 0.9 }} data-testid="pesan-status-antrean">
              {pesanStatus}
            </div>
          </div>
        </div>

        {/* Sisi Tengah: Tiga Indikator Hitungan (Terkirim, Tertunda, Gagal) Sesuai DoD */}
        <div
          data-testid="indikator-tiga-status"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 'var(--s-1)',
            flexWrap: 'wrap',
          }}
        >
          <span data-testid="indikator-terkirim">
            <Lencana nada="success">
              ✓ Terkirim: <strong>{jumlahTerkirim}</strong>
            </Lencana>
          </span>
          <span data-testid="indikator-tertunda">
            <Lencana nada={jumlahTertunda > 0 ? 'warn' : 'netral'}>
              ⏳ Tertunda: <strong>{jumlahTertunda}</strong>
            </Lencana>
          </span>
          <span data-testid="indikator-gagal">
            <Lencana nada={jumlahGagal > 0 ? 'danger' : 'netral'}>
              ❌ Gagal: <strong>{jumlahGagal}</strong>
            </Lencana>
          </span>
        </div>

        {/* Sisi Kanan: Tombol Aksi Cepat */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
          {jumlahGagal > 0 && (
            <Tombol
              jenis="button"
              ragam="bahaya"
              onClick={() => void tanganiCobaLagiSemua()}
              nonaktif={sedangSinkronisasi}
              data-testid="btn-coba-lagi-semua-gagal"
            >
              {sedangSinkronisasi ? 'Memproses...' : `Coba Lagi Gagal (${jumlahGagal})`}
            </Tombol>
          )}

          {apakahDaring && jumlahTertunda > 0 && jumlahGagal === 0 && (
            <Tombol
              jenis="button"
              ragam="kecil"
              onClick={() => void tanganiSinkron()}
              nonaktif={sedangSinkronisasi}
              data-testid="btn-kirim-antrean-sekarang"
            >
              {sedangSinkronisasi ? 'Mengirim...' : 'Kirim Sekarang'}
            </Tombol>
          )}

          <Tombol
            jenis="button"
            ragam="polos"
            onClick={() => setBukaRincian(true)}
            data-testid="btn-buka-rincian-antrean"
          >
            Rincian Antrean
          </Tombol>
        </div>
      </aside>

      {/* Modal Dialog Rincian Antrean (Lapis) */}
      <Lapis
        buka={bukaRincian}
        judul="Rincian Status Antrean & Pengiriman"
        onTutup={() => {
          setBukaRincian(false)
          setIdAkanDihapus(null)
          setPesanAksi(null)
        }}
        kaki={
          <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
            <div>
              {jumlahTerkirim > 0 && (
                <Tombol
                  ragam="polos"
                  onClick={() => void tanganiBersihkanSukses()}
                  data-testid="btn-bersihkan-sukses"
                >
                  Bersihkan Riwayat Terkirim ({jumlahTerkirim})
                </Tombol>
              )}
            </div>
            <Tombol
              ragam="utama"
              onClick={() => {
                setBukaRincian(false)
                setIdAkanDihapus(null)
              }}
              data-testid="btn-tutup-rincian"
            >
              Tutup
            </Tombol>
          </div>
        }
      >
        <div data-testid="wadah-dialog-antrean">
          {/* Petunjuk Kejujuran Status Peladen (DoD T10-03) */}
          <div
            className="kotak-peringatan"
            style={{ marginBottom: 'var(--s-3)', fontSize: '0.875rem' }}
          >
            <div>
              <strong>Ketahanan Jaringan & Kunci Idempoten:</strong>
              <div>
                Status terkirim diverifikasi langsung dari respons peladen, bukan tebakan sepihak
                perangkat. Pesanan yang dicoba kirim berulang aman dari pesanan ganda berkat kunci
                idempoten menyeluruh (ART-8).
              </div>
            </div>
          </div>

          {pesanAksi && (
            <div
              className="kotak-peringatan"
              data-testid="pesan-aksi-antrean"
              style={{ marginBottom: 'var(--s-3)' }}
            >
              {pesanAksi}
            </div>
          )}

          {/* Tombol Aksi Massal di Dalam Dialog */}
          <div
            style={{
              display: 'flex',
              gap: 'var(--s-2)',
              marginBottom: 'var(--s-3)',
              flexWrap: 'wrap',
            }}
          >
            {jumlahGagal > 0 && (
              <Tombol
                ragam="bahaya"
                onClick={() => void tanganiCobaLagiSemua()}
                nonaktif={sedangSinkronisasi}
                data-testid="btn-dialog-coba-lagi-semua"
              >
                Coba Kirim Ulang Semua Gagal ({jumlahGagal})
              </Tombol>
            )}

            {apakahDaring && jumlahTertunda > 0 && (
              <Tombol
                ragam="biasa"
                onClick={() => void tanganiSinkron()}
                nonaktif={sedangSinkronisasi}
                data-testid="btn-dialog-kirim-semua"
              >
                Kirim Semua Tertunda ({jumlahTertunda})
              </Tombol>
            )}
          </div>

          {/* Daftar Item Antrean */}
          {daftarAntrean.length === 0 ? (
            <p className="teks-bantu" data-testid="antrean-kosong">
              Tidak ada antrean pesanan tersimpan di perangkat ini. Semua transaksi telah selesai
              diproses.
            </p>
          ) : (
            <div
              data-testid="daftar-item-antrean"
              style={{ display: 'flex', flexDirection: 'column', gap: 'var(--s-3)' }}
            >
              {daftarAntrean.map((item: ItemAntrean) => {
                const apakahGagal = item.status === 'gagal'
                const apakahSukses = item.status === 'sukses'
                const apakahSedangHapus = idAkanDihapus === item.id

                return (
                  <div
                    key={item.id}
                    data-testid={`item-antrean-${item.id}`}
                    style={{
                      border: '1px solid var(--border)',
                      borderRadius: 'var(--radius)',
                      padding: 'var(--s-3)',
                      backgroundColor: apakahGagal
                        ? 'var(--danger-soft, var(--bg-kartu))'
                        : 'var(--bg-kartu)',
                    }}
                  >
                    {/* Baris Atas Item: Jenis Aksi & Status */}
                    <div
                      style={{
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        marginBottom: 'var(--s-2)',
                        flexWrap: 'wrap',
                        gap: 'var(--s-2)',
                      }}
                    >
                      <div>
                        <strong>{uraikanJenisAksi(item)}</strong>
                        <div style={{ fontSize: '0.75rem', opacity: 0.7 }}>
                          ID: {item.id} · Dibuat:{' '}
                          {new Date(item.dibuatPada).toLocaleTimeString('id-ID')}
                        </div>
                      </div>

                      <div>
                        {apakahSukses && <Lencana nada="success">✓ Terkonfirmasi Peladen</Lencana>}
                        {item.status === 'menunggu' && (
                          <Lencana nada="warn">⏳ Menunggu Pengiriman</Lencana>
                        )}
                        {item.status === 'mengirim' && (
                          <Lencana nada="accent">🔄 Sedang Mengirim...</Lencana>
                        )}
                        {apakahGagal && <Lencana nada="danger">❌ Gagal Terkirim</Lencana>}
                      </div>
                    </div>

                    {/* Ringkasan Muatan */}
                    <div style={{ fontSize: '0.875rem', marginBottom: 'var(--s-2)' }}>
                      <div>{uraikanMuatanRingkas(item)}</div>
                      <div style={{ fontSize: '0.75rem', opacity: 0.8, marginTop: 'var(--s-1)' }}>
                        Percobaan kirim: <strong>{item.percobaan}x</strong>
                        {item.terakhirDicoba && (
                          <span>
                            {' '}
                            · Terakhir dicoba:{' '}
                            {new Date(item.terakhirDicoba).toLocaleTimeString('id-ID')}
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Pesan Galat Jujur dari Peladen / Jaringan (DoD: Tidak ada gagal diam-diam) */}
                    {apakahGagal && (
                      <div
                        className="kotak-galat"
                        data-testid={`galat-item-${item.id}`}
                        style={{
                          margin: 'var(--s-2) 0',
                          padding: 'var(--s-2)',
                          fontSize: '0.875rem',
                        }}
                      >
                        <div>
                          <div style={{ fontWeight: 600 }}>
                            ⚠️ Laporan Galat dari Peladen/Jaringan:
                          </div>
                          <div
                            data-testid={`teks-galat-${item.id}`}
                            style={{ wordBreak: 'break-word', marginTop: 'var(--s-1)' }}
                          >
                            {item.pesanGalat || 'Koneksi terputus saat menghubungi peladen.'}
                          </div>
                          <div
                            style={{
                              fontSize: '0.75rem',
                              opacity: 0.9,
                              marginTop: 'var(--s-1)',
                            }}
                          >
                            Kasir dapat menekan tombol &quot;Coba Lagi&quot; untuk mengirim ulang
                            secara manual. Pesanan dijamin tidak akan terduplikasi.
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Bagian Konfirmasi Hapus atau Tombol Aksi */}
                    {apakahSedangHapus ? (
                      <div
                        style={{
                          marginTop: 'var(--s-2)',
                          padding: 'var(--s-2)',
                          border: '1px solid var(--border)',
                          borderRadius: 'var(--radius)',
                          backgroundColor: 'var(--bg)',
                        }}
                        data-testid={`konfirmasi-hapus-${item.id}`}
                      >
                        <p style={{ fontSize: '0.875rem', margin: '0 0 var(--s-2) 0' }}>
                          Apakah Anda yakin ingin membatalkan/menghapus pesanan ini dari antrean?
                          Pesanan yang dihapus tidak akan dikirimkan ke peladen.
                        </p>
                        <div style={{ display: 'flex', gap: 'var(--s-2)' }}>
                          <Tombol
                            ragam="bahaya"
                            jenis="button"
                            onClick={() => void tanganiHapus(item.id)}
                            data-testid={`btn-konfirmasi-hapus-ya-${item.id}`}
                          >
                            Ya, Hapus
                          </Tombol>
                          <Tombol
                            ragam="polos"
                            jenis="button"
                            onClick={() => setIdAkanDihapus(null)}
                            data-testid={`btn-konfirmasi-hapus-batal-${item.id}`}
                          >
                            Batal
                          </Tombol>
                        </div>
                      </div>
                    ) : (
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'flex-end',
                          gap: 'var(--s-2)',
                          marginTop: 'var(--s-2)',
                        }}
                      >
                        {!apakahSukses && (
                          <Tombol
                            ragam="kecil"
                            onClick={() => void tanganiCobaLagiItem(item.id)}
                            nonaktif={sedangSinkronisasi}
                            data-testid={`btn-coba-lagi-${item.id}`}
                          >
                            Coba Lagi
                          </Tombol>
                        )}
                        <Tombol
                          ragam="polos"
                          onClick={() => setIdAkanDihapus(item.id)}
                          data-testid={`btn-hapus-${item.id}`}
                        >
                          Hapus
                        </Tombol>
                      </div>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </Lapis>
    </>
  )
}

/**
 * Membantu membuat teks judul aksi yang ramah manusia bagi kasir.
 */
function uraikanJenisAksi(item: ItemAntrean): string {
  if (item.jenis === 'simpan_pesanan') {
    const pesanan =
      item.muatan.pesanan && typeof item.muatan.pesanan === 'object'
        ? (item.muatan.pesanan as Record<string, unknown>)
        : null
    const meja = pesanan?.meja_id || item.muatan.meja_id
    if (meja) return `Pesanan Baru (Meja ${String(meja)})`
    return 'Pesanan Baru (Bawa Pulang / Luar Meja)'
  }
  if (item.jenis === 'bayar_pesanan') return 'Pembayaran Transaksi'
  if (item.jenis === 'pakai_voucher') return 'Pemakaian Voucher'
  if (item.jenis === 'buka_shift') return 'Buka Shift Kasir'
  if (item.jenis === 'tutup_shift') return 'Tutup Shift Kasir'
  if (item.jenis === 'set_stok' || item.jenis === 'opname_stok') return 'Penyesuaian Stok Barang'
  return `Aksi Sistem: ${item.jenis}`
}

/**
 * Merangkum ringkasan muatan data transaksi secara singkat.
 */
function uraikanMuatanRingkas(item: ItemAntrean): string {
  try {
    if (item.jenis === 'simpan_pesanan') {
      const pesanan =
        item.muatan.pesanan && typeof item.muatan.pesanan === 'object'
          ? (item.muatan.pesanan as Record<string, unknown>)
          : null
      const total = typeof item.muatan.total === 'number' ? item.muatan.total : pesanan?.total
      const itemDaftar = Array.isArray(item.muatan.items) ? item.muatan.items : []
      const teksItem =
        itemDaftar.length > 0 ? `${itemDaftar.length} item hidangan` : 'Item hidangan'
      if (typeof total === 'number') {
        return `${teksItem} · Total: Rp ${total.toLocaleString('id-ID')}`
      }
      return teksItem
    }
    if (item.jenis === 'bayar_pesanan') {
      const bayar =
        typeof item.muatan.nominal_bayar === 'number'
          ? item.muatan.nominal_bayar
          : item.muatan.bayar
      if (typeof bayar === 'number') {
        return `Nominal pembayaran: Rp ${bayar.toLocaleString('id-ID')}`
      }
    }
    if (item.jenis === 'pakai_voucher') {
      const kode = item.muatan.kodeVoucher || item.muatan.kode
      if (typeof kode === 'string') {
        return `Kode voucher: ${kode}`
      }
    }
  } catch {
    // Abaikan jika muatan khusus
  }
  return `Kunci Idempoten: ${item.kunciIdempoten.slice(0, 18)}...`
}
