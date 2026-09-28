# SESI YANG SENGAJA DITINGGALKAN (catatan Lee)

> Berkas ini **catatan manusia**: diisi atas perintah Lee, dibaca mesin (`alat/lanjut-sesi.py`).
> Gunanya: sesi yang memang ingin ditinggalkan **tidak** disarankan/dipakai lagi oleh sesi berikutnya.
> Menambah sesi ke daftar ini **tidak** menghapus apa pun — cabangnya tetap ada di GitHub sebagai
> riwayat. Isi satu baris per sesi: `| `cabang` | tanggal | alasan singkat |`

| Cabang | Tanggal | Alasan |
|---|---|---|
| `arena/01a0b4c3-resto-barokah` | 2026-09-18 | Sesi uji coba mekanisme pindah sesi (dibuka Lee untuk menguji, bukan untuk dipakai). Lee memutuskan melanjutkan sesi `arena/01a0a8a2-resto-barokah`; pekerjaannya tetap tersimpan di GitHub sebagai riwayat, tidak digabung. |

## Cara kerjanya (dijaga mesin)

- `python3 alat/lanjut-sesi.py` → **GAGAL** bila handoff `docs/ops/SIAP-LANJUT.md` menunjuk sesi di daftar ini.
- `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang-di-daftar-ini>` → **GAGAL** (dengan penjelasan).
- Kalau memang **mau** dilanjutkan atas keputusan Lee, tambahkan `--paksa`: pilihan itu dicatat di handoff
  (`Dasar pilihan cabang: … DIPAKSA atas perintah Lee (sesi tercatat sengaja ditinggalkan)`), jadi jejaknya terbaca.
- `python3 alat/lanjut-sesi.py --daftar-sesi` menandai sesi di daftar ini dengan tulisan **SENGAJA DITINGGALKAN**.
