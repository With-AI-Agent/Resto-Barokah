#!/usr/bin/env python3
"""periksa-rujukan.py — penjaga RUJUKAN HIDUP di dokumen yang MENGIKAT.

Kenapa ada: temuan audit A-F-08 / B-F-08 — `docs/teknis/BUKU_INSIDEN.md` (dokumen yang dibaca
saat keadaan darurat) menyuruh memakai alat `alat/denyut.py` yang **tidak ada**. Rujukan mati
di dokumen pengikut seperti itu bukan cacat kosmetik: saat panik, orang mengikuti langkahnya.

Buku induk (`PANDUAN_PENGGUNA.md`) sudah dijaga `alat/periksa-panduan.py`. Pemeriksa ini
menutup berkas pengikat lainnya:

  docs/teknis/BUKU_INSIDEN.md · docs/KEAMANAN.md · docs/PANDUAN_PEMILIK.md
  docs/ops/SIAP_AKUN_PEMILIK.md · docs/teknis/REKAM_PESAN_PEMILIK.md
  docs/uji/DAFTAR_PEKERJAAN_ULANG.md · docs/uji/AUDIT_RIWAYAT.md · docs/uji/REVIEW_PR_RIWAYAT.md
  docs/TERTANGGUH.md · PROFIL_PENGGUNA.md · ACCEPTANCE_TESTS.md

Aturan: setiap rujukan berkas harus benar-benar ada, KECUALI barisnya menandai bahwa berkas itu
memang belum ada (mengandung `(rencana)`, `belum ada`, `belum dibuat`, `akan dibuat`, `menyusul`,
`dijadwalkan`, atau id tugas seperti `T1-33`). Rujukan yang dilewati dicetak sebagai catatan —
supaya "ditandai rencana" tetap terlihat, bukan tersembunyi.

Mode `--uji-diri`: salin repo ke folder sementara, hidupkan rujukan mati, pastikan MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon

BERKAS_PENGIKAT = (
    "docs/teknis/BUKU_INSIDEN.md",
    "docs/KEAMANAN.md",
    "docs/PANDUAN_PEMILIK.md",
    "docs/ops/SIAP_AKUN_PEMILIK.md",
    "docs/teknis/REKAM_PESAN_PEMILIK.md",
    "docs/uji/DAFTAR_PEKERJAAN_ULANG.md",
    "docs/uji/AUDIT_RIWAYAT.md",
    "docs/uji/REVIEW_PR_RIWAYAT.md",
    "docs/TERTANGGUH.md",
    "PROFIL_PENGGUNA.md",
    "ACCEPTANCE_TESTS.md",
)

# URUTAN EKSTENSI PENTING: yang lebih panjang lebih dulu (`tsx` sebelum `ts`, `json` sebelum
# `js`). Cacat nyata 2026-09-17: `ts` lebih dulu -> rujukan `…/PemilihRingkas.tsx` terbaca
# sebagai `…/PemilihRingkas.ts` (berkas yang tidak ada) sehingga dokumen yang benar dianggap
# punya rujukan mati. Dijaga mutasi "berkas .tsx yang dirujuk dihapus" di uji-diri.
POLA_JALUR = re.compile(r"(?:alat|docs|supabase|aplikasi|_sistem|_log-sesi|prototipe|\.github)/[\w./-]+\.(?:tsx|markdown|mjs|json|ya?ml|sql|html|md|py|sh|ts)")
POLA_HARAPAN = re.compile(r"\(rencana|belum ada|belum dibuat|akan dibuat|menyusul|dijadwalkan|T\d+-\d+", re.I)


def rujukan_dalam(teks: str) -> list[tuple[int, str, str]]:
    """Kembalikan (nomor baris, jalur, baris) untuk setiap rujukan berkas."""
    hasil: list[tuple[int, str, str]] = []
    for no, baris in enumerate(teks.splitlines(), 1):
        kandidat = set(POLA_JALUR.findall(baris))
        for m in re.finditer(r"`([^`\n]+)`", baris):
            t = m.group(1).strip()
            if POLA_JALUR.fullmatch(t):
                kandidat.add(t)
        for t in sorted(kandidat):
            hasil.append((no, t.rstrip(".,;:)"), baris))
    return hasil


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    catatan: list[str] = []
    total = 0
    for rel in BERKAS_PENGIKAT:
        berkas = akar / rel
        if not berkas.is_file():
            errs.append(f"berkas pengikat hilang: {rel}")
            continue
        teks = berkas.read_text(encoding="utf-8")
        for no, jalur, baris in rujukan_dalam(teks):
            total += 1
            if (akar / jalur).exists():
                continue
            if POLA_HARAPAN.search(baris):
                catatan.append(f"{rel}:{no} rujukan ditandai rencana → {jalur}")
                continue
            errs.append(f"{rel}:{no} menunjuk berkas yang TIDAK ADA: {jalur}")
    print(f"PERIKSA RUJUKAN — {len(BERKAS_PENGIKAT)} dokumen pengikat · {total} rujukan diperiksa")
    for c in catatan:
        print(f"  [catatan] {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} rujukan mati")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — semua rujukan di dokumen pengikat hidup (yang belum ada ditandai jelas).")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1500])

        # Mutasi: rujukan mati baru di dokumen darurat → harus GAGAL
        with salin_pohon() as tmp2:
            berkas = tmp2 / "docs/teknis/BUKU_INSIDEN.md"
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi + "\n7. Jalankan `alat/alat-yang-belum-ada.py` untuk memulihkan.\n", encoding="utf-8")
            kode2, keluar2 = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(("mutasi: rujukan mati disisipkan di Buku Insiden", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (tumpul)"))

        # Mutasi: rujukan mati diberi penanda rencana → harus LULUS (aturan penanda bekerja)
        with salin_pohon() as tmp3:
            berkas = tmp3 / "docs/teknis/BUKU_INSIDEN.md"
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi + "\n7. Jalankan `alat/alat-yang-belum-ada.py` (rencana, dibuat di T1-30).\n", encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(("mutasi: rujukan mati DITANDAI rencana", kode3 == 0,
                          "diterima" if kode3 == 0 else "ditolak (penanda rencana tidak bekerja)"))
        # Mutasi: berkas `.tsx` yang DIRUJUK di dokumen pengikat dihapus → harus GAGAL.
        # Mutasi ini menjaga jebakan ekstensi di POLA_JALUR (dulu `.tsx` terbaca `.ts`
        # sehingga mutasi seperti ini DILOLOSKAN).
        with salin_pohon() as tmp4:
            berkas = tmp4 / "docs/uji/REVIEW_PR_RIWAYAT.md"
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi + "\n9. Bukti: `aplikasi/src/komponen/PemilihRingkas.tsx` (uji antarmuka).\n", encoding="utf-8")
            (tmp4 / "aplikasi/src/komponen/PemilihRingkas.tsx").unlink()
            kode4, _ = jalankan_pemeriksa(periksa, tmp4)
            hasil.append(("mutasi: berkas .tsx yang dirujuk DIHAPUS", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (rujukan .tsx tak terbaca)"))

    return laporkan("periksa-rujukan", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
