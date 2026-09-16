import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lapis } from '../../komponen/Lapis'
import { Lencana } from '../../komponen/Lencana'
import { Tabel, type KolomTabel } from '../../komponen/Tabel'
import { Toast } from '../../komponen/Toast'
import { Tombol } from '../../komponen/Tombol'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { rupiah, jamLokal, tanggalLokal } from '../../lib/format'
import { KERAPATAN, TEMA, type KodeTema, type Kerapatan } from '../../lib/tema'
import { statusEnv } from '../../lib/env'
import { useJam } from '../../hook/useJam'
import { useTema } from '../../hook/useTema'

/**
 * Layar bukti Fase 0 (bukan layar produksi).
 * Membuktikan: 10 tema + 2 kerapatan bisa diganti tanpa memuat ulang halaman,
 * seluruh komponen dasar (termasuk keadaan kosong/memuat/gagal) hidup di
 * aplikasi, dan pengaturan rahasia terbaca dari berkas `.env`.
 * Halaman ini diganti layar sungguhan mulai Fase 2.
 */

type BarisPesanan = {
  meja: string
  menu: string
  total: number
  status: string
}

const CONTOH_PESANAN: BarisPesanan[] = [
  { meja: 'Meja 3', menu: 'Nasi Goreng Kampung', total: 27500, status: 'Baru' },
  { meja: 'Meja 5', menu: 'Ayam Geprek + Es Teh', total: 36000, status: 'Dimasak' },
  { meja: 'Bungkus', menu: 'Mie Ayam', total: 18000, status: 'Siap' },
]

const KOLOM_PESANAN: readonly KolomTabel<BarisPesanan>[] = [
  { kunci: 'meja', judul: 'Meja' },
  { kunci: 'menu', judul: 'Menu' },
  { kunci: 'total', judul: 'Total', rata: 'kanan', nilai: (b) => rupiah(b.total) },
  { kunci: 'status', judul: 'Status', nilai: (b) => <Lencana nada="info">{b.status}</Lencana> },
]

export default function LayarContoh() {
  const sekarang = useJam()
  const { tema, kerapatan, gantiTema, gantiKerapatan } = useTema()
  const temaAktif = TEMA.find((butir) => butir.kode === tema) ?? TEMA[0]

  const [lapisBuka, setLapisBuka] = useState(false)
  const [toastTampil, setToastTampil] = useState(true)
  const [catatan, setCatatan] = useState('')
  const env = statusEnv()

  return (
    <div className="halaman">
      <header className="kepala-halaman">
        <p className="label">Contoh tampilan · Fase 0</p>
        <h1>Sajian</h1>
        <p className="aksen">Kasir, dapur, laporan, dan pelanggan dalam satu tempat.</p>
        <p className="small muted">
          Sekarang {jamLokal(sekarang)} · {tanggalLokal(sekarang)} · tema aktif{' '}
          <strong>{temaAktif.nama}</strong>
        </p>
      </header>

      {toastTampil ? (
        <Toast
          pesan="Contoh pemberitahuan: pesanan meja 3 sudah tersimpan."
          nada="sukses"
          aksi={
            <Tombol ragam="polos" onClick={() => setToastTampil(false)} nama="Tutup pemberitahuan">
              Tutup
            </Tombol>
          }
        />
      ) : (
        <div className="baris-tombol">
          <Tombol ragam="kecil" onClick={() => setToastTampil(true)}>
            Tampilkan pemberitahuan lagi
          </Tombol>
        </div>
      )}

      <div className="row wrap-row">
        <details className="picker">
          <summary className="btn btn-sm">Ganti tema ({TEMA.length})</summary>
          <div className="picker-panel">
            {TEMA.map((butir) => (
              <button
                key={butir.kode}
                type="button"
                aria-pressed={butir.kode === tema}
                onClick={() => gantiTema(butir.kode as KodeTema)}
                className="tombol-tema"
              >
                <span className="tanda" aria-hidden="true" />
                <span>
                  <strong>{butir.nama}</strong>
                  <small>{butir.keterangan}</small>
                </span>
              </button>
            ))}
          </div>
        </details>

        <div className="segmen" role="group" aria-label="Kerapatan tampilan">
          {KERAPATAN.map((butir) => (
            <button
              key={butir.kode}
              type="button"
              aria-pressed={butir.kode === kerapatan}
              onClick={() => gantiKerapatan(butir.kode as Kerapatan)}
            >
              {butir.nama}
            </button>
          ))}
        </div>
      </div>

      <div className="kisi-2">
        <Kartu judul="Tombol" aksi={<Lencana nada="netral">5 ragam</Lencana>}>
          <div className="baris-tombol">
            <Tombol>Simpan pesanan</Tombol>
            <Tombol ragam="biasa">Tahan</Tombol>
            <Tombol ragam="kecil">Kecil</Tombol>
            <Tombol ragam="polos">Polos</Tombol>
            <Tombol ragam="bahaya">Batalkan</Tombol>
          </div>
          <div className="baris-tombol mt-16">
            <Tombol nonaktif>Sedang nonaktif</Tombol>
            <Tombol ragam="biasa" lebar>
              Lebar penuh
            </Tombol>
          </div>
        </Kartu>

        <Kartu judul="Lencana">
          <div className="row wrap-row">
            <Lencana nada="accent">Aksen</Lencana>
            <Lencana nada="success">Lunas</Lencana>
            <Lencana nada="warn">Belum dibayar</Lencana>
            <Lencana nada="danger">Dibatalkan</Lencana>
            <Lencana nada="info">Dibungkus</Lencana>
            <Lencana>Netral</Lencana>
          </div>
          <hr className="pemisah" />
          <div className="between">
            <div>
              <p className="label">Total belanja</p>
              <p className="angka-besar">{rupiah(27500)}</p>
            </div>
            <Lencana nada="warn">Meja 3</Lencana>
          </div>
        </Kartu>
      </div>

      <Kartu judul="Kolom isian" aksi={<Lencana nada="info">44 px</Lencana>}>
        <div className="kisi-2">
          <KolomIsian
            label="Nama pelanggan"
            nilai={catatan}
            onUbah={setCatatan}
            keterangan="Boleh dikosongkan."
            contoh="contoh: Budi"
          />
          <KolomIsian
            label="Nomor meja"
            nilai=""
            onUbah={() => undefined}
            jenis="number"
            wajib
            galat="Nomor meja wajib diisi."
          />
        </div>
      </Kartu>

      <Kartu
        judul="Tabel pesanan"
        aksi={
          <Tombol ragam="kecil" onClick={() => setLapisBuka(true)}>
            Buka lapis
          </Tombol>
        }
      >
        <Tabel kolom={KOLOM_PESANAN} baris={CONTOH_PESANAN} />
      </Kartu>

      <div className="kisi-2">
        <Kartu judul="Keadaan kosong">
          <KeadaanKosong
            judul="Belum ada pesanan hari ini"
            keterangan="Pesanan yang masuk dari kasir akan muncul di daftar ini."
            aksi={<Tombol ragam="biasa">Buat pesanan</Tombol>}
          />
        </Kartu>

        <Kartu judul="Sedang memuat">
          <KeadaanMemuat judul="Memuat daftar pesanan…" baris={3} />
        </Kartu>

        <Kartu judul="Gagal memuat">
          <KeadaanGagal onCoba={() => setToastTampil(true)} />
        </Kartu>

        <Kartu judul="Tabel tanpa data">
          <Tabel kolom={KOLOM_PESANAN} baris={[]} judulKosong="Belum ada transaksi" />
        </Kartu>
      </div>

      <Kartu judul="Huruf tema">
        <div className="contoh-huruf">
          <div>
            <span className="nama-huruf huruf-outfit">Outfit</span>
            <span className="small muted">huruf judul, tegas dan bersih</span>
          </div>
          <div>
            <span className="nama-huruf huruf-bigshoulders">Big Shoulders</span>
            <span className="small muted">huruf judul tema Bara</span>
          </div>
          <div>
            <span className="nama-huruf huruf-youngserif">Young Serif</span>
            <span className="small muted">huruf judul tema Vintage</span>
          </div>
          <div>
            <span className="nama-huruf huruf-bricolage">Bricolage</span>
            <span className="small muted">huruf judul tema Etnik</span>
          </div>
        </div>
      </Kartu>

      <Kartu judul="Pengaturan rahasia (T0-05)">
        <p className="small muted">
          Hanya dua nilai ini yang boleh dibaca aplikasi (aman untuk publik). Kunci rahasia lain
          hanya hidup di sisi peladen.
        </p>
        <div className="row wrap-row">
          {env.map((butir) => (
            <Lencana key={butir.nama} nada={butir.terisi ? 'success' : 'warn'}>
              {butir.nama}: {butir.terisi ? 'terisi' : 'belum diisi'}
            </Lencana>
          ))}
        </div>
      </Kartu>

      <Lapis
        buka={lapisBuka}
        judul="Rincian pesanan meja 3"
        onTutup={() => setLapisBuka(false)}
        kaki={
          <>
            <Tombol ragam="biasa" onClick={() => setLapisBuka(false)}>
              Tutup
            </Tombol>
            <Tombol
              onClick={() => {
                setLapisBuka(false)
                setToastTampil(true)
              }}
            >
              Kirim ke dapur
            </Tombol>
          </>
        }
      >
        <p className="small muted">
          Contoh lapis mengambang. Tekan Esc atau klik latar untuk menutup.
        </p>
        <Tabel kolom={KOLOM_PESANAN.slice(0, 3)} baris={CONTOH_PESANAN.slice(0, 2)} />
      </Lapis>
    </div>
  )
}
