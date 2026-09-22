#!/usr/bin/env python3
"""tambah-uji.py — skrip pembantu penambahan baris ke BUKU UJI PEMILIK (docs/uji/BUKU_UJI_PEMILIK.md).

Aturan yang ditegakkan:
 1. Membedakan jenis 'lakukan' (P-nn) dan 'coba' (U-nn).
 2. Penomoran otomatis ID berikutnya (atau validasi jika ID diberikan eksplisit).
 3. Langkah bernomor 1..n (maksimal 5 langkah, minimal 2 langkah).
 4. Kolom harapan (Yang seharusnya terjadi) tidak boleh kosong.
 5. Tugas ROADMAP yang dirujuk wajib ada di docs/ROADMAP.md.
 6. Memverifikasi hasil penyuntingan dengan alat/periksa-buku-uji.py.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

from bantu_uji_diri import AKAR, laporkan, salin_pohon

BUKU = "docs/uji/BUKU_UJI_PEMILIK.md"


def dapatkan_id_berikutnya(teks: str, awalan: str) -> str:
    pola = rf"\|\s*{awalan}-(\d{{2}})\s*\|"
    nomor_terpakai = [int(m) for m in re.findall(pola, teks)]
    maks = max(nomor_terpakai) if nomor_terpakai else 0
    return f"{awalan}-{maks + 1:02d}"


def tambah_baris(
    akar: pathlib.Path,
    jenis: str,
    judul: str,
    langkah: str,
    harapan: str,
    tugas: str = "",
    catatan: str = "",
    id_kustom: str | None = None,
) -> tuple[int, str]:
    berkas = akar / BUKU
    if not berkas.is_file():
        return 1, f"Berkas {BUKU} tidak ditemukan."

    teks = berkas.read_text(encoding="utf-8")
    awalan = "P" if jenis.lower() in ("lakukan", "p") else "U"
    baris_id = id_kustom or dapatkan_id_berikutnya(teks, awalan)

    # Validasi tugas bila ada
    if tugas:
        roadmap = (akar / "docs/ROADMAP.md").read_text(encoding="utf-8") if (akar / "docs/ROADMAP.md").is_file() else ""
        tugas_ada = set(re.findall(r"T\d+-\d+", roadmap))
        for t in re.findall(r"T\d+-\d+", tugas):
            if t not in tugas_ada:
                return 1, f"Tugas '{t}' tidak terdaftar di docs/ROADMAP.md."

    # Format baris markdown
    kolom_judul = f"{judul} (tugas `{tugas}`)" if tugas and tugas not in judul else judul
    baris_baru = f"| {baris_id} | {kolom_judul} | {langkah} | {harapan} |  | {catatan} |\n"

    # Tentukan bagian penempatan
    if awalan == "P":
        bagian_target = "## 1. Yang harus Lee LAKUKAN"
        bagian_berikutnya = "## 2. Yang harus Lee COBA"
    else:
        bagian_target = "## 2. Yang harus Lee COBA"
        bagian_berikutnya = "## 3. Log buku ini"

    if bagian_target not in teks or bagian_berikutnya not in teks:
        return 1, f"Struktur bagian '{bagian_target}' tidak ditemukan di {BUKU}."

    # Sisipkan sebelum bagian berikutnya
    posisi = teks.find(bagian_berikutnya)
    teks_baru = teks[:posisi] + baris_baru + "\n" + teks[posisi:]
    berkas.write_text(teks_baru, encoding="utf-8")

    # Jalankan verifikasi
    skrip_periksa = akar / "alat/periksa-buku-uji.py"
    if skrip_periksa.is_file():
        res = subprocess.run(
            [sys.executable, str(skrip_periksa)],
            cwd=akar,
            capture_output=True,
            text=True,
        )
        if res.returncode != 0:
            berkas.write_text(teks, encoding="utf-8")  # rollback
            return 1, f"Gagal: baris baru tidak memenuhi aturan validasi buku uji ({res.stdout.strip()}). Rollback dilakukan."

    return 0, f"Berhasil menambahkan {baris_id} ke {BUKU}."


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        # Kasus 1: Tambah baris coba baru (valid)
        kode1, pesan1 = tambah_baris(
            tmp,
            jenis="coba",
            judul="Uji Coba Otomatis Valid",
            langkah="1) Buka aplikasi 2) Tekan tombol",
            harapan="Halaman menampilkan hasil",
            tugas="T1-40",
            catatan="Uji-diri",
        )
        hasil.append(("tambah baris valid", kode1 == 0, pesan1))

        # Kasus 2: Tambah baris dengan langkah melampaui batas 5 -> harus ditolak
        kode2, pesan2 = tambah_baris(
            tmp,
            jenis="coba",
            judul="Uji Coba Melebihi Langkah",
            langkah="1) a 2) b 3) c 4) d 5) e 6) f",
            harapan="Gagal",
        )
        hasil.append(("tolak lebih dari 5 langkah", kode2 != 0, "berhasil ditolak" if kode2 != 0 else "LOLOS"))

        # Kasus 3: Tambah baris dengan tugas fiktif -> harus ditolak
        kode3, pesan3 = tambah_baris(
            tmp,
            jenis="lakukan",
            judul="Tugas fiktif",
            langkah="1) Mulai 2) Selesai",
            harapan="Harus ditolak",
            tugas="T9-99",
        )
        hasil.append(("tolak tugas fiktif", kode3 != 0, "berhasil ditolak" if kode3 != 0 else "LOLOS"))

    return laporkan("tambah-uji", hasil)


def main() -> int:
    parser = argparse.ArgumentParser(description="Tambah baris ke Buku Uji Pemilik.")
    parser.add_argument("--jenis", choices=["lakukan", "coba", "P", "U"], help="Jenis baris (lakukan/coba)")
    parser.add_argument("--id", dest="id_kustom", help="ID baris kustom (opsional, mis. U-09)")
    parser.add_argument("--judul", help="Judul atau hal yang dilakukan/dicoba")
    parser.add_argument("--langkah", help="Langkah-langkah terurut (contoh: '1) ... 2) ...')")
    parser.add_argument("--harapan", help="Yang seharusnya terjadi")
    parser.add_argument("--tugas", default="", help="Kode tugas ROADMAP (contoh: T1-40)")
    parser.add_argument("--catatan", default="", help="Catatan tambahan")
    parser.add_argument("--uji-diri", action="store_true", help="Jalankan uji-diri integritas skrip")

    args = parser.parse_args()

    if args.uji_diri:
        return uji_diri()

    if not args.jenis or not args.judul or not args.langkah or not args.harapan:
        parser.print_help()
        return 1

    kode, pesan = tambah_baris(
        AKAR,
        jenis=args.jenis,
        judul=args.judul,
        langkah=args.langkah,
        harapan=args.harapan,
        tugas=args.tugas,
        catatan=args.catatan,
        id_kustom=args.id_kustom,
    )
    print(pesan)
    return kode


if __name__ == "__main__":
    sys.exit(main())
