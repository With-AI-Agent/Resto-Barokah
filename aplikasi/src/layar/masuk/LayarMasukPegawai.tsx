import React, { useState, useEffect } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { LembarBantuan } from '../../komponen/LembarBantuan'
import { Tombol } from '../../komponen/Tombol'
import { ambilPerangkatLokal, type PenggunaSesi } from '../../lib/auth'
import { formatPesanError } from '../../lib/pesan'
import type { PesanRamah } from '../../lib/pesan'

export interface LayarMasukPegawaiProps {
  onMasukSukses?: (sesi?: PenggunaSesi | null) => void
  onMasuk: (
    email: string,
    pin: string,
  ) => Promise<{ berhasil: boolean; kode?: string; pesan: string; sesi?: PenggunaSesi | null }>
}

export const LayarMasukPegawai: React.FC<LayarMasukPegawaiProps> = ({ onMasukSukses, onMasuk }) => {
  const [email, setEmail] = useState('')
  const [pin, setPin] = useState('')
  const [memuat, setMemuat] = useState(false)
  const [errorRamah, setErrorRamah] = useState<PesanRamah | null>(null)

  const perangkat = ambilPerangkatLokal()

  const handleTekanAngka = (angka: string) => {
    if (pin.length < 6) {
      setPin((prev) => prev + angka)
      setErrorRamah(null)
    }
  }

  const handleHapusAngka = () => {
    setPin((prev) => prev.slice(0, -1))
    setErrorRamah(null)
  }

  const handleResetPin = () => {
    setPin('')
    setErrorRamah(null)
  }

  // Dukungan input keyboard fisik untuk ergonomi & keamanan (0-9, Backspace, Esc, Enter, Spasi)
  useEffect(() => {
    const tanganiKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null
      if (
        target &&
        (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)
      ) {
        // Jika sedang fokus di input email dan menekan Enter, coba submit jika PIN sudah 6 digit
        if (e.key === 'Enter' && pin.length === 6 && !memuat) {
          e.preventDefault()
          handleSubmit()
        }
        return
      }

      if (e.key >= '0' && e.key <= '9') {
        e.preventDefault()
        handleTekanAngka(e.key)
      } else if (e.key === 'Backspace') {
        e.preventDefault()
        handleHapusAngka()
      } else if (e.key === 'Escape') {
        e.preventDefault()
        handleResetPin()
      } else if (e.key === 'Enter' || e.key === ' ' || e.code === 'Space') {
        e.preventDefault()
        if (pin.length === 6 && !memuat) {
          handleSubmit()
        }
      }
    }

    window.addEventListener('keydown', tanganiKeyDown)
    return () => window.removeEventListener('keydown', tanganiKeyDown)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [email, pin, memuat])

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault()
    if (!email.trim()) {
      setErrorRamah({
        kode: 'EMAIL-400',
        judul: 'Email Belum Diisi',
        pesan: 'Mohon masukkan alamat email pegawai yang terdaftar.',
        tindakan: 'Ketik alamat email Anda pada kolom yang disediakan.',
      })
      return
    }

    if (pin.length !== 6) {
      setErrorRamah({
        kode: 'PIN-400',
        judul: 'PIN Belum Lengkap',
        pesan: 'PIN harus terdiri dari 6 angka.',
        tindakan: 'Lengkapi 6 angka PIN Anda menggunakan keypad di bawah.',
      })
      return
    }

    setMemuat(true)
    setErrorRamah(null)
    try {
      const res = await onMasuk(email, pin)
      if (res.berhasil) {
        if (onMasukSukses) onMasukSukses(res.sesi)
      } else {
        setErrorRamah(formatPesanError(res))
        setPin('')
      }
    } catch (err) {
      setErrorRamah(formatPesanError(err))
      setPin('')
    } finally {
      setMemuat(false)
    }
  }

  return (
    <div
      className="isi-tengah"
      style={{
        width: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '0 var(--s-3)',
      }}
    >
      <div style={{ maxWidth: '440px', width: '100%' }}>
        <Kartu judul="Masuk Pegawai">
          <p
            className="small muted"
            style={{
              marginTop: 0,
              marginBottom: 'var(--s-4)',
              color: 'var(--text-muted)',
              fontSize: 'var(--t-3)',
            }}
          >
            Gunakan email & PIN 6 angka untuk mulai bertugas
          </p>
          <form onSubmit={handleSubmit}>
            <KolomIsian
              label="Email Pegawai"
              jenis="email"
              contoh="nama@resto.test"
              nilai={email}
              onUbah={(val) => {
                setEmail(val)
                setErrorRamah(null)
              }}
              wajib
            />

            <div style={{ marginTop: 'var(--s-4)' }}>
              <label
                style={{
                  display: 'block',
                  fontSize: 'var(--t-3)',
                  fontWeight: 600,
                  marginBottom: 'var(--s-2)',
                  color: 'var(--text)',
                }}
              >
                PIN Keamanan (6 Digit)
              </label>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'center',
                  gap: 'var(--s-2)',
                  marginBottom: 'var(--s-3)',
                }}
              >
                {[0, 1, 2, 3, 4, 5].map((idx) => {
                  const terisi = Boolean(pin[idx])
                  const adalahPosisiSekarang = pin.length === idx
                  return (
                    <div
                      key={idx}
                      style={{
                        width: '46px',
                        height: '52px',
                        borderRadius: 'var(--radius)',
                        border: adalahPosisiSekarang
                          ? '2px solid var(--primary)'
                          : terisi
                            ? '2px solid var(--border-kuat, var(--border))'
                            : '2px solid var(--border)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: 'var(--t-7)',
                        fontWeight: 'bold',
                        color: 'var(--primary)',
                        background: terisi ? 'var(--surface-2)' : 'transparent',
                        transition: 'all 0.15s ease',
                        boxShadow: adalahPosisiSekarang ? '0 0 0 3px var(--accent-soft)' : 'none',
                      }}
                    >
                      {terisi ? '●' : ''}
                    </div>
                  )
                })}
              </div>

              {/* Keypad Angka Responsif */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(3, 1fr)',
                  gap: 'var(--s-2)',
                  marginBottom: 'var(--s-3)',
                }}
              >
                {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
                  <Tombol key={num} ragam="biasa" onClick={() => handleTekanAngka(num)}>
                    <span style={{ fontSize: 'var(--t-5)', fontWeight: 600 }}>{num}</span>
                  </Tombol>
                ))}
                <Tombol ragam="biasa" onClick={handleResetPin} nama="Hapus semua angka PIN">
                  <span style={{ fontSize: 'var(--t-4)', fontWeight: 600 }}>C</span>
                </Tombol>
                <Tombol ragam="biasa" onClick={() => handleTekanAngka('0')}>
                  <span style={{ fontSize: 'var(--t-5)', fontWeight: 600 }}>0</span>
                </Tombol>
                <Tombol ragam="biasa" onClick={handleHapusAngka} nama="Hapus satu angka PIN">
                  <span style={{ fontSize: 'var(--t-4)', fontWeight: 600 }}>⌫</span>
                </Tombol>
              </div>
              <div
                style={{
                  fontSize: 'var(--t-2)',
                  color: 'var(--text-muted)',
                  textAlign: 'center',
                  marginBottom: 'var(--s-3)',
                  padding: 'var(--s-1) var(--s-2)',
                  background: 'var(--surface-2)',
                  borderRadius: 'var(--radius-pil)',
                  border: '1px solid var(--border)',
                  display: 'inline-flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 'var(--s-1)',
                  width: '100%',
                }}
              >
                <span>⌨️</span>
                <span>Bisa diketik langsung via keyboard (0–9, Backspace, Esc, Enter / Spasi)</span>
              </div>
            </div>

            {errorRamah && (
              <div
                role="alert"
                style={{
                  padding: 'var(--s-3)',
                  borderRadius: 'var(--radius)',
                  background: 'var(--surface-2)',
                  border: '1px solid var(--danger)',
                  borderLeft: '5px solid var(--danger)',
                  marginBottom: 'var(--s-4)',
                }}
              >
                <div
                  style={{
                    fontWeight: 700,
                    color: 'var(--danger)',
                    fontSize: 'var(--t-4)',
                  }}
                >
                  [{errorRamah.kode}] {errorRamah.judul}
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-3)',
                    marginTop: 'var(--s-1)',
                    color: 'var(--text)',
                    lineHeight: 1.4,
                  }}
                >
                  {errorRamah.pesan}
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-2)',
                    marginTop: 'var(--s-2)',
                    color: 'var(--text-muted)',
                    fontWeight: 500,
                  }}
                >
                  👉 {errorRamah.tindakan}
                </div>
              </div>
            )}

            <Tombol
              ragam="utama"
              lebar
              jenis="submit"
              nonaktif={!email || pin.length !== 6 || memuat}
            >
              {memuat ? 'Memproses...' : 'Masuk Sekarang'}
            </Tombol>
          </form>

          {/* Pilihan Cepat Akun Demo / Uji Coba — PMB1-F-127 (K-1): HANYA saat pengembangan.
              Build produksi tidak boleh memuat akun demo + PIN; keputusan Lee 2026-09-29 (klaster cara masuk = B):
              perbaikan disiapkan di balik saklar yang MATI secara bawaan (import.meta.env.DEV = false pada build produksi). */}
          {import.meta.env.DEV && (
          <div
            style={{
              marginTop: 'var(--s-4)',
              padding: 'var(--s-3)',
              borderRadius: 'var(--radius)',
              background: 'var(--surface-2)',
              border: '1px solid var(--border)',
              textAlign: 'center',
            }}
          >
            <div
              style={{
                fontSize: 'var(--t-2)',
                fontWeight: 600,
                color: 'var(--text-muted)',
                marginBottom: 'var(--s-2)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 'var(--s-1)',
              }}
            >
              <span>⚡</span>
              <span>Pilihan Cepat Masuk Akun Demo (PIN: 123456):</span>
            </div>
            <div
              style={{
                display: 'flex',
                gap: 'var(--s-2)',
                justifyContent: 'center',
                flexWrap: 'wrap',
              }}
            >
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setEmail('owner@resto.test')
                  setPin('123456')
                  setErrorRamah(null)
                }}
                nama="Isi otomatis akun Owner"
              >
                👑 Owner (Lee)
              </Tombol>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setEmail('kasir@resto.test')
                  setPin('123456')
                  setErrorRamah(null)
                }}
                nama="Isi otomatis akun Kasir"
              >
                💳 Kasir
              </Tombol>
              <Tombol
                ragam="biasa"
                onClick={() => {
                  setEmail('dapur@resto.test')
                  setPin('123456')
                  setErrorRamah(null)
                }}
                nama="Isi otomatis akun Dapur"
              >
                🍳 Dapur
              </Tombol>
            </div>
          </div>
          )}

          <div
            style={{
              marginTop: 'var(--s-4)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              fontSize: 'var(--t-2)',
              color: 'var(--text-muted)',
            }}
          >
            <span>Perangkat: {perangkat.nama}</span>
            <LembarBantuan idLayar="masuk" />
          </div>
        </Kartu>
      </div>
    </div>
  )
}
