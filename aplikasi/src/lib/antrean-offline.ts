/**
 * antrean-offline.ts — Antrean kirim luring berbasis IndexedDB (T10-01 / ART-8).
 *
 * Mengimplementasikan ketahanan saat koneksi kedai terputus:
 * 1. Pesanan dan aksi penulisan disimpan secara lokal di IndexedDB dengan kunci idempoten unik (ART-8).
 * 2. Tidak menyimpan data sensitif (PIN, kata sandi, token rahasia) — disaring otomatis.
 * 3. Mendukung fallback in-memory yang aman bila IndexedDB tidak tersedia/diblokir.
 * 4. Mendukung pemrosesan sekuensial (FIFO) otomatis saat kembali daring.
 */

export type StatusItemAntrean = 'menunggu' | 'mengirim' | 'gagal' | 'sukses'

export interface ItemAntrean {
  id: string
  jenis: string // misal: 'simpan_pesanan', 'bayar_pesanan', 'batal_pesanan'
  muatan: Record<string, unknown>
  kunciIdempoten: string // Wajib ART-8 untuk mencegah duplikasi di peladen
  status: StatusItemAntrean
  percobaan: number
  terakhirDicoba?: string | null
  pesanGalat?: string | null
  dibuatPada: string
  labelRingkas?: string // misal: "Pesanan Meja 03 — 2 Item"
}

export interface MasukanTambahAntrean {
  jenis: string
  muatan: Record<string, unknown>
  kunciIdempoten?: string
  labelRingkas?: string
}

export interface HasilProsesAntrean {
  diproses: number
  berhasil: number
  gagal: number
}

const NAMA_DB = 'resto_barokah_offline_db'
const NAMA_STORE = 'antrean_kirim'
const VERSI_DB = 1

/** Pola kunci data sensitif yang DILARANG disimpan di IndexedDB (DoD T10-01). */
const POLA_KUNCI_SENSITIF =
  /^(pin|pin_lama|pin_baru|pin_hash|kata_sandi|password|secret|kredensial|token_rahasia|authorization)$/i

/**
 * Memeriksa apakah suatu objek atau nilai memuat kunci data sensitif.
 */
export function apakahAdaDataSensitif(nilai: unknown): boolean {
  if (nilai === null || typeof nilai !== 'object') {
    return false
  }

  if (Array.isArray(nilai)) {
    return nilai.some((item) => apakahAdaDataSensitif(item))
  }

  for (const [kunci, isi] of Object.entries(nilai as Record<string, unknown>)) {
    if (POLA_KUNCI_SENSITIF.test(kunci)) {
      return true
    }
    if (typeof isi === 'object' && isi !== null && apakahAdaDataSensitif(isi)) {
      return true
    }
  }

  return false
}

/**
 * Membersihkan data sensitif (PIN, password, kredensial) secara rekursif sebelum disimpan (DoD).
 */
export function bersihkanDataSensitif<T>(nilai: T): T {
  if (nilai === null || typeof nilai !== 'object') {
    return nilai
  }

  if (Array.isArray(nilai)) {
    return nilai.map((item) => bersihkanDataSensitif(item)) as unknown as T
  }

  const hasil: Record<string, unknown> = {}
  for (const [kunci, isi] of Object.entries(nilai as Record<string, unknown>)) {
    if (POLA_KUNCI_SENSITIF.test(kunci)) {
      // Dihapus demi kepatuhan keamanan
      continue
    }
    hasil[kunci] = bersihkanDataSensitif(isi)
  }
  return hasil as T
}

/** Menghasilkan ID unik untuk item antrean. */
function buatIdUnik(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `antrean-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

/** Menghasilkan kunci idempoten default bila tidak disediakan pemanggil. */
export function buatKunciIdempoten(jenis = 'pos'): string {
  return `${jenis}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
}

// ============================================================================
// ADAPTER PENYIMPANAN: INDEXEDDB DENGAN FALLBACK MEMORI
// ============================================================================

/** Memori fallback saat IndexedDB tidak tersedia di lingkungan tertentu. */
const fallbackMemori = new Map<string, ItemAntrean>()

/** Callback pendengar perubahan antrean lokal. */
type PendengarAntrean = (daftar: ItemAntrean[]) => void
const daftarPendengar = new Set<PendengarAntrean>()

export function langgananPerubahanAntrean(pendengar: PendengarAntrean): () => void {
  daftarPendengar.add(pendengar)
  return () => {
    daftarPendengar.delete(pendengar)
  }
}

async function siarkanPerubahan(): Promise<void> {
  try {
    const daftar = await ambilSemuaAntrean()
    for (const pendengar of daftarPendengar) {
      try {
        pendengar(daftar)
      } catch {
        // Abaikan kesalahan di handler pendengar
      }
    }
    if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
      window.dispatchEvent(
        new CustomEvent('resto:antrean-berubah', {
          detail: { jumlah: daftar.filter((i) => i.status === 'menunggu').length },
        }),
      )
    }
  } catch {
    // Abaikan
  }
}

/** Membuka koneksi IndexedDB atau null bila tidak didukung. */
function bukaDb(): Promise<IDBDatabase | null> {
  return new Promise((resolve) => {
    if (typeof indexedDB === 'undefined') {
      resolve(null)
      return
    }

    try {
      const permintaan = indexedDB.open(NAMA_DB, VERSI_DB)

      permintaan.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result
        if (!db.objectStoreNames.contains(NAMA_STORE)) {
          const store = db.createObjectStore(NAMA_STORE, { keyPath: 'id' })
          store.createIndex('kunciIdempoten', 'kunciIdempoten', { unique: true })
          store.createIndex('status', 'status', { unique: false })
          store.createIndex('dibuatPada', 'dibuatPada', { unique: false })
        }
      }

      permintaan.onsuccess = () => {
        resolve(permintaan.result)
      }

      permintaan.onerror = () => {
        // Gagal membuka IndexedDB (mis. mode privat ketat) -> gunakan fallback
        resolve(null)
      }
    } catch {
      resolve(null)
    }
  })
}

// ============================================================================
// OPERASI ANTREAN
// ============================================================================

/**
 * Menambahkan pesanan/aksi ke dalam antrean offline.
 * Menjamin pembersihan data sensitif dan kepemilikan kunci idempoten (ART-8).
 */
export async function tambahKeAntrean(masukan: MasukanTambahAntrean): Promise<ItemAntrean> {
  const kunciIdempoten = (masukan.kunciIdempoten || buatKunciIdempoten(masukan.jenis)).trim()
  const muatanBersih = bersihkanDataSensitif(masukan.muatan)

  // Cek apakah sudah ada item dengan kunci idempoten ini (anti dobel lokal)
  const semua = await ambilSemuaAntrean()
  const sudahAda = semua.find((i) => i.kunciIdempoten === kunciIdempoten)
  if (sudahAda) {
    return sudahAda
  }

  const itemBaru: ItemAntrean = {
    id: buatIdUnik(),
    jenis: masukan.jenis,
    muatan: muatanBersih,
    kunciIdempoten,
    status: 'menunggu',
    percobaan: 0,
    dibuatPada: new Date().toISOString(),
    labelRingkas: masukan.labelRingkas,
  }

  const db = await bukaDb()
  if (!db) {
    fallbackMemori.set(itemBaru.id, itemBaru)
    void siarkanPerubahan()
    return itemBaru
  }

  return new Promise((resolve) => {
    try {
      const tx = db.transaction(NAMA_STORE, 'readwrite')
      const store = tx.objectStore(NAMA_STORE)
      const req = store.add(itemBaru)

      req.onsuccess = () => {
        void siarkanPerubahan()
        resolve(itemBaru)
      }

      req.onerror = () => {
        // Jika gagal karena index unik bentrok, kembalikan data yang ada
        fallbackMemori.set(itemBaru.id, itemBaru)
        void siarkanPerubahan()
        resolve(itemBaru)
      }

      tx.oncomplete = () => {
        db.close()
      }
    } catch {
      fallbackMemori.set(itemBaru.id, itemBaru)
      void siarkanPerubahan()
      resolve(itemBaru)
    }
  })
}

/**
 * Mengambil semua antrean tersimpan, diurutkan dari yang paling awal dibuat (FIFO).
 */
export async function ambilSemuaAntrean(): Promise<ItemAntrean[]> {
  const db = await bukaDb()
  if (!db) {
    const list = Array.from(fallbackMemori.values())
    return list.sort((a, b) => a.dibuatPada.localeCompare(b.dibuatPada))
  }

  return new Promise((resolve) => {
    try {
      const tx = db.transaction(NAMA_STORE, 'readonly')
      const store = tx.objectStore(NAMA_STORE)
      const req = store.getAll()

      req.onsuccess = () => {
        const hasil = (req.result || []) as ItemAntrean[]
        // Gabungkan dengan item fallback bila ada
        const gabunganMap = new Map<string, ItemAntrean>()
        for (const it of hasil) gabunganMap.set(it.id, it)
        for (const [id, it] of fallbackMemori.entries()) {
          if (!gabunganMap.has(id)) gabunganMap.set(id, it)
        }
        const daftar = Array.from(gabunganMap.values())
        daftar.sort((a, b) => a.dibuatPada.localeCompare(b.dibuatPada))
        resolve(daftar)
      }

      req.onerror = () => {
        resolve(Array.from(fallbackMemori.values()))
      }

      tx.oncomplete = () => {
        db.close()
      }
    } catch {
      resolve(Array.from(fallbackMemori.values()))
    }
  })
}

/**
 * Mengambil daftar antrean yang berstatus 'menunggu' atau 'gagal' (siap dikirim ulang).
 */
export async function ambilAntreanMenunggu(): Promise<ItemAntrean[]> {
  const semua = await ambilSemuaAntrean()
  return semua.filter((i) => i.status === 'menunggu' || i.status === 'gagal')
}

/**
 * Menghitung jumlah item yang menunggu dikirim (DoD: "menunggu dikirim X").
 */
export async function hitungAntreanMenunggu(): Promise<number> {
  const menunggu = await ambilAntreanMenunggu()
  return menunggu.length
}

/**
 * Memperbarui status item di antrean.
 */
export async function perbaruiStatusItem(
  id: string,
  status: StatusItemAntrean,
  pesanGalat?: string | null,
): Promise<void> {
  const db = await bukaDb()
  const sekarang = new Date().toISOString()

  if (!db) {
    const item = fallbackMemori.get(id)
    if (item) {
      item.status = status
      item.terakhirDicoba = sekarang
      item.percobaan += 1
      if (pesanGalat !== undefined) item.pesanGalat = pesanGalat
      fallbackMemori.set(id, item)
    }
    void siarkanPerubahan()
    return
  }

  return new Promise((resolve) => {
    try {
      const tx = db.transaction(NAMA_STORE, 'readwrite')
      const store = tx.objectStore(NAMA_STORE)
      const getReq = store.get(id)

      getReq.onsuccess = () => {
        const item = getReq.result as ItemAntrean | undefined
        if (item) {
          item.status = status
          item.terakhirDicoba = sekarang
          item.percobaan += 1
          if (pesanGalat !== undefined) item.pesanGalat = pesanGalat
          store.put(item)
        }
      }

      tx.oncomplete = () => {
        db.close()
        void siarkanPerubahan()
        resolve()
      }

      tx.onerror = () => {
        db.close()
        resolve()
      }
    } catch {
      resolve()
    }
  })
}

/**
 * Menghapus satu item dari antrean.
 */
export async function hapusItemAntrean(id: string): Promise<void> {
  fallbackMemori.delete(id)
  const db = await bukaDb()
  if (!db) {
    void siarkanPerubahan()
    return
  }

  return new Promise((resolve) => {
    try {
      const tx = db.transaction(NAMA_STORE, 'readwrite')
      const store = tx.objectStore(NAMA_STORE)
      store.delete(id)

      tx.oncomplete = () => {
        db.close()
        void siarkanPerubahan()
        resolve()
      }

      tx.onerror = () => {
        db.close()
        resolve()
      }
    } catch {
      resolve()
    }
  })
}

/**
 * Menghapus semua item yang sudah berstatus 'sukses' untuk menghemat ruang.
 */
export async function bersihkanAntreanSukses(): Promise<number> {
  const semua = await ambilSemuaAntrean()
  const sukses = semua.filter((i) => i.status === 'sukses')
  for (const item of sukses) {
    await hapusItemAntrean(item.id)
  }
  return sukses.length
}

/**
 * Mengosongkan seluruh antrean (misal saat reset darurat atau pergantian shift).
 */
export async function kosongkanSemuaAntrean(): Promise<void> {
  fallbackMemori.clear()
  const db = await bukaDb()
  if (!db) {
    void siarkanPerubahan()
    return
  }

  return new Promise((resolve) => {
    try {
      const tx = db.transaction(NAMA_STORE, 'readwrite')
      const store = tx.objectStore(NAMA_STORE)
      store.clear()

      tx.oncomplete = () => {
        db.close()
        void siarkanPerubahan()
        resolve()
      }

      tx.onerror = () => {
        db.close()
        resolve()
      }
    } catch {
      resolve()
    }
  })
}

/**
 * Memproses pengiriman antrean luring ke peladen satu per satu secara sekuensial (FIFO).
 * Menghentikan proses bila jaringan kembali terputus untuk menghindari spam kegagalan.
 */
export async function prosesAntrean(
  penangan: (item: ItemAntrean) => Promise<{ sukses: boolean; pesan?: string }>,
): Promise<HasilProsesAntrean> {
  const daftar = await ambilAntreanMenunggu()
  const hasil: HasilProsesAntrean = {
    diproses: 0,
    berhasil: 0,
    gagal: 0,
  }

  for (const item of daftar) {
    hasil.diproses += 1
    await perbaruiStatusItem(item.id, 'mengirim')

    try {
      const respon = await penangan(item)
      if (respon.sukses) {
        hasil.berhasil += 1
        await perbaruiStatusItem(item.id, 'sukses', null)
        // Hapus item yang berhasil dikirim agar antrean bersih
        await hapusItemAntrean(item.id)
      } else {
        hasil.gagal += 1
        await perbaruiStatusItem(item.id, 'gagal', respon.pesan || 'Gagal mengirim')

        // Jika terdeteksi masalah koneksi/jaringan, hentikan pengiriman sisa antrean
        if (
          respon.pesan?.toLowerCase().includes('network') ||
          respon.pesan?.toLowerCase().includes('fetch') ||
          respon.pesan?.toLowerCase().includes('koneksi') ||
          (typeof navigator !== 'undefined' && !navigator.onLine)
        ) {
          break
        }
      }
    } catch (err) {
      hasil.gagal += 1
      const pesan = err instanceof Error ? err.message : String(err)
      await perbaruiStatusItem(item.id, 'gagal', pesan)

      if (typeof navigator !== 'undefined' && !navigator.onLine) {
        break
      }
    }
  }

  return hasil
}
