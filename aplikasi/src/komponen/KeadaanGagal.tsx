import { Tombol } from './Tombol'

/**
 * Penjelasan saat data gagal dimuat + tombol mencoba lagi.
 * `role="alert"` dipakai supaya pembaca layar langsung memberitahu pegawai.
 */
export function KeadaanGagal({
  judul = 'Gagal memuat data',
  keterangan = 'Periksa sambungan internet lalu coba lagi.',
  onCoba,
}: {
  judul?: string
  keterangan?: string
  onCoba?: () => void
}) {
  return (
    <div className="keadaan keadaan-gagal" role="alert">
      <span className="keadaan-ikon" aria-hidden="true">
        !
      </span>
      <p className="keadaan-judul">{judul}</p>
      <p className="small muted">{keterangan}</p>
      {onCoba ? (
        <div className="keadaan-aksi">
          <Tombol ragam="biasa" onClick={onCoba}>
            Coba lagi
          </Tombol>
        </div>
      ) : null}
    </div>
  )
}
