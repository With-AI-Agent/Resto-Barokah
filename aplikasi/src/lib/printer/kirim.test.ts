/**
 * Uji T6-02 & T6-03 — jalur kirim ke printer.
 *
 * Diuji dengan printer TIRUAN (bukan perangkat nyata), karena yang bisa
 * dipastikan tanpa perangkat adalah PERILAKUNYA: apakah data dipotong dengan
 * benar, apakah printer merek asing tetap ditemukan jalurnya, dan apakah
 * kegagalan menghasilkan pesan yang bisa dimengerti kasir. Uji printer nyata
 * tetap gerbang tersendiri (T6-08).
 */
import { describe, expect, it, vi } from 'vitest'
import {
  GagalCetak,
  cariJalurUsb,
  cariKarakteristikTulis,
  cetakBluetooth,
  cetakUsb,
  kirimKeKarakteristik,
  pesanTakDidukung,
  potongData,
  type KonfigurasiUsb,
  type PerangkatUsb,
} from './kirim'
import { UUID_LAYANAN_UMUM } from './profil'

describe('potongData — printer murah hanya menerima sedikit per kiriman', () => {
  it('memotong tepat 20 byte', () => {
    const data = new Uint8Array(45).fill(1)
    const potongan = potongData(data)
    expect(potongan).toHaveLength(3)
    expect(potongan[0]).toHaveLength(20)
    expect(potongan[2]).toHaveLength(5)
  })

  it('data kosong menghasilkan nol potongan', () => {
    expect(potongData(new Uint8Array(0))).toHaveLength(0)
  })

  it('isi seluruh potongan sama persis dengan aslinya (tidak ada byte hilang)', () => {
    const asli = Uint8Array.from({ length: 50 }, (_, i) => i)
    const gabung = potongData(asli).flatMap((p) => Array.from(p))
    expect(gabung).toEqual(Array.from(asli))
  })

  it('besar potongan 0 ditolak, bukan menggantung selamanya', () => {
    expect(() => potongData(new Uint8Array(5), 0)).toThrow()
  })
})

describe('pesan saat perangkat tidak mendukung', () => {
  it('pesan Bluetooth menyebut iPhone dan menawarkan jalan keluar', () => {
    const pesan = pesanTakDidukung('bluetooth')
    expect(pesan).toContain('iPhone')
    expect(pesan.toLowerCase()).toContain('struk digital')
  })

  it('pesan USB menawarkan jalan keluar juga', () => {
    expect(pesanTakDidukung('usb').toLowerCase()).toContain('struk digital')
  })
})

// --------------------------------------------------------------- Bluetooth

/** Printer BLE tiruan. */
function buatLayanan(uuid: string, bisaTulis: boolean) {
  const tulis = vi.fn(async () => {})
  return {
    layanan: {
      uuid,
      getCharacteristics: async () => [
        bisaTulis
          ? { properties: { write: true }, writeValue: tulis }
          : { properties: { write: false } },
      ],
    },
    tulis,
  }
}

describe('Bluetooth — menemukan jalur kirim', () => {
  it('memakai alamat layanan yang dikenal bila ada', async () => {
    const { layanan, tulis } = buatLayanan(UUID_LAYANAN_UMUM[0], true)
    const peladen = {
      getPrimaryService: async (u: string) => {
        if (u === UUID_LAYANAN_UMUM[0]) return layanan
        throw new Error('tidak ada')
      },
    }
    const k = await cariKarakteristikTulis(peladen)
    await kirimKeKarakteristik(k, new Uint8Array([1, 2, 3]))
    expect(tulis).toHaveBeenCalled()
  })

  it('JAMINAN MEREK LAIN: alamat tidak dikenal pun tetap ketemu lewat penelusuran', async () => {
    const { layanan, tulis } = buatLayanan('aneh-sekali-uuid-pabrik-asing', true)
    const peladen = {
      // Semua alamat yang dikenal GAGAL — persis keadaan printer asing.
      getPrimaryService: async () => {
        throw new Error('tidak ada')
      },
      getPrimaryServices: async () => [layanan],
    }
    const k = await cariKarakteristikTulis(peladen)
    await kirimKeKarakteristik(k, new Uint8Array([1, 2, 3]))
    expect(tulis).toHaveBeenCalled()
  })

  it('melewati layanan yang karakteristiknya tidak bisa ditulisi', async () => {
    const buruk = buatLayanan('uuid-buruk', false)
    const baik = buatLayanan('uuid-baik', true)
    const peladen = {
      getPrimaryService: async () => {
        throw new Error('tidak ada')
      },
      getPrimaryServices: async () => [buruk.layanan, baik.layanan],
    }
    const k = await cariKarakteristikTulis(peladen)
    await kirimKeKarakteristik(k, new Uint8Array([9]))
    expect(baik.tulis).toHaveBeenCalled()
  })

  it('kalau benar-benar tidak ada jalur, pesannya bisa dimengerti kasir', async () => {
    const peladen = {
      getPrimaryService: async () => {
        throw new Error('tidak ada')
      },
      getPrimaryServices: async () => [],
    }
    await expect(cariKarakteristikTulis(peladen)).rejects.toThrow(GagalCetak)
    await expect(cariKarakteristikTulis(peladen)).rejects.toThrow(/printer/i)
  })

  it('data dikirim potong demi potong, bukan sekaligus', async () => {
    const tulis = vi.fn(async () => {})
    const k = { properties: { write: true }, writeValue: tulis }
    const jumlah = await kirimKeKarakteristik(k, new Uint8Array(50))
    expect(jumlah).toBe(3)
    expect(tulis).toHaveBeenCalledTimes(3)
  })

  it('cetakBluetooth menyambung lebih dulu lalu mengirim', async () => {
    const { layanan, tulis } = buatLayanan(UUID_LAYANAN_UMUM[0], true)
    const connect = vi.fn(async () => ({
      getPrimaryService: async () => layanan,
    }))
    await cetakBluetooth({ name: 'Printer Apa Saja', gatt: { connect } }, new Uint8Array([1]))
    expect(connect).toHaveBeenCalled()
    expect(tulis).toHaveBeenCalled()
  })

  it('gagal menyambung memberi pesan yang menyebut printer menyala & dekat', async () => {
    const connect = vi.fn(async () => {
      throw new Error('putus')
    })
    await expect(cetakBluetooth({ gatt: { connect } }, new Uint8Array([1]))).rejects.toThrow(
      /menyala/i,
    )
  })

  it('perangkat tanpa gatt ditolak dengan pesan jelas', async () => {
    await expect(cetakBluetooth({}, new Uint8Array([1]))).rejects.toThrow(GagalCetak)
  })
})

// --------------------------------------------------------------------- USB

describe('USB — menemukan jalur kirim', () => {
  it('mengutamakan antarmuka kelas 7 (Printer)', () => {
    const konfigurasi: KonfigurasiUsb = {
      interfaces: [
        {
          interfaceNumber: 0,
          alternate: { interfaceClass: 3, endpoints: [{ direction: 'out', endpointNumber: 9 }] },
        },
        {
          interfaceNumber: 1,
          alternate: { interfaceClass: 7, endpoints: [{ direction: 'out', endpointNumber: 2 }] },
        },
      ],
    }
    expect(cariJalurUsb(konfigurasi)).toEqual({ antarmuka: 1, ujung: 2 })
  })

  it('JAMINAN MEREK LAIN: printer yang tidak mengaku kelas 7 tetap dipakai', () => {
    const konfigurasi: KonfigurasiUsb = {
      interfaces: [
        {
          interfaceNumber: 0,
          alternate: { interfaceClass: 255, endpoints: [{ direction: 'out', endpointNumber: 4 }] },
        },
      ],
    }
    expect(cariJalurUsb(konfigurasi)).toEqual({ antarmuka: 0, ujung: 4 })
  })

  it('mendukung bentuk alternates (jamak) selain alternate', () => {
    const konfigurasi: KonfigurasiUsb = {
      interfaces: [
        {
          interfaceNumber: 3,
          alternates: [{ interfaceClass: 7, endpoints: [{ direction: 'out', endpointNumber: 1 }] }],
        },
      ],
    }
    expect(cariJalurUsb(konfigurasi)).toEqual({ antarmuka: 3, ujung: 1 })
  })

  it('jalur masuk saja (tanpa keluar) ditolak dengan pesan jelas', () => {
    const konfigurasi: KonfigurasiUsb = {
      interfaces: [
        {
          interfaceNumber: 0,
          alternate: { interfaceClass: 7, endpoints: [{ direction: 'in', endpointNumber: 1 }] },
        },
      ],
    }
    expect(() => cariJalurUsb(konfigurasi)).toThrow(GagalCetak)
  })
})

describe('cetakUsb — urutan langkah & pembersihan', () => {
  function buatPerangkat(): PerangkatUsb & { jejak: string[]; terkirim: unknown[] } {
    const jejak: string[] = []
    const terkirim: unknown[] = []
    return {
      jejak,
      terkirim,
      configuration: {
        interfaces: [
          {
            interfaceNumber: 0,
            alternate: { interfaceClass: 7, endpoints: [{ direction: 'out', endpointNumber: 1 }] },
          },
        ],
      },
      async open() {
        jejak.push('open')
      },
      async close() {
        jejak.push('close')
      },
      async selectConfiguration() {
        jejak.push('config')
      },
      async claimInterface() {
        jejak.push('claim')
      },
      async releaseInterface() {
        jejak.push('release')
      },
      async transferOut(_u: number, data: BufferSource) {
        jejak.push('kirim')
        terkirim.push(data)
      },
    }
  }

  it('membuka, mengambil antarmuka, mengirim, lalu MELEPAS dan menutup', async () => {
    const p = buatPerangkat()
    await cetakUsb(p, new Uint8Array([1, 2, 3]))
    expect(p.jejak).toEqual(['open', 'claim', 'kirim', 'release', 'close'])
  })

  it('antarmuka tetap dilepas walau pengiriman gagal (cetak berikutnya tidak ikut rusak)', async () => {
    const p = buatPerangkat()
    p.transferOut = async () => {
      p.jejak.push('kirim-gagal')
      throw new Error('putus')
    }
    await expect(cetakUsb(p, new Uint8Array([1]))).rejects.toThrow(GagalCetak)
    expect(p.jejak).toContain('release')
    expect(p.jejak).toContain('close')
  })

  it('gagal membuka memberi pesan tentang program lain', async () => {
    const p = buatPerangkat()
    p.open = async () => {
      throw new Error('sibuk')
    }
    await expect(cetakUsb(p, new Uint8Array([1]))).rejects.toThrow(/program lain/i)
  })

  it('memilih konfigurasi dulu bila perangkat belum punya', async () => {
    const p = buatPerangkat()
    p.configuration = null
    p.configurations = [
      {
        configurationValue: 1,
        interfaces: [
          {
            interfaceNumber: 0,
            alternate: { interfaceClass: 7, endpoints: [{ direction: 'out', endpointNumber: 1 }] },
          },
        ],
      },
    ]
    await cetakUsb(p, new Uint8Array([1]))
    expect(p.jejak).toContain('config')
    expect(p.jejak).toContain('kirim')
  })

  it('data yang dikirim sama persis dengan yang diminta', async () => {
    const p = buatPerangkat()
    const data = new Uint8Array([0x1b, 0x40, 0x41])
    await cetakUsb(p, data)
    expect(p.terkirim[0]).toBe(data)
  })
})
