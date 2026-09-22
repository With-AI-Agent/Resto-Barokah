import { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { PemilihRingkas } from '../../komponen/PemilihRingkas'
import { KolomIsian } from '../../komponen/KolomIsian'
import { Lapis } from '../../komponen/Lapis'
import { Lencana } from '../../komponen/Lencana'
import { Tabel, type KolomTabel } from '../../komponen/Tabel'
import { Toast } from '../../komponen/Toast'
import { Tombol } from '../../komponen/Tombol'
import { KeadaanGagal } from '../../komponen/KeadaanGagal'
import { KeadaanKosong } from '../../komponen/KeadaanKosong'
import { KeadaanMemuat } from '../../komponen/KeadaanMemuat'
import { LembarBantuan } from '../../komponen/LembarBantuan'
import { rupiah, jamLokal, tanggalLokal } from '../../lib/format'
import { KERAPATAN, TEMA, type KodeTema, type Kerapatan } from '../../lib/tema'
import { statusEnv } from '../../lib/env'
import { useJam } from '../../hook/useJam'
import { useTema } from '../../hook/useTema'
import { useBahasa, DAFTAR_BAHASA, type KodeBahasa } from '../../bahasa'

/**
 * Layar bukti Fase 0, 1C, i18n & Bantuan Kontekstual.
 * Membuktikan: 10 tema + 2 kerapatan + 4 bahasa (i18n LTR/RTL) bisa diganti
 * tanpa memuat ulang halaman, seluruh komponen dasar hidup, bantuan kontekstual
 * tanda '?' berfungsi, dan pengaturan rahasia terbaca aman.
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
  const { bahasa, meta, arah, gantiBahasa, t } = useBahasa()

  const temaAktif = TEMA.find((butir) => butir.kode === tema) ?? TEMA[0]
  const kerapatanAktif = KERAPATAN.find((butir) => butir.kode === kerapatan) ?? KERAPATAN[0]

  const [lapisBuka, setLapisBuka] = useState(false)
  const [toastTampil, setToastTampil] = useState(true)
  const [catatan, setCatatan] = useState('')
  const env = statusEnv()

  return (
    <div className="halaman">
      <header className="kepala-halaman">
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: 'var(--s-2)',
          }}
        >
          <p className="label">Contoh tampilan · Fase 0 & 1C</p>
          <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--s-2)' }}>
            <LembarBantuan idLayar="contoh" />
          </div>
        </div>
        <h1>{t('umum.aplikasi')}</h1>
        <p className="aksen">
          {t('umum.selamat_datang')} — Kasir, dapur, laporan, dan pelanggan dalam satu tempat.
        </p>
        <p className="small muted">
          Sekarang {jamLokal(sekarang)} · {tanggalLokal(sekarang)} · tema aktif{' '}
          <strong>{temaAktif.nama}</strong> · kerapatan <strong>{kerapatanAktif.nama}</strong> ·
          bahasa <strong>{meta.namaLokal}</strong> ({arah.toUpperCase()})
        </p>
      </header>

      {toastTampil ? (
        <Toast
          pesan="Contoh pemberitahuan: pesanan meja 3 sudah tersimpan."
          nada="sukses"
          aksi={
            <Tombol ragam="polos" onClick={() => setToastTampil(false)} nama="Tutup pemberitahuan">
              {t('umum.tutup')}
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

      <div className="row wrap-row" style={{ gap: 'var(--s-3)' }}>
        <PemilihRingkas
          label={`Pilih tema (${TEMA.length} pilihan)`}
          anakTombol={`Ganti tema (${TEMA.length})`}
          judulPanel={
            <>
              Pilih tema — ada {TEMA.length}. Bila belum terlihat semua, geser daftar di dalam kotak
              ini.
            </>
          }
        >
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
        </PemilihRingkas>

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

        <div className="segmen" role="group" aria-label="Pilihan Bahasa">
          {DAFTAR_BAHASA.map((b) => (
            <button
              key={b.kode}
              type="button"
              aria-pressed={b.kode === bahasa}
              onClick={() => gantiBahasa(b.kode as KodeBahasa)}
            >
              {b.namaLokal}
            </button>
          ))}
        </div>
      </div>

      <div className="kisi-2">
        <Kartu judul="Tombol" aksi={<Lencana nada="netral">5 ragam</Lencana>}>
          <div className="baris-tombol">
            <Tombol>{t('umum.simpan')}</Tombol>
            <Tombol ragam="biasa">Tahan</Tombol>
            <Tombol ragam="kecil">Kecil</Tombol>
            <Tombol ragam="polos">Polos</Tombol>
            <Tombol ragam="bahaya">{t('umum.batal')}</Tombol>
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
              <p className="label">{t('kasir.total_belanja')}</p>
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

      <Kartu judul="Kerapatan tampilan" aksi={<Lencana nada="info">Nyaman vs Padat</Lencana>}>
        <p className="small muted">
          Tombol Nyaman/Padat di atas mengubah jarak dan tepi di seluruh halaman. Huruf sengaja{' '}
          <strong>tidak</strong> dikecilkan supaya tetap terbaca dan tombol tetap mudah dipijit.
          Sekarang: <strong>{kerapatanAktif.nama}</strong>.
        </p>
        <div className="mt-16">
          {CONTOH_PESANAN.map((baris) => (
            <div className="baris-rapat" key={baris.meja}>
              <span>
                <strong>{baris.menu}</strong>
                <br />
                <small className="muted">{baris.meja}</small>
              </span>
              <span className="angka-besar">{rupiah(baris.total)}</span>
            </div>
          ))}
        </div>
      </Kartu>

      <div className="kisi-2">
        <Kartu judul="Keadaan kosong">
          <KeadaanKosong
            judul={t('keadaan.kosong_judul')}
            keterangan={t('keadaan.kosong_keterangan')}
            aksi={<Tombol ragam="biasa">Buat pesanan</Tombol>}
          />
        </Kartu>

        <Kartu judul="Sedang memuat">
          <KeadaanMemuat judul={t('keadaan.memuat_judul')} baris={3} />
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
          hanya hidup di sisi peladen. Di komputer pengembang nilainya dibaca dari berkas
          aplikasi/.env yang tidak ikut Git; kalau belum ada, lencana di bawah berwarna kuning dan
          aplikasi tetap terbuka.
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
              {t('umum.tutup')}
            </Tombol>
            <Tombol
              onClick={() => {
                setLapisBuka(false)
                setToastTampil(true)
              }}
            >
              {t('kasir.kirim_dapur')}
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
