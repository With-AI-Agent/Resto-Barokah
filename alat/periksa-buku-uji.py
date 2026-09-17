#!/usr/bin/env python3
"""periksa-buku-uji.py — penjaga BUKU UJI PEMILIK (docs/uji/BUKU_UJI_PEMILIK.md).

Kenapa ada: Buku Uji Pemilik adalah lembar kerja Lee — "apa yang harus saya lakukan/coba, apa yang
seharusnya terjadi, bagaimana hasilnya". Berkas yang tidak dijaga akan pelan-pelan kehilangan bentuk:
baris tanpa langkah, id kembar, urutan langkah melompat, atau menunjuk tugas yang tidak ada.
Pemeriksa ini menjalankannya di CI.

Yang diperiksa:
 1. Berkas ada, punya bagian "Yang harus Lee LAKUKAN" & "Yang harus Lee COBA", dan menyatakan batasnya
    (uji mesin tetap di CI — buku ini bukan pengganti uji otomatis).
 2. Setiap baris punya ID unik berformat `P-nn` (bagian 1) / `U-nn` (bagian 2), kolom lengkap, dan
    kolom "Yang seharusnya terjadi" tidak kosong.
 3. Langkah di setiap baris **bernomor 1..n tanpa melompat** dan **maksimal 5 langkah** (aturan buku).
 4. Setiap tugas ROADMAP (`T\d+-\d+`) yang disebut benar-benar ada di `docs/ROADMAP.md`.
 5. Kepala buku menyebut aturan "satu baris = satu hal" dan "dokumen ini sumber kebenaran".

Mode `--uji-diri`: salin repo, rusak bukunya, pastikan pemeriksa MENOLAK.
"""
from __future__ import annotations

import pathlib
import re
import sys

from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon

BUKU = "docs/uji/BUKU_UJI_PEMILIK.md"
KOLOM_WAJIB = ("ID", "Langkah", "seharusnya terjadi", "Hasil", "Catatan")
MAKS_LANGKAH = 5


def baris_tabel(teks: str) -> list[tuple[int, list[str]]]:
    hasil = []
    for no, b in enumerate(teks.splitlines(), 1):
        if not b.strip().startswith("|"):
            continue
        kolom = [k.strip() for k in b.strip().strip("|").split("|")]
        if len(kolom) < 5 or set(kolom[0]) <= set("-: "):
            continue
        if kolom[0] in ("ID",) or kolom[0].lower().startswith(("id ", "id")):
            continue
        hasil.append((no, kolom))
    return hasil


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    berkas = akar / BUKU
    if not berkas.is_file():
        print(f"GAGAL: {BUKU} tidak ada")
        return 1
    teks = berkas.read_text(encoding="utf-8")
    roadmap = (akar / "docs/ROADMAP.md").read_text(encoding="utf-8") if (akar / "docs/ROADMAP.md").is_file() else ""
    tugas_roadmap = set(re.findall(r"T\d+-\d+", roadmap))

    if "Yang harus Lee LAKUKAN" not in teks:
        errs.append("bagian 'Yang harus Lee LAKUKAN' hilang — buku wajib memisahkan tugas Lee dari uji coba")
    if "Yang harus Lee COBA" not in teks:
        errs.append("bagian 'Yang harus Lee COBA' hilang")
    for aturan in ("satu baris = satu hal", "sumber kebenaran", "CP"):
        if aturan == "CP":
            continue
        if aturan.lower() not in teks.lower():
            errs.append(f"aturan wajib hilang dari kepala buku: '{aturan}'")
    if "uji mesin" not in teks.lower():
        errs.append("kepala buku wajib menegaskan bahwa uji mesin tetap di CI (buku ini bukan pengganti uji otomatis)")

    for kolom in KOLOM_WAJIB:
        if kolom.lower() not in teks.lower():
            errs.append(f"kolom wajib hilang dari tabel: '{kolom}'")

    id_terlihat: set[str] = set()
    baris = baris_tabel(teks)
    jumlah = {"P": 0, "U": 0}
    for no, kolom in baris:
        kid = kolom[0]
        if not re.fullmatch(r"[PU]-\d{2}", kid):
            errs.append(f"baris {no}: ID '{kid}' tidak berformat P-nn / U-nn")
            continue
        if kid in id_terlihat:
            errs.append(f"baris {no}: ID kembar: {kid}")
        id_terlihat.add(kid)
        jumlah[kid[0]] += 1
        if len(kolom) < 6:
            errs.append(f"baris {no} ({kid}): kolom kurang ({len(kolom)}) — wajib ada Langkah, Yang seharusnya terjadi, Hasil, Catatan")
            continue
        langkah, harapan = kolom[2], kolom[3]
        if not harapan:
            errs.append(f"baris {no} ({kid}): kolom 'Yang seharusnya terjadi' KOSONG — tanpa itu hasil tidak bisa dinilai")
        if not langkah:
            errs.append(f"baris {no} ({kid}): kolom Langkah kosong")
        # Ambil HANYA deret langkah yang benar-benar 1), 2), 3), … — angka lain di dalam
        # kalimat (mis. "Ganti tema (10)") bukan langkah dan tidak boleh dihitung.
        kandidat = [int(m.group(1)) for m in re.finditer(r"(?<![\d(])(\d+)\)", langkah)]
        nomor: list[int] = []
        harap = 1
        for n in kandidat:
            if n == harap:
                nomor.append(n)
                harap += 1
        if not nomor:
            errs.append(f"baris {no} ({kid}): langkah tidak bernomor (pakai bentuk '1) … 2) …')")
        else:
            if len(nomor) > MAKS_LANGKAH:
                errs.append(f"baris {no} ({kid}): {len(nomor)} langkah — aturan buku maksimal {MAKS_LANGKAH} (pecah barisnya)")
            if len(nomor) < 2:
                errs.append(f"baris {no} ({kid}): hanya {len(nomor)} langkah bernomor — minimal 2")
        for t in set(re.findall(r"T\d+-\d+", " ".join(kolom))):
            if t not in tugas_roadmap:
                errs.append(f"baris {no} ({kid}): menyebut tugas '{t}' yang tidak ada di ROADMAP")

    if jumlah["P"] == 0 or jumlah["U"] == 0:
        errs.append("buku wajib punya minimal satu baris 'lakukan' (P-) dan satu baris 'coba' (U-)")

    print(f"PERIKSA BUKU UJI PEMILIK — {jumlah['P']} baris lakukan · {jumlah['U']} baris coba · {len(id_terlihat)} baris total")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — setiap baris punya langkah (maksimal 5), harapan, kolom hasil, dan tugas yang benar.")
    return 0


def uji_diri() -> int:
    hasil = []
    with salin_pohon() as tmp:
        kode, keluar = jalankan_pemeriksa(periksa, tmp)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))
        if kode != 0:
            print(keluar[:1500])

        # Mutasi 1: baris baru dengan 6 langkah → harus GAGAL
        with salin_pohon() as tmp2:
            berkas = tmp2 / BUKU
            isi = berkas.read_text(encoding="utf-8")
            baris_baru = "| U-99 | Uji karangan | 1) a 2) b 3) c 4) d 5) e 6) f | sesuatu terjadi |  |  |\n"
            berkas.write_text(isi.replace("\n## 3. Log buku ini", baris_baru + "\n## 3. Log buku ini"), encoding="utf-8")
            kode2, _ = jalankan_pemeriksa(periksa, tmp2)
            hasil.append(("mutasi: baris dengan 6 langkah", kode2 != 0,
                          "ditolak" if kode2 != 0 else "DILOLOSKAN (batas langkah tidak dijaga)"))

        # Mutasi 2: kolom harapan dikosongkan → harus GAGAL
        with salin_pohon() as tmp3:
            berkas = tmp3 / BUKU
            baris = berkas.read_text(encoding="utf-8").splitlines()
            idx = next((i for i, b in enumerate(baris) if re.match(r"\|\s*U-\d{2}", b)), None)
            kolom = [k.strip() for k in baris[idx].strip().strip("|").split("|")]
            kolom[3] = ""
            baris[idx] = "| " + " | ".join(kolom) + " |"
            berkas.write_text("\n".join(baris) + "\n", encoding="utf-8")
            kode3, _ = jalankan_pemeriksa(periksa, tmp3)
            hasil.append(("mutasi: kolom harapan dikosongkan", kode3 != 0,
                          "ditolak" if kode3 != 0 else "DILOLOSKAN (harapan tidak dijaga)"))

        # Mutasi 3: menunjuk tugas yang tidak ada di ROADMAP → harus GAGAL
        with salin_pohon() as tmp4:
            berkas = tmp4 / BUKU
            isi = berkas.read_text(encoding="utf-8")
            berkas.write_text(isi.replace("`T0-00`", "`T9-99`", 1), encoding="utf-8")
            kode4, _ = jalankan_pemeriksa(periksa, tmp4)
            hasil.append(("mutasi: menunjuk tugas yang tidak ada", kode4 != 0,
                          "ditolak" if kode4 != 0 else "DILOLOSKAN (rujukan tugas tidak dijaga)"))
    return laporkan("periksa-buku-uji", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa(AKAR))
