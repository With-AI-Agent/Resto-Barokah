/**
 * KebijakanPrivasi.tsx — Halaman Kebijakan Privasi & Pelindungan Data Pelanggan (T8-15)
 *
 * Sesuai Undang-Undang No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP).
 * Memuat transparansi pengumpulan data minimal, hak akses, hak koreksi,
 * serta hak anonimisasi/penghapusan data tanpa menghapus catatan keuangan.
 */

import { Kartu } from '../../komponen/Kartu'
import { Tombol } from '../../komponen/Tombol'

export interface KebijakanPrivasiProps {
  namaResto?: string
  kontakResto?: {
    telepon?: string
    whatsapp?: string
    email?: string
  }
  onKembali?: () => void
}

export function KebijakanPrivasi({
  namaResto = 'Resto Barokah',
  kontakResto,
  onKembali,
}: KebijakanPrivasiProps) {
  return (
    <div
      className="layar-kebijakan-privasi"
      style={{
        maxWidth: '680px',
        margin: '0 auto',
        padding: 'var(--s-4)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--s-4)',
      }}
      data-testid="layar-kebijakan-privasi"
    >
      {/* Header Halaman */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 'var(--s-2)',
        }}
      >
        <div>
          <h1
            style={{
              fontSize: 'var(--t-4)',
              fontWeight: 800,
              color: 'var(--text)',
              margin: 0,
            }}
          >
            Kebijakan Privasi
          </h1>
          <p
            style={{
              fontSize: 'var(--t-1)',
              color: 'var(--text-muted)',
              margin: 'var(--s-1) 0 0 0',
            }}
          >
            Pelindungan Data Pribadi Pelanggan {namaResto} · Versi 1.0 (September 2026)
          </p>
        </div>

        {onKembali && (
          <Tombol ragam="biasa" onClick={onKembali} nama="Kembali ke halaman sebelumnya">
            ← Kembali
          </Tombol>
        )}
      </div>

      {/* Ringkasan Singkat Komitmen Kami */}
      <div
        style={{
          padding: 'var(--s-3)',
          background: 'var(--surface-2)',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border)',
          fontSize: 'var(--t-2)',
          color: 'var(--text)',
          lineHeight: 1.5,
        }}
        data-testid="ringkasan-privasi"
      >
        Kami di <strong>{namaResto}</strong> sangat menghargai privasi dan kepercayaan Anda. Sesuai
        ketentuan <strong>Undang-Undang Pelindungan Data Pribadi (UU PDP No. 27/2022)</strong>, kami
        berkomitmen untuk mengumpulkan data Anda sesedikit mungkin, menjaga keamanannya, dan tidak
        pernah menjual atau membagikannya kepada pihak mana pun.
      </div>

      {/* Bagian 1: Data yang Dikumpulkan */}
      <Kartu judul="1. Data yang Kami Kumpulkan">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0 }}>
            Saat Anda mendaftar program voucher atau promo di {namaResto}, kami hanya mencatat data
            berikut dengan persetujuan Anda:
          </p>
          <ul
            style={{
              margin: 0,
              paddingLeft: 'var(--s-4)',
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-1)',
            }}
          >
            <li>
              <strong>Nama Lengkap (Wajib):</strong> Digunakan untuk menyapa dan mencocokkan
              kepemilikan voucher.
            </li>
            <li>
              <strong>Alamat Email (Wajib untuk jalur email/Google):</strong> Digunakan untuk
              mengirimkan kode voucher dan bukti verifikasi.
            </li>
            <li>
              <strong>Nomor Telepon / WhatsApp (Opsional):</strong> Hanya jika Anda bersedia
              menerima pemberitahuan promo kedai.
            </li>
            <li>
              <strong>Alamat Domisili (Opsional):</strong> Membantu kami memahami jangkauan layanan
              kedai.
            </li>
          </ul>

          <div
            style={{
              padding: 'var(--s-2)',
              background: 'var(--surface)',
              borderLeft: '4px solid var(--accent)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--t-1)',
              color: 'var(--text-muted)',
            }}
          >
            🛡️ <strong>Prinsip Minimalisasi:</strong> Kami <em>TIDAK PERNAH</em> meminta atau
            menyimpan Nomor Induk Kependudukan (NIK), data biometrik/wajah, lokasi GPS langsung,
            maupun nomor kartu perbankan Anda.
          </div>
        </div>
      </Kartu>

      {/* Bagian 2: Tujuan & Penggunaan Data */}
      <Kartu judul="2. Tujuan Penggunaan Data">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-2)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0 }}>
            Data Anda digunakan semata-mata untuk keperluan operasional kedai:
          </p>
          <ol
            style={{
              margin: 0,
              paddingLeft: 'var(--s-4)',
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-1)',
            }}
          >
            <li>
              Menerbitkan barcode dan kode voucher resmi yang dapat Anda tukarkan saat berkunjung.
            </li>
            <li>
              Mencegah penyalahgunaan voucher agar kuota diskon terbagi adil bagi semua pelanggan.
            </li>
            <li>
              Membantu kasir memverifikasi potongan diskon pada tagihan pesanan Anda di kasir.
            </li>
          </ol>
          <p style={{ margin: 'var(--s-1) 0 0 0', fontWeight: 600, color: 'var(--sukses)' }}>
            ✓ Kami menjamin data Anda tidak akan pernah dijual, disewakan, atau dibagikan ke pihak
            ketiga pengiklan.
          </p>
        </div>
      </Kartu>

      {/* Bagian 3: Penyimpanan & Keamanan Data */}
      <Kartu judul="3. Tempat Penyimpanan & Keamanan">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-2)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0 }}>
            Data tersimpan pada infrastruktur peladen berstandar industri dengan enkripsi data dan
            kontrol akses ketat yang berlokasi di region <strong>Singapore (Asia Tenggara)</strong>.
          </p>
          <p style={{ margin: 0 }}>
            Hanya staf berwenang di kedai (kasir, admin cabang, dan pemilik resto) yang memiliki hak
            baca terbatas untuk memeriksa keabsahan voucher Anda saat transaksi.
          </p>
        </div>
      </Kartu>

      {/* Bagian 4: Hak Anda sebagai Subjek Data (UU PDP) */}
      <Kartu judul="4. Hak Anda sebagai Pemilik Data">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-3)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0 }}>
            Berdasarkan UU Pelindungan Data Pribadi, Anda memiliki hak penuh terhadap data Anda:
          </p>

          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))',
              gap: 'var(--s-2)',
            }}
          >
            <div
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}
            >
              <strong style={{ color: 'var(--accent)' }}>🔍 Hak Akses</strong>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Anda berhak meminta informasi mengenai data pribadi Anda yang tersimpan di sistem
                kami.
              </p>
            </div>

            <div
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}
            >
              <strong style={{ color: 'var(--accent)' }}>✏️ Hak Koreksi</strong>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Anda berhak memperbaiki atau memperbarui informasi kontak Anda bila ada kekeliruan
                penulisan.
              </p>
            </div>

            <div
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}
            >
              <strong style={{ color: 'var(--bahaya)' }}>🗑️ Hak Penghapusan / Anonimisasi</strong>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Anda berhak meminta data nama, email, dan telepon Anda dihapus/dianonimkan kapan pun
                Anda inginkan.
              </p>
            </div>

            <div
              style={{
                padding: 'var(--s-2)',
                background: 'var(--surface-2)',
                borderRadius: 'var(--radius-sm)',
                border: '1px solid var(--border)',
              }}
            >
              <strong style={{ color: 'var(--sukses)' }}>⏱️ Waktu Tanggap Cepat</strong>
              <p
                style={{
                  margin: 'var(--s-1) 0 0 0',
                  fontSize: 'var(--t-1)',
                  color: 'var(--text-muted)',
                }}
              >
                Kami berkomitmen memproses permintaan hak privasi Anda dalam waktu maksimal{' '}
                <strong>3 × 24 jam</strong>.
              </p>
            </div>
          </div>

          <div
            style={{
              padding: 'var(--s-2)',
              background: 'var(--surface-2)',
              borderRadius: 'var(--radius-sm)',
              fontSize: 'var(--t-1)',
              color: 'var(--text-muted)',
            }}
          >
            <em>Catatan Pembukuan Keuangan:</em> Saat kontak Anda dihapus, sistem kami menganonimkan
            data identitas Anda menjadi data anonim. Catatan nilai nominal transaksi resto tetap
            tersimpan utuh demi kepatuhan perpajakan dan pembukuan kas kedai, tanpa lagi
            mengaitkannya dengan data pribadi Anda.
          </div>
        </div>
      </Kartu>

      {/* Bagian 5: Cara Mengajukan Permintaan */}
      <Kartu judul="5. Cara Mengajukan Permintaan Hak Privasi">
        <div
          style={{
            padding: 'var(--s-3)',
            display: 'flex',
            flexDirection: 'column',
            gap: 'var(--s-2)',
            fontSize: 'var(--t-2)',
            color: 'var(--text)',
            lineHeight: 1.6,
          }}
        >
          <p style={{ margin: 0 }}>
            Untuk mengajukan permintaan peninjauan, koreksi, atau penghapusan (anonimisasi) data
            Anda, Anda dapat:
          </p>
          <ul
            style={{
              margin: 0,
              paddingLeft: 'var(--s-4)',
              display: 'flex',
              flexDirection: 'column',
              gap: 'var(--s-1)',
            }}
          >
            <li>
              <strong>Datang Langsung ke Kasir:</strong> Minta kasir di kedai {namaResto} untuk
              memproses penghapusan data kontak Anda langsung dari sistem kasir.
            </li>
            {kontakResto?.telepon && (
              <li>
                <strong>Telepon / WhatsApp:</strong> Hubungi nomor kedai di{' '}
                <strong>{kontakResto.telepon}</strong>.
              </li>
            )}
            {kontakResto?.email && (
              <li>
                <strong>Surat Elektronik:</strong> Kirimkan permohonan ke alamat email{' '}
                <strong>{kontakResto.email}</strong>.
              </li>
            )}
          </ul>
        </div>
      </Kartu>

      {/* Footer Aksi */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'center',
          padding: 'var(--s-3) 0',
        }}
      >
        {onKembali && (
          <Tombol ragam="utama" onClick={onKembali} nama="Tutup kebijakan privasi dan kembali">
            Saya Mengerti &amp; Kembali
          </Tombol>
        )}
      </div>
    </div>
  )
}
