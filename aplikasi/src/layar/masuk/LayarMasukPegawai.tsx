import React, { useState } from 'react'
import { Kartu } from '../../komponen/Kartu'
import { KolomIsian } from '../../komponen/KolomIsian'
import { LembarBantuan } from '../../komponen/LembarBantuan'
import { Tombol } from '../../komponen/Tombol'
import { ambilPerangkatLokal } from '../../lib/auth'
import { formatPesanError } from '../../lib/pesan'
import type { PesanRamah } from '../../lib/pesan'

export interface LayarMasukPegawaiProps {
  onMasukSukses?: () => void
  onMasuk: (
    email: string,
    pin: string,
  ) => Promise<{ berhasil: boolean; kode?: string; pesan: string }>
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
        if (onMasukSukses) onMasukSukses()
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
        minHeight: '80vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 'var(--s-4)',
      }}
    >
      <div style={{ maxWidth: '440px', width: '100%' }}>
        <Kartu judul="Masuk Pegawai">
          <p className="small muted" style={{ marginTop: 0, marginBottom: 'var(--s-3)' }}>
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

            <div style={{ marginTop: 'var(--s-3)' }}>
              <label
                style={{
                  display: 'block',
                  fontSize: 'var(--t-4)',
                  fontWeight: 600,
                  marginBottom: 'var(--s-1)',
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
                {[0, 1, 2, 3, 4, 5].map((idx) => (
                  <div
                    key={idx}
                    style={{
                      width: '44px',
                      height: '48px',
                      borderRadius: 'var(--sudut-sedang)',
                      border: '2px solid var(--b-netral)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: 'var(--t-7)',
                      fontWeight: 'bold',
                      background: pin[idx] ? 'var(--latar-kartu-abu)' : 'transparent',
                    }}
                  >
                    {pin[idx] ? '●' : ''}
                  </div>
                ))}
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
                  <button
                    key={num}
                    type="button"
                    className="btn"
                    onClick={() => handleTekanAngka(num)}
                    style={{ fontSize: 'var(--t-6)', fontWeight: 'bold', height: '52px' }}
                  >
                    {num}
                  </button>
                ))}
                <button
                  type="button"
                  className="btn"
                  onClick={handleResetPin}
                  style={{ fontSize: 'var(--t-3)' }}
                >
                  C
                </button>
                <button
                  type="button"
                  className="btn"
                  onClick={() => handleTekanAngka('0')}
                  style={{ fontSize: 'var(--t-6)', fontWeight: 'bold', height: '52px' }}
                >
                  0
                </button>
                <button
                  type="button"
                  className="btn"
                  onClick={handleHapusAngka}
                  style={{ fontSize: 'var(--t-4)' }}
                >
                  ⌫
                </button>
              </div>
            </div>

            {errorRamah && (
              <div
                style={{
                  padding: 'var(--s-3)',
                  borderRadius: 'var(--radius)',
                  background: 'var(--surface-2)',
                  borderLeft: '4px solid var(--peringatan)',
                  marginBottom: 'var(--s-3)',
                }}
              >
                <div
                  style={{ fontWeight: 'bold', color: 'var(--teks-utama)', fontSize: 'var(--t-4)' }}
                >
                  [{errorRamah.kode}] {errorRamah.judul}
                </div>
                <div
                  style={{
                    fontSize: 'var(--t-3)',
                    marginTop: 'var(--s-1)',
                    color: 'var(--teks-redup)',
                  }}
                >
                  {errorRamah.pesan}
                </div>
                <div
                  style={{ fontSize: 'var(--t-2)', marginTop: 'var(--s-1)', fontStyle: 'italic' }}
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

          <div
            style={{
              marginTop: 'var(--s-4)',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              fontSize: 'var(--t-2)',
              color: 'var(--teks-redup)',
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
