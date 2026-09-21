/**
 * Penanda sedang memuat (bukan layar putih).
 * Batang berdenyut murni hiasan (`aria-hidden`), sedangkan pembaca layar
 * menerima teksnya lewat kelas `.sr`.
 */
export function KeadaanMemuat({
  judul = 'Memuat data…',
  baris = 3,
}: {
  judul?: string
  baris?: number
}) {
  return (
    <div className="keadaan keadaan-memuat" role="status" aria-live="polite">
      <span className="sr">{judul}</span>
      <div className="pemuat" aria-hidden="true">
        {Array.from({ length: Math.max(1, baris) }, (_, urutan) => (
          <span key={urutan} className="pemuat-batang" />
        ))}
      </div>
    </div>
  )
}
